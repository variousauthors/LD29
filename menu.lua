local Component = require("component")

LANG     = 0
USERNAME = 1
TOKEN    = 2

return function ()
    local showing       = false
    local hide_callback = function () end
    local cursor_pos    = 0
    local lang          = "en"
    local menu_index    = 0
    local username      = ""
    local token         = ""
    local time, flash   = 0, 0

    local inputs = {
        {   -- language_select
            clear      = function ()
                lang       = "en"
                cursor_pos = 0
            end,
            keypressed = function (key)
                if key == "left" or key == "right" then
                    if lang ~= "en" then
                        lang       = "en"
                        cursor_pos = 0
                    else
                        lang       = "jp"
                        cursor_pos = 40
                    end
                end
            end
        },
        {   -- username
            clear      = function ()
                username = ""
                username_cursor_pos = 64
            end,
            textinput = function (key)
                username = username .. key
            end
        },
        {   -- token
            clear      = function ()
                token = ""
                token_cursor_pos = 64
            end,
            textinput = function (key)
                token = token .. key
            end
        }
    }

    local drawCursor = function (x, y)
        local icon = ">"

        love.graphics.print(icon, x + cursor_pos, y)
    end

    local drawUsername = function (x, y)
        local icon = ""
        if flash == 0 and menu_index == USERNAME then icon = "_" end

        love.graphics.print(username .. icon, x, y)
    end

    local drawToken = function (x, y)
        local icon = ""
        if flash == 0 and menu_index == TOKEN then icon = "_" end

        love.graphics.print(token .. icon, x, y)
    end

    local localization  = Component(0, 0, Component(0, 0, "LANG"), Component(64, 0, drawCursor), Component(72, 0, "EN"), Component(112, 0, "JP"))
    local username_part = Component(0, 32, Component(0, 0, "USERNAME"), Component(72, 0, drawUsername))
    local token_part    = Component(0, 64, Component(0, 0, "   TOKEN"), Component(72, 0, drawToken))

    local component = Component(32, W_HEIGHT/2 - 64, localization, username_part, token_part)

    local draw = function ()
        component.draw(0, 0)
    end

    local update = function (dt)
        time = time + 2*dt
        flash = math.floor(time)%2
    end

    local writeProfile = function ()
        local hfile = love.filesystem.newFile("profile.lua", "w")
        if hfile == nil then return end

        hfile:write('return { lang = "' .. lang .. '", username = "' .. username .. '", token = "' .. token .. '" }')--bad argument #1 to 'write' (string expected, got nil)

        hfile:close()
    end

    local findProfile = function ()
        return love.filesystem.isFile("profile.lua")
    end

    local recoverProfile = function ()
        local profile = love.filesystem.load("profile.lua")
        local status, result = pcall(profile)
        if status then return result end
    end

    local show = function (callback)
        hide_callback = callback
        showing = not findProfile()

        if not showing then
            callback()
        end
    end

    local hide = function ()
        hide_callback()
        showing = false
    end

    local isShowing = function ()
        return showing
    end

    local keypressed = function (key)
        if menu_index == TOKEN and key == "return" then
            writeProfile()

            hide()
        end

        if key == "down" or (key == "return" and menu_index < 2) then
            menu_index = (menu_index + 1)%3
            inputs[menu_index + 1].clear()
        end

        if key == "up" then
            menu_index = (menu_index - 1)%3
            inputs[menu_index + 1].clear()
        end

        if inputs[menu_index + 1].keypressed then
            inputs[menu_index + 1].keypressed(key)
        end
    end

    local textinput = function (key)
        if inputs[menu_index + 1].textinput then
            inputs[menu_index + 1].textinput(key)
        end
    end

    return {
        draw           = draw,
        update         = update,
        keypressed     = keypressed,
        textinput      = textinput,
        show           = show,
        hide           = hide,
        recoverProfile = recoverProfile,
        isShowing      = isShowing
    }

end
