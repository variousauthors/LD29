LD29
====

Super Mario Bros.

BUG

OK So small Mario is falling through the floor sometimes. To figure out why,
I stood on the first flower block in 5-1, centered mario so that his bottom
middle and bottom right collision pixels (1, 0) and (1, 1) were in contact
with the block. Then I jumped, clearing the logs each time so that I would
capture only the collision that causes mario to slip down through the floor.

Here is the collision:

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

Then mario, having slipped through the floor, landed (normally)
on the next block below:

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

We can see that he was standing on tile (22, 20) but was moved 18 pixels
to the left by the collision, which put him on tile (21, 20) (mid air).
The collision direction appears to have been "from the left" (1, 0). The
corner pixel used was (24, 16) based on the mini mario bounding box.

Compare this with the normal collision that follows, in which the direction
is "from above" (0, 1) and the corner is (12, 32).
