local i = require("vendor/inspect/inspect")
inspect = function (a, b)
    print(i.inspect(a, b))
end

require("player")
require("vector")

-- globals having to do with the tile library
global = {}
global.limitDrawing = true      -- If true then the drawing range example is shown
global.benchmark = false        -- If true the map is drawn 20 times instead of 1
global.useBatch = false         -- If true then the layers are rendered with sprite batches
global.tx = 0                   -- X translation of the screen
global.ty = 0                   -- Y translation of the screen
global.scale = 2                -- Scale of the screen


-- we store the levels in a table and I expect when there are more of them we will just
-- iterate
local maps = {
    require("map")
}

local num = 1                   -- The map we're currently on
local fps = 0                   -- Frames Per Second
local fpsCount = 0              -- FPS count of the current second
local fpsTime = 0               -- Keeps track of the elapsed time

-- Reset the current example
if maps[num].reset then maps[num].reset() end

local origin, player

function love.load()
    origin = Point(0, 0) -- somehow I just feel safer having a global "origin"
    start  = Point(origin.getX() + 200, origin.getY() + 200)
    player = Player(start)
end

function love.update(dt)

    player.update(dt, maps[num])

    -- Call update in our example if it is defined
    if maps[num].update then maps[num].update(dt) end
end

function love.keypressed(k)
    -- quit
    if k == 'escape' then
        love.event.push("quit")
    end

    player.keypressed(k)

    -- Call keypressed in our maps if it is defined
    if maps[num].keypressed then maps[num].keypressed(k) end
end

function love.draw()

    -- Draw our map
    maps[num].draw()
    player.draw()
end

