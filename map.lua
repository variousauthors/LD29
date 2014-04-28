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
    local map         = loader.load(tmx)
    local is_finished = false
    local events      = {}
    local sprite      = {}
    local glitch_lvl  = 0
    local glitch_max  = 4
    local death_line  = map.height - 1

    -- the amount to cheat the screen by on level start
    local origin_y = 0
    local start_y  = 0

    local proceed_handler, death_handler, victory_handler

    -- initialize the various glitches
    local missing_tiles_glitch = Glitches()
    missing_tiles_glitch.load_layer(map.layers["obstacle"])

    -- run all the glitches
    local glitch = function ()
        missing_tiles_glitch.generate_glitches(20)
        missing_tiles_glitch.modify_layer()
        glitch_lvl = glitch_lvl + 1
        Sound.playMusic("M100tp5e".. math.min(glitch_lvl, glitch_max))
    end

    -- expose the state of the map
    local isFinished = function ()
        return is_finished
    end

    local setFinished = function (finished)
        is_finished = finished
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

        local x = 200 -- arbitrary for now
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
        if tile > 30 + start_y                                                  then return { zone = "catacombs", transition = false } end
        if tile > 15 + start_y                                                  then return { zone = "dungeon",   transition = false } end
        if tile == 15 + start_y or tile == 14 + start_y or tile == 13 + start_y then return { zone = "dungeon",   transition = true  } end
        if tile > 0 + start_y and tile < 12 + start_y                           then return { zone = "ground" ,   transition = false } end
        if tile == 0 + start_y or tile == -1 + start_y or tile == -2 + start_y  then return { zone = "clouds",    transition = true  } end
        if tile < -2                                                            then return { zone = "clouds",    transition = false } end
    end

    local getCameraForBand = function (band)

        if band.zone == "catacombs" and band.transition == false  then return -(( global.tile_height ) * global.tile_size * global.scale) + origin_y end
        if band.zone == "dungeon" and band.transition == false  then return -(( global.tile_height / 2 ) * global.tile_size * global.scale) + origin_y end
        if band.zone == "dungeon" and band.transition == true   then return -(( global.tile_height / 4 ) * global.tile_size * global.scale) + origin_y end
        if band.zone == "ground"  and band.transition == false  then return 0 + origin_y                                                               end
        if band.zone == "clouds"  and band.transition == true   then return (( global.tile_height / 4 ) * global.tile_size * global.scale) + origin_y  end
        if band.zone == "clouds"  and band.transition == false  then return (( global.tile_height / 4 ) * global.tile_size * global.scale) + origin_y  end
    end

    -- set handlers for events like "onVictory"
    local setDeathHandler = function (callback)
        death_handler = callback
    end

    local setVictoryHandler = function (callback)
        victory_handler = callback
    end

    local setProceedHandler = function (callback)
        proceed_handler = callback
    end

    -- respond to events like "onVictory"
    local onDeath = function ()
        if death_handler ~= nil then death_handler() end
    end

    local onVictory = function ()
        if victory_handler ~= nil then victory_handler() end
    end

    local onProceed = function ()
        if proceed_handler ~= nil then proceed_handler() end
    end

    -- important methods for the public interface
    -- reset, update, draw

    -- Resets the example
    local reset = function ()
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
        return math.ceil((pixel_x - global.tx * 2) / (map.tileWidth * global.scale)), math.ceil((pixel_y - global.ty * 2) / (map.tileHeight * global.scale))
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
            x = 1
        end

        if y < 0 then
            y = math.floor(y)
        elseif y > 0 then
            y = math.ceil(y)
        else
            y = 1
        end

        return x, y
    end

    -- TODO this is necessary because I want to dynamically send
    -- messages like "onDeath" but haven't been able to use
    -- a self variable. In the future I could do self["onVictory"]
    -- but for now I do callbacks["onVictory"]
    local callbacks = {}
    callbacks["onDeath"]      = onDeath
    callbacks["onVictory"]    = onVictory

    -- callbacks for layer properties
    callbacks["obstacle"] = function (layer, v, tx, ty, rx, ry)
        return Vector(0, 0)
    end

    -- callbacks for layer properties
    callbacks["destructible"] = function (layer, v, tx, ty, rx, ry)

        -- if the resolution_tile is below the collision_tile then we hit from below
        -- ... I hope
        if ry > ty then
            layer:set(tx, ty, nil)
            Sound.playSFX("smash")
        end

        return v
    end

    callbacks["collectable"] = function (layer, v, tx, ty, rx, ry)
        return v
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

    local resolveCollision = function (p, v, offset, layer)
        -- the position of the tile we are colliding with
        local tx, ty         = pixel_to_tile(p.getX() + offset.x, p.getY() + offset.y)
        tile_x, tile_y       = tx, ty -- debug stuff

        -- this is where the tile is "detected"
        local tile           = detect(p, offset, layer)
        local new_v, is_dead = v, false

        -- this 14 will need to be based on the map bounds
        if ty > death_line then
            onDeath()
            is_dead = true
        end

        -- if we've collided with an event tile, then we need to
        -- process the event (the tile may not actually be a "hit", such as doors)
        if events[tx] ~= nil and events[tx][ty] ~= nil then
            local callback = callbacks[events[tx][ty]]

            callback()
        end

        local count = 0
        local collision_occured = tile ~= nil
        local collision_tile    = tile

        -- the "algorithm" is to push the object back in the direction it came until
        -- there is no longer a collision :/
        -- we want the "tile" to be different from the "collision_tile"
        while (tile ~= nil and count < 100) do
            p.setX(p.getX() - v.getX())
            p.setY(p.getY() - v.getY())

            tile = layer(pixel_to_tile(p.getX() + offset.x, p.getY() + offset.y))
            count = count + 1
        end

        -- resolve the collision's side effects
        if collision_occured then
            -- and run collision callbacks
            for key, value in pairs(layer.properties) do
                local callback = callbacks[key]

                -- the position of the tile that we resolved to
                rx, ry = pixel_to_tile(p.getX() + offset.x, p.getY() + offset.y)

                -- some callbacks will change the vector (halt it, for example)
                new_v = callback(layer, new_v, tx, ty, rx, ry)
            end

            -- debug
            table.insert(collisions, { x = tx, y = ty, tile = tile})
        end

        return p, new_v, is_dead
    end

    -- for each tile layer, try to resolve collisions on that layer
    -- APPOLOGIES
    local resolveCollisions = function (data)
        -- back the o up pixel by pixel
        -- return mid_air for mid-air collisions
        local p                       = Point(data.x, data.y)
        local v                       = Vector(data.v.x, data.v.y)
        local x, y                    = primary_direction(v) -- index at which to start collision detection
        local new_v, is_dead, mid_air = v, false, true -- assume we are in mid_air and not dead

        -- collision points are single pixels on the sprite that collide
        -- The actual data is an offset from the position of the sprite,
        -- so like a 16px square sprite at
        -- 0, 0 will have 4 collision points at (0, 0), (16, 0), (0, 16), (16, 16)
        -- but at the moment we just use one of these

        -- run this code once for every tile layer
        for key in pairs(map.layers) do
            local layer = map.layers[key]

            -- if the layer is an obstacle layer
            if layer.properties["obstacle"] ~= nil then
                -- run collision detection once to resolve the "most likely collision"

                corner = data.collision_points[1][1]

                magic_keys = {
                    data.h - 1,
                    0,
                    (data.h - 1) / 8,
                    (data.h - 1) - (data.h - 1) / 8,
                    (data.h - 1) / 4,
                    (data.h - 1) - (data.h - 1) / 4
                }

                for key, value in pairs(magic_keys) do
                    local pixel = value

                    offset = { x = corner.x, y = corner.y - (data.h - 1 - pixel) }
                    p, new_v, is_dead = resolveCollision(p, new_v, offset, layer)

                    offset = { x = corner.x - data.w, y = corner.y - (data.h - 1 - pixel) }
                    p, new_v, is_dead = resolveCollision(p, new_v, offset, layer)
                end

                ground_tile = layer(pixel_to_tile(p.getX() - (data.w ) + ( data.w / 2  ), p.getY() - ( data.h / 2 ) + 1))
                ground_tile = ground_tile or layer(pixel_to_tile(p.getX() - (data.w) - ( data.w / 2 ), p.getY() - ( data.h / 2 ) + 1))

                -- mid_air is the AND of all mid_air calculations
                -- so if _any_ collision detected a ground_tile then we are _not_ in mid_air
                mid_air = mid_air and (ground_tile == nil)
            end
        end

        return p, new_v, mid_air, is_dead
    end

    -- data is a serialization of some object. I guess I'm just being a dick,
    -- but I don't like passing references to objects. I prefer to serialize
    -- the data and pass that... probably this is dumb, but only time will tell.
    local collide = function (data)
        local p, new_v, mid_air, is_dead = resolveCollisions(data)

        -- the results of the collision
        return {
            p = p,
            v = new_v,
            mid_air = mid_air,
            is_dead = is_dead
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

        setVictoryHandler = setVictoryHandler,
        setDeathHandler   = setDeathHandler,
        setProceedHandler = setProceedHandler,
        setEvents         = setEvents,
        setOrigin         = setOrigin,
        getStart          = getStart,

        glitch            = glitch,
        reset             = reset,

        onProceed         = onProceed,

        sprite            = sprite
    }
end

LevelOne = function (tmx, options)
    local map = Map(tmx)

    map.setEvents(options.doors)

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

    map.sprite = options.sprite

    return map
end

---------------------------------------------------------------------------------------------------
return Map

