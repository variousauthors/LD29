--[[ Glitches

    Instances hold a perpetual set of glitch coordinates, generated from
    existing tiles in a map layer.
    Glitches are generated from whatever map layer is currently loaded, but
    glitch coordinates are forever.
    Can also apply glitches to a map layer -- will attempt to apply all
    accumulated glitch coordinates, deleting any matching tiles in the layer.

  ]]--
Glitches = function ()
    local glitch_coords = {}
    local map_layer, tile_list = nil, nil
    --hacky RNG seeding/init
    local rng = love.math.newRandomGenerator(os.time())
    rng:random()
    rng:random()

    -- loads a map layer and populates a tile list for creating glitches
    local load_layer = function (layer_in)
        map_layer = layer_in

        tile_list = {}
        for x, y, tile in map_layer:iterate() do
            table.insert(tile_list, {x, y, tile.properties})
        end
    end

    -- everybody loves a getter
    local get_glitch_coords = function()
        return glitch_coords
    end

    -- iterator over glitch coords, stolen from AdvTiledLoader.Grid
    local glitch_coords_iterate = function()
        local x, y, row, val = nil, nil, nil, nil
        return function()
            repeat
                if not y then
                    x, row = next(glitch_coords, x)
                    if not row then return end
                end
                y, val = next(row, y)
            until y
            return x, y, val
        end
    end

    -- safely write coords to 2d table
    local glitch_coords_add = function(x, y, p)
        if (glitch_coords[x] == nil) then
            glitch_coords[x] = {}
        end
        glitch_coords[x][y] = p
    end

    -- Generate cross-shaped glitches on tiles in loaded layer.
    -- Doesn't try to avoid duplicates, nor to keep whole glitch on-screen.
    local generate_glitches = function(num_glitches)
        for i = 1, num_glitches, 1 do
            local x, y, p = unpack(tile_list[rng:random(1, #tile_list)])
            glitch_coords_add(x, y, p)
            glitch_coords_add(x + 1, y, p)
            glitch_coords_add(x - 1, y, p)
            glitch_coords_add(x, y + 1, p)
            glitch_coords_add(x, y - 1, p)
        end
    end

    -- Modify/Delete glitched tiles from a map layer.
    -- Shouldn't choke if impossible/nonexistent tiles are in the list.
    local modify_layer = function ()
        local x, y = nil, nil
        for x, y in glitch_coords_iterate() do
            if (map_layer(x,y)) then
                map_layer:set(x, y, nil)
            end
        end
    end

    -- Public Interface
    return {
        load_layer = load_layer,
        get_glitch_coords = get_glitch_coords,
        generate_glitches = generate_glitches,
        modify_layer = modify_layer
    }
end
