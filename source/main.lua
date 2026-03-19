import "CoreLibs/graphics"
import "CoreLibs/crank"
import "obstacles"
import "game_constants"
import "ui"
import "plant"

local gfx = playdate.graphics
local C = GameConstants

local gameState = C.STATE_MENU

-- Score variables
local score = 0
local bestScore = 0

-- Player visuals and collision
local playerImage = nil
local hitboxRadius = C.PLAYER_HITBOX_RADIUS

local loadedImage = gfx.image.new(C.PLAYER_IMAGE_PATH)
if loadedImage then
    playerImage = loadedImage:scaledImage(C.PLAYER_SCALE)
end

-- Forward declarations for functions called in playdate.update()
local resetGame
local startGame
local gameOver

local function clamp(x, minValue, maxValue)
    if x < minValue then return minValue end
    if x > maxValue then return maxValue end
    return x
end

local function hasObstacleCollision()
    local smoothHeadX, smoothHeadY = Plant.getSmoothHeadPosition()

    for _, o in ipairs(obstacles) do
        local closestX = clamp(smoothHeadX, o.x, o.x + o.w)
        local closestY = clamp(smoothHeadY, o.y, o.y + o.h)

        local dx = smoothHeadX - closestX
        local dy = smoothHeadY - closestY
        local distanceSquared = (dx * dx) + (dy * dy)

        if distanceSquared < (hitboxRadius * hitboxRadius) then
            return true
        end
    end

    return false
end

function playdate.update()
    gfx.clear()

    if gameState == C.STATE_MENU then
        UI.drawStartMenu(gfx, bestScore)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            startGame()
        end
        return
    end

    if gameState == C.STATE_GAMEOVER then
        UI.drawGameOver(gfx, score, bestScore)

        if playdate.buttonJustPressed(playdate.kButtonA) then
            startGame()
        elseif playdate.buttonJustPressed(playdate.kButtonB) then
            gameState = C.STATE_MENU
        end
        return
    end

    if gameState ~= C.STATE_PLAYING then
        return
    end

    if playdate.buttonJustPressed(playdate.kButtonB) then
        gameState = C.STATE_MENU
        return
    end

    local dt = playdate.getElapsedTime()
    playdate.resetElapsedTime()

    local crankDelta = playdate.getCrankChange()
    local scrollOffset, climbDelta, offscreenLoss = Plant.update(dt, crankDelta)

    updateObstacles(dt, scrollOffset)
    score = score + climbDelta

    if offscreenLoss then
        gameOver()
        return
    end

    Plant.drawStem(gfx)
    UI.drawHUD(gfx, score)
    drawObstacles()
    Plant.drawHead(gfx, playerImage)

    if hasObstacleCollision() then
        gameOver()
        return
    end

    local waterTop = C.SCREEN_HEIGHT - C.WATER_HEIGHT
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(0, waterTop, C.SCREEN_WIDTH, C.WATER_HEIGHT)

    local _, smoothHeadY = Plant.getSmoothHeadPosition()
    if smoothHeadY + hitboxRadius > waterTop then
        gameOver()
        return
    end
end

resetGame = function()
    score = 0
    clearObstacles()
    Plant.reset()
end

startGame = function()
    resetGame()
    gameState = C.STATE_PLAYING
    playdate.resetElapsedTime()
end

gameOver = function()
    gameState = C.STATE_GAMEOVER
    if score > bestScore then
        bestScore = score
    end
end
