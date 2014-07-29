-- globals having to do with the tile library
global               = {}

function DEC_HEX(IN)
    local B,K,OUT,I,D=16,"0123456789abcdef","",0
    while IN>0 do
        I=I+1
        IN,D=math.floor(IN/B),math.mod(IN,B)+1
        OUT=string.sub(K,D,D)..OUT
    end
    return OUT
end

sides = { 1005366685, 1351747387, 3316243027, 930149632 }
floor_height = 27754

global.side_length   = ""
global.floor_height  = "" .. floor_height

for i, v in ipairs(sides) do
    global.side_length = global.side_length .. DEC_HEX(v)
end

global.limitDrawing  = true  -- If true then the drawing range example is shown
global.benchmark     = false -- If true the map is drawn 20 times instead of 1
global.useBatch      = false -- If true then the layers are rendered with sprite batches
global.tx            = 0     -- X translation of the screen
global.ty            = 0     -- Y translation of the screen
global.max_tx        = nil   -- how big map is map even?
global.tile_size     = 16    -- the pixels in a tile square
global.tile_height   = 15    -- the tile squares in a window
global.tile_width    = 16    -- the tile squares in a window
global.flower_get    = false -- whether a flower was got this tic
global.flowers       = 0     -- the number of flowers collected so far
global.double_jump   = false -- EVERYTHING IS GLOBAL NOW...  prorgamming!
global.walljump      = false -- arbitrary shrine, no gamplay effect
global.backwards     = false -- HOOK IN HERE ZIGGY, this doesn't actually have gameplay yet
global.secret        = false
global.max_fps       = 60
global.window_height = global.tile_size * global.tile_height
global.window_width  = global.tile_size * global.tile_width


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
    t.window.height = global.window_height
    t.window.width  = global.window_width
    t.window.title = "Super Plumber Bros."
    t.modules.physics = false
    t.window.vsync = true
end
