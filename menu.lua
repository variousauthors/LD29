local Component = require("component")

LANG     = 0
USERNAME = 1
TOKEN    = 2

return function ()
    local showing     = true
    local cursor_pos  = 0
    local lang        = "en"
    local menu_index  = 0
    local username    = ""
    local token       = ""
    local time, flash = 0, 0

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
                        cursor_pos = 100
                    end
                end
            end
        },
        {   -- username
            clear      = function ()
                username = ""
                username_cursor_pos = 200
            end,
            textinput = function (key)
                username = username .. key
            end
        },
        {   -- token
            clear      = function ()
                token = ""
                token_cursor_pos = 200
            end,
            textinput = function (key)
                token = token .. key
            end
        }
    }

    local drawCursor = function (x, y)
        local icon = ">"

        love.graphics.print(icon, cursor_pos, y)
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

    local localization = Component(0, 0, Component(0, 0, drawCursor), Component(30, 0, "EN"), Component(130, 0, "JP"))
    local username     = Component(0, 100, Component(0, 0, "USERNAME"), Component(200, 0, drawUsername))
    local token        = Component(0, 200, Component(0, 0, "TOKEN"), Component(200, 0, drawToken))

    local component = Component(0, 0, localization, username, token)

    local draw = function ()
        component.draw(0, 0)
    end

    local update = function (dt)
        time = time + 2*dt
        flash = math.floor(time)%2
    end

    local keypressed = function (key)
        if key == "down" then
            menu_index = (menu_index + 1)%3
            inputs[menu_index + 1].clear()
        end

        if key == "up" then
            menu_index = (menu_index - 1)%3
            inputs[menu_index + 1].clear()
        end

        print(menu_index)
        if inputs[menu_index + 1].keypressed then
            inputs[menu_index + 1].keypressed(key)
        end
    end

    local textinput = function (key)
        if inputs[menu_index + 1].textinput then
            inputs[menu_index + 1].textinput(key)
        end
    end

    local show = function ()
        showing = true
    end

    local hide = function ()
        showing = false
    end

    local isShowing = function ()
        return showing
    end

    return {
        draw       = draw,
        update     = update,
        keypressed = keypressed,
        textinput  = textinput,
        show       = show,
        hide       = hide,
        isShowing  = isShowing
    }

end
