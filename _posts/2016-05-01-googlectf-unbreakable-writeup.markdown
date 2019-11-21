---
layout: post
writeup: :)
title:  "GoogleCTF 2016 - Unbreakable Enterprise Activation Product Writeup (RE)"
date:   2016-05-01 12:45:00
description: googlectf writeup 2016 150 Unbreakable Enterprise Activation Product
categories:
- writeup
- RE
---

> We need help activating this product -- we've lost our license key :(
> You're our only hope!

So, we are given a 64bits executable that asks for a password in argument. It
only consists in one main function that will check that the `67 bytes long`
password matches some conditions. The conditions are split in 50 different
functions and are pretty clear, so without thinking much I decide to rewrite them
with z3 (even if I first tried to launch an instruction counting tool when I saw that
the program exited at the first unmatched condition).


The constraints only check the first 50 characters of the password, and thus
there should be some collisions. But we see that the flag corresponds only to
these characters, so collisions don't really matter.

Here is the script used to get the flag:

{% highlight python %}
#!/usr/bin/python2

from z3 import *

PASS_LEN = 67

s = Solver()
p = []

for i in range(PASS_LEN):
    p.append(BitVec(i, 8))
    s.add(And(p[i] >= 0x20, p[i] < 0x7f))  # Charset

s.add(p[0] == p[6] + (p[38] ^ p[30]) - p[8])
s.add(p[1] == (p[42] ^ (p[38] ^ p[20] ^ p[19])))
s.add(p[2] == p[35] + p[36] - p[19] - p[3] - p[44])
s.add(p[3] == p[19] + (p[17] ^ (p[41] - p[10] - p[10])))
s.add(p[4] == p[33] - p[21])
s.add(p[5] == (p[4] ^ (p[4] ^ p[8] ^ p[39])))
s.add(p[6] == (p[14] ^ (p[10] + p[25] - p[39])))
s.add(p[7] == p[32] + (p[15] ^ p[1]))
s.add(p[8] == p[8])
s.add(p[9] == (p[24] ^ p[7]))
s.add(p[10] == p[32] + (p[49] ^ p[17]) - p[4])
s.add(p[11] == (p[42] ^ p[38]) - p[17] - p[8])
s.add(p[12] == p[14] + p[8])
s.add(p[13] == p[45] + p[20])
s.add(p[14] == p[9] + (p[20] ^ (p[25] - p[48])))
s.add(p[15] == p[18] - p[31] )
s.add(p[16] == (p[24] ^ p[46]))
s.add(p[17] == ((p[13] + p[2] + p[47]) ^ (p[14] ^ p[50])))
s.add(p[18] == p[0] + p[36] + p[44] - p[3])
s.add(p[19] == (p[41] ^ p[30]) - p[25] - p[28])
s.add(p[20] == (p[25] ^ p[44]))
s.add(p[21] == p[25] + ((p[28] + p[22]) ^ (p[39] ^ p[21])))
s.add(p[22] == (p[31] ^ (p[44] - p[4] - p[12])) - p[30])
s.add(p[23] == (p[39] ^ (p[32] - p[14])))
s.add(p[24] == (p[21] ^ (p[0] ^ p[18] ^ p[21])))
s.add(p[25] == p[18] + p[4] + (p[12] ^ p[17]) - p[11])
s.add(p[26] == (p[32] ^ p[46]) + p[49] + p[20])
s.add(p[27] == p[36] + p[25] + p[39] - p[48])
s.add(p[28] == (p[14] ^ p[15]))
s.add(p[29] == p[1] + p[35] - p[42])
s.add(p[30] == p[8] - p[31] - p[30] - p[24])
s.add(p[31] == (p[42] ^ (p[15] + p[18] - p[29])))
s.add(p[32] == p[14] + p[5] + p[15] - p[44])
s.add(p[33] == (p[20] ^ (p[45] - p[15])) - p[32])
s.add(p[34] == (p[3] ^ p[33]) - p[20] - p[10])
s.add(p[35] == (p[44] ^ (p[6] - p[43])) + p[1] - p[44])
s.add(p[36] == (p[49] ^ (p[31] + p[25] - p[28])))
s.add(p[37] == p[11] + (p[34] ^ p[31]) - p[34])
s.add(p[38] == p[42] + (p[27] ^ p[36]) - p[5])
s.add(p[39] == (p[37] ^ p[8]))
s.add(p[40] == (p[44] ^ (p[7] + p[28])) - p[10])
s.add(p[41] == (p[20] ^ (p[7] ^ p[17] ^ p[26])))
s.add(p[42] == p[50] + p[1] - p[28])
s.add(p[43] == p[46] + p[33] - p[15])
s.add(p[44] == ((p[24] + p[42] + p[16]) ^ (p[45] ^ p[21])))
s.add(p[45] == p[22] - p[40])
s.add(p[46] == p[12] - p[46] - p[7] - p[35])
s.add(p[47] == (p[39] ^ (p[15] + p[26])) - p[12])
s.add(p[48] == (p[11] ^ (p[15] - p[8])))
s.add(p[49] == (p[27] ^ p[37]))
s.add(p[50] == ((p[13] + p[8] + p[17]) ^ (p[24] ^ p[15])))

if s.check() == sat:
    string = " "
    for y in p:
        string += chr(int(str(s.model()[y])))
    print(string)

{% endhighlight %}

Running it gives us:

{% highlight console %}
p1kachu@GreenLabOfGazon:GoogleCTF$ ./GoogleCTF_Unbreakable_Entreprise_Product_Activator.py
CTF{0The1Quick2Brown3Fox4Jumped5Over6The7Lazy8Fox9}
{% endhighlight %}

> Flag: CTF{0The1Quick2Brown3Fox4Jumped5Over6The7Lazy8Fox9}

Unbreakable keygen [executable and solution](/assets/content/googlectf16_keygen.tar.gz)
