---
title: "Back At It - What I've Been Up To Since 2022"
topic: "general"
tags: ["general", "reverse-engineering", "hardware", "machine-learning"]
next: "/posts/perseus-deobfuscation/"
date: 2026-08-21T10:00:00-05:02
---

# Table of Contents
1. [Grad school, and a pivot](#grad-school-and-a-pivot)
2. [Perseus](#perseus)
3. [Flare-On 12](#flare-on-12)
4. [NSA Codebreaker, again](#nsa-codebreaker-again)
5. [Teaching hardware hacking at BSides SD](#teaching-hardware-hacking-at-bsides-sd)
6. [A badge for DEF CON 2027](#last-but-not-least-a-badge-for-def-con-2027)

- - -

The last thing I posted here was my NSA Codebreaker 2022 writeup series. That was almost four
years ago. Plenty has happened since, so this is the catch-up post.

## Grad school, and a pivot

I finished my M.S. in Cybersecurity at Georgia Tech in May 2026.

The longer version is that I didn't start out in the cybersecurity program. I was two classes
from finishing an M.S. in Computer Science with a specialization in Artificial Intelligence when 
I decided to switch. Around that time I recently got a full time job working in the Cybersecurity
industry and wanted the degree to match where my career was going. 

That being said, two classes was a genuinely annoying place to change my mind, but I don't regret it.
The AI coursework turned out to be far from wasted and my capstone ended up sitting squarely on top of it.

## Perseus

My capstone was **Perseus**, a tool that fine-tunes code LLMs to automatically deobfuscate x86-64
assembly. Obfuscated function in, clean function out.

It works reasonably well on mixed boolean arithmetic and control flow flattening, but fails
completely on virtualization.

I wrote it up properly here: [Perseus - Teaching an LLM to Deobfuscate Malware](/posts/perseus-deobfuscation).
You can read the paper [here](/papers/perseus.pdf) and find the code on my github at
[github.com/aromans/Perseus](https://github.com/aromans/Perseus).

## Flare-On 12

Solved all nine challenges in Flare-On 12 and finished in the top 100. Still the best RE
competition running. [More on that here](/posts/flare-on-12).

![Flare-On 12 solve time & placement](/posts/solvetime.png "Flare-On 12 Solve time & Placement")

## NSA Codebreaker, again

Came back to the NSA Codebreaker Challenge in 2025 and earned High Performer, solving all but
one task — the same result I managed in 2022.

![High Performer](/posts/highperformer2025.png "High Performer 2025")

## Teaching hardware hacking at BSides SD

I created an introductory hardware hacking CTF at **BSides San Diego 2026**. 

The challenge consisted of a Pico rp2040. Hackers could either use my provided
walkthrough that held their hand every step of the way, teaching them about
hardware hacking concepts and their real-world equivalents. Or more seasoned
hackers could attempt the challenges on their own, using the walkthrough as a
crutch if they got stuck.

The challenge taught the UART and SPI protocols, how to use a logic analyzer to
extract a squashfs over the SPI protocol, how to extract the rootfs from a
squashfs file, and nested standard CTF challenges such as password hash cracking,
binary pwn, and more. Lastly, I provided an opportunity for hackers to learn about
Electromagnetic Fault Injection (EMFI) with the ability to use a [FaultyCat](https://pwnlab.mx/products/faultycat/) to glitch the rp2040 on boot. 

If you are interested in trying the challenges yourself, all you need is an extra
Pico rp2040. Walkthrough and firmware can be found on my github [here](https://github.com/aromans/Bsides2026). 

## Last but not least, a badge for DEF CON 2027

I've started building an electronic badge for **DEF CON 2027** that will consist of 
different CTF challenges and more goodies!

I know what you are thinking, at the time of writing this we are a 
year away from Defcon 35! Well, after getting a taste of making my [first SAO for 
Defcon 33](https://github.com/aromans/DumpsterSAO), I wanted to do more.
This project is very ambitious, so I'm getting started early to make sure I finish
on time!

I'll post more updates on that as it comes together.

- - -

That's the gap closed. The plan going forward is to post more often than once every four years.
