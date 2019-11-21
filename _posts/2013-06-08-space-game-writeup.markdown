---
layout: post
writeup: :)
title:  "BkP 2013 - Space Game Writeup (RE)"
date:   2013-06-08 22:00:00
description: Boston Key Party 2013 - space_game writeup
categories:
- writeup
- RE
---

This is an exercice from the Boston Key Party 2013 worth 250 points, starring a
Nintendo ROM. I really like this kind of challenges, so I decided to give
it a look.

The binary is a `Nintendo DS ROM`. I thus decide to give it a look with No$GBA:

<img src="http://i.imgur.com/ZnbqXdx.png" width="428" height="328"/>

The game asks for a special sequence of keys (left screen) and writes a message
on the bottom screen if it is incorrect (right screen). Let's find the sequence
checker in IDA. The keys pressed are stored in an array `(dword_2021464)` and
compared in `sub_2000430()` to some constant values:

![graph](http://i.imgur.com/31xtluj.png)

This graph gives a pretty clear pseudocode

{% highlight C %}
bool sequence_checker()
{
  bool result;

  result = 0;
  if ( *(_BYTE *)(dword_2021464 + 5) == 0x47
    && *(_BYTE *)(dword_2021464 + 2) == 0x56
    && *(_BYTE *)(dword_2021464 + 1) == 0x6e
    && *(_BYTE *)(dword_2021464 + 3) == 0x73
    && *(_BYTE *)dword_2021464 == 0x5a
    && *(_BYTE *)(dword_2021464 + 6) == 0x46 )
  {
    result = (unsigned int)*(_BYTE *)(dword_2021464 + 4) - 0x62 <= 0;
  }
  return result;
}
{% endhighlight %}

We then understand that the sequence is 7 keys long. Now, we need to find what
these values correspond to. Let's break at the top of the function that calls
our checker (the one that prints the bottom messages, easily found thanks to
the strings) at `0x200087c` and see what values are in our array to determine
each key. I input a serie of 7 keys and look at their key codes in `$r2`, which
gives me:

{% highlight sh %}
> A     == 0x56
> B     == 0x62
> L     == 0x47
> R     == 0x46
> <--   == 0x5a
> -->   == 0x6e
> Start == 0x73
{% endhighlight %}

I thus input the good keys in the right order and get the flag:

`<-- --> A Start B L R`

<img src="http://i.imgur.com/33MNbnP.png" width="214" height="328"/>

> Flag: thegamesux
