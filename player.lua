
Player = function (point)
    local p, v = point.copy(), Vector(0, 0)
    local speed, is_jumping = 100, true
    local forces = {
        key = Vector(0, 0),
        gravity = Vector(0, 0.1)
    }

    local keypressed = function (key)
        if key == "right" then forces.key.setX(1) end
        if key == "left"  then forces.key.setX(-1) end
    end

    local slowDown = function (dt, get, set)
        if (get() == 0) then
        elseif (get() > 0) then
            set(math.max(get() - 1 * dt, 0))
        else
            set(math.min(get() + 1 * dt, 0))
        end
    end

    local isJumping = function ()
        return is_jumping
    end

    local update = function (dt, map)
        if (forces.key ~= nil) then
            v = v.plus(forces.key)

            if isJumping() then
                v = v.plus(forces.gravity) 
            end
        end

        p.setY(p.getY() + v.getY() * dt * speed)
        p.setX(p.getX() + v.getX() * dt * speed)

        collision  = map.collide(p, v)
        p          = collision.p
        v          = collision.v
        is_jumping = collision.mid_air

        forces.key.setX(0)
        forces.key.setY(0)
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
