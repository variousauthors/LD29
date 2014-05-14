local i = require("vendor/inspect/inspect")
inspect = function (a, b)
    print(i.inspect(a, b))
end

function math.round(val, decimal)
  local exp = decimal and 10^decimal or 1
  return math.ceil(val * exp - 0.5) / exp
end

love.graphics.setDefaultFilter("nearest", "nearest", 0)
MARIO_FONT = love.graphics.newFont("assets/images/emulogic.ttf", 8 * global.scale)
W_WIDTH  = love.window.getWidth()
W_HEIGHT = love.window.getHeight()

require("sound") -- Sound global object
require("input")

require("cutscenes")
require("sprites")
require("player")
require("vector")

-- we store the levels in a table and I expect when there are more of them we will just
-- iterate
local Map = require("map")
local maps = require("map_data")

local num = 1                   -- The map we're currently on
local fps = 0                   -- Frames Per Second
local fpsCount = 0              -- FPS count of the current second
local fpsTime = 0               -- Keeps track of the elapsed time

-- Reset the current example
if maps[num].reset then maps[num].reset() end

local origin, player

function init_player (p, s)
    inspect({ global.tx, global.ty })
    inspect({ p.getX(), p.getY() })
    player = Player(p, s)
end

function love.load()
    love.graphics.setFont(MARIO_FONT)

    origin = Point(0, 0) -- somehow I just feel safer having a global "origin"
    start  = Point(origin.getX() + 200, origin.getY() + 200)
    maps[num].reset()
    init_player(maps[num].getStart(), maps[num].sprite)
    --First cutscene.
    Cutscenes.current = Cutscenes.StartScreen
    Cutscenes.current.start()
end

local deflower = false

-- increment the number of flowers
global.getFlower = function ()
    global.flower_get = true
end

global.resolveFlower = function ()
    if global.flower_get then
        print("getting a flower")
        global.flowers = global.flowers + 1
    end

    global.flower_get = false
end

function love.update(dt)
    collisions = {}
    time = time + dt

    -- Polling/cleanup/loop stuff.
    Sound.update()

    -- If cutscene running, abort rest of loop.
    if Cutscenes.current.update(dt) then return end

    player.update(dt, maps[num])
    global.resolveFlower()

    -- the player pushes the screen along
    if player.getX() > W_WIDTH / 2 and player.getX() > global.tx then
        local v = player.getV()
        global.tx = global.tx - ( math.min(v.getX(), 1.5) * dt * 100 )
        player.setX(W_WIDTH / 2)
    end

    -- the player cannot go backwards
    if player.getX() < 0 then player.setX(0) end

    -- if the player is standing on the 12th block (the ground)
    -- the screen should always be centered
    --
    band   = maps[num].getBand(tile_y)

    if band ~= nil then
        local scroll = 10
        camera = maps[num].getCameraForBand(band)

        -- lock the player relative to the window, and scroll the background up
        if global.ty < camera then
            global.ty = global.ty + scroll
            player.setY(player.getY() + scroll * global.scale)
        end

        if global.ty > camera then
            global.ty = global.ty - scroll
            player.setY(player.getY() - scroll * global.scale)
        end
    end

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

        if maps[num].isGlitchedout() then
            -- play the glichout scene
            maps[num].setGlitchedout(false)
            if(Cutscenes[maps[num].scenes.glitch]) then
                Cutscenes.current = Cutscenes[maps[num].scenes.glitch]
                if (num ~= #maps) then
                    Cutscenes.current.start( function ()
                        Sound.playMusic(maps[num].getGlitchMusic())
                    end)
                end
            else
                -- if no glitch cutscene
                Sound.playMusic(maps[num].getGlitchMusic())
            end
        elseif not Cutscenes.current.isRunning() then
            -- No "new level" cutscene running, not glitchout, so finish
            -- by castle ("subsequent runs")
            if(Cutscenes[maps[num].scenes.sub]) then
                Cutscenes.current = Cutscenes[maps[num].scenes.sub]
                -- Callback here is kind of hacky. The purpose is to
                -- Make sure the level retains the proper glitchy music.
                Cutscenes.current.start( function ()
                    Sound.playMusic(maps[num].getGlitchMusic())
                end)
            else
                -- if no sub cutscene
                Sound.playMusic(maps[num].getGlitchMusic())
            end
        end

        -- must be called after map number is potentially incremented so that
        -- the right character loads
        init_player(maps[num].getStart(), maps[num].sprite)
    end

  --if #collisions > 0 then
  --    print("======================")
  --    print(time)
  --    inspect(collisions)
  --end

end

local inputPressed = function(k, isRepeat)
    -- No jumping during cutscenes
    if Cutscenes.current.isRunning() then
        if not isRepeat then Cutscenes.current.update(65535) end
    else
        player.keypressed(k)
    end

    -- Call keypressed in our maps if it is defined
    if maps[num].keypressed then maps[num].keypressed(k) end
end

function love.keypressed(k, isRepeat)
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

    if k =='s' then
        global.ty = global.ty - 100
        player.setY(player.getY() - 200)
    end

    if k =='w' then
        global.ty = global.ty + 100
        player.setY(player.getY() + 200)
    end

    inputPressed(k, isRepeat)
end

function love.gamepadpressed(j, k)
    inputPressed(k)
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

    if not Cutscenes.current.isRunning() then
        love.graphics.print("FLOWERS x " .. global.flowers, W_WIDTH - (100 * global.scale), (10 * global.scale))
    end
end

