LD29
====

Super Mario Bros.


Screen Scrolling & Bands
------------------------

### Bands as a property on Player

We want the current band to be a property on mario that is checked whenever the
player lands on a platform, rather than something based purely on tx, ty coords.

The screen should only jump up or down when mario has landed on a tile in a new
band. We can use `mid_air` to determine that.

### Map Origin

Currently the bands depend on mario's starting tx, ty but this is lame. Instead
each level should define an "origin" on the map (top left of the start screen)
and base the bands on that offset. Mario's starting tx, ty should also be based
on that offset.

### Starting Position

Currently mario seems to be detecting as slightly below his current position,
and in particular when starting mario is often sucked into the earth, and out
of time forever.

Wall Sliding
------------

As it stands, Mario slides up surfaces. Mario can catch his forehead on a ledge
and slide down it, or increase his maximum jump height by sliding up a ledge.

When mario jumps into an object or surface, we expect him to lose all forward
momentum, but to retain momentum along the y-axis. He should appear to "slide"
up towards the tops of pipes, and continue falling after hitting a surface.

The work here relates to the collision detection being unable to resolve a
good direction to send mario when resolving a diagonal collision pixel.

Collision Detection
-------------------

_RESOLVED_

OK So small Mario is falling through the floor sometimes. To figure out why,
I stood on the first flower block in 5-1, centered mario so that his bottom
middle and bottom right collision pixels (1, 0) and (1, 1) were in contact
with the block. Then I jumped, clearing the logs each time so that I would
capture only the collision that causes mario to slip down through the floor.

Here is the collision:

```
    before resolution
    { 250.50054608999, 196.13867341042 }
    after resolution
    { 232.50054608999, 196.13867341042 }
    collision:
      corner:
    { 24, 16 }
      direction:
    { 1, -0 }
      tile:
    { 22, 20 }
```

Then mario, having slipped through the floor, landed (normally)
on the next block below:

```
    before resolution
    { 232.50054608999, 289.51609361011 }
    after resolution
    { 232.50054608999, 287.51609361011 }
    collision:
      corner:
    { 12, 32 }
      direction:
    { -0, 1 }
      tile:
    { 21, 24 }
```

We can see that he was standing on tile (22, 20) but was moved 18 pixels
to the left by the collision, which put him on tile (21, 20) (mid air).
The collision direction appears to have been "from the left" (1, 0). The
corner pixel used was (24, 16) based on the mini mario bounding box. That
means... the corner in use is... the right middle? WTF

Compare this with the normal collision that follows, in which the direction
is "from above" (0, 1) and the corner is (12, 32).

On closer inspection, it seems that mario's right middle collision point
is detecting a tile (tile 22, 20) and colliding off of it in the first
of the two collision loops (LOOP A)

Here is the output from a more recent run (in this run mario was given a
perfectly square bounding box).

```
    LOOP A <-- WTF
    before resolution
    { 237.12184571, 196.78205050003 }
    after resolution
    { 213.12184571, 196.78205050003 }
    collision:
      corner:
    { 32, 16 } <-- one full mario width over, and half a mario height down
      direction:
    { 1, -0 }
      tile:
    { 22, 20 }
```

I feel there might be something wrong with the "detect" function.

Aha! The problem is that small mario is travelling fast enough that he
gets buried deep in the tile below him.

For now I'm going to try reducing gravity, so that this threshold isn't crossed. I think
I don't understand the "speculative" collision detection. I must meditate on this.
Also, I think mario's jump needs to accelerate to full force.

OH MAN. I found an ages old bug (a typo) that was preventing me from setting
resistance so that x != y. Now there is more horizontal resistance than vertical,
I've capped max speed, and lowered gravity. Feels much better! Also, later
mario is less likely to crash through the earth. The collision with the corners
is still weird (if mario lands on a platform with just a corner, he will be nudged
away from the corner) but I feel like that is a much less fundamental problem.

In the original Japanese Mario, the jumps are _very_ slow.

Mario still "slides" up stairs. This is because of the corners again. We want
him to lose his X velocity but maintain the Y in these cases... but how to detect
the cases.


