local i = require("vendor/inspect/inspect")
inspect = function (a, b)
    print(i.inspect(a, b))
end

-- globals having to do with the tile library
global = {}
global.limitDrawing = true      -- If true then the drawing range example is shown
global.benchmark = false        -- If true the map is drawn 20 times instead of 1
global.useBatch = false         -- If true then the layers are rendered with sprite batches
global.tx = 0                   -- X translation of the screen
global.ty = 0                   -- Y translation of the screen
global.scale = 2                -- Scale of the screen

W_WIDTH  = love.window.getWidth()
W_HEIGHT = love.window.getHeight()

require("sound") -- Sound global object
require("cutscenes")
require("sprites")
require("player")
require("vector")

-- debugging stuff
tile_x = ""
tile_y = ""
player_vx = ""
player_vy = ""
sprite_quad = ""
sprite_facing = ""
collisions = {}
time = 0
teleport = ""

-- we store the levels in a table and I expect when there are more of them we will just
-- iterate
local Map = require("map")

local maps = {
    -- 1-1
    LevelOne("map1-1.tmx", {
        sprite = Sprites.bigguy,
        doors = {
            {
                coords = { 204, 12 },
                event  = "onVictory"
            }
        },
        scenes = {
            init = "StartScreen",
            sub = "Pre11"
        }
    }),

    -- 2-1
    SubsequentLevels("map2-1.tmx", {
        sprite = Sprites.ladyguy,
        doors = {
            {
                coords = { 204, 12 },
                event  = "onVictory"
            }
        },
        scenes = {
            init = "Pre21",
            sub  = "Pre21Sub"
        }
    }),

    -- 5-1
    SubsequentLevels("map2-1.tmx", {
        sprite = Sprites.lilguy,
        doors = {
            {
                coords = { 204, 12 },
                event  = "onVictory"
            }
        },
        scenes = {
            init = "Pre51",
            sub  = "Pre51Sub"
        }
    }),

    -- 9-1
    SubsequentLevels("map2-1.tmx", {
        sprite = Sprites.oldguy,
        doors = {
            {
                coords = { 204, 12 },
                event  = "onVictory"
            }
        },
        scenes = {
            init = "Pre91",
            sub  = "Pre91Sub"
        }
    }),

    -- 10-0 (Finale)
    SubsequentLevels("map2-1.tmx", {
        sprite = Sprites.oldguy,
        doors = {
            {
                coords = { 204, 12 },
                event  = "onVictory"
            }
        },
        scenes = {
            init = "Finale100"
        }
    })
}

local num = 1                   -- The map we're currently on
local fps = 0                   -- Frames Per Second
local fpsCount = 0              -- FPS count of the current second
local fpsTime = 0               -- Keeps track of the elapsed time

-- Reset the current example
if maps[num].reset then maps[num].reset() end

local origin, player

function init_player (p, s)
    player = Player(p, s)
end

function love.load()
    origin = Point(0, 0) -- somehow I just feel safer having a global "origin"
    start  = Point(origin.getX() + 200, origin.getY() + 200)
    maps[num].reset()
    init_player(start, maps[num].sprite)
    --First cutscene.
    Cutscenes.current = Cutscenes.StartScreen
    Cutscenes.current.start()
end

function love.update(dt)
    collisions = {}
    time = time + dt

    -- Polling/cleanup/loop stuff.
    Sound.update()

    -- If cutscene running, abort rest of loop.
    if Cutscenes.current.update(dt) then return end

    player.update(dt, maps[num])

    -- the player pushes the screen along
    if player.getX() > W_WIDTH / 2 and player.getX() > global.tx then
        local v = player.getV()
        global.tx = global.tx - ( math.min(v.getX(), 1.5) * dt * 100 )
        player.setX(W_WIDTH / 2)
    end

    if player.getX() < 0 then player.setX(0) end

    -- Call update in our example if it is defined
    if maps[num].update then maps[num].update(dt) end

    if maps[num].isFinished() then
        if player.isDead() then
            -- remove the player
            -- do the mario death jump
            -- something to hold back following code until anim & music are done
        end

        -- "proceed" either loads the next world or the next level
        -- depending on the map state
        maps[num].onProceed()

        -- if we "proceed" and the map is still finished, then we move to
        -- the next world
        if maps[num].isFinished() then
            -- TODO the end game
            num = num + 1
            maps[num].reset()

            -- New map means new "initial" scene
            if(Cutscenes[maps[num].scenes.init]) then
                Cutscenes.current = Cutscenes[maps[num].scenes.init]
                if (num ~= #maps) then
                    Cutscenes.current.start()
                else
                    --Final map == final cutscene
                    Cutscenes.current.start(function ()
                        --What to do after the final cutscene is done?
                        print("GAME OVER")
                    end)
                end
            end
        end

        -- If no scene has started, show the "subsequent runs" screen.
        if not Cutscenes.current.isRunning() then
            if(Cutscenes[maps[num].scenes.sub]) then
                Cutscenes.current = Cutscenes[maps[num].scenes.sub]
                -- Callback here is kind of hacky. The purpose is to
                -- Make sure the level retains the proper glitchy music.
                Cutscenes.current.start( function ()
                    Sound.stopMusic()
                    Sound.playMusic(maps[num].getGlitchMusic())
                end)
            end
        end

        -- must be called after map number is potentially incremented so that
        -- the right character loads
        init_player(start, maps[num].sprite)
    end

  --if #collisions > 0 then
  --    print("======================")
  --    print(time)
  --    inspect(collisions)
  --end

end

function love.keypressed(k)
    -- quit
    if k == 'escape' then
        love.event.push("quit")
    end

    if k == "0"
    or k == "1"
    or k == "2"
    or k == "3"
    or k == "4"
    or k == "5"
    or k == "6"
    or k == "7"
    or k == "8"
    or k == "9" then
        teleport = teleport .. k
    end

    if #teleport == 4 then
        local dest = tonumber(teleport)
        teleport = ""

        global.tx = -dest
    end

    player.keypressed(k)

    -- Call keypressed in our maps if it is defined
    if maps[num].keypressed then maps[num].keypressed(k) end
end

function love.draw()
    local red, green, blue = love.graphics.getColor()
    -- we are all the red square
    love.graphics.setColor(146, 144, 255)
    love.graphics.rectangle("fill", 0, 0, W_WIDTH, W_HEIGHT)
    love.graphics.setColor(red, green, blue)

    -- Draw cutscene or map
    if Cutscenes.current.isRunning() then
        Cutscenes.current.draw()
    else
        maps[num].draw()
        player.draw()
    end

    love.graphics.print(player.getX(), 50, 50)
    love.graphics.print(player.getY(), 50, 70)
    love.graphics.print(tile_x, 50, 90)
    love.graphics.print(tile_y, 50, 110)
    love.graphics.print(global.tx, 50, 130)
    love.graphics.print(global.ty, 50, 150)
    love.graphics.print(player_vx, 50, 170)
    love.graphics.print(player_vy, 50, 190)
    love.graphics.print(sprite_facing .. " " .. sprite_quad, 50, 210)
end

