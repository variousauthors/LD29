local gen_spriteset = function(image, gridW, gridH, base_facing, names)
    if(type(image) == "string") then
        image = love.graphics.newImage(image)
    end

    image:setFilter("nearest", "nearest")

    gridW = gridW or 16
    gridH = gridH or 16

    local width = image:getWidth()
    local height = image:getHeight()
    local tile_height = height / global.tile_size
    local quads = {}
    local namedQuads = {}
    for y = 0, height / gridH - 1 do
        for x = 0, width / gridW - 1 do
            local num = #quads + 1
            quads[num] = love.graphics.newQuad(x * gridW +0.002, y * gridH, gridW - 0.004, gridH, width, height)
            if (names and names[num]) then namedQuads[names[num]] = quads[num] end
        end
    end

    return {
        image       = image,
        quads       = quads,
        namedQuads  = namedQuads,
        base_facing = base_facing,
        width       = gridW,
        height      = gridH,
        tile_height = tile_height
    }
end


Sprites = {}

Sprites.bigguy = gen_spriteset("assets/images/bigguy.png", 16, 32, "right",
                     {"stand", "walk1", "walk2", "walk3", "turn", "jump"})
Sprites.bigguy.walk_anim = {"walk1", "walk2", "walk3"}
Sprites.bigguy.turn_anim = {"turn", "turn", "walk1", "walk2", "walk3"}

Sprites.lilguy = gen_spriteset("assets/images/lilguy.png", 16, 16, "right",
                     {"stand", "walk1", "walk2", "walk3", "turn", "jump"})
Sprites.lilguy.walk_anim = {"walk1", "walk2", "walk3"}
Sprites.lilguy.turn_anim = {"turn", "turn", "walk1", "walk2", "walk3"}

Sprites.oldguy = gen_spriteset("assets/images/oldguy.png", 16, 32, "right",
                     {"stand", "walk1", "walk2", "walk3", "turn", "jump"})
Sprites.oldguy.walk_anim = {"walk1", "walk2", "walk3"}
Sprites.oldguy.turn_anim = {"turn", "turn", "walk1", "walk2", "walk3"}

Sprites.ladyguy = gen_spriteset("assets/images/ladyguy.png", 16, 32, "right",
                     {"stand", "walk1", "walk2", "walk3", "turn", "jump"})
Sprites.ladyguy.walk_anim = {"walk1", "walk2", "walk3"}
Sprites.ladyguy.turn_anim = {"turn", "turn", "walk1", "walk2", "walk3"}
