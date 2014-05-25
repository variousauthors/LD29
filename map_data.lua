-- This is a little delicate, in that it requires the sprites and various other
-- globals to exist already. Really it is just a convenience.

local mapoffset51 = 14

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
                missing = 40,
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
                y = 12
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
                missing = 30,
                dmissing = 20,
                cmissing = 10,
                crazy = 50
            },
            -- the distance in tiles between the top left corner of the MAP
            -- and the top left corner of the starting screen (with the castle)
            origin = {
                x = 0,
                y = 15
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
            glitch_penalty = 10,
            doors = {
                {
                    coords = { 196, 52 },
                    event  = "onVictory"
                },

                {
                    coords = { 18, 65 },
                    event  = "enterWallJumpShrine"
                },

                {
                    coords = { 36, 52 },
                    event  = "enterCloudShrine91"
                },

                {
                    coords = { 82, 82 },
                    event  = "enterTreeShrine"
                },

                {
                    coords = { 98, 67 },
                    event  = "enterDoubleJumpShrine91"
                },

                {
                    coords = { 187, 30 },
                    event  = "enterBackwardsShrine91"
                },
            },
            scenes = {
                init = "Pre91",
                sub  = "Pre91Sub",
                glitch = "Pre91G"
            },
            glitches = {
                missing = 30,
                dmissing = 20,
                cmissing = 10,
                crazy = 70
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
        }),

        -- 10-0
        SubsequentLevels("map9-1.tmx", {
            name = "9-1",
            item = "flower",
            sprite = Sprites.oldguy,
            glitch_penalty = 10,
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
