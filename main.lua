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
local Map            = require("map")
local HeadsUpDisplay = require("heads_up_display")
local maps           = require("map_data")

local num = 1                   -- The map we're currently on
local fps = 0                   -- Frames Per Second
local fpsCount = 0              -- FPS count of the current second
local fpsTime = 0               -- Keeps track of the elapsed time

local origin, player, hud

function init_player (p, s)
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

    hud = HeadsUpDisplay()
end

local deflower = false

-- increment the number of flowers
global.getFlower = function ()
    global.flower_get = true
end

global.resolveFlower = function ()
    if global.flower_get then
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
    -- if global.tx < global.max_tx
    -- then mario should push the screen
    -- if mario can move backwards
    -- and global.tx > 0
    -- then mario should push the screen
    if player.getX() > W_WIDTH / 2 + 50 and math.abs(global.tx) < global.max_tx then
        local v = player.getV()
        global.tx = global.tx - ( v.getX() * dt * player.getSpeed() ) / global.scale
        player.setX(W_WIDTH / 2 + 50)
    elseif global.backwards and player.getX() < W_WIDTH / 2 - 50 and global.tx < 0 then
        local v = player.getV()
        global.tx = global.tx - ( v.getX() * dt * player.getSpeed() ) / global.scale
        player.setX(W_WIDTH / 2 - 50)
    end

    -- the player cannot leave the screen
    if player.getX() < 0 then player.setX(0) end
    if player.getX() > global.window_width then player.setX(global.window_width) end

    -- if the player is standing on the 12th block (the ground)
    -- the screen should always be centered
    --
    local tile_tall = maps[num].sprite.tile_height
    band            = maps[num].getBand(tile_y)

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

        -- "proceed" either decides to load the next world or the next level
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
        -- in order to ski pa cutscene we just pass in a huge number of seconds
        -- if not isRepeat then Cutscenes.current.update(65535) end
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

    local increment = global.tile_width
    if k =='s' then
        global.ty = global.ty - increment
        player.setY(player.getY() - increment)
    end

    if k =='w' then
        global.ty = global.ty + increment
        player.setY(player.getY() + increment)
    end

    if k == 'd' then
        global.double_jump = true
    end

    if k == "k" then
        hud.decrementY()
    end

    if k == "j" then
        hud.incrementY()
    end

    if k == "h" then
        hud.decrementX()
    end

    if k == "l" then
        hud.incrementX()
    end

    inputPressed(k, isRepeat)
end

function love.gamepadpressed(j, k)
    inputPressed(k)
end

function love.draw()
    -- Draw cutscene or map
    if Cutscenes.current.isRunning() then
        Cutscenes.current.draw()
    else
        maps[num].draw()
        player.draw()
    end

    if not Cutscenes.current.isRunning() or Cutscenes.current.showHUD() then
        hud.draw()
    end
end
