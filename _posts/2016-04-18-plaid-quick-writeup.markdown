---
layout: post
writeup: :)
title:  "PlaidCTF 2016 - Quick Writeup (RE)"
date:   2016-04-17 23:45:00
description: PlaidCTF quick writeup 2016 175
categories:
- writeup
- RE
---

> Why be slow when you can be quick?

This is an exercice from the PlaidCTF that was worth 175 points. It's the first
exercise I solved around 6a.m. and was the only reversing exercise available at
this time.

{% highlight console%}
p1kachu@GreenLabOfGazon:PLAID$ file quick
quick: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 2.6.32, stripped
{% endhighlight %}

Right. Looks like a standard ELF. Let's try running it:

{% highlight console %}
p1kachu@GreenLabOfGazon:PLAID$ ./quick
./quick: error while loading shared libraries: libswiftCore.so: cannot open shared object file: No such file or directory
{% endhighlight %}

Well. So Swift it will be then. I decided to build the Swift repo to be able to
run the executable anyway, but this was quite a big repo so I went through IDA
to save some time during the build, and started analyzing what I could find.
Swift is based on C++ so IDA did not suffer too much from this brutal change of
habits...

There is a main function that contains every message you can get while executing
it.
It takes our input, seems to build a Swift String object out of it and does some
other initialization-looking stuff.
So I went from the `Good job!` one and found the function that would interest me.

By then the build had finished, so we could test the binary:
{%highlight console %}
p1kachu@GreenLabOfGazon:PLAID$ ./quick
Please provide your input.
coucou
Nope!

# By mistake, one of our teammate found out
# that just pressing enter offered us a "Good job"
# message

p1kachu@GreenLabOfGazon:PLAID$ ./quick
Please provide your input.

Good job!
{% endhighlight %}

Anyway, back to IDA. The interesting function is the one located at `0x403660`
which takes 3 QWORDS parameters. By looking at the disassembly, we see that the
arguments given by main are `(QWORD) input, (QWORD) input + 1, (QWORD) input + 2`.
By checking dynamically in GDB, we understand that the first parameter is the
raw string, and the second one its length. We never actually understood what the
third one was.

Anyway, this comforts our previous analysis and discard any further research in the
first part of main. The executable just builds a string object out of our input.

The interesting function (the one telling if the binary should print 'good job'
or 'bad job') is quite long and painful to follow. It sets two hardcoded arrays
of 32 chars each at some point (we can guess the password length) and calls
some other mangled function. Francis from our team is the one to tell us that
there is a Swift utility available to demangle them, so it was a little bit
clearer after using it.
By looking carefully at it and playing a little bit with the executable, we
understand that the function takes each character from the input, builds a String
object out of it (of length 1), and add the freshly created object to an Iterable
container. After that, it loops over the list, get each character from our input,
each character from the first hardcoded array and compare them.

{% highlight c %}
// SNIPPED

// First hardcoded array
*(_BYTE *)array_1 = 0x81u;
*(_BYTE *)(array_1 + 1) = 0x74;
*(_BYTE *)(array_1 + 2) = 0x87u;
*(_BYTE *)(array_1 + 3) = 0x79;
*(_BYTE *)(array_1 + 4) = 0xB0u;
*(_BYTE *)(array_1 + 5) = 0x6A;
*(_BYTE *)(array_1 + 6) = 0xAAu;
*(_BYTE *)(array_1 + 7) = 0xA7u;
*(_BYTE *)(array_1 + 8) = 0x68;
*(_BYTE *)(array_1 + 9) = 0x94u;
*(_BYTE *)(array_1 + 10) = 0xA4u;
*(_BYTE *)(array_1 + 11) = 0x7B;
*(_BYTE *)(array_1 + 12) = 0xAFu;
*(_BYTE *)(array_1 + 13) = 0x89u;
*(_BYTE *)(array_1 + 14) = 0xD4u;
*(_BYTE *)(array_1 + 15) = 0xD1u;
*(_BYTE *)(array_1 + 16) = 0x92u;
*(_BYTE *)(array_1 + 17) = 0xBEu;
*(_BYTE *)(array_1 + 18) = 0x94u;
*(_BYTE *)(array_1 + 19) = 0xD8u;
*(_BYTE *)(array_1 + 20) = 0x92u;
*(_BYTE *)(array_1 + 21) = 0xCCu;
*(_BYTE *)(array_1 + 22) = 0xDAu;
*(_BYTE *)(array_1 + 23) = 0xD1u;
*(_BYTE *)(array_1 + 24) = 0xD3u;
*(_BYTE *)(array_1 + 25) = 0xA9u;
*(_BYTE *)(array_1 + 26) = 0xD3u;
*(_BYTE *)(array_1 + 27) = 0xAAu;
*(_BYTE *)(array_1 + 28) = 0xECu;
*(_BYTE *)(array_1 + 29) = 0xA8u;
*(_BYTE *)(array_1 + 30) = 0xDDu;
*(_BYTE *)(array_1 + 31) = 0xEFu;
*(_BYTE *)(array_1 + 32) = 0xFAu;

// SNIPPED
{% endhighlight %}

Easy then, don't you think ? Just take the bytes from the hardcoded array and
get the 175 points!

Of course not. At this point, I decided to try to see what is going on with GDB.
I always try to examine the binary dynamically, as static analysis is not my
strongest asset. And of course, the input is tempered before arriving to the
checks.
So I try a little bit, but the only way to pass the first char check seems to be
an input beginning with `\%` (yes, with the backslash). Well, ok, I don't like
this array and its checks, let's just skip it then ! (It's the moment when you
don't know what to do and thus try something totally stupid).

So, when we arrive at the first check (in the loop on each one-char-long strings,
at `0x4038e9`), we tell the binary that everything is alright and continue until we
get to the next interesting part, located at `0x403922`:
{% highlight elisp %}
gdb-peda$ b *0x4038e9
Breakpoint 1 at 0x4038e9
gdb-peda$ while($rip !=0x403922)
  >set $cl = $al
  >c
  >end

<SNIPPED>
Breakpoint 1, 0x0000000000403922 in ?? ()
gdb-peda$
{% endhighlight %}


Good. Now let's try to continue and see what else is going on.
The execution continues, lots of functions are called and the second hardcoded
array is filled. The programs then enters a second infinite loop at `0x403dfa`
that will check each character and break if
one-condition-that-will-still-don't-know-the-nature-of is respected. With GDB,
I enter the loop, step in until the check (at `0x403eeb`), and compare `$al` and
`$cl`. The first actual value I tried this time was a 'P' for the
PCTF{*} flag format. And it matched the hardcoded value. I then relaunched it
with `PCTF{` as input and they all matched ! Great, now I know how to get the
flag without having to reverse the whole stuff.

With a little gdb script, I skip the whole first array checks, get into the
second check loop, and see what the rest of the flag looks like. Each character
from the input is modified in some way that is not always the same, but still is
quite regular: you can see what's going on by trying some close-to-each-other
letters and interpolating after. For instance:

{% highlight mathematica %}
h == XX - 9; i == XX; j == XX + 9
h == XX - 2; i == XX; j == XX + 2
h == XX - 0xf; i == XX; j == XX + 0xf
{% endhighlight %}

was the kind of pattern you could encounter. I thus compared what my character
was, what it was supposed to be, computed 2 or 3 other values and quickly got
the whole flag.

> Flag: PCTF{5ur3\_a5\_5ur3\_5w1ft\_a5\_5w1ft}

I am a little bit annoyed because I didn't fully understand what was going on
but hey, stuff had to be done ! Great challenge PPP anyway !
