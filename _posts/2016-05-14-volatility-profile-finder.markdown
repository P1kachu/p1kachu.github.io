---
layout: post
title:  "ProfileScan - Volatility plugin to guess profiles"
date:   2016-05-14 02:15:00
description: volatility plugin to discover os lying in dumps
categories:
- project
- forensics
---

> Let's do some forensics analysis, shall we ?

I recently found myself playing with CTF challenges featuring memory dumps to
play a little bit with Volatility. For those who are new to this project,
[Volatility][volatility] is an open-source framework written in Python2 which
first goal is data and informations extraction from memory dumps. It lays on a
system of plugins, which are loaded at runtime and can perform different actions,
and profiles, which represent the system of the memory dump.

One of the first obstacle you usually encounter when faced with a dump,
especially in CTF, is recovering where it comes from and what it was running
before being dumped (for Volatility, the `profile`). Indeed, Volatility's plugins
are often OS dependant and some really useful (like `imageinfo`, which gives you
the almost exact OS version of a Windows dump) are not available for every
platform.

There are multiple techniques to guess the operating system. One can grep for
strings in the binary and try to recognize some patterns, manually or with a
little bit of programming:

{% highlight sh %}
strings -a dump | grep -ioE '(windows|linux|debian|osx|ubuntu)' | sort | uniq -c | sort -n
{% endhighlight %}

You can also try blindly to run `imageinfo` or `mac_get_profile`, praying for
one to work. But you may waste time waiting for an output that may never come,
in the worst case.

So right, I decided to give it a try, and look for some ways to get informations
about the underlying operating system. My first try was as script
based on the previous `grep` command, but a little bit more sophisticated, and OS
independant (python). It works pretty well for Linux and Windows, even if it is
waaaaay slower than grep, but fails with OSX. Why ? Because grepping for
"windows" might look clever, but since a 'window' is actually an object that
can represent any GUI component, you will see that every OS with any sense of
graphical interface will magically turn into Windows.

So right, let's try to think of any other interesting keyword. I went on looking
for `vmlinuz` for Linux kernels, but didn't find anything for OSX. Plus, this
still was to slow to execute and too innaccurate.

So, what will almost everytime differentiate two different systems, such that we
can guess their profiles ?
Well, their executables will. Unix runs `ELFs`, Windows runs `PEs/EXEs` and OSX
runs `Mach-Os`. This could be a good indicator!

So the plan was to look for these formats' signatures in the dump. Let's do
things properly, and make a Volatility plugin out of it. So I took the `Scanner`
baseclass, and created one that would look for magic numbers in the dump, and
count them. This worked pretty well at first sight, but a magic number is rarely
more than 4 bytes, and even 2 for the PE format. I thus quickly saw PEs spawning
everywhere, and decided to restrict things a bit.

Problem is, a file header may change regarding the versions, size, etc. So I
needed something that would only look for the bytes that never changed. First,
let's try to determine these bytes. For that, I took the naive way: a set of
each executable format, and `binwalk`.


{% highlight console %}
p1kachu@GreenLabOfGazon:pe$ binwalk -l 0x10 -W $PE_SET
OFFSET      rev200.exe
--------------------------------------------------------------------------------
0x00000000  4D 5A 90 00 03 00 00 00 04 00 00 00 FF FF 00 00 |MZ..............| \
#           ^  ^     ^     ^  ^  ^     ^  ^  ^        ^  ^
{% endhighlight %}
(The output was cropped so that it fits smoothly here.)

A `^` indicates a byte that never changes. To be able to verify only these bytes,
we will apply a mask on the bytes sequence that we want to compare to our
signature, and check if both are equal. The bytes we don't care about are
replaced with `0xff` in the signature and the mask, and the interesting ones are
replaced with `0x00` in the mask:

{% highlight sh %}
00 01 02 03 04 05 06 07 08 09 1a 1b 1c 1d 1e 1f # Byte sequence to check
                    ||
00 00 FF 00 FF 00 00 00 FF 00 00 00 FF FF 00 00 # Mask
                    ?=
4D 5A FF 00 FF 00 00 00 FF 00 00 00 FF FF 00 00 # Signature
{% endhighlight %}

Translated in python, it gave this:

{% highlight python %}
def check(self, offset):

    if offset % self.PAGE_SIZE:
        return False

    for signature in self.signature_hashes:

        # Read sequence of bytes of length equal to the signature's length
        dump_chunk = self.address_space.read(offset, len(signature['magic']))

        # Convert hex strings to int to perform comparison
        magic = int(signature['magic'].encode('hex'), 16)
        mask = int(signature['mask'].encode('hex'), 16)
        chunk = int(dump_chunk.encode('hex'), 16)
        if (chunk | mask) == magic:
            return True

    return False
{% endhighlight %}



With strong signatures like this there were far less false positive and the
result was quite good, but very slow. Indeed, I had to read each byte sequence
X times (X being the number of signatures, of different length for some) and
check, which was way to long. So I looked for ways to reduce computations. My
first thought was to try to read the executable header and skip the size
registered in it. But Gaby reminded me that executables were always loaded at
the beginning of a memory page. Thus, instead of reading each byte, I read each
page's first byte, and thus multiplied the speed by `4096`.

So now, the plugin determines quite accurately the OS in less than a minute
(which is still quite long, I still look for ways to speed it up), and is
available on [Github][repo] (UPDATE 05/29/16: the suite has been merged into [volatilityfoundation/community][community]).
I also found a way to get the linux distribution from a magic string in linux
kernels; right now it seems quite accurate, but I only tested it on the sample
set I was given.

Here is an output example:
{% highlight console %}
p1kachu@GreenLabOfGazon:dumps$ volatility -f linux-sample03.bin profilescan -v
Volatility Foundation Volatility Framework 2.5
[ ] DEBUG: elf found at offset 0xa5c000
[ ] DEBUG: elf found at offset 0xd4c000
[ ] DEBUG: elf found at offset 0xd59000
[ ] DEBUG: elf found at offset 0xe05000
[ ] DEBUG: elf found at offset 0xe41000
[ ] DEBUG: elf found at offset 0xf01000
[ ] DEBUG: elf found at offset 0x13a5000
[ ] DEBUG: elf found at offset 0x15f1000
[ ] DEBUG: elf found at offset 0x1603000
[ ] DEBUG: elf found at offset 0x16cf000
[ ] DEBUG: elf found at offset 0x16dc000
[ ] DEBUG: elf found at offset 0x16fd000
[ ] DEBUG: elf found at offset 0x1829000
[ ] DEBUG: elf found at offset 0x189f000
[ ] DEBUG: elf found at offset 0x19b5000
[ ] DEBUG: elf found at offset 0x19f4000
Found OS: Linux (100% match)

p1kachu@GreenLabOfGazon:dumps$ volatility -f osx-sample02.bin profilescan -v
Volatility Foundation Volatility Framework 2.5
[ ] DEBUG: mach-o_32-rev found at offset 0x312000
[ ] DEBUG: mach-o_32-rev found at offset 0x42a000
[ ] DEBUG: mach-o_64-rev found at offset 0x4bb000
[ ] DEBUG: mach-o_32-rev found at offset 0x4bd000
[ ] DEBUG: mach-o_32-rev found at offset 0x6d8000
[ ] DEBUG: mach-o_64-rev found at offset 0x714000
[ ] DEBUG: mach-o_32-rev found at offset 0x737000
[ ] DEBUG: mach-o_64-rev found at offset 0x9cf000
[ ] DEBUG: mach-o_64-rev found at offset 0xe18000
[ ] DEBUG: mach-o_32-rev found at offset 0xe19000
[ ] DEBUG: mach-o_32-rev found at offset 0xe1a000
[ ] DEBUG: mach-o_64-rev found at offset 0xe9a000
[ ] DEBUG: mach-o_64-rev found at offset 0x120b000
[ ] DEBUG: mach-o_32-rev found at offset 0x12a3000
[ ] DEBUG: mach-o_64-rev found at offset 0x12c8000
[ ] DEBUG: mach-o_32-rev found at offset 0x1340000
Found OS: OSX (100% match)
{% endhighlight %}


[volatility]: http://www.volatilityfoundation.org
[repo]: https://github.com/P1kachu/VolatilityProfileScan
[community]: https://github.com/volatilityfoundation/community/pull/12
