-- Gestion centralisée des musiques et effets sonores.
import "game_constants"

Audio = {}

local Config = GameConstants
local sound <const> = playdate.sound

local musicMenu = nil
local musicGame = nil
local soundGameOver = nil
local currentMusic = nil


function Audio.load()
    musicMenu = sound.fileplayer.new(Config.MUSIC_MENU_PATH)
    if not musicMenu then
        print("Erreur : impossible de charger " .. Config.MUSIC_MENU_PATH)
    end

    musicGame = sound.fileplayer.new(Config.MUSIC_GAME_PATH)
    if not musicGame then
        print("Erreur : impossible de charger " .. Config.MUSIC_GAME_PATH)
    end

    soundGameOver = sound.sampleplayer.new(Config.SOUND_GAMEOVER_PATH)
    if not soundGameOver then
        print("Erreur : impossible de charger " .. Config.SOUND_GAMEOVER_PATH)
    end
end

-- Coupe la piste en cours avant d'en lancer une nouvelle.
local function stopCurrentMusic()
    if currentMusic and currentMusic:isPlaying() then
        currentMusic:stop()
    end
    currentMusic = nil
end

function Audio.playMenuMusic()
    if currentMusic == musicMenu then return end
    stopCurrentMusic()
    if musicMenu then
        musicMenu:play(0)
        currentMusic = musicMenu
    end
end

function Audio.playGameMusic()
    if currentMusic == musicGame then return end
    stopCurrentMusic()
    if musicGame then
        musicGame:play(0)
        currentMusic = musicGame
    end
end

function Audio.playGameOver()
    stopCurrentMusic()
    if soundGameOver then
        soundGameOver:play()
    end
end

function Audio.stopAll()
    stopCurrentMusic()
end