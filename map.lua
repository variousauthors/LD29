
-- Setup
local loader     = require("vendor/AdvTiledLoader.Loader")
loader.path      = "assets/maps/"
local map        = loader.load("map.tmx")
local tile_layer = map.layers["obstacle"]

-- Our example class
local Map = {}

---------------------------------------------------------------------------------------------------
-- Resets the example
-- puts the player in her starting position
function Map.reset()
    -- tx and ty are the offset of the tilemap
    global.tx = 0
    global.ty = 0
    displayTime = 0
end

---------------------------------------------------------------------------------------------------
-- Update the display time for the character control instructions
function Map.update(dt)

end

---------------------------------------------------------------------------------------------------
-- Called from love.draw()
function Map.draw()

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

function pixel_to_tile (pixel_x, pixel_y)
    return math.ceil((pixel_x) / (map.tileWidth * global.scale)), math.ceil((pixel_y) / (map.tileHeight * global.scale))
end

-- @param p is a point and v is a direction vector for the point
function Map.collide(p, v, o)
    -- back the o up pixel by pixel
    -- return mid_air for mid-air collisions
    local p = Point(o.x, o.y)
    local v = Vector(o.v.x, o.v.y)

    local tile = tile_layer(pixel_to_tile(p.getX() + o.collision_points[1].x, p.getY() + o.collision_points[1].y))
    local new_v = v
    local mid_air

    if tile ~= nil then
        new_v = Vector(0, 0)
    end

    while (tile ~= nil) do
        p.setX(p.getX() - v.getX())
        p.setY(p.getY() - v.getY())

        tile = tile_layer(pixel_to_tile(p.getX() + o.collision_points[1].x, p.getY() + o.collision_points[1].y))
    end

    ground_tile = tile_layer(pixel_to_tile(p.getX() + o.collision_points[1].x, p.getY() + o.collision_points[1].y + 1))
    mid_air = ground_tile == nil

    return {
        p = p,
        v = new_v,
        mid_air = mid_air
    }
end

---------------------------------------------------------------------------------------------------
return Map

