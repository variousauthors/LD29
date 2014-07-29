local Component = require("component")

local HeadsUpDisplay = function ()
    -- this needs to account for global.scale
    local x = 20
    local y = 8

    local data = {
        score = "00000",
        items = "00",
        item_type = "",
        world = "",
        timer = ""
    }

    local drawScore = function (x, y)
        love.graphics.print(data["score"], x, y)
    end

    local drawTimer = function (x, y)
        love.graphics.print("" .. data["timer"], x, y)
    end

    local drawWorld = function (x, y)
        love.graphics.print(data["world"], x, y)
    end

    local drawItems = function (x, y)
        image:setFilter("nearest", "nearest")

        local r, ox, oy = 0, 0, 0
        local width     = image:getWidth()
        local height    = image:getHeight()


        love.graphics.draw(image, x + 1, y + 1, r, 1, 1, ox, oy)
        love.graphics.print("x" .. data["items"], x + 8, y)
    end

    local setScore = function (score)
        data["score"] = score
    end

    local setWorld = function (world)
        data["world"] = world
    end

    -- TODO time should display leading zeroes
    local setTimer = function (time)
        data["timer"] = "" .. time
    end

    -- TODO items should have a coin or a flower
    local setItems = function (items)
        data["items"] = "" .. items
    end

    local setItemType = function (item_type)
        data["item_type"] = item_type

        if data["item_type"] == "coin"   then image = "assets/images/coin_icon.png" end
        if data["item_type"] == "flower" then image = "assets/images/flower_icon.png" end

        image = love.graphics.newImage(image)
    end

    local component = Component(x, y,
        Component(0, 0, Component(0, 0, Component(0, 0, "MARIO"), Component(0, 8, drawScore))),
        Component(64, 0, Component(0, 0, Component(0, 0, ""), Component(0, 8, drawItems))),
        Component(124, 0, Component(0, 0, Component(0, 0, "WORLD"), Component(8, 8, drawWorld))),
        Component(176, 0, Component(0, 0, Component(0, 0, "TIME"), Component(8, 8, drawTimer)))
    )

    local current_component = component

    local draw = function ()
        component.draw(0, 0)
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

        setScore    = setScore,
        setTimer    = setTimer,
        setWorld    = setWorld,
        setItems    = setItems,
        setItemType = setItemType
    }
end

return HeadsUpDisplay
