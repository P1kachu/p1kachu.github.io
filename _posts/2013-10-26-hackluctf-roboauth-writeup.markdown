---
layout: post
writeup: :)
title:  "Hack.lu 2013 - RoboAuth.exe Writeup (RE)"
date:   2013-10-26 22:00:00
description: Hack.lu CTF 2013 - Roboauth.exe RE 100  Writeu
categories:
- writeup
- RE
---

> Oh boy, those crazy robots can't catch a break! Now they're even stealing our
> liquid gold from one of our beer tents! And on top of that they lock it behind
> some authentication system. Quick! Access it before they consume all of our
> precious beverage!

RobotAuth.exe is a Windows PE32 from the Hack.lu 2013, worth 150 points.

When launched, that prompts a banner and ask for a first password, which
is consistent with the website asking for a flag under the form `passwd1_passwd2`.
I find a string `'You passed level 1!'`, Xrefs to it, and I am in the function
that prints the beginning of the text and reads the first user input (`sub_401627`).

By disassembling it in IDA, we can start understanding what's going on. The function
registers a handler with `getModuleHandle` and `getProcAddress`. The first
password appears quickly after (`r0b0RUlez!`).
It's a simple strcmp that allows us to examine the strings addresses (and thus
contents) at runtime.

Great, now the second password. By stepping in, we finally hit a trap debugger
that, if passed to the program (meaning, not discarded by IDA), will allow us to
jump to another function (`sub_40157f`) that will check for the second password.
We then understand that the handler registered before was for that purpose.

So, the second function reads 20 other bytes from stdin, and just check if the
first 8 of them match the 8 bytes beginning at an address on the stack, each of them
being XORed with 2. So, by stepping in, I arrive to the `0x40155b: cmp dl, al`,
and just dump the 8 bytes.


> u1nnf21g


I then XOR them with 2 and get the second pass `w3lld0ne`

> Flag: r0b0RUlez!\_w3lld0ne

