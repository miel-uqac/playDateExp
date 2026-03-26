import "CoreLibs/sound"
import "game_constants"

Audio = {}

local C = GameConstants
local snd = playdate.sound

local musicMenu = nil
local musicGame = nil
local soundGameOver = nil
local currentMusic = nil


function Audio.load()
    musicMenu = snd.fileplayer.new(C.MUSIC_MENU_PATH)
    if not musicMenu then
        print("Erreur : impossible de charger " .. C.MUSIC_MENU_PATH)
    end

    musicGame = snd.fileplayer.new(C.MUSIC_GAME_PATH)
    if not musicGame then
        print("Erreur : impossible de charger " .. C.MUSIC_GAME_PATH)
    end

    soundGameOver = snd.sampleplayer.new(C.SOUND_GAMEOVER_PATH)
    if not soundGameOver then
        print("Erreur : impossible de charger " .. C.SOUND_GAMEOVER_PATH)
    end
end

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