
-- constructor for Players!
Player = function (point)
    local p, v = point.copy(), Vector(0, 0)
    local speed, max_speed, is_jumping = 100, 2, true

    -- height/width of the sprite's shape
    local draw_w = 16
    local draw_h = 16

    local forces = {
        key        = Vector(0, 0),
        gravity    = Vector(0, 1),
        resistance = Vector(0.3, 0.3)
    }

    -- these are offsets from the Player's x, y as describe
    -- in Map.collide. Later there will be 4+ of these
    -- the points should be arranged so that
    local collision_points = {}
    collision_points[1]  = {}
    collision_points[-1] = {} -- yes... -1

    -- these are using vectors with unitary components so that we can determine which
    -- should be checked first (the one closest to the direction of movement)
    -- WHOA TODO where are 16 and 32 coming from? Why negative? This I cannot
    -- explain. It is a "bug"
    collision_points[1 ][1]  = { x = -16, y = -16 } -- bottom right
    collision_points[-1][1]  = { x = -32, y = -16 } -- bottom left
    collision_points[-1][-1] = { x = -32, y = -32 } -- top left
    collision_points[1 ][-1] = { x = -16, y = -32 } -- top right

    local serialize = function ()
        return {
            x = p.getX(),
            y = p.getY(),
            v = { x = v.getX(), y = v.getY() },
            collision_points = collision_points,
        }
    end

    -- this is for "one-off" keypresses. So like, jump,
    -- or throw fireball
    local keypressed = function (key)
        if is_jumping then return end

        if love.keyboard.isDown("up") then
            Sound.playSFX("ptooi_big")
            forces.key.setY(-15)
        end
    end

    -- this is for forces that get set continuously while the key is down
    local setKeyForces = function ()
        if love.keyboard.isDown("right", "left") then
            if love.keyboard.isDown("left") then forces.key.setX(-0.4) end
            if love.keyboard.isDown("right") then forces.key.setX(0.4) end
        end
    end

    -- ha ha, naive physics for the win! Without some kind of "drag" the
    -- player would just keep going in whatever direction they pressed,
    -- with no way of stopping!
    local drag = function (v)
        local x, y   = v.getX(), v.getY()
        local rx, ry = forces.resistance.getX(), forces.resistance.getX()

        -- drag "drags" the x, y values towards 0
        if x > 0 then x = math.max(x - rx, 0)
        else          x = math.min(x + rx, 0) end

        if y > 0 then y = math.max(y - ry, 0)
        else          y = math.min(y + ry, 0) end

        return Vector(x, y)
    end

    local isJumping = function ()
        return is_jumping
    end

    -- the beef!
    local update = function (dt, map)
        setKeyForces()

        -- here is where we sum up all the forces acting on the player
        -- and determine their v (what does v stand for? Vector? Velocity?
        -- No clue!)
        if (forces.key ~= nil) then
            v = v.plus(forces.key)

            -- we turn off gravity when the player is not "jumping/falling"
            -- in order to avoid jitter
            if isJumping() then
                v = v.plus(forces.gravity)
            end

            v = drag(v)
        end

        -- clamp horizontal speed
        v.setX(math.max(-max_speed, math.min(v.getX(), max_speed)))

        -- update position optimistically
        p.setY(p.getY() + v.getY() * dt * speed)
        p.setX(p.getX() + v.getX() * dt * speed)

        -- if there is a collision, then we will overwrite
        -- the optimistic position
        local collision = map.collide(serialize())
        p.setX(collision.p.getX())
        p.setY(collision.p.getY())
        v.setX(collision.v.getX())
        v.setY(collision.v.getY())
        is_jumping = collision.mid_air

        player_vx = v.getX()
        player_vy = v.getY()

        -- this is a thing
        forces.key.setX(0)
        forces.key.setY(0)
    end

    local draw = function ()
        local r, g, b = love.graphics.getColor()
        love.graphics.setColor(255, 0, 0)
        love.graphics.rectangle("fill", p.getX(), p.getY(), draw_w, draw_h)

        love.graphics.setColor(r, g, b)
    end

    -- lean public interface of Player is pretty lean
    return {
        update     = update,
        draw       = draw,
        keypressed = keypressed,

        getX = p.getX,
        getY = p.getY,
        setX = p.setX,
        setY = p.setY,

        getV = function ()
            return v.copy()
        end

    }
end
