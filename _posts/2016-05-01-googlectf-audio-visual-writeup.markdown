---
layout: post
writeup: :)
title:  "GoogleCTF 2016 - Audio Visual Receiver Writeup (RE)"
date:   2016-05-01 13:45:00
description: googlectf writeup 2016 150 audio visual receiver code
categories:
- writeup
- RE
---

> Can you find the code?

This is another 64bits executable. This one just read characters from stdin and
handles them as buttons. If the character entered is different from the expected
charset, the function will just skip it.

The charset represents a gamepad:

{% highlight console %}
'U' or 'u' will call up()
'D' or 'd' will call down()
'R' or 'r' will call left()
'L' or 'l' will call right()
'A' or 'a' will call a()
'B' or 'b' will call b()
{% endhighlight %}

In every function, a `state` globale variable is modified in some way, along with
some other variables used to keep state of the position in the input buffer. When
`a` is pressed, a check is made regarding the value of `state`. It should be called
3 times, and have the values 0x25, 0x68, and 0xef respectively.
If one of them fail, the game is 'reset' (but the reset() function does nothing).
If the check is passed for each value, the input sequence is xored with a hardcoded
buffer in memory.

The pass is supposed to be between 29 and 32 chars long.

At this point, I was going to give it to z3 again when [Gaby](mailto:gabriel@lse.epita.fr)
asked me `'have you tried the konami code ?'`

For those who don't know, the [Konami code](https://en.wikipedia.org/wiki/Konami_Code)
is a famous 10 buttons long cheat code using only the buttons we are waiting for:

> Up Up Down Down Left Right Left Right B A

With GDB, I saw that inputing it actually matched the first check, but I
thought that it was lucky guess. We needed to determine the two other checks,
so Gaby went on simplifying the code to reduce it to a simple function:

{% highlight c %}
#include <stdio.h>

#define __int8 char
#define _BYTE char

// SHOULD BE THE HARDCODED BUFFER
char flag[] = "TMP";

char check;
char state = 5;
char buffer[32];
char *pos = buffer;

char *cross_ptr = "%hn";

//----- (00000000004009C7) ----------------------------------------------------
int output_flag()
{
  char *v1; // [sp+0h] [bp-10h]@1
 char *v2; // [sp+8h] [bp-8h]@1

  v2 = flag;
  v1 = buffer;
  while ( *v2 )
    putchar((*v2++ ^ *v1++));
  return putchar('\n');
}

int main(int argc, const char **argv, const char **envp)
{
        unsigned __int8 v3; // ST1F_1@2
        char v1, v0;


        while ( 1 ) {
                *(_BYTE *)pos = state;
                pos = (char *)pos + 1;
                if ( (_BYTE *)pos - buffer > 32 )
                        pos = buffer;
                check ^= state;

                switch ( getchar() ) {
                        default:
                                continue;
                        case 'u':
                                state = state * 3;
                                break;
                        case 'd':
                                state = state*4 - state/2;
                                break;
                        case 'l':
                                state *= 2;
                                break;
                        case 'r':
                                state = (state / 8) | (state * 32);
                                break;
                        case 'b':
                                state = ~state;
                                break;
                        case 'a':

                                if ( *(_BYTE *)cross_ptr == check ) {
                                        check = 0;
                                        cross_ptr = (char *)cross_ptr + 1;
                                        if ( (_BYTE *)pos - buffer > 29 )
                                                output_flag();
                                } else {
                                        puts("loser");
                                        // reset();
                                }
                                break;
                }
        }

        return 0;
}
{% endhighlight %}

But, before trying to go further, I actually tried another `konami code` after
the first check, which... worked. Another one maybe ? Good too. And here goes the
flag...

{% highlight console %}
p1kachu@GreenLabOfGazon:GoogleCTF$ ./audio_visual_receiver_code
Enter char: uuddlrlrbauuddlrlrbauuddlrlrba
Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: Enter char: CTF{the_3rd_time_is_the_charm}
Enter char:
{% endhighlight %}

So yes, if we had just played dumb we would probably have solved it in 2 minutes.
Three konami codes, 150 pts. Hell of a cheat !

> Flag: CTF{the_3rd_time_is_the_charm}


Audio visual [executable and simplification](/assets/content/googlectf16_konami.tar.gz)
