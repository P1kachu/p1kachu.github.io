---
layout: post
writeup: :)
title:  "HackCon 2016 - angry-reverser writeup (RE)"
date:   2016-09-01 02:05:00
description: hackcon angr ctf writeup 2016 angry reverser 200pts
categories:
- writeup
- RE
---

> Binary: yolomolo.

I unfortunately couldn't participate in this CTF, but some people who actually
did sent me this exercise because they think it was a little bit too tricky to
be solved by hand, and thought that `angr` could be helpful. Now that I have
some time, I could actually take a look at it and indeed, angr does its job (the
name was a big hint, maybe a little bit too much in my opinion).

I will not get into much details here, the binary is a 64-bit ELF executable
with only a short main function that calls another one called `GoHomeOrGoCrazy`.
The return value of this function determines if you have the right flag or not:

![graph](/assets/content/hackcon2016_graph.png)

It takes a lot of time for angr to solve it, but it's always easier than doing
it ourselves :)

Here is the script I used to solve this challenge:
{% highlight python %}
import angr
import sys

# P1kachu 2016 - LSE
# HackCon 2016 - angry-reverser
# Took ~31 minutes on Intel Core i7-3770 CPU @ 3.40GHz (8 CPUs)
# Flag: HACKCON{VVhYS04ngrY}

p = angr.Project('yolomolo')

main        = 0x405a6f # Fail message to be printed
find        = 0x405aee # Win message printed
avoid       = (0x405af0, 0x405ab4) # First two ways to fail from main
crazy       = 0x400646 # Entry point of Crazy function

# Offset (from IDA) of 'FAIL' blocks in Crazy
fails = [0x2619, 0x288C, 0x2AF9, 0x2D68, 0x2FD5, 0x3245, 0x34B2,
         0x3724, 0x3996, 0x3C04, 0x3E73, 0x40E7, 0x4355, 0x45C9,
         0x4836, 0x4AA4, 0x4D15, 0x4F86, 0x51D1, 0x5408]

# Create blank state with $pc at &main
init = p.factory.blank_state(addr=main)

# Avoid blocks
avoid = list(avoid)
avoid += [(crazy + offst) for offst in fails] # Let's save RAM

print("Launching exploration")
pg = p.factory.path_group(init, threads=8)
ex = pg.explore(find=find, avoid=avoid)

# Get stdout
final = ex.found[0].state
print("Flag: {0}".format(final.posix.dumps(1)))
{% endhighlight %}

> Flag: HACKCON{VVhYS04ngrY}

angry-reverser [executable and script](https://github.com/angr/angr-doc/tree/master/examples/hackcon2016_angry-reverser/)

