---
layout: post
title:  Fuzzing IOCTLs with angr
date:   2016-07-18 15:48:45
categories:
- project
- security
---

>  angr and I will join forces in a quest through anarchy, reversing compiled
> kernel modules to tear their beloved ioctls down…

*This was the subject of my talk at the LSEWeek 2016. The stream and the
slides are available at the end for further informations.*

My first project at the LSE was what put me on `angr`. The idea was to help `strace`
developpers (some at the labs) to handle IOCTLs and determine what commands could
be sent for a given kernel driver. Right now, the whole system is sadly too
unstable to be reliable.

This article will briefly explain what was done, what didn't work, and what I did
to fix the multiple issues I encountered. I will skip the very first parts where
I tried to use metasm and miasm, because nothing actually worked, and I will
directly jump to the part where angr comes in.

### The project

The idea was to take an IOCTL, launch a symbolic/concolic execution
engine on it, and determine which constraints were applied on the `cmd` argument.
As a bonus, finding the type of the `arg` argument would be nice.

The overall 'algorithm' looks like this:
{% highlight c %}
ioctls = find_ioctls("peel_me_sensually.ko");
for (ioctl in ioctls)
{
        endpoints = find_endpoints(ioctl);
        ex = explorer();
        for (endpoint in endpoints)
        {
                paths = get_paths(ex, ioctl.entry, endpoint);
                for (path in paths)
                {
                        print(get_constraints(path));
                        print(get_ret_val(path));
                }
        }
}
{% endhighlight %}

To begin, I explicitly had to tell the tool which function was interesting. I
would then get its endpoints (basic block where the function returns), tell angr
to go from the entry point to each of them, and print the paths where `%eax`
would be positive when reaching the end. I would then analyze the constraints
and get the possible return values. On a test module, which was not too easy nor
too complicated, it would work fine:

{% highlight c%}
/* ki_dev.c - Test binary */


/* Used to determine if the ioctl finder would work */
static long false_ioctl(int asd, int tmp)
{
        return asd * 2 + tmp;
}

static long my_ioctl(int fd, unsigned int cmd, unsigned long arg)
{
        int ret = 0;
        int tmp;
        i++;

        if (cmd == 0xb0bca7)
                return false_ioctl(1, 1);

        if (cmd == 0xa110c)
                return 0;

        if (cmd == 0xcafe) {
                printk("Cafe stuff\n");
                ret = EINVAL;
        }
        else if (cmd == 0xc0ca) {
                printk("Coca stuff\n");
                tmp = 7;
                tmp *=2;
                ret = 3;
                tmp += 2 * fd;
                ret = tmp;
                ret = false_ioctl(ret, 0xc1a55ed + i);
        }
        else
                ret = ENODEV;

        printk("Failed stuff\n");
        return -ret;
}
{% endhighlight %}

would give:

{% highlight console %}
p1kachu@GreenLabOfGazon:peeler$ ./pyfinder -q ki_dev.ko -f my_ioctl
[ ]   INFOS   Peeling ki_dev's ioctls

[ ]   INFOS   Analyzing function my_ioctl at 0x400030
[ ]   INFOS   Launching path_group explorer
[ ]   INFOS   Explorer: <PathGroup with 1 active, 1 found>

[ ]   INFOS   Analyzing 1 found paths
[ ]   INFOS   Path from 0x400030 to 0x400089L (1/1)
[+] SUCCESS   Satisfiable value: 0x3L
[ ]   INFOS   Explorer: <PathGroup with 1 active, 1 found>

[ ]   INFOS   Analyzing 1 found paths
[ ]   INFOS   Path from 0x400030 to 0x400053L (1/1)
[+] SUCCESS   Satisfiable value: 0x0L
[ ]   INFOS   Explorer: <PathGroup with 2 active, 1 found>

[ ]   INFOS   Analyzing 1 found paths
[ ]   INFOS   Path from 0x400030 to 0x400089L (1/1)
[ ]   INFOS   Return value would be 0xffffffffffffffedL - Skipping
[ ]   INFOS   Explorer: <PathGroup with 1 active, 1 found>

[ ]   INFOS   Analyzing 1 found paths
[ ]   INFOS   Path from 0x400030 to 0x400089L (1/1)
[ ]   INFOS   Return value would be 0xffffffffffffffeaL - Skipping
[ ]   INFOS   Explorer: <PathGroup with 1 found>

[ ]   INFOS   Analyzing 1 found paths
[ ]   INFOS   Path from 0x400030 to 0x400089L (1/1)
[+] SUCCESS   Min satisfiable value: 0x2L
[+] SUCCESS   Max satisfiable value: 0x7ffffffeL
[+] SUCCESS   Recovered values:
[ ]   INFOS   <Bool reg_40_13_64[31:0] == 0xb0bca7>: [0x3L, 0x3L]
[ ]   INFOS   <Bool reg_40_13_64[31:0] == 0xa110c>: [0x0L, 0x0L]
[ ]   INFOS   <Bool (reg_40_13_64[31:0] == 0xc0ca) && ((0xf3e5a9f6 + (0xffffffff * reg_48_17_64[29:0] .. 0#2))[31:31] == 0)>: [0x2L, 0x7ffffffeL]
[ ]   INFOS   End of analysis
{% endhighlight %}

The result was interesting, but lacked precision and would quickly explode when
the function was big. That was one of the first problem I encountered when using
angr: I was not in a CTF where only one path interested me and where I could help
it by patching some stuff, it had to be fully automatic. I thus tried to provide
some generic handling for redundant errors.

### Finding IOCTLs and duct taping

One thing I eventually figured out was that when you ask angr to find some address,
this address should be the one of the first instruction of a basic block, or the
exploration would not give you the expected result. This means that, if your address
was in a block, but not at the first instruction, angr would still stop at this
first instruction (it found the block, why would it go further ?). I didn't
thought this to be a problem until finding that some 'vital' instructions for
the project might be at the end of the block, like `mov eax, 0xfffffffe`, which
would set the return value of the function before returning. Fixing this was my
first angr pull request.

After polishing the exploration part, and securing it as much as possible (merge
paths to save memory, exception handling when it's 'not too dangerous'...), another
problem was to determine which IOCTL was interesting and where to find it. I first
went for a dumb method that would serve as fallback if the clever one failed, which
was to look for every symbol that would have 'ioctl' in it. This worked pretty
well but obviously missed some that were not called like that, and this would add
work because not every ioctl is called everytime, as some are just helpers.

The second way is the cleverest one in my opinion. When an IOCTL is registered
in a driver, it is passed to a `file_operations` structure first. This structure
holds multiple function pointers used by the module for different operations, and
amongst them are `compat_ioctl` and `unlocked_ioctl`. Sometimes, the
`compat_ioctl` is used for compatibility purpose and will call `unlocked_ioctl`,
or they just point toward the same function. Usually, these structures  are
static structures that stay in the `.data` section:

{% highlight c%}
struct file_operations {
        struct module *owner;
        loff_t (*llseek) (struct file *, loff_t, int);
        ssize_t (*read) (struct file *, char __user *, size_t, loff_t *);
        ssize_t (*write) (struct file *, const char __user *, size_t, loff_t *);
        ssize_t (*read_iter) (struct kiocb *, struct iov_iter *);
        ssize_t (*write_iter) (struct kiocb *, struct iov_iter *);
        int (*iterate) (struct file *, struct dir_context *);
        unsigned int (*poll) (struct file *, struct poll_table_struct *);
        long (*unlocked_ioctl) (struct file *, unsigned int, unsigned long);
        long (*compat_ioctl) (struct file *, unsigned int, unsigned long);
        int (*mmap) (struct file *, struct vm_area_struct *);

        <SNIPPED>
};
{% endhighlight%}

So the idea was to find them in memory and determine the value of the fields to
get the interesting IOCTLs. The `fops` is given to a register function for...
well registration. There are few of them. I thus took some for testing, and tried to
look in the module if any was called. When I found one, I could determine that
the `fops` would be one of its parameter and get its address. For this, I needed
to find where it was called... Let's be stupid for once, and parse the `CFG
(Control Flow Graph)` to find something like `call my_register_function`.
When found, I could take the instruction's address, and determine in which
function it was  by checking the upper and lower addresses of each symbol. With
that, I had the caller function, and the call instruction's address of the
registration function.

To determine the address of `fops`, I decided to launch an angr explorer from
the entry point of the caller toward the register function call, where I could break and just check
the registers. Sadly, the callers are often long functions and the multiple
unresolved function calls (we are in kernel land, which is not where angr feels
the better) used to break angr. So, let's try to be clever: the parameters are
passed to the function through registers, and they are just before the call,
so we can just launch the explorer toward the call from the beginning of the `block`
containing it, not from the caller's entry point. This saves time and memory.
Great. Doing this, we are able to examine the register, get the fops address,
compute the offset of the IOCTLs in the structure and crave in memory at the
found address to get the good IOCTL functions. FINALLY.

Well, it doesn't work all the time sadly. Calling conventions fail to give the
same registers, and often the memory is symbolic at this place and doesn't give
anything interesting. So I had to get something else to add a layer of fallback.

This was done in a simple manner: the DWARF symbols. We compiled the modules
with `KCFLAGS='-g'` and just used the debug infos to get the fops offset in
memory. However, this closed the project to private modules where the code was
not available...

The project's IOCTLs craver then looked like this:
{% highlight python %}

# Accurate and fast - Requires DWARF symbols
ioctls = find_ioctls_with_dwarf(project)

if ioctls is None:
        # Slow and instable, but accurate when
        # not breaking everything
        ioctls = find_ioctls_with_fops(project)

if ioctls is None:
        # Fast but inacurate
        ioctls = find_ioctls_with_symbols(project)

if ioctls is None:
        fail("No ioctl found")
{% endhighlight%}


In the end, the whole system is unusable for big modules¹, and I would have
needed too many layers of fallback for it to be robust enough. However, angr is
a great framework that can prove to be incredibly efficient when you are willing to
help it a little, and it was nice to dive in it in some unusual context (meaning,
not a CTF!)

*¹. A.K.A modules whose function call ANY library function, or have more than
~10 basic blocks...*

#### LSEWEEK 2016

You can see the [slides][slides] and the video (with english subs) of my talk on the
subject for some more details and context.
<iframe width="560" height="315" src="https://www.youtube.com/embed/2e_rPECxOB0" frameborder="0" allowfullscreen></iframe>


[slides]: http://p1kachu.github.io/lse/lseweek16/index.html#/
[video]: https://www.youtube.com/watch?v=2e_rPECxOB0

