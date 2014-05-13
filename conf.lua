-- globals having to do with the tile library
global              = {}
global.limitDrawing = true  -- If true then the drawing range example is shown
global.benchmark    = false -- If true the map is drawn 20 times instead of 1
global.useBatch     = false -- If true then the layers are rendered with sprite batches
global.tx           = 0     -- X translation of the screen
global.ty           = 0     -- Y translation of the screen
global.scale        = 2     -- Scale of the screen
global.tile_size    = 16    -- the pixels in a tile square
global.tile_height  = 15    -- the tile squares in a window
global.tile_width   = 16    -- the tile squares in a window
global.flower_get   = false -- whether a flower was got this tic
global.flowers      = 0     -- the number of flowers collected so far
global.double_jump  = false -- EVERYTHING IS GLOBAL NOW...  prorgamming!
global.walljump     = false -- arbitrary shrine, no gamplay effect
global.backwards	= false -- HOOK IN HERE ZIGGY, this doesn't actually have gameplay yet

-- debugging stuff
tile_x        = nil
tile_y        = nil
player_vx     = ""
player_vy     = ""
sprite_quad   = ""
sprite_facing = ""
collisions    = {}
time          = 0
teleport      = ""

function love.conf(t)
    -- tile height * scale factor * layer height
    t.window.height = global.tile_size * global.scale * global.tile_height
    t.window.width  = global.tile_size * global.scale * global.tile_width
    t.window.title = "Super Plumber Bros."
    t.modules.physics = false
end
