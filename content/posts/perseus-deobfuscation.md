---
title: "Perseus - Teaching an LLM to Deobfuscate Malware"
topic: "malware-analysis"
tags: ["reverse-engineering", "malware-analysis", "machine-learning", "obfuscation"]
prev: "/posts/back-at-it-2026/"
next: "/posts/flare-on-12/"
date: 2026-08-21T10:00:00-05:01
---

# Table of Contents
1. [Why bother](#why-bother)
2. [What Perseus actually is](#what-perseus-actually-is)
3. [The three obfuscations](#the-three-obfuscations)
4. [The data pipeline](#the-data-pipeline)
5. [Training](#training)
6. [Results](#results)
7. [The Flare-On test](#the-flare-on-test)
8. [Where it fell apart](#where-it-fell-apart)
9. [What I'd do differently](#what-id-do-differently)

- - -

This was my M.S. capstone at Georgia Tech, finished in May 2026. The short version: I fine-tuned
four code LLMs to take obfuscated x86-64 assembly as input and emit clean, semantically
equivalent assembly as output. It worked on two of the three obfuscation classes I targeted and
failed completely on the third.

Paper is [here](/papers/perseus.pdf). Code is at
[github.com/aromans/Perseus](https://github.com/aromans/Perseus).

## Why bother

Manual reverse engineering of obfuscated malware is slow, and it is slow in a particular way:
you spend most of your time not on the interesting logic but on undoing whatever transformation
the author applied to hide it. During incident response that time is expensive.

Prior work on automated deobfuscation leaned on dynamic trace analysis, API call recovery, and
guided binary methods. Machine learning had been applied plenty to malware *classification*
(is this sample malicious, what family is it), but assembly-level deobfuscation across multiple
obfuscation types was largely untouched. Given how good code models have gotten at reading
assembly, trying it seemed overdue.

## What Perseus actually is

Perseus takes a single obfuscated x86-64 function and produces a deobfuscated version of it.
Assembly in, assembly out. It's built as an analyst *assistance* tool, which
matters a lot for how you should read the numbers later on.

## The three obfuscations

I picked three techniques that break a binary in genuinely different ways, with minimal overlap:

**Mixed Boolean Arithmetic (MBA)** rewrites arithmetic using semantically equivalent but
gnarly bitwise identities. `x + y` becomes `(x ^ y) + 2*(x & y)`. The control flow is
untouched and the obfuscation lives entirely inside expressions. This is *expression-level*.

**Control Flow Flattening (CFF)** tears out the function's branching structure and replaces it
with a state machine: every basic block gets a numeric state ID, all of them get stuffed into a
switch, and a dispatcher decides what runs next. The instructions inside each block stay
readable, which gives you a false sense of confidence. This is *graph-level*.

Here's what it does to `strend`, a 16-instruction string traversal:

```nasm
; strend -- CFF obfuscated (40 instructions)
+0x0:  endbr64
+0x4:  push rbp
+0x5:  mov rbp, rsp
+0x8:  mov qword ptr [rbp - 0x18], rdi
+0xc:  mov qword ptr [rbp - 8], 2      ; state = 2 (initial)
+0x14: cmp qword ptr [rbp - 8], 6
+0x19: ja +0x95                        ; dispatcher: bounds check
+0x1b: mov rax, qword ptr [rbp - 8]
+0x1f: lea rdx, [rax*4]
+0x27: lea rax, [rip + 0xe3b]          ; jump table base
+0x2e: mov eax, dword ptr [rdx + rax]
+0x31: cdqe
+0x33: lea rdx, [rip + 0xe2f]
+0x3a: add rax, rdx
+0x3d: notrack jmp rax                 ; computed dispatch
+0x40: mov rax, qword ptr [rbp - 0x18] ; case 2: return s
+0x44: jmp +0x9b
+0x46: add qword ptr [rbp - 0x18], 1   ; case 1: s++
+0x4b: mov qword ptr [rbp - 8], 6      ; state = 6
+0x53: jmp +0x96                       ; -> dispatcher
...
```

That `notrack jmp rax` in the middle of the dispatcher is the disorienting part. There is no
branch target to follow, just a jump table resolved at runtime.

**Virtualization** replaces native instructions with bytecode for a custom ISA, executed by an
embedded interpreter. There are no shared semantics with x86 at all; you have to learn the VM
before you can say anything about the program. This is *full abstraction*, and it's by far the
hardest of the three.

## The data pipeline

This ended up being most of the work, and in hindsight it's the part I'd point at first.

1. **Source collection.** C files pulled from [AnghaBench](https://github.com/brenocfg/AnghaBench),
   a suite of a million compilable programs mined from large public GitHub C repos. Each
   candidate gets filtered on a minimum line count and at least one control flow construct, then
   test-compiled with GCC. Failures are discarded.
2. **Obfuscation.** [Tigress](https://tigress.wtf/) processes each file three times:
   `EncodeArithmetic` for MBA, `Flatten` for CFF, `Virtualize` for virtualization, leaving four
   variants per source file including the clean one.
3. **Compilation.** All four variants compiled to x86-64 ELF with GCC at `-O0`, to preserve the
   structure of the obfuscated output.
4. **Disassembly.** Function boundaries pulled from the ELF symbol table, each function
   disassembled independently with objdump. CRT boilerplate (`_start`, `frame_dummy`, etc.)
   dropped here.
5. **Pair construction.** Each obfuscated function is paired with its clean counterpart and
   serialized to JSONL, then split into train/validation/test.

Tigress can produce unlimited instances at controllable difficulty, and every single
one arrives with ground truth attached. That property turned out to matter more than any
modeling decision I made.

### Normalization

Raw disassembly can't go straight into a model. Absolute virtual addresses shift between
compilation runs and carry no structural information, so every instruction address is rewritten
as a function-relative offset (`+0x{offset}`). For control flow instructions, operand addresses
are resolved against a symbol map built from `.symtab` and `.dynsym`; targets inside the
function's own boundaries become relative offsets, anything else keeps its raw address.

There's a second normalization pass at evaluation time, which exists entirely because
DeepSeek-Coder kept emitting whitespace-collapsed output that failed string comparison despite
being semantically correct. Strings get split on address boundaries, prefixes stripped,
whitespace removed, everything lowercased.

## Training

Four base models, chosen for strong code benchmarks and a spread of parameter counts so I could
see how scale mattered: **Qwen2.5-Coder 1.5B**, **Qwen2.5-Coder 7B**, **DeepSeek-Coder 6.7B**,
and **Codestral-22B**.

All four trained with QLoRA: LoRA adapters on 4-bit quantized frozen base weights, rank
`r = 16`, `alpha = 32`, and dropout `0.1`. The 1:2 rank-to-alpha ratio is a standard starting point
that lets the adapters actually influence the base model without stomping its pretrained
representations. Adapters go into all seven projection layers (`q_proj`, `k_proj`, `v_proj`,
`o_proj`, `gate_proj`, `up_proj`, `down_proj`), which are consistent across all four since they
share a transformer architecture.

5,000 AnghaBench samples, 12 epochs, early stopping, top 3 checkpoints saved. Codestral-22B
trained on a rented H100 PCIe 80GB. Checkpointing was not optional there, since I lost a
session early on and had to redo it.

## Results

Scoring uses exact match and a line-level F1, plus an `F1*` variant that replaces `[rip + 0xN]`
operands with a placeholder before comparison. That last one exists because RIP-relative offsets
legitimately differ between the obfuscated and clean binaries even when the instruction is
correct, and I was penalizing the model for it.

---
| Model | Exact | F1 | F1* |
|---|---|---|---|
| Qwen2.5-Coder-1.5B | 0.0% | 0.261 | 0.290 |
| Qwen2.5-Coder-7B | 0.0% | 0.275 | 0.314 |
| DeepSeek-Coder-6.7B | 0.0% | 0.279 | 0.309 |
| Codestral-22B | 0.0% | 0.344 | 0.388 |


| Model | MBA | MBA* | CFF | CFF* | Virt | Virt* |
|---|---|---|---|---|---|---|
| Qwen2.5-Coder-1.5B | 0.447 | 0.463 | 0.302 | 0.382 | 0.061 | 0.061 |
| Qwen2.5-Coder-7B | 0.454 | 0.523 | 0.326 | 0.378 | 0.073 | 0.074 |
| DeepSeek-Coder-6.7B | 0.471 | 0.493 | 0.313 | 0.389 | 0.079 | 0.079 |
| Codestral-22B | 0.510 | 0.539 | 0.505 | 0.619 | 0.066 | 0.066 |
---

Exact match is 0% everywhere, which is expected at this data scale. Functions run 10 to 30+
instructions and one wrong register fails the whole thing.

Two things stand out. First, the jump from 7B to 22B matters far more than the jump from 1.5B to
7B; the three smaller models cluster together and Codestral pulls away, most dramatically on CFF
(0.505 vs ~0.31). That tracks with what CFF actually demands: reconstructing a state machine
means reasoning about the whole function at once, not instruction by instruction, and that
favors larger models. Second, virtualization drags the weighted average down across the board.

**Is 0.344 good?** Depends entirely on the use case. For autonomous deobfuscation with no human
involved, it's useless. For an assistance tool it's a different question: does this reduce the
time and cognitive load of understanding an obfuscated function?

Consider `strchr` under MBA, where Codestral scored F1 0.426. By the metric, less than half the
instructions match. The obfuscated version blows two simple equality checks into dense 10-12
instruction bitwise sequences, growing the function from 21 to 42 instructions. Perseus collapses
it back to 26. And any analyst reading that output sees args on the stack, a byte fetched per
iteration, a null check, a character comparison, a pointer increment, a loop. That's `strchr`,
identifiable in seconds. Manual analysis of those MBA sequences gets you to the same place,
considerably slower.

## The Flare-On test

To check whether any of this generalized outside the training distribution, I pulled a function
out of `FlareAuthenticator.exe`, challenge 8 from
[Flare-On 12](/posts/flare-on-12). Perseus was trained exclusively on ELF binaries built by GCC
and obfuscated with Tigress. This is a Windows PE, hand-obfuscated by the FLARE team, using
techniques Perseus never saw.

The target function at RVA `0x176c2` is 18 MBA-obfuscated instructions:

```nasm
; Obfuscated input (18 instructions)
0x176c2: mov rax, [rbp + 0x678]
0x176c9: mov r9, [rbp + 0x348]
0x176d0: mov rdx, [rax + 0x78]
0x176d4: mov rcx, r9
0x176d7: not rcx
0x176da: mov r8, rdx
0x176dd: not r8
0x176e0: or  r8, rcx
0x176e3: mov rcx, rdx
0x176e6: add rcx, r9
0x176e9: lea r8, [r8 + rcx + 1]
0x176ee: or  rdx, r9
0x176f1: sub rcx, rdx
0x176f4: mov rdx, rcx
0x176f7: or  rdx, r8
0x176fa: and rcx, r8
0x176fd: add rcx, rdx
0x17700: mov [rax + 0x78], rcx
```

Fine-tuned Qwen2.5-7B and Codestral-22B both got it:

```nasm
; Codestral-22B, fine-tuned (5 instructions)
0x176c2: mov rax, [rbp + 0x678]
0x176c9: mov rdx, [rbp + 0x348]
0x176d0: mov rcx, [rax + 0x78]
0x176d4: add rcx, rdx
0x176d7: mov [rax + 0x78], rcx
```

Eighteen instructions down to five. The whole sequence is `[rax + 0x78] += r9`. Qwen produced
the same thing using `rdx` instead of `rcx` different register allocation, equally correct.

The base models are the instructive part. Both Codestral-22B base and Qwen2.5-7B base responded
with *markdown prose*: "The given assembly function is obfuscated using Mixed Boolean-Arithmetic
(MBA) technique. Here's the deobfuscated version:" followed by a code block with wrong
arithmetic and a numbered explanation. They understood the request. They had not learned the
output format or the algebraic reasoning to actually simplify it. Fine-tuning fixed both.

The other two fine-tuned models echoed the input back unchanged.

## Where it fell apart

Virtualization failed completely, F1 between 0.061 and 0.079, and RIP normalization changed
nothing because the errors weren't positional.

The cause is input length. Tigress `Virtualize` expands functions by **3.5x to 7.9x**:

---
| Sample | Clean | Virtualized |
|---|---|---|
| glxewInfo | 71 | 273 |
| layout | 164 | 568 |
| tiler | 111 | 604 |
| hash | 102 | 673 |
| psm | 91 | 722 |
| poll | 155 | 940 |
---

Clean functions in my test set ran 16 to 109 instructions. Their virtualized counterparts
averaged over 600 and peaked past 1,000, well beyond a 4,096-token context window.

The failure mode is the part worth staring at. **Perseus generated roughly 48 instructions
every time, regardless of how long the clean function actually was.** It wasn't deobfuscating
badly; it had learned a fixed-length approximation that scores non-zero without doing the task
at all.

I considered a sliding window and rejected it. Virtualized code has a fetch-decode-dispatch
structure, and slicing it into windows destroys exactly the structural context that makes the
dispatcher identifiable. You'd hand the model fragments of handler code with no view of how they
connect, which is the one thing it needs.

The right fix is a control flow graph. I initially wrote a CFG builder with the idea
of going down the route of basic block extraction, edge classification, graph-level features
for training all obfuscation types (`src/feature_selection.py`). Unfortunately, I ran out of
time before I could wire it into the training pipeline.

While I was writing this up, [Pushan](https://arxiv.org/abs/2603.18355) was
shown to me by another grad student. In March 2026, this paper demonstrated CFG-based virtualization 
deobfuscation with 988 of 1,000 Tigress binaries successfully handled. They decompile to C pseudocode
rather than recovering assembly, but the underlying insight is the same one my unused code was reaching 
for: **the structure lives in the graph, not the linear trace.**

Seeing that felt genuinely great. I never got to finish the idea myself, but having an
independent team land in the same place and prove it out was the best confirmation I could have
asked for that I'd been digging in the right spot.

## What I'd do differently

**A semantic evaluation metric.** Line-level F1 measures structural similarity, not semantic
equivalence. Two assembly sequences can do identical things and score badly because of register
allocation or instruction ordering. Compiling the output and comparing execution traces would
tell me what I actually want to know. For an assistance tool this distinction matters: correct
output with different registers is still useful, and incorrect output that *looks* structurally
right is actively harmful.

**More data, and different data.** 5,000 samples is not much. Real malware samples would be the
obvious next source.

**Other obfuscators.** Everything here is Tigress. Real-world malware uses OLLVM, Themida,
VMProtect, and custom packers, and I have exactly one data point (the Flare-On result)
suggesting MBA patterns transfer across toolchains. That needs much broader validation before
I'd claim it.

**Wire up the CFG.** See above.

**Make it a plugin.** The whole design premise is that this sits alongside an analyst's
workflow, and an analyst's workflow is IDA, Ghidra, or Binary Ninja. Deobfuscating a function
without leaving the disassembler is the version of this that people would actually use.

- - -

Perseus is not an analyst-ready tool. It can't handle virtualization, it's only ever seen one
obfuscator, and its evaluation metric measures the wrong thing. But it does collapse real MBA
from a real CTF binary it was never trained on, which is more than I expected when I started,
and the path from here is clear enough that I'll probably keep pulling on it.

Paper: [/papers/perseus.pdf](/papers/perseus.pdf) ·
Code: [github.com/aromans/Perseus](https://github.com/aromans/Perseus)
