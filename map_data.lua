-- This is a little delicate, in that it requires the sprites and various other
-- globals to exist already. Really it is just a convenience.

local mapoffset51 = 28
local mapoffset91 = 55

local write_map_data = function ()
    return {
        -- 1-1
        LevelOne("map1-1.tmx", {
            name = "1-1",
            item = "coin",
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
            },
            origin = {
                x = 0,
                y = 0
            },
            start = {
                x = 5,
                y = 12
            }
        }),

        -- 2-1
        SubsequentLevels("map2-1.tmx", {
            name = "2-1",
            item = "flower",
            glitch_penalty = 50,
            sprite = Sprites.ladyguy,
            doors = {
                {
                    coords = { 204, 12 },
                    event  = "onVictory"
                },

                {
                    coords = { 98, 27 },
                    event  = "enterDoubleJumpShrine21"
                },
            },
            scenes = {
                init = "Pre21",
                sub  = "Pre21Sub",
                glitch = "Pre21G"
            },
            glitches = {
                missing = 35,
                dmissing = 25,
                crazy = 45
            },
            -- the distance in tiles between the top left corner of the MAP
            -- and the top left corner of the starting screen (with the castle)
            origin = {
                x = 0,
                y = 0
            },
            -- mario's starting location, relative to the origin (the top left
            -- corner of the castle screen)
            start = {
                x = 5,
                y = 12  -- I have no idea why this # works better
            }
        }),

        -- 5-1
        SubsequentLevels("map5-1.tmx", {
            name = "5-1",
            item = "flower",
            glitch_penalty = 50,
            sprite = Sprites.lilguy,
            doors = {
                {
                    coords = { 202+mapoffset51, 27 },
                    event  = "onVictory"
                },

                {
                    coords = { 36+mapoffset51, 27 },
                    event  = "enterCloudShrine51"
                },

                {
                    coords = { 98+mapoffset51, 42 },
                    event  = "enterDoubleJumpShrine51"
                },

                {
                    coords = { 187+mapoffset51, 5 },
                    event  = "enterBackwardsShrine51"
                },
            },
            scenes = {
                init = "Pre51",
                sub  = "Pre51Sub",
                glitch = "Pre51G"
            },
            glitches = {
                missing = 45,
                dmissing = 25,
                cmissing = 8,
                crazy = 45
            },
            -- the distance in tiles between the top left corner of the MAP
            -- and the top left corner of the starting screen (with the castle)
            origin = {
                x = mapoffset51,
                y = 15 -- was 15
            },
            -- mario's starting location, relative to the origin (the top left
            -- corner of the castle screen)
            start = {
                x = 5, --formerly 5
                y = 12
            }
        }),

        -- 9-1
        SubsequentLevels("map9-1.tmx", {
            name = "9-1",
            item = "flower",
            sprite = Sprites.oldguy,
            glitch_penalty = 50,
            doors = {
                {
                    coords = { 196+mapoffset91, 52 },
                    event  = "onVictory"
                },

                {
                    coords = { 18+mapoffset91, 65 },
                    event  = "enterWallJumpShrine91"
                },

                {
                    coords = { 19+mapoffset91, 80 },
                    event  = "enterSecretShrine"
                },

                {
                    coords = { 36+mapoffset91, 52 },
                    event  = "enterCloudShrine91"
                },

                {
                    coords = { 82+mapoffset91, 82 },
                    event  = "enterTreeShrine"
                },

                {
                    coords = { 98+mapoffset91, 67 },
                    event  = "enterDoubleJumpShrine91"
                },

                {
                    coords = { 187+mapoffset91, 30 },
                    event  = "enterBackwardsShrine91"
                },
            },
            scenes = {
                init = "Pre91",
                sub  = "Pre91Sub",
                glitch = "Pre91G"
            },
            glitches = {
                missing = 65,
                dmissing = 35,
                cmissing = 10,
                crazy = 40
            },

            -- the distance in tiles between the top left corner of the MAP
            -- and the top left corner of the starting screen (with the castle)
            origin = {
                x = mapoffset91,
                y = 40
            },
            -- mario's starting location, relative to the origin (the top left
            -- corner of the castle screen)
            start = {
                x = 5,
                y = 12
            }
        }),

        -- 10-0
        SubsequentLevels("map9-1.tmx", {
            name = "9-1",
            item = "flower",
            sprite = Sprites.oldguy,
            glitch_penalty = 50,
            doors = {
                {
                    coords = { 196, 52 },
                    event  = "onVictory"
                }
            },
            scenes = {
                init = "Finale100"
            },

            -- the distance in tiles between the top left corner of the MAP
            -- and the top left corner of the starting screen (with the castle)
            origin = {
                x = 0,
                y = 40
            },
            -- mario's starting location, relative to the origin (the top left
            -- corner of the castle screen)
            start = {
                x = 5,
                y = 12
            }
        })
    }
end

return write_map_data
