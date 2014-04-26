local i = require("vendor/inspect/inspect")
inspect = function (a, b)
    print(i.inspect(a, b))
end

require("player")
require("vector")

-- Some global stuff that the examples use.
global = {}
global.limitDrawing = true      -- If true then the drawing range example is shown
global.benchmark = false        -- If true the map is drawn 20 times instead of 1
global.useBatch = false         -- If true then the layers are rendered with sprite batches
global.tx = 0                   -- X translation of the screen
global.ty = 0                   -- Y translation of the screen
global.scale = 1                -- Scale of the screen


---------------------------------------------------------------------------------------------------
-- Load the examples
local maps = {
    require("map")
}

local num = 1                   -- The map we're currently on
local fps = 0                   -- Frames Per Second
local fpsCount = 0              -- FPS count of the current second
local fpsTime = 0               -- Keeps track of the elapsed time

---------------------------------------------------------------------------------------------------
-- Reset the current example
if maps[num].reset then maps[num].reset() end

local origin, player

function love.load()
    origin = Point(0, 0)
    start  = Point(origin.getX() + 200, origin.getY() + 200)
    player = Player(start)
end

---------------------------------------------------------------------------------------------------
function love.update(dt)
    -- Camera follows the player's position as long as the player is moving "forward"

--  if love.keyboard.isDown("up") then global.ty = global.ty + 250*dt end
--  if love.keyboard.isDown("down") then global.ty = global.ty - 250*dt end
--  if love.keyboard.isDown("left") then global.tx = global.tx + 250*dt end
--  if love.keyboard.isDown("right") then global.tx = global.tx - 250*dt end

    player.update(dt, maps[num])

    -- Call update in our example if it is defined
    if maps[num].update then maps[num].update(dt) end
end

---------------------------------------------------------------------------------------------------
function love.keypressed(k)
    -- quit
    if k == 'escape' then
        love.event.push("quit")
    end

    player.keypressed(k)

    -- Call keypressed in our maps if it is defined
    if maps[num].keypressed then maps[num].keypressed(k) end
end

---------------------------------------------------------------------------------------------------
function love.draw()

    -- Draw our map
    maps[num].draw()
    player.draw()

end

