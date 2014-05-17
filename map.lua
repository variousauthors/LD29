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
    local map_midpoint    = map.properties["midpoint"] or map.height -- if not set, then all sky
    local map_midpoint_px = map_midpoint * global.tile_size

    -- the amount to cheat the screen by on level start
    local origin_y = 0
    local start_y  = 0

    local origin_x = 0
    local start_x  = 0

    local proceed_handler, death_handler, victory_handler, glitchout_handler

    -- initialize the various glitches
    local missing_tiles_glitch = Glitches()
    missing_tiles_glitch.load_layer(map.layers["obstacle"])

    local missing_dtiles_glitch = Glitches()
    missing_dtiles_glitch.load_layer(map.layers["destructible"])

    local missing_ctiles_glitch = Glitches()
    missing_ctiles_glitch.load_layer(map.layers["clouds"])

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
    local glitch = function (glitch_options)
        if not glitch_options then
            glitch_options = { }
        end
        glitch_options.missing  = glitch_options.missing or 20
        glitch_options.dmissing = glitch_options.dmissing or 10
        glitch_options.cmissing = glitch_options.cmissing or 0
        glitch_options.crazy    = glitch_options.crazy or 50


        local layer = map.layers["collectible"]

        for key, value in pairs(old_collectible) do
            layer:set(value.x, value.y, value.tile)
        end

        missing_tiles_glitch.generate_glitches(glitch_options.missing)
        missing_tiles_glitch.modify_layer(start_x)

        missing_dtiles_glitch.generate_glitches(glitch_options.dmissing, "single")
        missing_dtiles_glitch.modify_layer(start_x)

        missing_ctiles_glitch.generate_glitches(glitch_options.cmissing, "single")
        missing_ctiles_glitch.modify_layer(start_x)

        crazy_death_glitch.generate_glitches(glitch_options.crazy, "single", true)
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

    local tile_to_pixel = function (tx, ty)
        local tile_width = map.tileWidth * global.scale;

        -- x, y relative to a moving frame
        local rel_x = tile_width * tx
        local rel_y = tile_width * ty

        local pixel_x = rel_x + global.tx * global.scale
        local pixel_y = rel_y + global.ty * global.scale

        return pixel_x, pixel_y
    end


    local setOrigin = function (origin, start)
        -- the tile value for the upper left corner of the start
        -- screen as an offset from the upper left corner of the Tiled Map
        origin_x, origin_y = origin.x, origin.y

        -- mario needs to know where to start. This is usually an offset from
        -- the corner of the start screen. For now it is the same in every level
        -- 12 tiles down, 5 over
        start_x = origin_x + start.x
        start_y = origin_y + start.y
    end

    -- returns the pixel coords at which mario shouls appear
    -- mario should start on the ground (5 tiles below the center)
    local getStart = function ()
        local x, y = tile_to_pixel(start_x, start_y)

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

    local getBand = function (tile)
        if tile == nil then return nil end

        tile = tile - origin_y

        if tile > 30                              then return { zone = "catacombs",    transition = false } end
        if tile > 15                              then return { zone = "dungeon",      transition = false } end
        if tile == 15 or tile == 14 or tile == 13 then return { zone = "dungeon",      transition = true  } end
        if tile > 0 and tile <= 12                then return { zone = "ground" ,      transition = false } end
        if tile == 0 or tile == -1                then return { zone = "clouds",       transition = true  } end
        if tile < -28                             then return { zone = "mesosphere",   transition = false } end
        if tile < -16                             then return { zone = "stratosphere", transition = false } end
        if tile < -1                              then return { zone = "clouds",       transition = false } end
    end

    local getCameraForBand = function (band)

        -- TODO someone can explain to me why these have to be 2 while the global scale is 3...
        if band.zone == "catacombs" and band.transition == false  then return -(( global.tile_height ) * global.tile_size * 2) - pixel_origin_y end
        if band.zone == "dungeon"   and band.transition == false  then return -(( global.tile_height / 2 ) * global.tile_size * 2) - pixel_origin_y end
        if band.zone == "dungeon"   and band.transition == true   then return -(( global.tile_height / 4 ) * global.tile_size * 2) - pixel_origin_y end
        if band.zone == "ground"    and band.transition == false  then return 0 - pixel_origin_y                                                               end
        if band.zone == "clouds"    and band.transition == true   then return (( global.tile_height / 4 ) * global.tile_size * 2) - pixel_origin_y  end
        if band.zone == "clouds"    and band.transition == false  then return (( global.tile_height / 2 ) * global.tile_size * 2) - pixel_origin_y  end

        -- unimplemented
        if band.zone == "stratosphere"  and band.transition == false  then return (( global.tile_height - 2 ) * global.tile_size * 2) - pixel_origin_y  end
        if band.zone == "mesosphere"    and band.transition == false   then return (( global.tile_height * (4/3)) * global.tile_size * 2) - pixel_origin_y  end
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

            Cutscenes.current = Cutscenes.Shrines.Clouds51
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
        Cutscenes.current = Cutscenes.Shrines.Doublejump51
        Cutscenes.current.start()

        global.double_jump = true
    end

    local enterDoubleJumpShrine91 = function ()
        if global.double_jump == true then return end

        -- start the cutscene
        Cutscenes.current = Cutscenes.Shrines.Doublejump91
        Cutscenes.current.start()

        global.double_jump = true
    end

    local enterBackwardsShrine51 = function ()
        if global.backwards == true then return end

        -- start the cutscene
        Cutscenes.current = Cutscenes.Shrines.Backwards51
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
        --
        -- global tx and ty need to be set without SCALE because the map draw
        -- function already knows how to scale things
        -- global tx moves the WORLD RIGHT
        -- global ty moves the WORLD DOWN
        -- at the start of the game we want to move the world UP so that
        -- the origin_x, origin_y are in the corner of the screen
        pixel_origin_y = origin_y * global.tile_width
        global.tx = 0
        global.ty = - pixel_origin_y
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

        -- draw the sky
        -- a bit wider than the whole map, for scrolling
        local map_drawx, map_drawy  = map:getDrawRange()
        local red, green, blue = love.graphics.getColor()
        love.graphics.setColor(146, 144, 255)
        love.graphics.rectangle("fill", 0, map_drawy, map.width * global.tile_size + 512, map_midpoint_px-map_drawy)
        love.graphics.setColor(red, green, blue)

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

    local collisionDirection = function (px, py, v, tx, ty, value)
        -- value gives us the current diagonal direction
        -- create a line from p and v
        -- iterate over 4 sides of the tile
        --

        local v_slope = v.getSlope()

        -- if the slope is infinite, mario is colliding with the top
        -- or bottom of a tile
        if v_slope == math.infinity then
            value.x = 0
            return value
        end

        -- TODO these should all also incorporate global.ty
        -- the earlier point should be the current point minus the vector
        local px_0       = px - v.getX() * global.scale - global.tx * global.scale
        local py_0       = py - v.getY() * global.scale
        local px_1       = px - global.tx * global.scale
        local py_1       = py

        -- distance from y = 0 to the line
        local height = py_1 - v_slope * px_1

        -- use the value to determine which TWO sides are
        -- likely in collision
        local bridge = { x = -value.x / 2 + 1 / 2, y = -value.y / 2 + 1 / 2 }
        local points = { }
        points[1] = { x = (bridge.x + 1) % 2, y = (bridge.y) % 2 }
        points[2] = { x = bridge.x, y = bridge.y }
        points[3] = { x = (bridge.x) % 2, y = (bridge.y + 1) % 2 }

        for i = 1, 2 do
            local x_0, y_0 = points[i].x, points[i].y
            local x_1, y_1 = points[i + 1].x, points[i + 1].y

            -- pixel coords of this tile
            local ox, oy = tile_to_pixel(tx, ty)

            local tx_0       = ox + x_0 * (global.tile_width  * global.scale) - global.tx * global.scale
            local ty_0       = oy + y_0 * (global.tile_height * global.scale)

            local tx_1       = ox + x_1 * (global.tile_width  * global.scale) - global.tx * global.scale
            local ty_1       = oy + y_1 * (global.tile_height * global.scale)


            local side = Vector(tx_0 - tx_1, ty_0 - ty_1)
            local side_m = side.getSlope()

            bob = {}
            table.insert(bob, {
                a = {
                    x = tx_0,
                    y = ty_0
                },
                b = {
                    x = tx_1,
                    y = ty_1
                }
            })

            -- so if the slope is infinite then we have x = c'
            -- if the slow is zero we have y = c'
            --
            -- the vector is y = m*x + c,
            -- c' = m*x + c
            -- so we can solve for the variable in both cases
            if side_m == math.infinity then
                -- solve for y
                local x = tx_0 + 1
                local y = v_slope * x + height

                local in_px = 0 <= math.abs(x - px_0) and math.abs(x - px_0) <= math.abs(px_1 - px_0)
                local in_py = 0 <= math.abs(y - py_0) and math.abs(y - py_0) <= math.abs(py_1 - py_0)

                local in_tx = 0 <= math.abs(x - tx_0) and math.abs(x - tx_0) <= math.abs(tx_1 - tx_0)
                local in_ty = 0 <= math.abs(y - ty_0) and math.abs(y - ty_0) <= math.abs(ty_1 - ty_0)

                if in_px and in_py and in_tx and in_ty then
                    value.y = 0
                    return value
                end
                -- now locate x, y on the line
            else
                -- solve for x
                local y = ty_0
                local x = (y - height) / v_slope

                local in_px = 0 <= math.abs(x - px_0) and math.abs(x - px_0) <= math.abs(px_1 - px_0)
                local in_py = 0 <= math.abs(y - py_0) and math.abs(y - py_0) <= math.abs(py_1 - py_0)

                local in_tx = 0 <= math.abs(x - tx_0) and math.abs(x - tx_0) <= math.abs(tx_1 - tx_0)
                local in_ty = 0 <= math.abs(y - ty_0) and math.abs(y - ty_0) <= math.abs(ty_1 - ty_0)

                -- now locate x, y on the line
                --
                if in_px and in_py and in_tx and in_ty then
                    value.x = 0
                    return value
                end
            end
        end

        -- something strange: there was a collision, but we were not able to
        -- find the vector's intersection with the tile... so there was no collision?
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
        local px, py         = p.getX() + corner.x, p.getY() + corner.y
        local tx, ty         = pixel_to_tile(px, py)
        tile_x, tile_y       = tx, ty -- this is actually used globally to determine band

        if collision and value.x ~= 0 and value.y ~= 0 then
            -- transform value so that it is an axis bound vector

            -- find the intersection of the vector v and the tile's sides
            -- comment this out to switch to the wall creep collision
            value = collisionDirection(px, py, v, tx, ty, value)
        end

        adjustPosition(p, v, value, corner, layer)

        if collision then
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
    map.setOrigin(options.origin, options.start)

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
    map.setOrigin(options.origin, options.start)

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

            map.glitch(options.glitches)
            map.reset()
        end)
    end)

    map.setGlitchoutHandler(function ()
        map.setFinished(true)

        map.setProceedHandler(function ()
            -- you aren't finished here mario...
            map.setFinished(false)
            map.setGlitchedout(true)

            map.glitch(options.glitches)
            map.reset()
        end)
    end)

    map.sprite = options.sprite
    map.scenes = options.scenes

    return map
end

---------------------------------------------------------------------------------------------------
return Map

