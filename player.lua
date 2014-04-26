
Player = function (point)
    local p, v = point.copy(), Vector(0, 0)
    local speed = 500

    local keypressed = function (key)
    end

    slowDown = function (dt, get, set)
        if (get() == 0) then
        elseif (get() > 0) then
            set(math.max(get() - 1 * dt, 0))
        else
            set(math.min(get() + 1 * dt, 0))
        end
    end

    local update = function (dt, map)
        local is_moving = love.keyboard.isDown("down", "up", "right", "left")

        if (is_moving) then
            if love.keyboard.isDown("right") then
                v.setX(math.min(v.getX() + 1 * dt, 1))
            elseif love.keyboard.isDown("left") then
                v.setX(math.max(v.getX() - 1 * dt, -1))
            else
                slowDown(dt, v.getX, v.setX)
            end

            if love.keyboard.isDown("down") then
                v.setY(math.min(v.getY() + 1 * dt, 1))
            elseif love.keyboard.isDown("up") then
                v.setY(math.max(v.getY() - 1 * dt, -1))
            else
                slowDown(dt, v.getY, v.setY)
            end
        else
            slowDown(dt, v.getX, v.setX)
            slowDown(dt, v.getY, v.setY)
        end

        p.setY(p.getY() + v.getY() * dt * speed)
        p.setX(p.getX() + v.getX() * dt * speed)

        p, v = map.collide(p, v)
    end

    local draw = function ()
        local r, g, b = love.graphics.getColor()
        love.graphics.setColor(255, 0, 0)
        love.graphics.rectangle("fill", p.getX(), p.getY(), 16, 16)

        love.graphics.setColor(r, g, b)
    end

    return {
        update     = update,
        draw       = draw,
        keypressed = keypressed,

        getX       = p.getX,
        getY       = p.getY
    }
end
