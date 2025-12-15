---
layout: post
writeup: :)
title:  "RSSIL 2011 - Chimay Rouge Writeup (RE)"
date: 2011-05-29 22:00:00
description: rssil 2011 re chimay rouge
categories:
- writeup
- RE
---

> Small introduction to z3

chimay_rouge is a small RE challenge that I found to be simple enough to get a
first approch of z3 without killing yourself. The binary is too simple for this
to be an actual writeup but will help anybody who wants to see how to use z3.

Here is the script used to solve the challenge. You can download the binary and
the solution [here](/assets/content/chimay_rouge.tar.gz).

{% highlight python %}
#!/usr/bin/python2

import sys
from z3 import *

s = Solver()

p = []

PASS_LEN = 24

# Compared buffer
buf = [0xb7, 0xb7, 0xe5, 0x37, 0x24, 0x80, 0xed, 0x14, 0x69, 0x10, 0x35,
       0x39, 0x6e, 0xa3, 0x2a, 0x59, 0x3e, 0xbd, 0x7a, 0x6a, 0x6e, 0xe5,
       0xec, 0x3d]

# Encryption key
key = [0xf4, 0x86, 0x95, 0x5d, 0x52, 0xb9, 0x97, 0x95, 0x0e, 0x6d, 0x67,
       0x4d, 0x11, 0xcf, 0x7d, 0xdb, 0x51, 0x38, 0x00, 0x2c, 0x1d, 0x65,
       0xa5, 0x4d]

for i in range(PASS_LEN):
    # Create a new symbolic character
    p.append(BitVec('pass_' + str(i), 8))

    # Constraint its value to the printable ones
    s.add(And(p[i] >= 0x20, p[i] < 0x7f))

    # Apply the operation from the binary
    # Interestingly enough, IDA's decompiler
    # added a '+ i' at the key[i], that was not
    # supposed to be here
    s.add(((p[i] + i) ^ key[i]) == buf[i])


# z3 didn't find any solution
if s.check() == unsat:
    print("Fail")
    exit(0)


# Prints the solver's result
# C0ngr4tz_tHis_Is_th3_k3Y
for y in p:
    sys.stdout.write(chr(int(str(s.model()[y]))))
print("")
{% endhighlight %}
