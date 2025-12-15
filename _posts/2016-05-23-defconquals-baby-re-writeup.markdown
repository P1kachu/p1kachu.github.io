---
layout: post
writeup: :)
title:  "Defcon Quals 2016 - baby-re Writeup (RE)"
date:   2016-05-23 02:05:00
description: defcon quals ctf writeup 2016 1 baby
categories:
- writeup
- RE
---

> Get to reversing.

baby-re is what the DEFCON organizers call a "Baby's first" exercice, which means
you shouldn't expect too much points from it.
Here, it's a 64bits executable that asks for a password character by character.

It will read 13 characters, store them and apply some mathematics on their ascii
values. LOTS of mathematics (here is an overview of the `CheckSolution` function)

![graph](/assets/content/defcon2016_graph.png)


And to solve this one since I suck at maths, I used
[angr][angr] which is a framework for analyzing binaries by using concolic
analysis.

Here is the script I used to solve this challenge:
{% highlight python %}
#!/usr/bin/python2

import angr
import simuvex
import logging

# DEFCON - BABY-RE
# @author: P1kachu
# @contact: p1kachu@lse.epita.fr

p = angr.Project('baby-re')


win            = 0x4028e9  # good
fail           = 0x402941  # fail
main           = 0x4025e7  # Address of main
PASS_LEN       = 13
call_check     = 0x4028e0
flag_addr      = 0x7fffffffffeff98 # First rsi from scanf
find           = (win,)
avoid          = (fail,)


def patch_scanf(state):
    print(state.regs.rsi)
    state.mem[state.regs.rsi:] = state.se.BVS('c', 8)

# Taken from xrefs
scanf_offsets = (0x4d, 0x85, 0xbd, 0xf5, 0x12d, 0x165,
                 0x19d, 0x1d5, 0x20d, 0x245, 0x27d,
                 0x2b5, 0x2ed)


init = p.factory.blank_state(addr=main)

# I don't know what angr handles right now
# So, patching.
# Patch patch patch.
for offst in scanf_offsets:
    p.hook(main + offst, func=patch_scanf, length=5)

# Specifying threads is only useful in z3-intensive paths
# (because z3, in C, multithreads)
pgp = p.factory.path_group(init, threads=8)

# Now LET'S EXPLORE
ex = pgp.explore(find=find, avoid=avoid)

print(ex)
s = ex.found[0].state

# Let's do that in a hacky, not clever way
# Yeah I didn't know about posix.dump...
flag = s.se.any_str(s.memory.load(flag_addr, 50))

# The flag is 'Math is hard!'
print("The flag is '{0}'".format(flag))
{% endhighlight %}

> Flag: Math is hard!

Yay, 1 point... (sobs)

baby-re [executable and solution](https://github.com/angr/angr-doc/blob/master/docs/examples.md#reverseme-example-defcon-quals-2016---baby-re)

[angr]: http://angr.io/
