--[[ Cutscene constructor class and Cutscenes object containing instances. ]]

Cutscenes = {}

function Cutscenes:scene(options)
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
    local sceneName = options.name or "?"
    local done_callback = options.done_callback
    local old_done_callback = nil

    local getSceneName = function ()
        return sceneName
    end

    -- ALL THE HUDS
    local show_hud = true
    if options.showHUD ~= nil then
        show_hud = options.showHUD
    end



    local isRunning = function ()
        return is_running
    end

    local showHUD = function ()
        return show_hud
    end

    local start = function (cb)
        if (type(cb) == "function") then
            if done_callback then old_done_callback = done_callback end
            done_callback = cb
        end
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
        if musicDone then
            Sound.playMusic(musicDone, musicDoneNL)
        else
            Sound.resumeMusic()
        end
        if (type(done_callback) == "function") then
            done_callback()
            if old_done_callback then
                done_callback = old_done_callback
            else
                done_callback = nil
            end
        end
        -- cutscene immediately following. kinda hacky, but TIIIIME
        if nextCutscene then
            self.current = self[nextCutscene]
            self.current.start()
        end
    end

    local update = function (dt)
        if not isRunning() then return false end
        if (type(delay) == "number") then -- count up delay
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
        isRunning    = isRunning,
        showHUD      = showHUD,
        start        = start,
        stop         = stop,
        update       = update,
        draw         = draw,
        getSceneName = getSceneName
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

Cutscenes.blank = Cutscenes.scene() -- blank

Cutscenes.current = Cutscenes.blank -- placeholder

local imgGlitchScreen = love.graphics.newImage("assets/scenes/glitchscreen.png")

-- Start of Game

local imgStartScreen = love.graphics.newImage("assets/scenes/0-1welcomescreen.png")

Cutscenes.StartScreen = Cutscenes:scene({
    name = "StartScreen",
    frames = { imgStartScreen },
    delay = 3,
    frameX = centerX(imgStartScreen),
    nextCutscene = "Pre11"
})

-- Plays before 1-1
local img11Start = love.graphics.newImage("assets/scenes/1-1start.png")

Cutscenes.Pre11 = Cutscenes:scene({
    name   = "Pre11",
    frames = { img11Start },
    delay = 3,
    frameX = centerX(img11Start),
    musicDone = "M100tp5e0"
})

-- Plays before 2-1

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

Cutscenes.Pre21 = Cutscenes:scene({
    name   = "Pre21",
    frames = {
        {img11end01, 1},
        {img11end02, 0.1},
        {img11end03, 0.1},
        {img11end04, 0.1},
        {img11end05, 0.1},
        {img11end06, 0.5},
        {img11end07, 4},
        {img11end08, 1},
        {img11end09, 2},
        {img11end10, 0.2},
        {img11end11, 5}
    },
    frameX = centerX(img11end01),
    delay = "frames",
    musicStart = "M100tp5e4",
    nextCutscene = "Pre21b"
})

local img21Start = love.graphics.newImage("assets/scenes/2-1start.png")

Cutscenes.Pre21b = Cutscenes:scene({
    name   = "Pre21b",
    frames = { img21Start },
    delay = 3,
    frameX = centerX(img21Start),
    nextCutscene = "Intro21"
})

local img21intro01 = love.graphics.newImage("assets/scenes/2-1intro/2-1intro01.jpg")
local img21intro02 = love.graphics.newImage("assets/scenes/2-1intro/2-1intro02.jpg")
local img21intro03 = love.graphics.newImage("assets/scenes/2-1intro/2-1intro03.jpg")
local img21intro04 = love.graphics.newImage("assets/scenes/2-1intro/2-1intro04.jpg")
local img21intro05 = love.graphics.newImage("assets/scenes/2-1intro/2-1intro05.jpg")

Cutscenes.Intro21 = Cutscenes:scene({
    name   = "Intro21",
    frames = {
            { img21intro01, 0.5},
            { img21intro02, 1},
            { img21intro03, 4.5},
            { img21intro02, 0.5},
            { img21intro04, 5},
            { img21intro02, 0.5},
            { img21intro05, 2},
            { img21intro02, 0.5},
            { img21intro01, 0.5},
    },
    delay = "frames",
    frameX = centerX(img21Start),
    musicStart = "M100tp5e0"
})

-- Subsequent 2-1 runs
local img21end01 = love.graphics.newImage("assets/scenes/2-1end/2-1end01.jpg")
local img21end02 = love.graphics.newImage("assets/scenes/2-1end/2-1end02.jpg")
local img21end03 = love.graphics.newImage("assets/scenes/2-1end/2-1end03.jpg")
local img21end04 = love.graphics.newImage("assets/scenes/2-1end/2-1end04.jpg")
local img21end05 = love.graphics.newImage("assets/scenes/2-1end/2-1end05.jpg")
local img21end06 = love.graphics.newImage("assets/scenes/2-1end/2-1end06.jpg")
local img21end07 = love.graphics.newImage("assets/scenes/2-1end/2-1end07.jpg")

Cutscenes.Pre21Sub = Cutscenes:scene({
    name   = "Pre21Sub",
    frames = {
        {img21end01, 1},
        {img21end02, 0.1},
        {img21end03, 0.1},
        {img21end04, 0.1},
        {img21end05, 0.1},
        {img21end06, 0.5},
        {img21end07, 4} -- changed
    },
    frameX = centerX(img21end01),
    delay = "frames",
    musicStart = "M100tp5e4",
    nextCutscene = "Pre21Subb"
})

Cutscenes.Pre21Subb = Cutscenes:scene({
    name   = "Pre21Subb",
    frames = { img21Start },
    delay = 3,
    frameX = centerX(img21Start)
})

Cutscenes.Pre21G = Cutscenes:scene({
    name   = "Pre21G",
    frames = { imgGlitchScreen },
    frameX = centerX(imgGlitchScreen),
    delay = 2,
    musicStart = "M100tp5e4",
    nextCutscene = "Pre21Gb",
    showHUD = false
})

Cutscenes.Pre21Gb = Cutscenes:scene({
    name   = "Pre21Gb",
    frames = { img21Start },
    delay = 3,
    frameX = centerX(img21Start)
})

-- Plays before 5-1 (Map 3)
local img51Start = love.graphics.newImage("assets/scenes/5-1start.png")

Cutscenes.Pre51 = Cutscenes:scene({
    name   = "Pre51",
    frames = { img51Start },
    delay = 3,
    frameX = centerX(img51Start),
    musicDone = "M100tp5e0"
})

-- Subsequent 5-1 runs
local img51end01 = love.graphics.newImage("assets/scenes/5-1end/5-1end01.jpg")
local img51end02 = love.graphics.newImage("assets/scenes/5-1end/5-1end02.jpg")
local img51end03 = love.graphics.newImage("assets/scenes/5-1end/5-1end03.jpg")
local img51end04 = love.graphics.newImage("assets/scenes/5-1end/5-1end04.jpg")
local img51end05 = love.graphics.newImage("assets/scenes/5-1end/5-1end05.jpg")
local img51end06 = love.graphics.newImage("assets/scenes/5-1end/5-1end06.jpg")
local img51end07 = love.graphics.newImage("assets/scenes/5-1end/5-1end07.jpg")

Cutscenes.Pre51Sub = Cutscenes:scene({
    name   = "Pre51Sub",
    frames = {
        {img51end01, 1},
        {img51end02, 0.1},
        {img51end03, 0.1},
        {img51end04, 0.1},
        {img51end05, 0.1},
        {img51end06, 0.5},
        {img51end07, 4}
    },
    frameX = centerX(img21end01),
    delay = "frames",
    musicStart = "M100tp5e4",
    nextCutscene = "Pre51Subb"
})

Cutscenes.Pre51Subb = Cutscenes:scene({
    name   = "Pre51Subb",
    frames = { img51Start },
    delay = 3,
    frameX = centerX(img51Start)
})

Cutscenes.Pre51G = Cutscenes:scene({
    name   = "Pre51G",
    frames = { imgGlitchScreen },
    frameX = centerX(imgGlitchScreen),
    delay = 2,
    musicStart = "M100tp5e4",
    nextCutscene = "Pre51Gb",
    showHUD = false
})

Cutscenes.Pre51Gb = Cutscenes:scene({
    name   = "Pre51Gb",
    frames = { img51Start },
    delay = 3,
    frameX = centerX(img51Start)
})

-- Plays before 9-1 (Map 4)

local img91Start = love.graphics.newImage("assets/scenes/9-1start.png")

Cutscenes.Pre91 = Cutscenes:scene({
    name   = "Pre91",
    frames = { img91Start },
    delay = 3,
    frameX = centerX(img91Start),
    musicDone = "M100tp5e0"
})

-- Subsequent 9-1 runs

local img91end01 = love.graphics.newImage("assets/scenes/9-1end/9-1end01.jpg")
local img91end02 = love.graphics.newImage("assets/scenes/9-1end/9-1end02.jpg")
local img91end03 = love.graphics.newImage("assets/scenes/9-1end/9-1end03.jpg")
local img91end04 = love.graphics.newImage("assets/scenes/9-1end/9-1end04.jpg")
local img91end05 = love.graphics.newImage("assets/scenes/9-1end/9-1end05.jpg")
local img91end06 = love.graphics.newImage("assets/scenes/9-1end/9-1end06.jpg")
local img91end07 = love.graphics.newImage("assets/scenes/9-1end/9-1end07.jpg")

Cutscenes.Pre91Sub = Cutscenes:scene({
    name   = "Pre91Sub",
    frames = {
        {img91end01, 1},
        {img91end02, 0.1},
        {img91end03, 0.1},
        {img91end04, 0.1},
        {img91end05, 0.1},
        {img91end06, 0.5},
        {img91end07, 4}
    },
    frameX = centerX(img21end01),
    delay = "frames",
    musicStart = "M100tp5e4",
    nextCutscene = "Pre91Subb"
})

Cutscenes.Pre91Subb = Cutscenes:scene({
    name   = "Pre91Subb",
    frames = { img91Start },
    delay = 3,
    frameX = centerX(img91Start)
})

Cutscenes.Pre91G = Cutscenes:scene({
    name   = "Pre91G",
    frames = { imgGlitchScreen },
    frameX = centerX(imgGlitchScreen),
    delay = 2,
    musicStart = "M100tp5e4",
    nextCutscene = "Pre91Gb",
    showHUD = false
})

Cutscenes.Pre91Gb = Cutscenes:scene({
    name   = "Pre91Gb",
    frames = { img91Start },
    delay = 3,
    frameX = centerX(img91Start)
})

-- 10-0 finale

local img100finale01 = love.graphics.newImage("assets/scenes/10-0finale/10-0finale01.jpg")
local img100finale02 = love.graphics.newImage("assets/scenes/10-0finale/10-0finale02.jpg")
local img100finale03 = love.graphics.newImage("assets/scenes/10-0finale/10-0finale03.jpg")
local img100finale04 = love.graphics.newImage("assets/scenes/10-0finale/10-0finale04.jpg")
local img100finale05 = love.graphics.newImage("assets/scenes/10-0finale/10-0finale05.jpg")
local img100finale06 = love.graphics.newImage("assets/scenes/10-0finale/10-0finale06.jpg")
local img100finale07 = love.graphics.newImage("assets/scenes/10-0finale/10-0finale07.jpg")
local img100finale08 = love.graphics.newImage("assets/scenes/10-0finale/10-0finale08.jpg")
local img100finale09 = love.graphics.newImage("assets/scenes/10-0finale/10-0finale09.jpg")
local img100finale10 = love.graphics.newImage("assets/scenes/10-0finale/10-0finale10.jpg")
local img100finale11 = love.graphics.newImage("assets/scenes/10-0finale/10-0finale11.jpg")
local img100finale12 = love.graphics.newImage("assets/scenes/10-0finale/10-0finale12.jpg")
local img100finale13 = love.graphics.newImage("assets/scenes/10-0finale/10-0finale13.jpg")
local img100finale14 = love.graphics.newImage("assets/scenes/10-0finale/10-0finale14.jpg")
local img100finale15 = love.graphics.newImage("assets/scenes/10-0finale/10-0finale15.jpg")

Cutscenes.Finale100 = Cutscenes:scene({
    name   = "Finale100",
    frames = {
        {img100finale01, 2},
        {img100finale02, 1},
        {img100finale03, 0.1},
        {img100finale04, 0.1},
        {img100finale05, 0.1},
        {img100finale06, 0.1},
        {img100finale07, 0.5},
        {img100finale08, 5},
        {img100finale09, 0.5},
        {img100finale10, 0.1},
        {img100finale11, 0.1},
        {img100finale12, 0.1},
        {img100finale13, 0.1},
        {img100finale14, 0.5},
        {img100finale15, 2}
    },
    frameX = centerX(img100finale01),
    delay = "frames",
    musicStart = "M100tp5e4"
})

Cutscenes.flower_screen = Cutscenes:scene({
    name = "flower_screen",
    frames = {
        { img100finale15, 65536 }
    },
    frameX = centerX(img100finale01),
    delay = "frames",
    musicStart = "M100tp5e4"
})

-- Shrines

Cutscenes.Shrines = {}

local imgbackwards01 = love.graphics.newImage("assets/scenes/backwards/shrines_backwards01.jpg")
local imgbackwards02 = love.graphics.newImage("assets/scenes/backwards/shrines_backwards02.jpg")

Cutscenes.Shrines.Backwards = Cutscenes:scene({
    name = "Shrines.Backwards",
    frames = {
        {imgbackwards01, 3}
    },
    frameX = centerX(imgbackwards01),
    delay = "frames"
})

local imgbackwards5101 = love.graphics.newImage("assets/scenes/backwards/shrines_backwards5101.jpg")
local imgbackwards5102 = love.graphics.newImage("assets/scenes/backwards/shrines_backwards5102.jpg")
local imgbackwards5102 = love.graphics.newImage("assets/scenes/backwards/shrines_backwards5102.jpg")
local imgbackwards5103 = love.graphics.newImage("assets/scenes/backwards/shrines_backwards5103.jpg")
local imgbackwards5105 = love.graphics.newImage("assets/scenes/backwards/shrines_backwards5105.jpg")

Cutscenes.Shrines.Backwards51 = Cutscenes:scene({
    name = "Shrines.Backwards51",
    frames = {
        {imgbackwards5101, 1},
        {imgbackwards5102, 0.1},
        {imgbackwards5101, 0.1},
        {imgbackwards5102, 0.1},
        {imgbackwards5101, 0.1},
        {imgbackwards5102, 0.1},
        {imgbackwards5101, 0.1},
        {imgbackwards5102, 0.5},
        {imgbackwards5103, 5},
        {imgbackwards5102, 0.5},
        {imgbackwards5105, 3}
    },
    frameX = centerX(imgbackwards01),
    delay = "frames"
})

local imgclouds5101 = love.graphics.newImage("assets/scenes/clouds/shrines_clouds5101.jpg")
local imgclouds5102 = love.graphics.newImage("assets/scenes/clouds/shrines_clouds5102.jpg")
local imgclouds5103 = love.graphics.newImage("assets/scenes/clouds/shrines_clouds5103.jpg")
local imgclouds5105 = love.graphics.newImage("assets/scenes/clouds/shrines_clouds5105.jpg")

Cutscenes.Shrines.Clouds51 = Cutscenes:scene({
    name = "Shrines.Clouds51",
    frames = {
        {imgclouds5101, 0.5},
        {imgclouds5102, 3},
        {imgclouds5103, 5},
        {imgclouds5101, 0.5}, -- 04 is same as 01
        {imgclouds5105, 3}
    },
    frameX = 0,
    delay = "frames"
})

local imgclouds01 = love.graphics.newImage("assets/scenes/clouds/shrines_clouds01.jpg")
local imgclouds02 = love.graphics.newImage("assets/scenes/clouds/shrines_clouds02.jpg")

Cutscenes.Shrines.Clouds = Cutscenes:scene({
    name = "Shrines.Clouds",
    frames = {
        {imgclouds01, 1},
        {imgclouds02, 2}
    },
    frameX = centerX(imgclouds01),
    delay = "frames"
})

local imgdoublejump2101 = love.graphics.newImage("assets/scenes/doublejump/shrines_doublejump2101.jpg")
local imgdoublejump2102 = love.graphics.newImage("assets/scenes/doublejump/shrines_doublejump2102.jpg")
local imgdoublejump2103 = love.graphics.newImage("assets/scenes/doublejump/shrines_doublejump2103.jpg")
local imgdoublejump2105 = love.graphics.newImage("assets/scenes/doublejump/shrines_doublejump2105.jpg")

Cutscenes.Shrines.Doublejump21 = Cutscenes:scene({
    name = "Shrines.Doublejump21",
    frames = {
        {imgdoublejump2101, 0.5},
        {imgdoublejump2102, 3},
        {imgdoublejump2103, 5},
        {imgdoublejump2101, 0.5}, -- 04 is same as 01
        {imgdoublejump2105, 3}
    },
    frameX = 0,
    delay = "frames"
})

local imgdoublejump5101 = love.graphics.newImage("assets/scenes/doublejump/shrines_doublejump5101.jpg")
local imgdoublejump5102 = love.graphics.newImage("assets/scenes/doublejump/shrines_doublejump5102.jpg")
local imgdoublejump5103 = love.graphics.newImage("assets/scenes/doublejump/shrines_doublejump5103.jpg")
local imgdoublejump5105 = love.graphics.newImage("assets/scenes/doublejump/shrines_doublejump5105.jpg")

Cutscenes.Shrines.Doublejump51 = Cutscenes:scene({
    name = "Shrines.Doublejump21",
    frames = {
        {imgdoublejump5101, 0.5},
        {imgdoublejump5102, 3},
        {imgdoublejump5103, 5},
        {imgdoublejump5101, 0.5}, -- 04 is same as 01
        {imgdoublejump5105, 3}
    },
    frameX = 0,
    delay = "frames"
})

local imgdoublejump9101 = love.graphics.newImage("assets/scenes/doublejump/shrines_doublejump9101.jpg")
local imgdoublejump9102 = love.graphics.newImage("assets/scenes/doublejump/shrines_doublejump9102.jpg")
local imgdoublejump9103 = love.graphics.newImage("assets/scenes/doublejump/shrines_doublejump9103.jpg")
local imgdoublejump9105 = love.graphics.newImage("assets/scenes/doublejump/shrines_doublejump9105.jpg")

Cutscenes.Shrines.Doublejump91 = Cutscenes:scene({
    name = "Shrines.Doublejump21",
    frames = {
        {imgdoublejump9101, 0.5},
        {imgdoublejump9102, 3},
        {imgdoublejump9103, 5},
        {imgdoublejump9101, 0.5}, -- 04 is same as 01
        {imgdoublejump9105, 3}
    },
    frameX = 0,
    delay = "frames"
})

local imgwalljump = love.graphics.newImage("assets/scenes/walljump/shrines_walljump.jpg")

Cutscenes.Shrines.Walljump = Cutscenes:scene({
    name = "Shrines.Walljump",
    frames = {
        {imgwalljump, 3}
    },
    frameX = centerX(imgwalljump),
    delay = "frames"
})

local imgtrees01 = love.graphics.newImage("assets/scenes/trees/shrines_trees01.jpg")
local imgtrees02 = love.graphics.newImage("assets/scenes/trees/shrines_trees02.jpg")
local imgtrees03 = love.graphics.newImage("assets/scenes/trees/shrines_trees03.jpg")
local imgtrees04 = love.graphics.newImage("assets/scenes/trees/shrines_trees04.jpg")
local imgtrees06 = love.graphics.newImage("assets/scenes/trees/shrines_trees06.jpg")

Cutscenes.Shrines.Trees = Cutscenes:scene({
    name = "Shrines.Trees",
    frames = {
        {imgtrees01, 1},
        {imgtrees02, 0.1},
        {imgtrees01, 0.1},
        {imgtrees02, 0.1},
        {imgtrees01, 0.1},
        {imgtrees02, 0.1},
        {imgtrees01, 0.1},
        {imgtrees02, 0.75},
        {imgtrees03, 3},
        {imgtrees04, 5},
        {imgtrees02, 0.5},
        {imgtrees06, 3}
    },
    frameX = 0,
    delay = "frames"
})

