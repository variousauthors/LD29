
-- Setup
local loader     = require("vendor/AdvTiledLoader.Loader")
loader.path      = "assets/maps/"
local map        = loader.load("map.tmx")
local tile_layer = map.layers["obstacle"]

-- So, this whole file I basically just stole from the examples in the 
-- tile library. That's why the code is so weird. In the days to come
-- I will change this so that Map is a constructor and we can make multiple
-- maps with different qualities.
--
-- Also on the TODO list is pulling the collision code out of here.
local Map = {}

-- Resets the example
function Map.reset()
    -- tx and ty are the offset of the tilemap
    global.tx = 0
    global.ty = 0
end

-- at some point we will probably want code in here
function Map.update(dt)

end

-- Called from love.draw()
function Map.draw()
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
        map:autoDrawRange(ftx, fty, global.scale, -40) 
    else 
        map:autoDrawRange(ftx, fty, global.scale, 50) 
    end

    -- Queue our guy to be drawn after the tile he's on and then draw the map.
    local maxDraw = global.benchmark and 20 or 1
    for i=1,maxDraw do 
        map:draw() 
    end
    love.graphics.rectangle("line", map:getDrawRange())

    -- Reset the scale and translation.
    love.graphics.pop()

end

-- the player's position is a point (x, y) in pixels, but I couldn't
-- find a function in the tile library that lets us ask for "the tile
-- around these pixels" So for now I'm just converting, but later I
-- will implement such a lookup.
function pixel_to_tile (pixel_x, pixel_y)
    return math.ceil((pixel_x) / (map.tileWidth * global.scale)), math.ceil((pixel_y) / (map.tileHeight * global.scale))
end

-- given a vector, determine which collision point should be checked
-- first by converting the vector into a diagonal vector
-- and using that as an index
function primary_direction (v)
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

function resolveCollision(p, v, offset)
    local tile  = tile_layer(pixel_to_tile(p.getX() + offset.x, p.getY() + offset.y))
    local new_v = v

    -- if there is a collision, then we will want to halt the incoming object
    if tile ~= nil then
        new_v = Vector(0, 0)
    end

    -- the "algorithm" is to push the object back in the direction it came until
    -- there is no longer a collision :/
    while (tile ~= nil) do
        p.setX(p.getX() - v.getX())
        p.setY(p.getY() - v.getY())

        tile = tile_layer(pixel_to_tile(p.getX() + offset.x, p.getY() + offset.y))
    end

    return p, new_v
end

-- data is a serialization of some object. I guess I'm just being a dick,
-- but I don't like passing references to objects. I prefer to serialize
-- the data and pass that... probably this is dumb, but only time will tell.
function Map.collide(data)
    -- back the o up pixel by pixel
    -- return mid_air for mid-air collisions
    local p      = Point(data.x, data.y)
    local v      = Vector(data.v.x, data.v.y)
    local x, y   = primary_direction(v) -- index at which to start collision detection
    local new_v  = v

    -- collision points are single pixels on the sprite that collide
    -- at the moment there is just one. The actual data is an offset
    -- from the position of the sprite, so like a 16px square sprite at
    -- 0, 0 will have 4 collision points at (0, 0), (16, 0), (0, 16), (16, 16)
    -- but at the moment we just use one of these
    local offset = data.collision_points[x][y]

    p, new_v = resolveCollision(p, v, offset)

    -- iterate over all collision points looking fro secondary collition
    for i, c1 in pairs(data.collision_points) do
        for j, c2 in pairs(data.collision_points[i]) do

            offset = data.collision_points[i][j]
            p, new_v   = resolveCollision(p, new_v, offset)
        end
    end


    -- if there is no tile directly beneath the collision point, then the player
    -- is in mid-air (this is used in the player code)
    ground_tile = tile_layer(pixel_to_tile(p.getX() + -16, p.getY() + -16 + 1))
    ground_tile = ground_tile or tile_layer(pixel_to_tile(p.getX() + -32, p.getY() + -16 + 1))
    mid_air     = ground_tile == nil

    -- the results of the collision
    return {
        p = p,
        v = new_v,
        mid_air = mid_air
    }
end

---------------------------------------------------------------------------------------------------
return Map

