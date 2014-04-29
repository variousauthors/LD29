--[[ The mighty Sound object!

    Sounds are loaded into Sound.assets.[sfx|music]. They are triggered by
    either the Sound.playSFX or Sound.playMusic functions. Simple!

]]--

require("vendor/TEsound") -- TEsound global object

Sound = {}

Sound.assets = {}

-- SFX are loaded into the table as SoundData (in-memory PCM) cuz they small.
Sound.assets.sfx = {
    ptooi_big        = love.sound.newSoundData("assets/sfx/ptooi_big.wav"),
    ptooi_small      = love.sound.newSoundData("assets/sfx/ptooi_small.wav"),
    badadoodahdeedah = love.sound.newSoundData("assets/sfx/badadoodahdeedah.wav"),
    smash            = love.sound.newSoundData("assets/sfx/smash.wav"),
    bading           = love.sound.newSoundData("assets/sfx/bading.wav"),
    boom             = love.sound.newSoundData("assets/sfx/boom.wav"),
    bounce           = love.sound.newSoundData("assets/sfx/bounce.wav"),
    ohheylook        = love.sound.newSoundData("assets/sfx/ohheylook.wav"),
    awyiss           = love.sound.newSoundData("assets/sfx/awwyiss.wav")
}

-- Music am just filename since are big.
Sound.assets.music = {
    M100tp5e0   = "assets/music/M100tp5e0.mp3",
    M100tp5e1   = "assets/music/M100tp5e1.mp3",
    M100tp5e2   = "assets/music/M100tp5e2.mp3",
    M100tp5e3   = "assets/music/M100tp5e3.mp3",
    M100tp5e4   = "assets/music/M100tp5e4.mp3",
    Undesirable = "assets/music/Undesirable.mp3"
}

TEsound.volume("sfx", 1)
TEsound.volume("music", 0.8)

Sound.playSFX = function(name)
    TEsound.play(Sound.assets.sfx[name], "sfx")
end

-- second parameter causes music not to loop, and can even be a callback
-- to run when the sound finishes
Sound.playMusic = function(name, noloop_cb)
    TEsound.stop("music")
    if (noloop_cb) then
        if(type(noloop_cb) == "function") then
            TEsound.play(Sound.assets.music[name], "music", nil, nil, noloop_cb)
        else
            TEsound.play(Sound.assets.music[name], "music")
        end
    else
        TEsound.playLooping(Sound.assets.music[name], "music")
    end
end

Sound.stopMusic = function ()
    TEsound.stop("music")
end

Sound.pauseMusic = function ()
    TEsound.pause("music")
end

Sound.resumeMusic = function ()
    TEsound.resume("music")
end

Sound.update = TEsound.cleanup
