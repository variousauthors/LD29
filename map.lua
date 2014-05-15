require("glitches")

-- Setup
local loader     = require("vendor/AdvTiledLoader.Loader")
loader.path      = "assets/images/maps/"

-- So, this whole file I basically just stole from the examples in the
-- tile library. That's why the code is so weird. In the days to come
-- I will change this so that Map is a constructor and we can make multiple
-- maps with different qualities.
--
-- Also on the TODO list is pulling the collision code out of here.
--

Map = function (tmx)
    local map             = loader.load(tmx)
    local is_finished     = false
    local events          = {}
    local sprite          = {}
    local glitch_lvl      = 0
    local glitch_max      = 4
    local is_glitchedout  = false
    local death_line      = map.height - 1
    local old_collectible = {}

    -- the amount to cheat the screen by on level start
    local origin_y = 0
    local start_y  = 0

    local origin_x = 0
    local start_x  = 0

    local proceed_handler, death_handler, victory_handler, glitchout_handler

    -- initialize the various glitches
    local missing_tiles_glitch = Glitches()
    missing_tiles_glitch.load_layer(map.layers["obstacle"])

    local rng = love.math.newRandomGenerator(os.time())
    rng:random()
    rng:random()
    local crazy_death_glitch = Glitches(function(layer, x, y, p)
        layer:set(x, y, map.tiles[rng:random(900,923)])
    end)
    crazy_death_glitch.load_layer(map.layers["glitches"])

    local getGlitchMusic = function ()
        return "M100tp5e".. math.min(glitch_lvl, glitch_max)
    end

    -- run all the glitches
    local glitch = function ()
        local layer = map.layers["collectible"]

        for key, value in pairs(old_collectible) do
            layer:set(value.x, value.y, value.tile)
        end

        missing_tiles_glitch.generate_glitches(20)
        missing_tiles_glitch.modify_layer(start_x)

        crazy_death_glitch.generate_glitches(50, "single", true)
        crazy_death_glitch.modify_layer(start_x)

        glitch_lvl = glitch_lvl + 1
        --Sound.playMusic()
    end

    -- expose the state of the map
    local isFinished = function ()
        return is_finished
    end

    local setFinished = function (finished)

        is_finished = finished
    end

    local isGlitchedout = function ()
        return is_glitchedout
    end

    local setGlitchedout = function (glitchedout)

        is_glitchedout = glitchedout
    end

    -- each map has a number of "doors" and stuff that
    -- trigger events (and stuff). This function takes
    -- tile coords and a function name (which should be
    -- a function like "onThis" or "onThat") and binds
    -- them up into a table so that, when tile (x, y) is
    -- collided with, we can easily just say "well, is there
    -- an event at (x, y) in our table?"
    --
    -- @param options is table like:
    -- {
    --   coords: { 1, 2 },
    --   event: "victory"
    -- },
    --
    local setEvents = function (options)

        for i, k in ipairs(options) do
            local x = k.coords[1]
            local y = k.coords[2]

            events[x]    = { }
            events[x][y] = k.event
        end
    end

    local setOrigin = function (origin)
        if origin ~= nil then
            origin_y = -(origin.y * global.tile_size)
            start_y  = origin.y

            origin_x = (origin.x * global.tile_size) -- ADDED FOR SYMMETRY, NEVER USED
            start_x  = origin.x
        end
    end

    -- returns the pixel coords at which mario shouls appear
    -- mario should start on the ground (5 tiles below the center)
    local getStart = function ()
        local arbitrary_offset = 5
        -- look, on level 9-1 for some reason, the player starts in the wrong place.
        if start_y == 40 then
            arbitrary_offset = -7
        end

        local x = global.tile_size * start_x * global.scale
        local y = -global.ty + (global.tile_size * global.scale * arbitrary_offset)

        return Point(x, y)
    end

    local isInDungeon = function (tile)
        return tile > 15 + start_y
    end

    local isInTransition = function (tile)
        return tile == 15 + start_y or tile == 14 + start_y or tile == 13 + start_y
    end

    local isOnGround = function (tile)
        return tile < 12 + start_y
    end

    local isCloudWalking = function (tile)
        return true
    end

    local getGroundY = function ()
        return 0 + origin_y
    end

    local getTransitionY = function ()
        return -(( global.tile_height / 4 ) * global.tile_size * global.scale) + origin_y
    end

    local getDungeonY = function ()
        return -(( global.tile_height / 2 ) * global.tile_size * global.scale) + origin_y
    end

    local getBand = function (tile)
        if tile == nil then return nil end

        if tile > 30 + start_y                                                  then return { zone = "catacombs", transition = false } end
        if tile > 15 + start_y                                                  then return { zone = "dungeon",   transition = false } end
        if tile == 15 + start_y or tile == 14 + start_y or tile == 13 + start_y then return { zone = "dungeon",   transition = true  } end
        if tile > 0 + start_y and tile < 12 + start_y                           then return { zone = "ground" ,   transition = false } end
        if tile == 0 + start_y or tile == -1 + start_y                          then return { zone = "clouds",    transition = true  } end
        if tile < -1 + start_y                                                  then return { zone = "clouds",    transition = false } end
    end

    local getCameraForBand = function (band)

        if band.zone == "catacombs" and band.transition == false  then return -(( global.tile_height ) * global.tile_size * 2) + origin_y end
        if band.zone == "dungeon" and band.transition == false  then return -(( global.tile_height / 2 ) * global.tile_size * 2) + origin_y end
        if band.zone == "dungeon" and band.transition == true   then return -(( global.tile_height / 4 ) * global.tile_size * 2) + origin_y end
        if band.zone == "ground"  and band.transition == false  then return 0 + origin_y                                                               end
        if band.zone == "clouds"  and band.transition == true   then return (( global.tile_height / 4 ) * global.tile_size * 2) + origin_y  end
        if band.zone == "clouds"  and band.transition == false  then return (( global.tile_height / 2 ) * global.tile_size * 2) + origin_y  end

        -- unimplemented
        if band.zone == "stratosphere"  and band.transition == false  then return (( global.tile_height / 2 ) * global.tile_size * global.scale) + origin_y  end
        if band.zone == "mesosphere"  and band.transition == true   then return (( global.tile_height / 4 ) * global.tile_size * global.scale) + origin_y  end
        if band.zone == "mesosphere"  and band.transition == false  then return (( global.tile_height / 2 ) * global.tile_size * global.scale) + origin_y  end
    end

    -- set handlers for events like "onVictory"
    local setDeathHandler = function (callback)
        death_handler = callback
    end

    local setVictoryHandler = function (callback)
        victory_handler = callback
    end

    local setGlitchoutHandler = function (callback)
        glitchout_handler = callback
    end

    local setProceedHandler = function (callback)
        proceed_handler = callback
    end

    -- respond to events like "onVictory"
    local onDeath = function ()
        if death_handler ~= nil then death_handler() end

        global.double_jump = false
    end

    local onVictory = function ()
        if victory_handler ~= nil then victory_handler() end

        global.double_jump = false
    end

    local onGlitchout = function ()
        if glitchout_handler ~= nil then glitchout_handler() end

        global.double_jump = false
    end

    local onProceed = function ()
        if proceed_handler ~= nil then proceed_handler() end
    end

    -- Sorry the code below is so ugly, but there wasn't an easier way to
    -- have different cutscenes for each shrine in each level
    -- so I just reduplicated the code

    local enterCloudShrine51 = function ()
        -- start the cutscene

        if map.layers["clouds"] then
            if map.layers["clouds"].properties["obstacle"] == 1 then
                return
            end

            Cutscenes.current = Cutscenes.Shrines.Clouds
            Cutscenes.current.start()

            map.layers["clouds"].properties["obstacle"] = 1
        end
    end

    local enterCloudShrine91 = function ()
        -- start the cutscene

        if map.layers["clouds"] then
            if map.layers["clouds"].properties["obstacle"] == 1 then
                return
            end

            Cutscenes.current = Cutscenes.Shrines.Clouds
            Cutscenes.current.start()

            map.layers["clouds"].properties["obstacle"] = 1
        end
    end

    local enterTreeShrine = function ()

        if map.layers["trees"] then
            if map.layers["trees"].properties["obstacle"] == 1 then
                return
            end

            -- start the cutscene
            Cutscenes.current = Cutscenes.Shrines.Trees
            Cutscenes.current.start()

            map.layers["trees"].properties["obstacle"] = 1
        end
    end

    -- Sorry the code below is so ugly, but there wasn't an easier way to
    -- have different cutscenes for each shrine in each level
    -- so I just reduplicated the code

    local enterDoubleJumpShrine21 = function ()
        if global.double_jump == true then return end

        -- start the cutscene
        Cutscenes.current = Cutscenes.Shrines.Doublejump21
        Cutscenes.current.start()

        global.double_jump = true
    end

    local enterDoubleJumpShrine51 = function ()
        if global.double_jump == true then return end

        -- start the cutscene
        Cutscenes.current = Cutscenes.Shrines.Doublejump
        Cutscenes.current.start()

        global.double_jump = true
    end

    local enterDoubleJumpShrine91 = function ()
        if global.double_jump == true then return end

        -- start the cutscene
        Cutscenes.current = Cutscenes.Shrines.Doublejump
        Cutscenes.current.start()

        global.double_jump = true
    end

    local enterBackwardsShrine51 = function ()
        if global.backwards == true then return end

        -- start the cutscene
        Cutscenes.current = Cutscenes.Shrines.Backwards
        Cutscenes.current.start()

        global.backwards = true
    end

    local enterBackwardsShrine91 = function ()
        if global.backwards == true then return end

        -- start the cutscene
        Cutscenes.current = Cutscenes.Shrines.Backwards
        Cutscenes.current.start()

        global.backwards = true
    end

    local enterWallJumpShrine = function ()
        if global.walljump == true then return end

        -- start the cutscene
        Cutscenes.current = Cutscenes.Shrines.Walljump
        Cutscenes.current.start()

        global.walljump = true
    end

    -- important methods for the public interface
    -- reset, update, draw

    -- Resets the example
    local reset = function ()
        -- reset shrine effects
        if map.layers["clouds"] then
            map.layers["clouds"].properties["obstacle"] = nil
        end
        if map.layers["trees"] then
            map.layers["trees"].properties["obstacle"] = nil
        end
        global.double_jump = false
        global.walljump    = false
        global.backwards   = false
        -- tx and ty are the offset of the tilemap
        global.tx = 0
        global.ty = origin_y
    end

    -- at some point we will probably want code in here
    local update = function (dt)

    end

    -- Called from love.draw()
    local draw = function ()
        -- this code is mainly copied from an example

        -- Set sprite batches if they are different than the settings.
        map.useSpriteBatch = global.useBatch

        -- Scale and translate the game screen for map drawing
        local ftx, fty = math.floor(global.tx), math.floor(global.ty)
        love.graphics.push()
        love.graphics.scale(global.scale)
        love.graphics.translate(ftx, fty)

        -- Limit the draw range
        if global.limitDrawing then
            map:autoDrawRange(ftx, fty, global.scale, -0)
        else
            map:autoDrawRange(ftx, fty, global.scale, 50)
        end

        -- Queue our guy to be drawn after the tile he's on and then draw the map.
        local maxDraw = global.benchmark and 20 or 1
        for i = 1, maxDraw do
            map:draw()
        end
        love.graphics.rectangle("line", map:getDrawRange())

        -- Reset the scale and translation.
        love.graphics.pop()

    end

    -- COLLISION CODE STARTS HERE

    -- the player's position is a point (x, y) in pixels, but I couldn't
    -- find a function in the tile library that lets us ask for "the tile
    -- around these pixels" So for now I'm just converting, but later I
    -- will implement such a lookup.
    local pixel_to_tile = function (pixel_x, pixel_y)
        local tile_width = map.tileWidth * global.scale;

        -- x, y relative to a moving frame
        local rel_x = pixel_x - global.tx * global.scale
        local rel_y = pixel_y - global.ty * global.scale

        return math.floor(rel_x / tile_width), math.floor(rel_y / tile_width)
    end

    -- given a vector, determine which collision point should be checked
    -- first by converting the vector into a diagonal vector
    -- and using that as an index
    local primary_direction = function (v)
        local u    = v.to_unit()
        local x, y = u.getX(), u.getY()

        -- oh my GOD there must be a better way!!!
        if x < 0 then
            x = math.floor(x)
        elseif x > 0 then
            x = math.ceil(x)
        else
            x = 0
        end

        if y < 0 then
            y = math.floor(y)
        elseif y > 0 then
            y = math.ceil(y)
        else
            y = 0
        end

        return x, y
    end

    -- TODO this is necessary because I want to dynamically send
    -- messages like "onDeath" but haven't been able to use
    -- a self variable. In the future I could do self["onVictory"]
    -- but for now I do callbacks["onVictory"]
    local callbacks = {}
    callbacks["onDeath"]               = onDeath
    callbacks["onVictory"]             = onVictory
    callbacks["onGlitchout"]           = onGlitchout
    callbacks["enterCloudShrine51"]      = enterCloudShrine51
    callbacks["enterCloudShrine91"]      = enterCloudShrine91
    callbacks["enterTreeShrine"]       = enterTreeShrine
    callbacks["enterDoubleJumpShrine21"] = enterDoubleJumpShrine21
    callbacks["enterDoubleJumpShrine51"] = enterDoubleJumpShrine51
    callbacks["enterDoubleJumpShrine91"] = enterDoubleJumpShrine91
    callbacks["enterBackwardsShrine51"]  = enterBackwardsShrine51
    callbacks["enterBackwardsShrine91"]  = enterBackwardsShrine91
    callbacks["enterWallJumpShrine"]     = enterWallJumpShrine

    -- callbacks for layer properties
    callbacks["obstacle"] = function (layer, v, tx, ty, rx, ry)
        return Vector(0, 0)
    end

    -- callbacks for layer properties
    callbacks["destructible"] = function (layer, v, tx, ty, rx, ry)

        -- if the resolution_tile is below the collision_tile then we hit from below
        -- ... I hope
        -- TODO mario can break blocks by walking into them... should only
        -- work when jumping
        -- Maybe this information should be gathered up and shipped out
        -- to the player, so then different players can have different
        -- callbacks for destructible objects etc
        -- OH YEAH! Then small mario won't be able to break blocks!!!
        if ry > ty then
            layer:set(tx, ty, nil)
            Sound.playSFX("smash")
        end

        return v
    end

    callbacks["collectible"] = function (layer, v, tx, ty, rx, ry)
        local tile = layer:get(tx, ty)
        table.insert(old_collectible, { tile = tile, x = tx, y = ty })

        layer:set(tx, ty, nil)

        Sound.playSFX("awyiss")
        global.getFlower()

        return v, true
    end

    callbacks["clouds"] = function (layer, v, tx, ty, rx, ry)
        return v
    end

    callbacks["trees"] = function (layer, v, tx, ty, rx, ry)
        return v
    end

    local detect = function (p, offset, layer)
        tile = layer(pixel_to_tile(p.getX() + offset.x, p.getY() + offset.y))

        return tile
    end

    local checkForDeath = function (tx, ty)
        local is_dead = false
        -- this 14 will need to be based on the map bounds
        if ty > death_line then
            onDeath()
            is_dead = true
        end

        return is_dead
    end

    local runMapEvents = function (tx, ty)
        -- if we've collided with an event tile, then we need to
        -- process the event (the tile may not actually be a "hit", such as doors)
        if events[tx] ~= nil and events[tx][ty] ~= nil then
            local callback = callbacks[events[tx][ty]]

            if callback ~= nil then callback() end
        end
    end

    local runCollisionEffects = function (tx, ty, p, v, corner, layer)
        -- and run collision callbacks
        for key, value in pairs(layer.properties) do
            local callback = callbacks[key]

            -- the position of the tile that we resolved to
            rx, ry = pixel_to_tile(p.getX() + corner.x, p.getY() + corner.y)

            -- some callbacks will change the vector (halt it, for example)
            v = callback(layer, v, tx, ty, rx, ry)
        end

        return v
    end

    local adjustPosition = function (p, v, value, corner, layer)
        -- don't run collision prevention for collectible
        if layer.properties["obstacle"] ~= nil then
            -- the "algorithm" is to push the object back in the direction it came until
            -- there is no longer a collision :/
            -- we want the "tile" to be different from the "collision_tile"
            while (tile ~= nil) do
                p.setX(p.getX() - value.x)
                p.setY(p.getY() - value.y)

                tile = detect(p, corner, layer)
            end
        end
    end

    local collisionDirection = function (p, v, tx, ty, value)
        print("in collisionDirection")
        -- value gives us the current diagonal direction
        inspect(value)
        -- create a line from p and v
        -- iterate over 4 sides of the tile
        --
        return value
    end

    -- given a real number, snap its value to the next
    -- integer in the direction of that real from 0
    local discretize = function (x)
        if x <= 0 then return math.floor(x) end
        if x > 0 then return math.ceil(x) end
    end

    local resolve = function (p, v, value, corner, layer)
        local tile      = detect(p, corner, layer)
        local collision = tile ~= nil

        -- the position of the tile we are colliding with
        local tx, ty         = pixel_to_tile(p.getX() + corner.x, p.getY() + corner.y)
        tile_x, tile_y       = tx, ty -- this is actually used globally to determine band

        if collision then
            print("before resolution")
            inspect({ p.getX(), p.getY() })
        end

        if collision and value.x ~= 0 and value.y ~= 0 then
            -- transform value so that it is an axis bound vector

            -- find the intersection of the vector v and the tile's sides
            value = collisionDirection(p, v, tx, ty, value)
        end

        adjustPosition(p, v, value, corner, layer)

        if collision then
            print("after resolution")
            inspect({ p.getX(), p.getY() })
        end

        if collision then
            print("collision:")
            print("  corner:")
            inspect({ corner.x, corner.y })
            print("  direction:")
            inspect({ value.x, value.y })
            print("  tile:")
            inspect({ tx, ty })
            runCollisionEffects(tx, ty, p, v, corner, layer)
        end

        -- no collision necessary
        runMapEvents(tx, ty)

        -- if mario collided in a y direction, then
        -- halt his y movement
        if collision and value.y ~= 0 then
            v.setY(0)
        end

        return p, v, false
    end

    local collisions = function (data)
        local p                       = Point(data.x, data.y)
        local prev                    = Point(data.px, data.py)
        local v                       = Vector(data.v.x, data.v.y)
        local x, y                    = primary_direction(v) -- index at which to start collision detection
        local new_v, mid_air = v, true -- assume we are in mid_air and not dead

        for key in pairs(map.layers) do
            local layer = map.layers[key]

            -- if the layer is an obstacle layer
            if layer.properties["obstacle"] ~= nil or layer.properties["collectible"] then
                -- run collision detection once to resolve the "most likely collision"
                -- to iterate over the adjacent squares we need to hit all
                -- the cardinal directions with TRIGONOMETRY BITCHES
                -- TODO we could run these two loops a couple of times, in order
                -- to prevent collisions from causing collisions.
                for i = 0, 3 do
                    local x      = math.round(math.cos(i * (math.pi / 2)))
                    local y      = math.round(math.sin(i * (math.pi / 2)))
                    local corner = data.collision_points[x][y]

                    p, new_v = resolve(p, new_v, { x = x, y = y }, corner, layer)
                end

                -- and now we'll hit the diagonals (but they should mostly already be resolved)
                for i = 0, 3 do
                    local x      = math.round(math.cos(i * (math.pi / 2) + (math.pi / 4)))
                    local y      = math.round(math.sin(i * (math.pi / 2) + (math.pi / 4)))
                    local corner = data.collision_points[x][y]

                    p, new_v = resolve(p, new_v, { x = x, y = y }, corner, layer)
                end

                -- mario is in mid_air if he is already in mid_air and
                -- his left and right bottom pixels are in mid_air
                local bottom_left  = data.collision_points[-1][1]
                local bottom_right = data.collision_points[1][1]
                bottom_left  = { x = bottom_left.x,  y = bottom_left.y + 1 }
                bottom_right = { x = bottom_right.x, y = bottom_right.y + 1 }

                mid_air = mid_air and not detect(p, bottom_left, layer) and not detect(p, bottom_right, layer)
            end
        end

        return p, new_v, mid_air
    end

    -- data is a serialization of some object. I guess I'm just being a dick,
    -- but I don't like passing references to objects. I prefer to serialize
    -- the data and pass that... probably this is dumb, but only time will tell.
    local collide = function (data)
        local p, new_v, mid_air = collisions(data)
        local tx, ty = pixel_to_tile(p.getX(), p.getY())

        -- the results of the collision
        return {
            p       = p,
            v       = new_v,
            mid_air = mid_air,
            is_dead = checkForDeath(tx, ty)
        }
    end
    -- public interface for map
    return {
        update            = update,
        draw              = draw,
        collide           = collide,

        isInDungeon       = isInDungeon,
        isInTransition    = isInTransition,
        isOnGround        = isOnGround,
        isCloudWalking    = isCloudWalking,
        getGroundY        = getGroundY,
        getTransitionY    = getTransitionY,
        getDungeonY       = getDungeonY,

        getBand           = getBand,
        getCameraForBand  = getCameraForBand,

        isFinished        = isFinished,
        setFinished       = setFinished,

        isGlitchedout        = isGlitchedout,
        setGlitchedout       = setGlitchedout,

        setVictoryHandler = setVictoryHandler,
        setGlitchoutHandler = setGlitchoutHandler,
        setDeathHandler   = setDeathHandler,
        setProceedHandler = setProceedHandler,
        setEvents         = setEvents,
        setOrigin         = setOrigin,
        getStart          = getStart,

        getGlitchMusic    = getGlitchMusic,

        glitch            = glitch,
        reset             = reset,

        onProceed         = onProceed,

        sprite            = sprite
    }
end

LevelOne = function (tmx, options)
    local map = Map(tmx)

    map.setEvents(options.doors)
    map.setOrigin(options.start)

    map.setDeathHandler(function ()

        map.setFinished(true)

        map.setProceedHandler(function ()
            map.setFinished(false)
            map.reset()
        end)
    end)

    map.setVictoryHandler(function ()
        map.setFinished(true)

        map.setProceedHandler(function ()
            -- NOP because we want to change worlds
        end)
    end)

    map.sprite = options.sprite
    map.scenes = options.scenes

    return map
end

SubsequentLevels = function (tmx, options)
    local map = Map(tmx)

    map.setEvents(options.doors)
    map.setOrigin(options.start)

    map.setDeathHandler(function ()
        map.setFinished(true)

        map.setProceedHandler(function ()
            -- nop because we want to change worlds
        end)
    end)

    map.setVictoryHandler(function ()
        map.setFinished(true)

        map.setProceedHandler(function ()
            -- you aren't finished here mario...
            map.setFinished(false)

            map.glitch()
            map.reset()
        end)
    end)

    map.setGlitchoutHandler(function ()
        map.setFinished(true)

        map.setProceedHandler(function ()
            -- you aren't finished here mario...
            map.setFinished(false)
            map.setGlitchedout(true)

            map.glitch()
            map.reset()
        end)
    end)

    map.sprite = options.sprite
    map.scenes = options.scenes

    return map
end

---------------------------------------------------------------------------------------------------
return Map

