local gen_spriteset = function(image, gridW, gridH, names)
    if(type(image) == "string") then
        image = love.graphics.newImage(image)
    end

    image:setFilter("nearest", "nearest")

    gridW = gridW or 16
    gridH = gridH or 16

    local width = image:getWidth()
    local height = image:getHeight()
    local quads = {}
    local namedQuads = {}
    for y = 0, height / gridH - 1 do
        for x = 0, width / gridW - 1 do
            local num = #quads + 1
            quads[num] = love.graphics.newQuad(x * gridW, y * gridH, gridW, gridH, width, height)
            if (names and names[num]) then namedQuads[names[num]] = quads[num] end
        end
    end

    return {image = image, quads = quads, namedQuads = namedQuads,
            width = gridW, height = gridH}
end


Sprites = {}

Sprites.bigguy = gen_spriteset("assets/images/guybigt.png", 16, 32,
                     {"stand", "walk1", "walk2", "walk3", "turn", "jump"})
Sprites.bigguy.base_facing = "right"
Sprites.bigguy.walk_anim = {"walk1", "walk2", "walk3"}
