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

require("sprites")
require("player")
require("vector")

-- we store the levels in a table and I expect when there are more of them we will just
-- iterate
local Map            = require("map")
local HeadsUpDisplay = require("heads_up_display")
local GameJolt       = require("gamejolt")
local write_map_data = require("map_data")
local Menu           = require("menu")
local viewport       = require("viewport").new({
    width = global.window_width,
    height = global.window_height,
    resizable = false
})
local maps           = write_map_data()

local num        = 1 -- The map we're currently on
local last_level = 4
local fps        = 0 -- Frames Per Second
local fpsCount   = 0 -- FPS count of the current second
local fpsTime    = 0 -- Keeps track of the elapsed time
local final_flower = love.graphics.newImage("assets/images/mana_flower.png")

local origin, player, hud, gj, menu, profile, locale

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
    menu = Menu()
    menu.show(function ()
        -- stuff that happens after the menu is hidden
        profile       = menu.recoverProfile()
        global.locale = profile.lang

        require("cutscenes")
        Cutscenes.current = Cutscenes.StartScreen
        Cutscenes.current.start()

        hud = HeadsUpDisplay()
        hud.setWorld(maps[num].getName())
        hud.setItemType(maps[num].getItem())

        gj = GameJolt(global.floor_height, global.side_length)
    end)
end

local deflower = false

-- increment the number of flowers
global.getFlower = function ()
    global.flower_get = true
end

global.resolveFlower = function ()
    if global.flower_get then
        global.flowers = global.flowers + 1
        hud.setScore(global.flowers * 100)
        hud.setItems(global.flowers)
    end

    global.flower_get = false
end

function love.update(dt)

    if menu.isShowing() then return menu.update(dt) end

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
    if player.getX() > W_WIDTH / 2 + 50 and math.abs(global.tx) < global.max_tx - global.scale then
        local v = player.getV()
        global.tx = global.tx - ( v.getX() * dt * player.getSpeed() ) / global.scale
        player.setX(W_WIDTH / 2 + 50)
    elseif global.backwards and player.getX() < W_WIDTH / 2 - 50 and global.tx < -global.scale then
        local v = player.getV()
        global.tx = global.tx - ( v.getX() * dt * player.getSpeed() ) / global.scale
        player.setX(W_WIDTH / 2 - 50)
    end

    -- the player cannot leave the screen
    if player.getX() < 0 then player.setX(0) end
    if player.getX() > (global.window_width - global.tile_size * global.scale) then player.setX(global.window_width - global.tile_size * global.scale) end

    -- if the player is standing on the 12th block (the ground)
    -- the screen should always be centered
    --
    local tile_tall = maps[num].sprite.tile_height
    band            = maps[num].getBand(tile_y)

    if band ~= nil then
        local scroll = 8
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
    hud.setTimer(maps[num].getTime())

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
            maps[num].setFinished(false)

            num = num + 1
            maps[num].reset()
            hud.setWorld(maps[num].getName())
            hud.setItemType(maps[num].getItem())

            -- New map means new "initial" scene
            if(Cutscenes[maps[num].scenes.init]) then
                Cutscenes.current = Cutscenes[maps[num].scenes.init]
                if (num ~= #maps) then
                    Cutscenes.current.start()
                else
                    --Final map == final cutscene
                    Cutscenes.current.start(function ()
                        --What to do after the final cutscene is done?

                        gj.connect_user(profile.username, profile.token)

                        local plural = ""
                        if global.flowers > 1 or global.flowers == 0 then plural = "s" end
                        gj.add_score(global.flowers .. " flower" .. plural, global.flowers)
                        Cutscenes.current = Cutscenes["flower_screen"]
                        Cutscenes.current.start(function ()
                            global.flowers = 0
                            hud.setScore(global.flowers * 100)
                            hud.setItems(global.flowers)
                        end)

                        -- overwrite maps to fix glitches
                        maps = write_map_data()

                        num = 2

                        maps[num].reset()
                        hud.setWorld(maps[num].getName())
                        hud.setItemType(maps[num].getItem())
                        init_player(maps[num].getStart(), maps[num].sprite)
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
end

local inputPressed = function(k, isRepeat)
    if menu.isShowing() then return menu.keypressed() end

    -- if(k == "r") then
    --     Cutscenes.current.stop()
    --     Sound.stopMusic()

    --     Cutscenes.current = Cutscenes.StartScreen
    --     Cutscenes.current.start()

    --     global.flowers = 0
    --     hud.setScore(global.flowers * 100)
    --     hud.setItems(global.flowers)

    --     maps = write_map_data()
    --     num = 1
    --     maps[num].reset()

    --     hud.setWorld(maps[num].getName())
    --     hud.setItemType(maps[num].getItem())
    --     init_player(maps[num].getStart(), maps[num].sprite)
    -- end

    -- No jumping during cutscenes
    if Cutscenes.current.isRunning() then
        -- in order to ski pa cutscene we just pass in a huge number of seconds
        if not isRepeat and Input.isPressed("jump") then Cutscenes.current.update(65536) end
    else
        player.keypressed(k)
    end

    -- Call keypressed in our maps if it is defined
    if maps[num].keypressed then maps[num].keypressed(k) end
end

function love.textinput(t)
    if menu.isShowing() then return menu.textinput(t) end
end

function love.keypressed(k, isRepeat)
    -- quit
    if (k == 'escape' or k == 'f10') then
        love.event.push("quit")
    elseif(k == 'f' or k == 'f11') then
        viewport:setFullscreen()
        viewport:setupScreen()
    end

    if menu.isShowing() then return menu.keypressed(k) end

--  if k == "0"
--  or k == "1"
--  or k == "2"
--  or k == "3"
--  or k == "4"
--  or k == "5"
--  or k == "6"
--  or k == "7"
--  or k == "8"
--  or k == "9" then
--      teleport = teleport .. k
--  end

--  if #teleport == 4 then
--      local dest = tonumber(teleport)
--      teleport = ""

--      global.tx = -dest
--  end

    inputPressed(k, isRepeat)
end

function love.gamepadpressed(j, k)
    inputPressed(k)
end

function love.draw()
    viewport:pushScale()

    if menu.isShowing() then
        menu.draw()
        viewport:popScale()
        return true
    end

    -- Draw cutscene or map
    if Cutscenes.current.isRunning() then
        Cutscenes.current.draw()
    else
        maps[num].draw()
        player.draw()
    end

    if Cutscenes.current.getSceneName() == "flower_screen" and Cutscenes.current.isRunning() then
        local sx, sy    = global.scale, global.scale
        love.graphics.draw(final_flower, W_WIDTH / 2 - global.scale * global.tile_size, W_HEIGHT / 2, 0, sx, sy, 0, 0)
        love.graphics.print("x" .. global.flowers, W_WIDTH / 2 + global.scale * global.tile_size - 20, W_HEIGHT / 2 + 20)
    end

    if not Cutscenes.current.isRunning() or Cutscenes.current.showHUD() then
        hud.draw()
    end

    viewport:popScale()
end
