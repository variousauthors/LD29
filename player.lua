
-- constructor for Players!
Player = function (point, sprite)
    local p, v                = point.copy(), Vector(0, 0)
    local speed, max_speed    = 100, 2
    local sprite = sprite
    local cur_state, prev_state = "stand", nil
    local cur_facing, prev_facing = sprite.base_facing, nil
    local current_quad = cur_state

    -- height/width of the sprite's shape
    local draw_w = (sprite.width or 16) * global.scale
    local draw_h = (sprite.height or 16) * global.scale

    local forces = {
        key        = Vector(0, 0),
        gravity    = Vector(0, 1),
        resistance = Vector(0.3, 0.3)
    }

    -- these are offsets from the Player's x, y as describe
    -- in Map.collide. Later there will be 4+ of these
    -- the points should be arranged so that
    local collision_points = {}
    collision_points[1]    = {}
    collision_points[-1]   = {} -- yes... -1

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

    local setState = function (new_state)
        prev_state = cur_state
        cur_state  = new_state
        return cur_state, prev_state
    end

    local getState = function ()
        return cur_state, prev_state
    end

    local isStateCont = function ()
        return cur_state == prev_state
    end

    local isJumping = function ()
        return cur_state == "jump"
    end

    local isDead = function ()
        return cur_state == "dead"
    end

    local isWalking = function ()
        return cur_state == "walk"
    end

    local isStanding = function ()
        return cur_state == "stand"
    end

    local setFacing = function (new_facing)
        prev_facing = cur_facing
        cur_facing  = new_facing
        sprite_facing = cur_facing
        return cur_facing, prev_facing
    end

    local getFacing = function ()
        return cur_facing, prev_facing
    end

    local isFacingCont = function ()
        return cur_facing == prev_facing
    end

    local reset = function ()
        cur_state   = nil
        prev_state  = nil
        cur_facing  = sprite.base_facing
        prev_facing = nil
    end

    -- this is for "one-off" keypresses. So like, jump,
    -- or throw fireball
    local keypressed = function (key)
        if isJumping() then return end

        if love.keyboard.isDown("up") then
            Sound.playSFX("ptooi_big")
            forces.key.setY(-15)
        end
    end

    -- this is for forces that get set continuously while the key is down
    local setKeyForces = function ()
        if love.keyboard.isDown("right", "left") then
            if love.keyboard.isDown("left") then
                setFacing("left")
                forces.key.setX(-0.4)
            end
            if love.keyboard.isDown("right") then
                setFacing("right")
                forces.key.setX(0.4)
            end
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

    -- the beef!
    local walkTimer, walkDelay, walkIter, speedUp = 0, 0.25, 1, 0
    local walkFrames = sprite.walk_anim
    local updateAnimation = function (dt)
        if isJumping() then
            current_quad = "jump"
        elseif isWalking() then
            -- reset on state change
            if not isStateCont() then
                walkTimer, walkIter = 0, 1
            -- reset and load frameset with turn frames
            elseif not isFacingCont() then
                walkTimer, walkIter = 0, 1
                walkFrames = sprite.turn_anim
            end
            -- speed up animation with movement, deltatime multiplied by 1-4
            speedUp = (1 + 3 * (math.abs(v.getX()) / max_speed))
            walkTimer = walkTimer + (dt * speedUp)
            if walkTimer > walkDelay then
                walkTimer = 0
                walkIter = walkIter + 1
                if walkIter > #walkFrames then
                    walkIter = 1
                    -- reset to normal frames in case we were turnt
                    walkFrames = sprite.walk_anim
                end
            end
            current_quad = walkFrames[walkIter]
        elseif isDead() then
            current_quad = "stand"
        else
            current_quad = "stand"
        end
        sprite_quad = current_quad
    end

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
        -- update state
        if collision.mid_air then
            setState("jump")
        elseif collision.is_dead then
            setState("dead")
        elseif(v.getX() == 0) then
            setState("stand")
        else
            setState("walk")
        end

        -- global variables for debugggggging
        player_vx = v.getX()
        player_vy = v.getY()

        -- this is a thing
        forces.key.setX(0)
        forces.key.setY(0)

        updateAnimation(dt)
    end

    local draw = function ()
        local r, g, b = love.graphics.getColor()
        love.graphics.setColor(255, 0, 0, 128)
        love.graphics.rectangle("fill", p.getX(), p.getY(), draw_w, draw_h)
        love.graphics.setColor(r, g, b)

        -- Flip if facing is different
        local sx, sy = global.scale, global.scale
        local r, ox, oy = 0, 0, 0
        if (getFacing() ~= sprite.base_facing) then
            sx = 0 - sx
            ox = sprite.width
        end

        -- a dead mario is an upside down mario
        if isDead() then
            sy = 0 - sy
            oy = sprite.height
        end

        love.graphics.draw(sprite.image, sprite.namedQuads[current_quad],
                           p.getX(), p.getY(), r, sx, sy, ox, oy)
    end

    -- lean public interface of Player is pretty lean
    return {
        update     = update,
        draw       = draw,
        keypressed = keypressed,

        sprite = sprite,

        isDead = isDead,

        getX = p.getX,
        getY = p.getY,
        setX = p.setX,
        setY = p.setY,

        getV = function ()
            return v.copy()
        end

    }
end
