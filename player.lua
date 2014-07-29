
-- constructor for Players!
Player = function (point, sprite)
    local p, v                    = point.copy(), Vector(0, 0)
    local prev                    = nil -- the previous point position
    local speed                   = 100
    local max_horizontal_speed    = 1.5
    local max_vertical_speed      = 3
    local sprite                  = sprite
    local cur_state, prev_state   = "stand", nil
    local cur_facing, prev_facing = sprite.base_facing, nil
    local current_quad            = cur_state
    local double_jump             = false
    local walk_force              = 12
    local jump_force              = 5 / global.fixed_dt

    local sprite_width  = (sprite.width or 16)
    local sprite_height = (sprite.height or 16)
    local draw_w        = sprite_width - (sprite_width / 4) -- skinny for collisions
    local draw_h        = sprite_height - (sprite_height / 8)

    local forces = {
        key        = Vector(0, 0),
        gravity    = Vector(0, 16),
        resistance = Vector(10, 2)
    }

    -- these are offsets from the Player's x, y as describe
    -- in Map.collide. Later there will be 4+ of these
    -- the points should be arranged so that
    local collision_points = {}
    collision_points[0]    = {}
    collision_points[1]    = {}
    collision_points[-1]   = {} -- yes... -1

    -- these are using vectors with unitary components so that we can determine which
    -- should be checked first (the one closest to the direction of movement)
    -- clockwise from top right
    collision_points[-1][-1]  = { x = 0         , y = 0          } -- top right (origin)
    collision_points[ 0][-1]  = { x = draw_w / 2, y = 0          } --
    collision_points[ 1][-1]  = { x = draw_w    , y = 0          } --
    collision_points[ 1][ 0]  = { x = draw_w    , y = draw_h / 2 } --
    collision_points[ 1][ 1]  = { x = draw_w    , y = draw_h     } --
    collision_points[ 0][ 1]  = { x = draw_w / 2, y = draw_h     } --
    collision_points[-1][ 1]  = { x = 0         , y = draw_h     } --
    collision_points[-1][ 0]  = { x = 0         , y = draw_h / 2 } --

    -- special case. This is mainly to prevent the nil but is also a reasonable value
    collision_points[ 0][ 0]  = { x = draw_w / 2, y = draw_h / 2 }

    local serialize = function ()
        return {
            x = p.getX(),
            y = p.getY(),
            px = prev.getX(),
            py = prev.getY(),
            v = { x = v.getX(), y = v.getY() },
            collision_points = collision_points,
            w = draw_w,
            h = draw_h
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

    local getSpeed = function ()
        return speed
    end

    local isStateCont = function ()
        return cur_state == prev_state
    end

    local isJumping = function ()
        return cur_state == "jump"
    end

    local isCloudWalking = function ()
        return true
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
        if isJumping() and not global.double_jump then return end

        if Input.isPressed("jump") then
            if isJumping() and not double_jump then
                double_jump = true

                Sound.playSFX("ptooi_big")
                v.setY(0) -- double jump don't need no bs downwards, biotch!
                forces.key.setY(-jump_force)
            elseif isJumping() then
                -- NOP

            else
                Sound.playSFX("ptooi_big")
                forces.key.setY(-jump_force)
                double_jump = false
            end
        end
    end

    -- this is for forces that get set continuously while the key is down
    local setKeyForces = function ()
        if Input.isPressed("left") and Input.isPressed("right") then
            -- Both directions! Do Nothing!
        elseif Input.isPressed("left") then
            setFacing("left")
            forces.key.setX(-walk_force)
        elseif Input.isPressed("right") then
            setFacing("right")
            forces.key.setX(walk_force)
        end
    end

    -- ha ha, naive physics for the win! Without some kind of "drag" the
    -- player would just keep going in whatever direction they pressed,
    -- with no way of stopping!
    local drag = function (v, dt)
        local res    = forces.resistance.times(dt)
        local x, y   = v.getX(), v.getY()
        local rx, ry = res.getX(), res.getY()

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
            speedUp = (1 + 3 * (math.abs(v.getX()) / max_horizontal_speed))
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
        prev = p.copy()
        setKeyForces()

        -- here is where we sum up all the forces acting on the player
        -- and determine their v (what does v stand for? Vector? Velocity?
        -- No clue!)
        if (forces.key ~= nil) then
            v = v.plus(forces.key.times(dt))

            -- we turn off gravity when the player is not "jumping/falling"
            -- in order to avoid jitter
            if isJumping() then
                v = v.plus(forces.gravity.times(dt))
            end

            v = drag(v, dt)
        end

        -- clamp speeds
        v.setX(math.max(-max_horizontal_speed, math.min(v.getX(), max_horizontal_speed)))
        if v.getY() > 0 then
            v.setY(math.max(-max_vertical_speed, math.min(v.getY(), max_vertical_speed)))
        end

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
        -- Flip if facing is different
        local sx, sy = 1, 1
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

        local x = p.getX() + draw_w - sprite.width + 1
        local y = p.getY() + draw_h - sprite.height + 1

        love.graphics.setColor(255, 255, 255)
        love.graphics.draw(sprite.image, sprite.namedQuads[current_quad],
                           x, y, r, sx, sy, ox, oy)
    end

    -- lean public interface of Player is pretty lean
    return {
        update     = update,
        draw       = draw,
        keypressed = keypressed,

        sprite = sprite,

        isDead         = isDead,
        isCloudWalking = isCloudWalking,

        getX = p.getX,
        getY = p.getY,
        setX = p.setX,
        setY = p.setY,

        getV = function ()
            return v.copy()
        end,

        getSpeed = getSpeed
    }
end
