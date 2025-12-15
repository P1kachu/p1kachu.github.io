---
layout: post
writeup: :)
title:  "ASISCTF 2016 - Firtog Writeup (FOR)"
date:   2016-05-09 10:45:00
description: asis ctf writeup 2016 109 firtog writeup
categories:
- writeup
- forensics
---

> Obscurity is definitely not security.

This is the only exercice we looked at for this CTF, because sadly we didn't have
time to really look at any other. Anyway, let's see what we have here.

Finally some funny forensics ! We are given a pcap that contains what looks like
some `git pull` command. There are some commits, and some packed objects.

I did a lot more than what was actually needed for this challenge (I began a
python script to extract objects that `git unpack-files` would not give me
because of a SHA-1 mismatch). So here I will give you the simple solution, that
I finally found later.

So, first wireshark would not let me extract the objects directly so I needed to
take them by hand. To avoid that, I used `binwalk` on the pcap to extract the
files:

{% highlight console %}
p1kachu@GreenLabOfGazon:asis$ binwalk -e firtog.pcap

DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------
2105          0x839           Zlib compressed data, default compression
2278          0x8E6           Zlib compressed data, default compression
2408          0x968           Zlib compressed data, default compression
2490          0x9BA           Zlib compressed data, default compression
2573          0xA0D           Zlib compressed data, default compression
2590          0xA1E           Zlib compressed data, default compression
2634          0xA4A           Zlib compressed data, default compression
4328          0x10E8          Zlib compressed data, default compression
4481          0x1181          Zlib compressed data, default compression
4558          0x11CE          Zlib compressed data, default compression
6642          0x19F2          Zlib compressed data, default compression
6791          0x1A87          Zlib compressed data, default compression
6895          0x1AEF          Zlib compressed data, default compression
7061          0x1B95          Zlib compressed data, default compression
11523         0x2D03          Zlib compressed data, default compression
11677         0x2D9D          Zlib compressed data, default compression
11806         0x2E1E          Zlib compressed data, default compression
11849         0x2E49          Zlib compressed data, default compression
13540         0x34E4          Zlib compressed data, default compression
13689         0x3579          Zlib compressed data, default compression
13793         0x35E1          Zlib compressed data, default compression
14025         0x36C9          Zlib compressed data, default compression
15997         0x3E7D          Zlib compressed data, default compression
16152         0x3F18          Zlib compressed data, default compression
16255         0x3F7F          Zlib compressed data, default compression
19619         0x4CA3          Zlib compressed data, default compression
19777         0x4D41          Zlib compressed data, default compression
19905         0x4DC1          Zlib compressed data, default compression
19995         0x4E1B          Zlib compressed data, default compression
21692         0x54BC          Zlib compressed data, default compression
21850         0x555A          Zlib compressed data, default compression
21974         0x55D6          Zlib compressed data, default compression
22018         0x5602          Zlib compressed data, default compression

{% endhighlight %}

Now I have all the file extracted, I begin to look for basics patterns:

{% highlight console %}
p1kachu@GreenLabOfGazon:_firtog.pcap.extracted$ rm *.zlib
p1kachu@GreenLabOfGazon:_firtog.pcap.extracted$ file *
10E8: ASCII text
1181: data
11CE: Python script, ASCII text executable
19F2: ASCII text
1A87: data
1AEF: Python script, ASCII text executable
1B95: ASCII text
2D03: ASCII text
2D9D: data
2E1E: ERROR: Offset out of range
2E49: ASCII text
34E4: ASCII text
3579: data
35E1: Python script, ASCII text executable
36C9: ASCII text
3E7D: ASCII text
3F18: data
3F7F: very short file (no magic)
4CA3: ASCII text
4D41: data
4DC1: data
4E1B: ASCII text, with no line terminators
54BC: ASCII text
555A: data
55D6: data
5602: ASCII text, with no line terminators
839:  ASCII text
8E6:  ASCII text
968:  data
9BA:  Python script, ASCII text executable
A0D:  ASCII text
A1E:  data
A4A:  ASCII text
p1kachu@GreenLabOfGazon:_firtog.pcap.extracted$
p1kachu@GreenLabOfGazon:_firtog.pcap.extracted$ sanitycheck
3E7D:author factoreal <factoreal@asis.io> 1462027916 +0430
3E7D:committer factoreal <factoreal@asis.io> 1462027916 +0430
3E7D:new encrypted flag :P
34E4:author factoreal <factoreal@asis.io> 1462027854 +0430
34E4:committer factoreal <factoreal@asis.io> 1462027854 +0430
9BA:# Simple but secure flag generator for ASIS CTF
54BC:author factoreal <factoreal@asis.io> 1462028513 +0430
54BC:committer factoreal <factoreal@asis.io> 1462028513 +0430
54BC:a new encrypted flag :P:P
10E8:author factoreal <factoreal@asis.io> 1462027558 +0430
10E8:committer factoreal <factoreal@asis.io> 1462027558 +0430
10E8:edit simple flag generator
36C9:ASIS{2d1290332ba95f7ddea2c99f249e3368}            # THIS LOOKS INTERSTING
35E1:# Simple but secure flag generator for ASIS CTF
35E1:flag = 'ASIS{' + h + '}'
35E1:f = open('flag.txt', 'r').read()
35E1:flag = ''
35E1:	flag += hex(pow(ord(c), 65537, 143))[2:]
35E1:print flag
A4A:this is just a sample flag generator repo :)
839:author factoreal <factoreal@asis.io> 1462026998 +0430
839:committer factoreal <factoreal@asis.io> 1462026998 +0430
839:start writing python script for flag generation
8E6:author factoreal <factoreal@asis.io> 1462026173 +0430
8E6:committer factoreal <factoreal@asis.io> 1462026173 +0430
8E6:initial release for flag-gen
1B95:ASIS{2d1290332ba95f7ddea2c99f249e3368}            # THIS IS NICE TOO
2D03:author factoreal <factoreal@asis.io> 1462027784 +0430
2D03:committer factoreal <factoreal@asis.io> 1462027784 +0430
4CA3:author factoreal <factoreal@asis.io> 1462028229 +0430
4CA3:committer factoreal <factoreal@asis.io> 1462028229 +0430
4CA3:generate new secure flag :D
4DC1:flag_enc = ''
4DC1:for c in flag:
11CE:# Simple but secure flag generator for ASIS CTF
11CE:flag = 'ASIS{' + h + '}'
11CE:print flag
2E49:ASIS{822a3abf70d7a599436be4633861db1f38720ce3}
19F2:author factoreal <factoreal@asis.io> 1462027671 +0430
19F2:committer factoreal <factoreal@asis.io> 1462027671 +0430
19F2:new hot flag :)
1AEF:# Simple but secure flag generator for ASIS CTF
1AEF:flag = 'ASIS{' + h + '}'
1AEF:print flag
{% endhighlight %}

Oh my, this wouldn't be that easy right ? I tried both visible flags, and of
course they didn't work. So I kept digging. If you look carefuly, you can observe
some python code. I thus looked at the different files containing code and found
out that this repo was used to host a random flag generator, and that the two
found earlier were certainly for demonstration purpose:


Here is the script we can found in the `1AEF` file:

{% highlight console %}
p1kachu@GreenLabOfGazon:_firtog.pcap.extracted$ cat 1AEF
#!/usr/bin/python
# Simple but secure flag generator for ASIS CTF

from os import urandom
from hashlib import md5

l = 128
rd = urandom(l)
h = md5(rd).hexdigest()
flag = 'ASIS{' + h + '}'
print flag
{% endhighlight %}

But hey, the flag generator uses random numbers, how can I guess it if it's none
of the previous one ?
By digging a little more, we can see other revisions of the previous script, and
a particularily interesting one:

{% highlight console %}
p1kachu@GreenLabOfGazon:_firtog.pcap.extracted$ cat 35E1
#!/usr/bin/python
# Simple but secure flag generator for ASIS CTF

from os import urandom
from hashlib import md5

l = 128
rd = urandom(l)
h = md5(rd).hexdigest()
flag = 'ASIS{' + h + '}'
f = open('flag.txt', 'r').read()
flag = ''
for c in f:
	flag += hex(pow(ord(c), 65537, 143))[2:]
print flag
{% endhighlight %}

(there were other versions but this one is simple enough)

Anyway, great. This one takes a flag, 'encrypts it' a little bit and prints it on
the screen. The encryption lays on maths, and is quite deterministic so we know
that the encrypted string `ASIS{*}` will always lead to the same encryption, which
is `41608a606a`. If we `grep -ra 41608a606a`, there are two entries that
appear, which are not the encrypted versions of the previously found flags. So
now we need to bruteforce the flag that will give us the encrypted ones we found.
There is about 30 characters by flag, and less than 255 possibilities for each (we could
reduce this to `0x20 < c < 0x7f` but... meh, this is fast enough).
By modifying the script, I manage to bruteforce the flag very quickly, and yay
109 points!

Here is the final script and its output:

{% highlight python %}
#!/usr/bin/python3

###############################################################################
#
# ASIS CTF 2016
# P1kachu
# Forensics 109 - firtog
#
###############################################################################

from os import urandom
from hashlib import md5
import io

# The encrypted string we found
encrypted = io.StringIO("41608a606a63201245f1020d205f1612147463d85d125c1416635c854c74d172010105c14f8555d125c3c")


flag_dec = ''
while True:
    c = encrypted.read(1)

    # For some reasons, running the script and printing the characters
    # shows that 'f' or 'd' will often (always?) remain alone
    # Every other byte will have two chars
    if (c != 'f' and c != 'd'):
        c += encrypted.read(1)

    # End of input
    if c == '':
        break

    # Bruteforce
    for x in range(0x00, 0xff):
        tmp = hex(pow(x, 65537, 143))[2:]
        if tmp == c:
            flag_dec += chr(x)
            print(flag_dec)
            break;

{% endhighlight %}

Output:
{% highlight console %}
p1kachu@GreenLabOfGazon:_firtog.pcap.extracted$ ./solution.py
A
AS
ASI
ASIS
ASIS{
ASIS{c
ASIS{c6
ASIS{c69
ASIS{c691
ASIS{c691a
ASIS{c691a0
ASIS{c691a06
ASIS{c691a064
ASIS{c691a0646
ASIS{c691a0646e
ASIS{c691a0646e7
ASIS{c691a0646e79
ASIS{c691a0646e79f
ASIS{c691a0646e79f3
ASIS{c691a0646e79f3c
ASIS{c691a0646e79f3c4
ASIS{c691a0646e79f3c4d
ASIS{c691a0646e79f3c4d4
ASIS{c691a0646e79f3c4d49
ASIS{c691a0646e79f3c4d495
ASIS{c691a0646e79f3c4d495f
ASIS{c691a0646e79f3c4d495f7
ASIS{c691a0646e79f3c4d495f7c
ASIS{c691a0646e79f3c4d495f7c5
ASIS{c691a0646e79f3c4d495f7c5d
ASIS{c691a0646e79f3c4d495f7c5db
ASIS{c691a0646e79f3c4d495f7c5db3
ASIS{c691a0646e79f3c4d495f7c5db34
ASIS{c691a0646e79f3c4d495f7c5db348
ASIS{c691a0646e79f3c4d495f7c5db3486
ASIS{c691a0646e79f3c4d495f7c5db34860
ASIS{c691a0646e79f3c4d495f7c5db348600
ASIS{c691a0646e79f3c4d495f7c5db3486005
ASIS{c691a0646e79f3c4d495f7c5db3486005f
ASIS{c691a0646e79f3c4d495f7c5db3486005fa
ASIS{c691a0646e79f3c4d495f7c5db3486005fad
ASIS{c691a0646e79f3c4d495f7c5db3486005fad2
ASIS{c691a0646e79f3c4d495f7c5db3486005fad24
ASIS{c691a0646e79f3c4d495f7c5db3486005fad249
ASIS{c691a0646e79f3c4d495f7c5db3486005fad2495
ASIS{c691a0646e79f3c4d495f7c5db3486005fad2495}
{% endhighlight %}

> Flag: ASIS{c691a0646e79f3c4d495f7c5db3486005fad2495}

firtog [pcap and solution](/assets/content/asis16-firtog.tar.gz)


