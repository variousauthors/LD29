--[[ Cutscene constructor class and Cutscenes object containing instances. ]]

Cutscenes = {}

function Cutscenes:Cutscene(options)
    options = options or {}
    local frames = options.frames or { }
    local delay  = options.delay or 3
    local musicStart  = options.musicStart
    local musicDone  = options.musicDone
    local musicStartNL = options.musicStartNL
    local musicDoneNL  = options.musicDoneNL
    local frameX = options.frameX or 0
    local frameY = options.frameY or 0
    local frameW = options.frameW or W_WIDTH
    local frameH = options.frameH or W_HEIGHT
    local nextCutscene = options.nextCutscene
    local is_running = false
    local current_frame, current_frame_delay = nil, nil
    local timer, frameIter = 0, 1

    local isRunning = function ()
        return is_running
    end

    local start = function ()
        is_running = true
        timer, frameIter = 0, 1

        if (not delay or type(delay) == "number") then
            current_frame = frames[frameIter]
        else -- every frame is an array of [frame, delay]
            current_frame = frames[frameIter][1]
            current_frame_delay = frames[frameIter][2]
        end

        if (musicStart == nil) then -- stop music
            Sound.pauseMusic()
        elseif (musicStart) then -- play the proper music
            Sound.stopMusic()
            Sound.playMusic(musicStart, musicStartNL)
        end
    end

    local stop = function ()
        is_running = false
    end

    local finish = function ()
        stop()
        if musicStart or musicDone then
            Sound.stopMusic()
        end
        if musicDone then
            Sound.playMusic(musicDone, musicDoneNL)
        else
            Sound.resumeMusic()
        end
        -- cutscene immediately following. kinda hacky, but TIIIIME
        if nextCutscene then
            self.current = self[nextCutscene]
            self.current.start()
        end
    end

    local update = function (dt)
        if not isRunning() then return false end
        if not delay then -- wait for keypress
            if love.keyboard.isDown("up", "down", "left", "right", " ") then
                frameIter = frameIter + 1
                if (frameIter > #frames) then
                    finish()
                else
                    current_frame = frames[frameIter]
                end
            end
        elseif (type(delay) == "number") then -- count up delay
            timer = timer + dt
            if timer >= delay then
                timer = 0
                frameIter = frameIter + 1
                if (frameIter > #frames) then
                    finish()
                else
                    current_frame = frames[frameIter]
                end
            end
        else -- delay of non-nil and non-number means frame-based
            timer = timer + dt
            if timer >= current_frame_delay then
                timer = 0
                frameIter = frameIter + 1
                if (frameIter > #frames) then
                    finish()
                else
                    current_frame = frames[frameIter][1]
                    current_frame_delay = frames[frameIter][2]
                end
            end
        end
        return true -- running and incremented
    end

    local draw = function ()
        --Cover everything with a rectangle first
        local red, green, blue = love.graphics.getColor()
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", 0, 0, W_WIDTH, W_HEIGHT)
        love.graphics.setColor(red, green, blue)

        -- Then draw frame
        if current_frame then
            love.graphics.draw( current_frame, frameX, frameY, 0,
                global.scale, global.scale)
        end
    end

    return {
        isRunning = isRunning,
        start     = start,
        stop      = stop,
        update    = update,
        draw      = draw
    }
end

--[[ Helpers! ]]

love.graphics.setDefaultFilter("nearest", "nearest")

local centerX = function (image)
    return (W_WIDTH / 2 ) - (image:getWidth() * global.scale / 2)
end

--[[
    Here be the Cutscenes
]]--

Cutscenes.current = Cutscenes.Cutscene() -- blank, placeholder

-- Start of Game
Cutscenes.StartScreen = Cutscenes:Cutscene({
    nextCutscene = "FirstLevel",
    musicStart = "Undesirable",
    musicStartNL = true
})

-- Plays before 1-1
local img11Start = love.graphics.newImage("assets/images/1-1start.png")
Cutscenes.FirstLevel = Cutscenes:Cutscene({
    frames = { img11Start },
    delay = 3,
    frameX = centerX(img11Start),
    musicDone = "M100tp5e0",
    nextCutscene = "Post11"
})

-- Plays after 1-1
local img11end01 = love.graphics.newImage("assets/scenes/1-1end/1-1end0001.jpg")
local img11end02 = love.graphics.newImage("assets/scenes/1-1end/1-1end0002.jpg")
local img11end03 = love.graphics.newImage("assets/scenes/1-1end/1-1end0003.jpg")
local img11end04 = love.graphics.newImage("assets/scenes/1-1end/1-1end0004.jpg")
local img11end05 = love.graphics.newImage("assets/scenes/1-1end/1-1end0005.jpg")
local img11end06 = love.graphics.newImage("assets/scenes/1-1end/1-1end0006.jpg")
local img11end07 = love.graphics.newImage("assets/scenes/1-1end/1-1end0007.jpg")
local img11end08 = love.graphics.newImage("assets/scenes/1-1end/1-1end0008.jpg")
local img11end09 = love.graphics.newImage("assets/scenes/1-1end/1-1end0009.jpg")
local img11end10 = love.graphics.newImage("assets/scenes/1-1end/1-1end0010.jpg")
local img11end11 = love.graphics.newImage("assets/scenes/1-1end/1-1end0011.jpg")
Cutscenes.Post11 = Cutscenes:Cutscene({
    frames = {
        {img11end01, 1},
        {img11end02, 0.1},
        {img11end03, 0.1},
        {img11end04, 0.1},
        {img11end05, 0.1},
        {img11end06, 0.5},
        {img11end07, 3.5},
        {img11end08, 1},
        {img11end09, 1},
        {img11end10, 0.2},
        {img11end11, 3.5}
    },
    frameX = centerX(img11end01),
    delay = "frames"
})

-- Plays before 2


-- Plays before 3

-- Shrines


