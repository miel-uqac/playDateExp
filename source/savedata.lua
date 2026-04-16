import "game_constants"

SaveData = {}

local SAVE_FILE = "saveData"

function SaveData.saveBestScore(score)
    playdate.datastore.write({ highscore = score }, SAVE_FILE)
end

function SaveData.loadBestScore()
    local data = playdate.datastore.read(SAVE_FILE)
    if data and data.highscore then
        return data.highscore
    end
    return 0
end