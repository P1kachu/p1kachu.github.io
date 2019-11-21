---
layout: post
title:  "Building a custom infotainment system"
date:   2018-12-17 02:35:00
description: custom ivi infotainment subaru polo obd can ssm
categories:
- project
- automotive
---

> What makes great car chases in movies and video games? The soundtrack.

This won't be a very technical post (unless I mess it up), but more of an
overview of the latest stupid thing I've been working on.

#### Background

I've liked cars and ~~racing~~ _driving sensibly_ since before I even got my
license.
After my [talk at 34c3](https://github.com/P1kachu/talking-with-cars#playing-with-can),
I've been fooling around automotive related computer science and security as
much as I could. Here, I will describe the longest project I have worked on
since starting computer science (merely 5 years ago), which is a "drive
controlled" infotainment system. What's that ? Simply put, I always listen to
music when I drive, and I unconsciously find myself matching my driving to the
song currently playing. What I've wanted for the longest time was the opposite,
an infotainment system that would match my driving.


#### Step one, lay the plan down

For this project, I wanted something easy to move from one car to another, as
responsive as possible, with a nice display. I usually hate doing graphic
stuff, but for this I might as well do something that integrates nicely with
the car. The initial idea I had was a system implementing those
characteristics:
- Pretty but minimalist interface with information about the current music, the
  minimum amount of buttons, and a media player taking roughly 90% of the
  screen playing videos
- Connected to the car, to poll data about my driving (mostly OBD-II)
- Powered through the cigarette lighter (still present in most cars, easiest
  way for a PoC)
- Have some girl co-pilot voice, or something that would react to the driving
  (like K.I.T.T, but... cuter.)

Choosing the hardware and frameworks for this project was a real pain, and the
first 4 weeks were mainly testing different ones until something seemed to
work. I won't dive into all of this, so let's fast-forward to the first
working version.

This was a very rough PoC. For the hardware, I used an
[Asus TinkerBoard](https://www.asus.com/us/Single-Board-Computer/Tinker-Board/)
running the official (mostly working) Debian TinkerOS. Discussing on the Asus
forum helped me plug the
[PiCAN2 shield](http://skpang.co.uk/catalog/pican2-canbus-board-for-raspberry-pi-23-p-1475.html)
for CAN communications through OBD-II. The car I did most of my initial testing
on was a [2013 Volkswagen Polo](https://p1kachu.github.io/34c3-how-to-drift-with-any-car/#/7)
that supported CAN and OBD-II, allowing me to query information about the car
(and thus my driving). The screen was a classic 7" Raspberry Pi touchscreen
through HDMI/USB. For the software, I used python for all the core tasks (music
through VLC bindings, python-can for CAN over OBD-II) and wxWidgets for the interface.
To this day, this is still what I use since *it works*. The wxWidget interface
and the python core communicate with each other through [ZeroMQ](http://zeromq.org/).
It's not as pretty as could have been something with [JUCE](https://juce.com/)
or even [Kivy](https://kivy.org), but these were too laggy on the Tinkerboard,
or didn't support some features I wanted. The sound was transfered to the car's
speakers through the auxilliary mini-jack input.

![Rough working setup](/assets/content/ivi-1.png)

#### Step two, match the music and the driving

The first version was my initial vision of the project: the interface would
play videos (the original audio tracks of the videos were removed) and musics
depending on my sole speed. There were
[calm, relaxed songs](https://www.youtube.com/watch?v=iWwU-Pfqt1g)
and videos for idle and low-speed driving (under around 40 km/h), and
[more aggressive ones](https://youtu.be/ivhqJrcl-V8?t=29) for higher speeds.
While this was easy to implement (I just needed to look at the
speed from OBD-II and change the media accordingly), this very quickly became
unpleasant when test driving. At each stop light, the music would cut to
something calm, then re-change when accelerating, which meant I was never able
to listen to one song completely when driving in city streets. Another thing I
expected would happen, but not to this extent, was the inconvenience generated
by the video clips. In Japan, most cars have a screen in the center panel that
allows drivers to watch baseball (for example) when waiting at the stop lights.
But when the car starts running over a certain speed (~5/10km/h), the screen
goes dark while the sound remains. Mine didn't turn dark, and while this was
very nice for passengers to pass time, it didn't help the driver's
concentration. Here is an early clip of the interface:

<div style="position:relative;padding-top:56.25%;">
<iframe style="position:absolute;top:0;left:0;width:100%;height:100%;" src="https://www.youtube.com/embed/2BpssHHmzCI" frameborder="0" allowfullscreen></iframe>
</div><br />

#### Step three, make it fancy

I added the first voice effect for the "not AI but looks like an AI"
co-pilot, as well as some "moods" that are different video+song playlists
depending on what I wanted to listen (Girls Und Panzer OST, calm musics,
driving musics, anime musics, retrowave, etc). I didn't add any way to match a
song and a video, so videos were quite generic for each songs of one specific
mood. Below is an extract of my first test drives (note the rough setup) and
testing. It was still quite buggy and full of experimental features, but at
least it was taking form.

<div style="position:relative;padding-top:56.25%;">
<iframe style="position:absolute;top:0;left:0;width:100%;height:100%;" src="https://www.youtube.com/embed/uOT86ZcrLoQ" frameborder="0" allowfullscreen></iframe></div><br />

#### Step four, discard everything

At this point (meaning, _after fixing all the bugs I had by driving in circles
on the highway interchanges_), I had pretty much reached the initial goal I had
fixed but was unhappy with the result. This was not very fun to drive with, and
only allowed me to change playlists with videos I couldn't (shouldn't) even
look at. Overall, I had the same result I would have by plugging my phone to
the aux input, but way more complicated in every sense.

In fact, the music changing depending on the speed was not really what I
needed. What I really needed for this project to become interesting, was what I
then called the `Now I'm pissed™ mode`. Picture yourself driving behind a
way-too-slow car on a montain road, when the once-in-a-lifetime opportunity of
passing it finally occurs, or having to escape the bad guys you just spotted in
your rear-mirror (you never know, ok ?). You go from third to second gear, and
floor it. This very moment is when you need that music boost: the `Now I'm
pissed™ mode`. This was very interesting to develop as I needed way more
information about the car (accelerator pressure, RPM, speed, etc), as there
were a lot of moments where this triggered when it shouldn't have, but in the
end it worked and completely replaced the previous modes. I also dropped the
video interface to display analytics about the car instead. The `Now I'm
pissed™ mode - LVL2` is a small upgrade where the IVI only relies on the
accelerator pedal to trigger the music. It's way more aggressive but also way
easier to trigger for track and racing.

Another detail worth noting is that I moved to Japan at this point and bought
my own car. It's an old Subaru Impreza that didn't support CAN, and I thus
needed to add a module to support its old Subaru Select Monitor v1 (SSM1)
protocol. The project being mostly car independant, it was just a matter of
overloading the base functions with SSM1-specific ones. All of this was however
a pain to create as there was few to none information available, so most of it
was done via reverse engineering. Also, as it didn't support CAN, I had to
replace the PiCAN2 shield with something else (Teensy 3.2, in the end). I won't
dive into that now, as this was part of my research work at WhiteMotion this
year, and will probably be the subject of a future post/talk/whatever (UPDATE: [here it is](https://p1kachu.github.io/project/automotive/2018/12/28/subaru-ssm1/)).

SSM1 works over a 1953 bauds serial link, so querying the data was waaaaay
slower than CAN, which is why I couldn't get data as accurate. But it's still
enough.

![Communicating through SSM1 via Teensy](/assets/content/ivi-2.png)

#### Step five, integrate it

I had my own car, that I often drove on tracks like the Fuji Speedway, so I was
willing to integrate the system to the central console as much as possible. The
car was built in 1997, so the previous infotainment system was pretty obsolete.

![Removing the old sound system...](/assets/content/ivi-4.png)

Fast-forward [replacing the whole sound sytem of the
car](https://youtu.be/AfneXDkRw64) (I replaced the big old aftermarket stereo
with a [Pioneer GM-D14000II amplifier](https://www.amazon.co.jp/dp/B00XBK34FE/ref=cm_sw_r_tw_dp_U_x_KRK8BbR1HGN7A)
connected to the car's speakers).
I fixed some bugs, added features and removed annoying ones, and was able to get
something ok-tier that fits my need. While not being perfect, it still works
even on long trips (more than 5 hours) without overheating (summer in Tokyo is
_harsh_), and is a great tool when going to the track. I added an option where
the IVI will trigger an alarm if some values go wild like, temperature too
high, RPM too low (happens sometimes on this car), and such. The gear displayed
is not always accurate when shifting as the exact gear was not available from
the ECU (UPDATE 2019: found it in RAM directly later). I thus used the fact that the
RPM and speed's relation is linear and each gear has a different ratio
constant. So I just had to look at the transmission's spec, find said constants
and check to which of them the current rpm/speed ratio is the closest.

![... and installing the new one](/assets/content/ivi-5.png)

Demonstration 1, out of the car with data replay
<div style="position:relative;padding-top:56.25%;">
<iframe style="position:absolute;top:0;left:0;width:100%;height:100%;" src="https://www.youtube.com/embed/wXUaatJNEQ0" frameborder="0" allowfullscreen></iframe></div><br />
Demonstration 2, SSM1 half-setup with audio and fixed dummy data
<div style="position:relative;padding-top:56.25%;">
<iframe style="position:absolute;top:0;left:0;width:100%;height:100%;" src="https://www.youtube.com/embed/JdRbURrrJuc" frameborder="0" allowfullscreen></iframe></div><br />
Demonstration 3, driving tests (simple autoradio and race display)
<div style="position:relative;padding-top:56.25%;">
<iframe style="position:absolute;top:0;left:0;width:100%;height:100%;" src="https://www.youtube.com/embed/5p0JIAQpxDQ" frameborder="0" allowfullscreen></iframe></div><br />
Demonstration 4, Now I'm Pissed™ mode trigger
<div style="position:relative;padding-top:56.25%;">
<iframe style="position:absolute;top:0;left:0;width:100%;height:100%;" src="https://www.youtube.com/embed/26vyWaAEJBI" frameborder="0" allowfullscreen></iframe></div><br />

For the little story, you can see I added a GIF of Mugi that blinks. While I'm
very fond of it, this GIF actually serves a real purpose, which is almost the
same as the CCC's Maneki-neko: it allows me at a glance to verify that the
interface didn't freeze, even if the displayed data doesn't change (when
testing, the engine is not always running, so the data barely evolves for
example).

#### Conclusion

The end result's features are the following:
- Realtime data acquisition and recording, so it can be replayed with a dummy-car
  plugin for testing purposes or driving analytics
- Full music controls (volume, play/pause, next)
- Different moods available (while there are slight differences between each of
  them, these are mainly just playlists now)
- Now I'm Pissed Mode™ works pretty well, and triggers only when I want it to
  (which is super nice)
- Adding support to a new car is easy (as long as the hardware is supported by the
  TinkerBoard, but at least I have CAN and SSM1 already)
- Different display modes, with bigger fonts and selected data, easier to see
  through GoPro footages

As surprising as it seems, this stupid project ended up useful when talking
with other drivers about how to drive on the track, as they could actually see
how and at which speed I was driving, how and when I shift, even when not being
with me in the car.

I'm still looking for ways to add more functionnalities to this, but I lack
ideas. Maybe add some position tracking to recreate tracks/roads that could
become a cheap racing GPS (manually add which speeds to brake to when reaching
each corner for example, like a rally copilot). (UPDATE: I did the GPS part for
recreating tracks/roads in the end, but I haven't found the time to actually write
about it yet. [Here is an
example](https://twitter.com/0xP1kachu/status/1085789186706165760) however).

I skipped an awful lot of details in this, as I don't feel this has any
technical interest, but I still wanted to showcase this project a bit. I'd like
to create a second version on "real", more robust hardware with more
capabilities, powered as an accessory, but as for now, my car at least made its
entrance into the 21th century. I hope you liked the overall project, feel free
to tell me your remarks and ideas on [Twitter](https://twitter.com/0xp1kachu),
and thanks for reading!

(2018/12/29): Quick update. I received some comments stating that this would
not help people driving any better, and just help them get angry. While this
could be true, this project is only here to present the fact that you could
have an infotainment system that evolves regarding the way you drive, in any
way possible, not only the music (fuel economy, warning messages, seat position
when cruising on the highway, cameras and sensors regarding whether you are in
the streets or the mountains, etc). I'm not promoting speeding here, just
showing up a programming project that could become the basis of software with
real usages.

#### Wowowow hey, where is the code ?

I won't release the code yet for multiple reasons, the first one being "omg I can't
let people see ~~this monstruosity~~ the magic". I'm still
working on it and it really is very unstable (I still work with copies of the
SD card image, that I need to reflash a lot), so as long as I don't deem it
finished, I will keep cleaning and enhancing it. :)

![3](/assets/content/ivi-3.gif)
