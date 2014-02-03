---
layout: post
title: "CodeKata: How it Started"
date: 2013-12-31 00:00:00 -0600
comments: true
categories: 
---

(This is a long one. It explains how I discovered that something I do
almost every day to improve my coding is actually a little ritual that
has much in common with practice in the martial arts…)

<!-- more -->

This all starts with the way RubLog, some blogging software I once
wrote. I wanted to experiment how it does searching (but this isn’t an
article about searching, or about bit twiddling. Trust me). Because I
eventually wanted to use cosine-based comparisons to find similar
articles, I build vectors mapping word occurrences to each document in
the blog. I basically ended up with a set of 1,200-1,500 bits for each
document. To implement a basic ranked search, I needed to be able to
perform a bitwise AND between each of these vectors and a vector
containing the search terms, and then count the number of one-bits in
the result.

I had a spare 45 minutes last night (I took Zachary to his karate
lesson, but there was no room in the parent’s viewing area), so I
thought I’d play with this. First I tried storing the bit vectors
different ways: it turns out (to my surprise) that storing them as an
array of fixnums has almost exactly the same speed as storing them as
the bits in a bignum. (Also, rather pleasingly, changing between the
two representations involves altering just two lines of code). Because
it marshals far more compactly, I decided to stick with the bignum.

Then I had fun playing with the bit counting itself. The existing code
uses the obvious algorithm:

```ruby
max_bit.times { |i| count += word[i] }
```

Just how slow was this? I wrote a simple testbed that generated one
hundred 1,000 bit vectors, each with 20 random bits set, and timed the
loop. For all 100, it took about .4s.

Then I tried using the ‘divide-and-conquer’ counting algorithm from
chapter 5 of Hacker’s Delight (modified to deal with chunking the
Bignum into 30-bit words).

``` ruby
((max_bit+29)/30).times do |offset|
  x = (word >> (offset*30)) & 0x3fffffff
  x = x - ((x >> 1) & 0x55555555)
  x = (x & 0x33333333) + ((x >> 2) & 0x33333333)
  x = (x + (x >> 4)) & 0x0f0f0f0f;
  x = x + (x >> 8)
  x = x + (x >> 16)
  count += x & 0x3f
end
```

This ran about 2.5 times faster that the naive algorithm.

Then I realized that when I was comparing a set of search times with
just a few words in it, the bit vector would be very sparse. Each
chunk in the loop above would be likely to be zero. So I added a test:

``` ruby
((max_bit+29)/30).times do |offset|
  x = (word >> (offset*30)) & 0x3fffffff
  next if x.zero?
  x = x - ((x >> 1) & 0x55555555)
  x = (x & 0x33333333) + ((x >> 2) & 0x33333333)
  x = (x + (x >> 4)) & 0x0f0f0f0f;
  x = x + (x >> 8)
  x = x + (x >> 16)
  count += x & 0x3f
end
```

Now I was seven times faster than the original. But my testbed was
using vectors containing 20 set bits (out of 1,000). I changed it to
generate timings with vectors containing 1, 2, 5, 10, 20, 100, and 900
set bits. This got even better: I was up to a factor of 15 faster with
1 or 2 bits in the vector.

But if I could speed things up this much by eliminating zero chunks in
the bit-twiddling algorithm could I do the same in the simple counting
algorithm? I tried a third algorithm:

``` ruby
((max_bit+29)/30).times do |offset|
   x = (word >> (offset*30)) # & 0x3fffffff
   next if x.zero?
   30.times {|i| count += x[i]}
 end
```
 
The inner loop here is the same as for the original count, but I now
count the bits in chunks of 30.

This code performs identically to the bit-twiddling code for 1 set
bit, and only slightly worse for 2 set bits. However. once the number
of bits starts to grow (past about 5 for my given chunk size), the
performance starts to tail off. At 100 bits it’s slower than the
original naive count.

So for my particular application, I could probably chose either of the
chunked counting algorithms. Because the bit twiddling one scales up
to larger numbers of bits, and because I’ll need that later on if I
ever start doing the cosine-based matching of documents, I went with
it.

So what’s the point of all this?

Yesterday I posted a [blog entry](http://pragdave.me/blog/2003/03/23/artifacting/)
about the importance of verbs. It said
"Often the true value of a thing isn’t the thing itself, but instead
is the activity that created it." Chad Fowler picked this up and wrote
a [wonderful piece](http://chadfowler.com/blog/2003/03/25/valueless-software/)
showing how this was true for musicians. And Brian
Marick picked up of Chad’s piece to emphasize the value of practice
when learning a creative process.

At the same time, Andy and I had been discussing a set of music tapes
he had. Originally designed to help musicians practice scales and
arpeggios, these had been so popular that they now encompassed a whole
spectrum of practice techniques. We were bemoaning the fact that it
seemed unlikely that we’d be able to get developers to do the same: to
buy some aid to help them practice programming. We just felt that
practicing was not something that programmers did.

Skip forward to this morning. In the shower, I got to thinking about
this, and realized that my little 45 minute exploration of bit
counting was actually a practice session. I wasn’t really worried
about the performance of bit counting in the blog’s search algorithm;
in reality it comes back pretty much instantaneously. Instead, I just
wanted to play with some code and experiment with a technique I hadn’t
used before. I did it in a simple, controlled environment, and I tried
many different variations (more than I’ve listed here). And I’ve still
got some more playing to do: I want to mess around with the effect of
varying the chunk size, and I want to see if any of the other bit
counting algorithms perform faster.

What made this a practice session? Well, I had some time without
interruptions. I had a simple thing I wanted to try, and I tried it
many times. I looked for feedback each time so I could work to
improve. There was no pressure: the code was effectively throwaway. It
was fun: I kept making small steps forward, which motivated me to
continue. Finally, I came out of it knowing more than when I went in.

Ultimately it was having the free time that allowed me to practice. If
the pressure was on, if there was a deadline to delivery the blog
search functionality, then the existing performance would have been
acceptable, and the practice would never have taken place. But those
45 pressure-free minutes let me play.

So how can we do this in the real world? How can we help developers do
the practicing that’s clearly necessary in any creative process? I
don’t know, but my gut tells me we need to do two main things.

The first is to take the pressure off every now and then. Provide a
temporal oasis where it’s OK not to worry about some approaching
deadline. It has to be acceptable to relax, because if you aren’t
relaxed you’re not going to learn from the practice.

The second is to help folks learn how to play with code: how to make
mistakes, how to improvise, how to reflect, and how to measure. This
is hard: we’re trained to try to do things right, to play to the
score, rather than improvise. I suspect that success here comes only
after doing.

So, my challenge for the day: see if you can carve out 45 to 60
minutes to play with a small piece of code. You don’t necessarily have
to look at performance: perhaps you could play with the structure, or
the memory use, or the interface. In the end it doesn’t
matter. Experiment, measure, improve.

Practice.
