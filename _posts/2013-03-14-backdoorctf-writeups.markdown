---
layout: post
writeup: :)
title:  "backdoorCTF 2013 - binary 100 Writeup (RE)"
date:   2013-03-14 22:00:00
description: backdoorCTF 2013 - Binary 100
categories:
- writeup
- RE
---


> Small introduction to IDAPython

binary100 is a quite small ELF64 written in C++, from the backdoorCTF 2013.

You are prompted to enter not one
but three passwords, then the program hashes it and tells you if this is the
right password or not.


This is solvable by using `strings`, but for the sake of training, let's try to
do it without.


We open it in IDA, and get quickly the main function. It gets the 3 passwords,
generates a random number with `rand % (argc - 1) + 1` to choose which password
from the three to hash, put it in a dynamically allocated buffer, pass it in a
`md5_custom` function, and compare the result to a constant.


The hashing function is pretty complicated:
{% highlight C %}
char *__fastcall md5_custom(char *a1)
{
        return a1;
}
{% endhighlight %}

Okay... let's check the check method then:

{% highlight C %}
// Main function
hashed = md5_custom(passw);
if ( (unsigned int)::check(hashed) != 0 )
        *check = '1';

        if ( *check == '1' ) { /* win */ }
// End Main

// [SNIPPED]

__int64 __fastcall check(char *a1)
{
        signed int i; // [sp+14h] [bp-4h]@1

        for ( i = 0; i <= 31; ++i )
        {
                if ( a1[i] != byte_400F00[(signed __int64)i] )
                        return 0LL;
        }
        return 1LL;
}

{% endhighlight %}

So yeah, there is no hashing and the string is directly compared to a buffer
in memory.

Let's launch IDAPython and get the pass now:

{% highlight python %}
# Pass is 32 chars long
Python> for i in range(0x400F00, 0x400F00 + 32):
Python>         sys.stdout.write(Byte(i))
Python> f2332291a6e1e6154f3cf4ad8b7504d8
{% endhighlight %}

> Flag: f2332291a6e1e6154f3cf4ad8b7504d8

