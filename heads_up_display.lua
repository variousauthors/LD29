local HeadsUpDisplay = function ()
    -- this needs to account for global.scale
    local x = 70
    local y = 44

    local data = {
        score = "00000",
        items = "",
        world = "",
        timer = ""
    }

    -- private class WHUT?
    -- @param ... any number of constructors, or a string or a function that returns a string
    local Component = function (x, y, ...)
        local offset = { x = x, y = y }
        local text, func, components = nil, nil, {}

        -- iterate over the args, until we hit a string
        -- or a function
        -- a component either: shows a string, or shows the result of a function
        -- call, and shows all of its components
        -- We call these: static, dynamic, and composite components
        local initialize = function (...)
            for i, arg in ipairs({...}) do

                if type(arg) == "string" then
                    text = arg
                    return

                -- later we should maybe replace func with a free standing
                -- draw function, rather than a function that returns a string.
                -- That way we will be able to have coin and flower pictures
                elseif type(arg) == "function" then
                    func = arg
                    return

                elseif type(arg) == "table" then
                    table.insert(components, arg)
                end
            end
        end

        initialize(unpack({...}))

        -- the draw function takes the position of the parent component
        local draw = function (frame_x, frame_y)
            if text ~= nil then
                love.graphics.print(text, frame_x + offset.x, frame_y + offset.y)
            elseif func ~= nil then
                love.graphics.print(func(), frame_x + offset.x, frame_y + offset.y)
            end

            for key, value in pairs(components) do
                value.draw(frame_x + offset.x, frame_y + offset.y)
            end
        end

        return {
            draw   = draw,
            offset = offset
        }
    end

    local getScore = function ()
        return data["score"]
    end

    local getTimer = function ()
        return "" .. data["timer"]
    end

    local getWorld = function ()
        return data["world"]
    end

    local setScore = function (score)
        data["score"] = score
    end

    local setWorld = function (world)
        data["world"] = world
    end

    local setTimer = function (time)
        data["timer"] = "" .. (400 - time)
    end

    -- draw rules for the components: score, flowers/coins, world, time
    -- ALL 5 CHARS! I AM SO EXCITED
    local components = {
        score = Component(-1, 0, Component(0, 0, Component(0, 0, "MARIO"), Component(0, 30, getScore))),
        items = Component(194, 0, "items", "items"),
        world = Component(359, 0, Component(0, 0, Component(0, 0, "WORLD"), Component(0, 30, getWorld))),
        timer = Component(527, 0, Component(0, 0, Component(0, 0, "TIME"), Component(25, 30, getTimer)))
    }

    local current_component = components["world"]

    local draw = function ()

        for key, value in pairs(components) do
            value.draw(x, y)
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
        decrementX = decrementX,

        setScore = setScore,
        setTimer = setTimer,
        setWorld = setWorld
    }
end

return HeadsUpDisplay
