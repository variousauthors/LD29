local HeadsUpDisplay = function ()
    -- this needs to account for global.scale
    local frame_y = 44
    local frame_x = 70

    local data = {
        score = "",
        items = "",
        world = "",
        timer = ""
    }

    -- private class WHUT?
    local Component = function (x, y, text, key)
        local offset = { x = x, y = y }

        local draw = function ()
            love.graphics.print(text .. data[key], frame_x + offset.x, frame_y + offset.y)
        end

        return {
            draw   = draw,
            offset = offset
        }
    end

    -- draw rules for the components: score, flowers/coins, world, time
    -- ALL 5 CHARS! I AM SO EXCITED
    local components = {
        score = Component(-1, 0, "MARIO", "score"),
        items = Component(194, 0, "items", "items"),
        world = Component(359, 0, "WORLD", "world"),
        world = Component(527, 0, "TIME", "timer")
    }

    local current_component = components["world"]

    local draw = function ()
        inspect(current_component.offset)

        for key, value in pairs(components) do
            value.draw()
        end

    end

    local incrementY = function ()
        current_component.offset.y = current_component.offset.y + 1
    end

    local decrementY = function ()
        current_component.offset.y = current_component.offset.y - 1
    end

    local incrementX = function ()
        current_component.offset.x = current_component.offset.x + 1
    end

    local decrementX = function ()
        current_component.offset.x = current_component.offset.x - 1
    end

    return {
        draw = draw,
        incrementY = incrementY,
        decrementY = decrementY,
        incrementX = incrementX,
        decrementX = decrementX
    }
end

return HeadsUpDisplay
