import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/crank"
import "game_constants"
import "obstacles"
import "ui"
import "plant"
import "bonus"
import "audio"
import "background"
import "savedata"

local graphics = playdate.graphics
local Config = GameConstants

local textFont = graphics.font.new("assets/Fonts/robkohr-mono-10x16")
if textFont then
    graphics.setFont(textFont)
else
    print("Erreur : Impossible de charger la police robkohr-mono-10x16")
end

local gameState = Config.STATE_MENU
local score = 0
local bestScore = SaveData.loadBestScore()

local playerImage = nil
local playerCollisionRadius = Config.PLAYER_HITBOX_RADIUS

local loadedImage = graphics.image.new(Config.PLAYER_IMAGE_PATH)
if loadedImage then
    playerImage = loadedImage:scaledImage(Config.PLAYER_SCALE)
end

Audio.load()
Background.load()

local activeBonuses = {}
local activeBonusEffect = nil
local nextBonusThreshold = Config.BONUS_SPAWN_INTERVAL
local scoreMultiplier = 1

local resetGame
local startGame
local gameOver

local function clamp(x, minValue, maxValue)
    if x < minValue then return minValue end
    if x > maxValue then return maxValue end
    return x
end

local function hasPlayerObstacleCollision()
    local playerHeadX, playerHeadY = Plant.getSmoothHeadPosition()
    for _, obstacle in ipairs(activeObstacles) do
        local collisionActive = true
        if obstacle.canCollide and not obstacle:canCollide() then
            collisionActive = false
        end
        if collisionActive then
            if obstacle.radius then
                local dx = playerHeadX - obstacle.centerX
                local dy = playerHeadY - obstacle.centerY
                local distSq = dx * dx + dy * dy
                local r = playerCollisionRadius + obstacle.radius
                if distSq < r * r then return true end
            else
                local closestX = clamp(playerHeadX, obstacle.x, obstacle.x + obstacle.w)
                local closestY = clamp(playerHeadY, obstacle.y, obstacle.y + obstacle.h)
                local dx = playerHeadX - closestX
                local dy = playerHeadY - closestY
                if dx * dx + dy * dy < playerCollisionRadius * playerCollisionRadius then
                    return true
                end
            end
        end
    end
    return false
end

local function updateBonuses(deltaTime, scrollOffset)
    local px, py = Plant.getSmoothHeadPosition()
    for i = #activeBonuses, 1, -1 do
        local bonus = activeBonuses[i]
        bonus:update(deltaTime, scrollOffset)
        if not bonus.collected and bonus:checkCollision(px, py, playerCollisionRadius) then
            bonus.collected = true
            local effect = bonus:onCollect()
            if effect then
                activeBonusEffect = { type = effect.type, multiplier = effect.multiplier, timer = effect.duration }
                scoreMultiplier = effect.multiplier
            end
        end
        if bonus.collected or bonus:isOffscreen() then
            table.remove(activeBonuses, i)
        end
    end
    if activeBonusEffect then
        activeBonusEffect.timer = activeBonusEffect.timer - deltaTime
        if activeBonusEffect.timer <= 0 then
            activeBonusEffect = nil
            scoreMultiplier = 1
        end
    end
end

local function drawBonuses()
    for _, bonus in ipairs(activeBonuses) do
        bonus:draw(graphics)
    end
end

local function spawnBonusWhenNeeded()
    if score >= nextBonusThreshold then
        nextBonusThreshold = nextBonusThreshold + Config.BONUS_SPAWN_INTERVAL
        local x = math.random(20, Config.SCREEN_WIDTH - 20)
        table.insert(activeBonuses, ScoreBonus.new(x, -20))
    end
end

function playdate.update()
    graphics.clear()

    if gameState == Config.STATE_MENU then
        Audio.playMenuMusic()
        Background.drawMenu()
        UI.drawStartMenu(graphics, bestScore)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            startGame()
        end
        return
    end

    if gameState == Config.STATE_GAMEOVER then
        UI.drawGameOver(graphics, score, bestScore)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            startGame()
        elseif playdate.buttonJustPressed(playdate.kButtonB) then
            gameState = Config.STATE_MENU
        end
        return
    end

    if gameState ~= Config.STATE_PLAYING then return end

    if playdate.buttonJustPressed(playdate.kButtonB) then
        gameState = Config.STATE_MENU
        return
    end

    local deltaTime = playdate.getElapsedTime()
    playdate.resetElapsedTime()

    local crankDelta = playdate.getCrankChange()
    local scrollOffset, climbDelta, playerWentOffscreen = Plant.update(deltaTime, crankDelta)

    Background.update(scrollOffset, climbDelta)
    updateObstacles(deltaTime, scrollOffset, score)
    score = score + (climbDelta * scoreMultiplier)

    if playerWentOffscreen then
        gameOver()
        return
    end

    Plant.drawStem(graphics)
    Plant.drawLeaves(graphics)
    UI.drawHUD(graphics, score, activeBonusEffect)
    drawObstacles()
    Plant.drawHead(graphics, playerImage)

    spawnBonusWhenNeeded()
    updateBonuses(deltaTime, scrollOffset)
    drawBonuses()

    if hasPlayerObstacleCollision() then
        gameOver()
        return
    end

    local waterTop = Config.SCREEN_HEIGHT - Config.WATER_HEIGHT
    graphics.setColor(graphics.kColorBlack)
    graphics.fillRect(0, waterTop, Config.SCREEN_WIDTH, Config.WATER_HEIGHT)

    local _, smoothHeadY = Plant.getSmoothHeadPosition()
    if smoothHeadY + playerCollisionRadius > waterTop then
        gameOver()
        return
    end
end

resetGame = function()
    score = 0
    UI.resetHUDLayout()
    clearObstacles()
    Plant.reset()
    Background.reset()
    activeBonuses = {}
    activeBonusEffect = nil
    scoreMultiplier = 1
    nextBonusThreshold = Config.BONUS_SPAWN_INTERVAL
end

startGame = function()
    resetGame()
    gameState = Config.STATE_PLAYING
    playdate.resetElapsedTime()
    Audio.playGameMusic()
end

gameOver = function()
    gameState = Config.STATE_GAMEOVER
    if score > bestScore then
        bestScore = score
        SaveData.saveBestScore(bestScore)
    end
    Audio.playGameOver()
end

function playdate.gameWillTerminate()
    SaveData.saveBestScore(bestScore)
end

function playdate.deviceWillSleep()
    SaveData.saveBestScore(bestScore)
end