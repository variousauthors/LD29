require("vendor/TEsound") -- TEsound global object

Sound = {}

Sound.assets = {}

-- SFX are loaded into the table as SoundData (in-memory PCM) cuz they small.
Sound.assets.sfx = {
    ptooi_big        = love.sound.newSoundData("assets/sfx/ptooi_big.wav"),
    ptooi_small      = love.sound.newSoundData("assets/sfx/ptooi_small.wav"),
    badadoodahdeedah = love.sound.newSoundData("assets/sfx/badadoodahdeedah.wav")
}

-- Music am just filename since are big.
Sound.assets.music = {
    M100tp5e0 = "assets/music/M100tp5e0.mp3",
    M100tp5e1 = "assets/music/M100tp5e1.mp3",
    M100tp5e2 = "assets/music/M100tp5e2.mp3",
    M100tp5e3 = "assets/music/M100tp5e3.mp3",
    M100tp5e4 = "assets/music/M100tp5e4.mp3"
}

TEsound.volume("sfx", 1)
TEsound.volume("music", 0.8)

Sound.playSFX = function(name)
    TEsound.play(Sound.assets.sfx[name], "sfx")
end

Sound.playMusic = function(name, noloop)
    if (noloop) then
        TEsound.play(Sound.assets.music[name], "music")
    else
        TEsound.playLooping(Sound.assets.music[name], "music")
    end
end

Sound.update = TEsound.cleanup
