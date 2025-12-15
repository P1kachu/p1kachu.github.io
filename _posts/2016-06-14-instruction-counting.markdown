---
layout: post
title:  "Instruction counting with v0lt"
date:   2016-06-14 15:48:45
categories:
- project
- security
---

> Instruction Counting is a black-box approch at determining a program's internal
> conception, just by counting the number of executed instructions.

Jonathan Salwan wrote an [article][salwan] on the subject, so I won't bother
explaining again how it works. But since it has often been useful for me, I
added an Instruction Counting plugin to v0lt!

You can check it on its [Github repo][repo].

#### Demo: Instruction Counting
{% highlight ruby %}
>>> from v0lt import *
>>> counter = InstructionCounter(pin_path='/home/pin', '/home/binary')
>>> counter.Accurate()
[!]WARNING  no length specified - guessing
[+]SUCCESS  Pass length guessed: 22
[+]SUCCESS  char guessed: I
[+]SUCCESS  char guessed: n
[+]SUCCESS  char guessed: S
[+]SUCCESS  char guessed: 7
[+]SUCCESS  char guessed: r
[+]SUCCESS  char guessed: u
[+]SUCCESS  char guessed: c
[+]SUCCESS  char guessed: t
[+]SUCCESS  char guessed: I
[+]SUCCESS  char guessed: 0
[+]SUCCESS  char guessed: n
[+]SUCCESS  char guessed: C
[+]SUCCESS  char guessed: o
[+]SUCCESS  char guessed: u
[+]SUCCESS  char guessed: n
[+]SUCCESS  char guessed: T
[+]SUCCESS  char guessed: i
[+]SUCCESS  char guessed: N
[+]SUCCESS  char guessed: 6
[+]SUCCESS  char guessed: R
[+]SUCCESS  char guessed: u
[+]SUCCESS  char guessed: l
[+]SUCCESS  char guessed: z
[+]SUCCESS  pass found: InS7ructI0nCounTiN6Rulz
{% endhighlight %}

[repo]: https://github.com/P1kachu/v0lt
[salwan]: http://shell-storm.org/blog/A-binary-analysis-count-me-if-you-can/

