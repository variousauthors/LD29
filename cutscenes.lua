--[[ Cutscene constructor class and Cutscenes object containing instances. ]]

Cutscene = function (options)
    options = options or {}
    local frames = options.frames or { }
    local delay  = options.delay or 3
    local musicStart  = options.musicStart
    local musicDone   = options.musicDone or "M100tp5e0"
    local frameX = options.frameX or 0
    local frameY = options.frameY or 0
    local frameW = options.frameW or love.window.getWidth()
    local frameH = options.frameH or love.window.getHeight()
    local is_running = false
    local current_frame = nil
    local timer, frameIter = 0, 1

    local isRunning = function ()
        return is_running
    end

    local start = function ()
        is_running = true
        timer, frameIter = 0, 1
        current_frame = frames[frameIter]
        if (musicStart == nil) then -- stop music
            Sound.stopMusic()
        elseif (musicStart) then -- play the proper music
            Sound.stopMusic()
            Sound.playMusic(music)
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
            Sound.playMusic(musicDone)
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
        else -- count up delay
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
        end
        return true -- running and incremented
    end

    local draw = function ()
        if current_frame then
            love.graphics.draw( current_frame, frameX, frameY, 0,
                global.scale, global.scale)
        else
            local red, green, blue = love.graphics.getColor()
            love.graphics.setColor(0, 0, 0)
            love.graphics.rectangle("fill", frameX, frameY, frameW, frameH)
            love.graphics.setColor(red, green, blue)
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

--[[ Here be the Cutscenes ]]

Cutscenes = {}

Cutscenes.current = Cutscene() -- blank, placeholder

Cutscenes.FirstLevel = Cutscene({})
