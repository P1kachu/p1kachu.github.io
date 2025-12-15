---
layout: post
writeup: :)
title:  "Random OSX Crackmes Writeups"
date:   2016-08-28 06:45:00
description: osx macos mac ios fg! reverse.put.as ctf writeup 2016 objective-c
categories:
- writeup
- RE
---

Here are some writeups for OSX crackmes randomly taken from [reverse.put.as](http://reverse.put.as/crackmes).
If you haven't done them and want to try them, of course this will spoil you.
They are mostly very easy serial checkers, so let's try to do it with only
static analysis.

I will not give the file as they are all available at reverse.put.as.

1. [Crackme #1](#crackme-1)
2. [Pie](#pie)
3. [FiveNiner](#fiveniner)
4. [DeadSimple](#deadsimple)

### Crackme #1

Crackme #1 is an i386 Mach-o application that asks for a name and a serial.
Let's write a keygen in python for it.

In the 'validar' function, we find that both fields are recovered when the user
presses the button. Then the program checks that none of the fields are empty,
that the name is more than 4 characters long and that the serial is 15 chars
long.

![crackme_1](/assets/content/osx/osx_crackme1_1.png)

It will then get the last two characters of the serial, get the int value and
check that it is equal to the name's length.

![crackme_1](/assets/content/osx/osx_crackme1_2.png)
It then verifies that `serial[10] == 'k' && serial[11] == 'n' && serial[12] == 'k'`.
![crackme_1](/assets/content/osx/osx_crackme1_3.png)
Here are the value of the hardcoded strings used in the comparison:
![crackme_1](/assets/content/osx/osx_crackme1_4.png)

And finally, it computes the SHA1 hash of the name, crop it to the first 10
characters, and check that the serial's first 10 chars and the hash match:
![crackme_1](/assets/content/osx/osx_crackme1_5.png)

Here is a simple python3 keygen:

{% highlight python %}
#!/usr/bin/env python

import sys
from hashlib import sha1

# len(name) >= 4
# len(pass) == 0xf
# last 2 serial chars == len(name)
# serial[10] = 'k'
# serial[11] = 'n'
# serial[12] = 'k'
# sha1(name)[:10] == serial[:10]

if len(sys.argv) < 2:
    sys.argv.append("P1kachu")

if len(sys.argv[1]) < 4:
    sys.argv[1] = "P1kachu"

NAME = sys.argv[1]
SERIAL = sha1(NAME).hexdigest()[:10]
SERIAL += 'knk'
SERIAL += "{:02}".format(len(NAME))

print("Name: {0} - Key: {1}".format(NAME, SERIAL))
{% endhighlight %}

![crackme_1](/assets/content/osx/osx_crackme1_6.png)

******************************************************************************

### Pie

Pie is a key checker from the MacSerialJunkies 2010 Contest. It asks for a
name and a serial for registration. Let's go for another keygen.

In the function `verifySerialandName` (yes, I think that's the one we
need to look at), the programs gets the two fields and check the serial's length
first. It must be equal to 16.

![pie](/assets/content/osx/osx_pie_1.png)

It then calculate the MD5 sum of the 6 first characters of the serial.
![pie](/assets/content/osx/osx_pie_2.png)

This will be compared to a hardcoded hash which is equal to
`66EAD6FE7CBE7987B7C4B1A1EED0E5A5`. A quick google search for this hash yields
this [page](http://hash-killer.com/dict/6/6/e/a) and the corresponding string:
`KRACK-`.
![pie](/assets/content/osx/osx_pie_3.png)

It then verifies that the 14th character of the serial is 'F'.
![pie](/assets/content/osx/osx_pie_4.png)

The next step will be to compute the MD5 sum of the name, get the 7 first chars
of its hexdigest, and compare them to the 7 chars long substring of the serial
beginning at index 6.
![pie](/assets/content/osx/osx_pie_5.png)
![pie](/assets/content/osx/osx_pie_6.png)

The last step is comparing the two last characters of the serial and 'BC', which
is a hardcoded string used earlier for encoding conversions.
![pie](/assets/content/osx/osx_pie_7.png)

Here is the keygen for this crackme:

{% highlight python %}
#!/usr/bin/env python

from hashlib import md5
import sys

# md5('KRACK-') == 66EAD6FE7CBE7987B7C4B1A1EED0E5A5

if len(sys.argv) < 2:
        sys.argv.append("P1kachu")

NAME = sys.argv[1]

PASS_1 = "KRACK-"
PASS_2 = md5(NAME).hexdigest()[:7]
PASS_3 = "BC"

PASS = PASS_1 + PASS_2 + 'F' + PASS_3

print("NAME: {0} - KEY: {1}".format(NAME, PASS.upper()))
{% endhighlight %}

![pie](/assets/content/osx/osx_pie_8.png)

******************************************************************************

### FiveNiner

This one from Corruptfire.com (which seems down) is quite straightforward too.

It asks only for a serial:

This serial should be composed of 4 words separated with dashes, like
`XXX-XXX-XXX-XXX`.
![fiveniner](/assets/content/osx/osx_fiveniner_1.png)

It then checks that the first word is equal to `FN10`.
![fiveniner](/assets/content/osx/osx_fiveniner_2.png)

Then, it takes the second word, pass it into the `sha1` function (which is in
reality a hidden MD5), crops it to take the 6 first chars, and compare it to the
third word.
![fiveniner](/assets/content/osx/osx_fiveniner_3.png)

It finally takes the three first words, join them with dashes, appends another
dash at the end, and MD5 it. The 6 first chars of the hash are finally compared
to the final word.
![fiveniner](/assets/content/osx/osx_fiveniner_4.png)

Here is the keygen for this challenge:
{% highlight python %}
#!/usr/bin/env python3

from hashlib import md5
import sys

if len(sys.argv) < 2:
    sys.argv.append("P1kachu")

sys.argv[1] = sys.argv[1].upper()

WORD0 = 'FN10'
WORD1 = sys.argv[1]
WORD2 = md5(WORD1.encode('utf-8')).hexdigest()[:6].upper()
SEQU = "{0}-{1}-{2}-".format(WORD0, WORD1, WORD2)
WORD3 = md5(SEQU.encode('utf-8')).hexdigest()[:6]

print("FiveNiner Key: {0}-{1}-{2}-{3}".format(WORD0, WORD1, WORD2, WORD3).upper())
{% endhighlight %}
![fiveniner](/assets/content/osx/osx_fiveniner_5.png)

******************************************************************************

### DeadSimple

This one is, indeed, really simple. It asks for a name and a serial.

The serial must be composed of two ints separated by a dash.
The second component must be the square of the first one...
![fiveniner](/assets/content/osx/osx_deadsimple_1.png)

And the first component must be the sum of every char in the name:
![fiveniner](/assets/content/osx/osx_deadsimple_2.png)

Here is a "keygen", but it's almost useless to have one:

{% highlight c %}
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv) {
        if (argc > 1) {
                int count = 0;
                int len = strlen(argv[1]);
                for (int i = 0; i < len; ++i) {
                        count += argv[1][i];
                }

                printf("Name: %s\nPassword: %d-%d\n", argv[1], count, count * count);
        }

}
{% endhighlight %}

![fiveniner](/assets/content/osx/osx_deadsimple_3.png)

******************************************************************************

I may do more, but I will first try to find some a little bit more complicated.
If you have any, please feel free to suggest them on
[Twitter](https://twitter.com/0xP1kachu) or by [mail](mailto:{{ site.p1kachu.author.email }}).


