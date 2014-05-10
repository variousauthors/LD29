-- This is a little delicate, in that it requires the sprites and various other
-- globals to exist already. Really it is just a convenience.

local maps = {
    -- 1-1
    LevelOne("map1-1.tmx", {
        sprite = Sprites.bigguy,
        doors = {
            {
                coords = { 204, 12 },
                event  = "onVictory"
            }
        },
        scenes = {
            init = "StartScreen",
            sub = "Pre11"
        }
    }),

    -- 2-1
    SubsequentLevels("map2-1.tmx", {
        sprite = Sprites.ladyguy,
        doors = {
            {
                coords = { 204, 12 },
                event  = "onVictory"
            },

            {
                coords = { 98, 27 },
                event  = "enterDoubleJumpShrine"
            },
        },
        scenes = {
            init = "Pre21",
            sub  = "Pre21Sub"
        }
    }),

    -- 5-1
    SubsequentLevels("map5-1.tmx", {
        sprite = Sprites.lilguy,
        doors = {
            {
                coords = { 202, 27 },
                event  = "onVictory"
            },

            {
                coords = { 36, 27 },
                event  = "enterCloudShrine"
            },

            {
                coords = { 98, 42 },
                event  = "enterDoubleJumpShrine"
            },
        },
        scenes = {
            init = "Pre51",
            sub  = "Pre51Sub"
        },
        -- this is the top left corner of the starting screen,
        -- in tile form
        start = {
            x = 0,
            y = 14 -- TODO this was 15, but I made it fourteen for testing mini mario
        }
    }),

    -- 9-1
    SubsequentLevels("map9-1.tmx", {
        sprite = Sprites.oldguy,
        doors = {
            {
                coords = { 196, 52 },
                event  = "onVictory"
            },

            {
                coords = { 36, 27 },
                event  = "enterCloudShrine"
            },

            {
                coords = { 82, 82 },
                event  = "enterTreeShrine"
            },

            {
                coords = { 98, 67 },
                event  = "enterDoubleJumpShrine"
            },
        },
        scenes = {
            init = "Pre91",
            sub  = "Pre91Sub"
        },

        start = {
            x = 5,
            y = 25
        }
    }),

    -- 10-0
    SubsequentLevels("map9-1.tmx", {
        sprite = Sprites.oldguy,
        doors = {
            {
                coords = { 196, 52 },
                event  = "onVictory"
            }
        },
        scenes = {
            init = "Finale100"
        },

        start = {
            x = 0,
            y = 40
        }
    })
}

return maps
