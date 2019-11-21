---
layout: post
writeup: :)
title:  "PlaidCTF 2016 - Rage Against The Machine Writeup (RE)"
date:   2016-04-17 23:55:00
description: PlaidCTF rage against the matchine ratm writeup 2016 250
categories:
- writeup
- RE
---

> All this new fangled machine learning stuff is pretty cool. But sometimes
> something comes out and you just have no idea what it is or how it works,
> you know? Running at 40.117.46.42:29281

This is an exercice from the PlaidCTF that was worth 250 points. It's not the
kind of reversing challenge I particulary like but it would have been sad not
to give it a try.

We are given a binary and a python2 script. The binary represents a database and the
script is a server that, when receiving a connection, sends a salt, waits for an
answer, computes a MD5 out of both, and quits if its first 3 bytes are not zeroes.
If they are, the server will read another (320 * 240 * 3 * 4) bytes and treat
it as a set of `rgb pixels from a 320x240 image`.

It will then pass it through a `neural network`, and if the image sent matches
more than `99%`, it will give you the flag. Else you will only be granted with a
"BAD". The database given represents the weights for the neural network nodes.

Okay, this challenge is in the "reversing" category. So normal minded people would
go on reversing the weights from the database and try to recover the picture from
the neural network, but nope. You, reading this, know like us that it's not the
hackiest way to solve this challenge. (wink wink)

Let's step back for a while. The challenge is called Rage against the Machine,
and it asks for a photo. Well, obviously, they want us to go on google, dump the
entire database of RATM pictures that fit the size 320x240, and feed them to the
server. Since the server was a pain in the ass to use (kill it if we modify it,
free the port, etc), [Pluggi](http://www.pluggi.fr) modified it so that
we could directly pass a binary file as argument to the neural network. He also
wrote a small util to convert any image to the right binary format (each color,
one at the time) and it worked remarkably well.

Okay, let's use the Google API to dump the whole set of pictures and... Just
kidding.
The challenge was released on the 16th, so we knew that the correct image would
be the Xth image on the Google search engine, with X % 16 == 0. So we
multihtreaded the lab and we all downloaded some of them to a common folder.
From there, we wrote a small script that would feed every picture to
Pluggi's utils and finally found the image from the dumped ones. 100% match! We
could not believe it.

Good. Let's try to send it to the server locally first, and see what happens. The
server sends a salt, we concatenate it to a 6 bytes long word, such that the MD5
of both begins with three `\x00\x00\x00`. For this, bruteforcing fits since we
are not limited by any timeout. We actually lost some time with
[xdbob](mailto:antoine.damhet@lse.epita.fr) while trying to handle tuples of
bytes and strings correctly, but it finally worked.

So now, little netcat in python, `cat "oh_gawd_it_works" > flag.txt`, and let's
launch our precious image:

{% highlight console %}
p1kachu@GreenLabOfGazon:ratm$ ./image_to_stream.py match.jpg match_stream
p1kachu@GreenLabOfGazon:ratm$ ./server_less_checker.py match_stream
Using Theano backend.
1.0
YAY!!!
p1kachu@GreenLabOfGazon:ratm$ ./server.py &
p1kachu@GreenLabOfGazon:ratm$ ./exploit_local.py
62700879138d
MD5 OK

oh_gawd_it_works
{% endhighlight %}

HOLY COWS, it works. Now, we need to send it to the real server. While it is running on
the MD5, we prepare the Russian Anthem (which was the selected song this year for
"we scored") and wait...

...

...for the "BAD" to arrive.

Wait what ?

{% highlight console %}
p1kachu@GreenLabOfGazon:ratm$ ./exploit.py
f412e6516ccf
MD5 OK

Flag: BAD
{% endhighlight %}


Indeed, what we did not see was the `'Hints'` section telling that we should use
the `tensor flow backend` and not `theano backend`, which was buggy and
apparently accepted some picture at higher ratios than it should. So
we changed the backend, tried our image, and got `0.0`... Well, the URSS anthem
will have to wait.

We must have missed something, let's think again... Wait, the challenge features
Machine learning, and is named Rage against the Machine ! So xdbob had the
revelation, and came up with this image from google:

![machinelearning.png](http://www.ratml.org/ratml-web.png)

That MUST be it, it fits too well !

But it was not on a position that was a multiple of 16 on google, so our hopes
were not very high, and indeed, it resulted in another (almost) 0.0.

{% highlight console %}
p1kachu@GreenLabOfGazon:ratm$ KERAS_BACKEND=tensorflow server_less_checker.py match_stream
Using TensorFlow backend.
4.587161983e-16
Boooh......
{% endhighlight %}

But, while we were trying this image, I had left a script running on the new
backend with the previous set of images, and one lead a 99,8% !

![This one](http://photos1.blogger.com/img/68/3526/320/Fist-800x600.jpg)

We transformed the image into a binary stream, sent it to the server, broke the
MD5, waited an eternity for the server to pass the picture into the neural
network, got the flag, submitted it and... PLAYED THE FREAKIN RUSSIAN ANTHEM!

{% highlight console %}
p1kachu@GreenLabOfGazon:ratm$ ./exploit.py
f412e6516ccf
MD5 OK

Flag: PCTF{be_glad_we_didnt_ask_what_it_is_supposed_to_recognize}
{% endhighlight %}


Thank you Plaid for this awesome challenge !

> Flag: PCTF{be\_glad\_we\_didnt\_ask\_what\_it\_is\_supposed\_to\_recognize}

An archive with what we used is available [here](/assets/content/ratm.tar.gz) if
anyone wants to take a look.

PS: I joke a little bit about the images being the 16th and stuff, we just wanted
to try some pictures to see how the weights were varying and we got extremely lucky!
Anyway, it still was fun!
