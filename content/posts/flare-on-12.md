---
title: "Flare-On 12 - All Nine, Top 100"
topic: "reverse-engineering"
tags: ["reverse-engineering", "ctf", "obfuscation"]
prev: "/posts/perseus-deobfuscation/"
next: "/posts/nsacodebreaker2022-taska1/"
date: 2026-08-21T10:00:00-05:00
---

# Table of Contents
1. [The competition](#the-competition)
2. [How it went](#how-it-went)
3. [How long did it take](#how-long-did-it-take)
4. [Which was my favorite](#which-was-my-favorite)
5. [Lessons learned](#lessons-learned)
6. [Conclusion](#conclusion)

- - -

![Flare-On 12 placement](/posts/placement.png "Flare-On 12 placement")

## The competition

Flare-On is Mandiant's annual reverse engineering CTF, and it's one of the few competitions that
is *only* reverse engineering. No web, no pwn, no misc. Challenges range across malicious
document formats, obfuscated binaries, custom cryptography, and whatever else the FLARE team
feels like inflicting that year. It runs for about six weeks, and the difficulty curve is steep
on purpose. Just look at these solve rates:

![Flare-On 12 Solve Rate](/posts/solverates.png "Solve Rates")

I went into Flare-On 12 in the fall of 2025 with one goal: solve all nine challenges. I managed
it, and finished *83rd* overall!

## How it went

I promised writeups for every challenge back in October and never delivered. Between work, life,
and grinding on the last NSA Codebreaker, I let it sit too long. As I write this we're about
30 days out from Flare-On 13, and it's safe to say my recollection of each solution is hazy at
best.

So rather than nine reconstructed writeups I'd only half-trust, here's what I do remember: how it
went, the lessons I took away from it, and the screenshots I collected over two-ish weeks of
effort. Proof is in the pudding, or something along those lines.

## How long did it take

![Flare-On 12 solve time](/posts/solvetime.png "Flare-On 12 solve time")

I started the evening after work on September 26th and solved the first challenge at 5:11 PM. The
last one fell on October 9th at 10:55 PM. Nine challenges in 13 days, worked around a full-time
job, a weekend at Disneyland, and considerably less sleep than I'd recommend to anyone. Challenge
7 cost me my first all-nighter since I was a teenager.

## Which was my favorite

Challenge 7 and Challenge 9, for completely different reasons.

**Challenge 7** was the one that felt closest to the day job. The sample turned out to be a C2
client, and solving it meant reading a PCAP, working out how the clients communicated with the
server, and using that to decrypt the traffic. I ended up writing my own server so I could issue
commands to the sample and watch how it behaved. That was real malware analysis work, just with a
flag at the end of it.

**Challenge 9** makes the list purely for its audacity: a 1 GB file containing 10,000 DLLs.
Absolute insanity, and a genuinely fun problem to pick apart.

## Lessons learned

**On getting stuck.** I learned more about my own process here than about any single technique,
specifically what I need to do when I've been staring at the same problem for hours. Being
consistent and stubborn matters more than being clever. The stretch where you're most frustrated
is usually the point where you're closest to the answer, and internalizing that made it much
easier to keep going.

**On tooling.** Don't marry a single RE tool. I used Ghidra, Binary Ninja, and IDA Home on every
challenge, and each one had strengths and weaknesses that showed up in different places. I'm
quite partial to Binary Ninja these days (it's an amazing tool that only seems to get better
with time), but the real win was being willing to move between all three.

I also picked up [Malcat](https://malcat.fr/), a one-time-purchase disassembler that I now
recommend to anyone who'll listen. It came in clutch on Challenge 7: it uses Yara signatures to
surface anomalies and flag the things worth a second look.

**On using frontier models.** This CTF was my first time working alongside Claude, and I came out
of it with a workflow I've kept since. I know I'm capable of solving all nine without a model. I
also know it would have taken me considerably longer.

The distinction that mattered was *how* I used it. Dumping large chunks of code in and blindly
hoping the model solves your problem doesn't work, and it doesn't teach you anything. What did
work was using it to bridge specific gaps: getting oriented in an unfamiliar section of assembly,
writing scripts that would otherwise have eaten an hour, and working through a theory before I
committed real time to a direction that turned out to be a rabbit hole. The reversing stayed
mine. The model cut down the overhead around it.

## Conclusion

Overall, I'm proud to be one of 273 finishers out of 4,139 registered players, and prouder still
to have landed 83rd among them. The canvas tote is on display, and I'm already looking forward to
Flare-On 13.

Flare-On remains the best RE competition out there. If you've never tried it, the challenges stay
online after the competition ends. [flare-on.com](https://flare-on.com) has the full archive
going back to Flare-On 1.
