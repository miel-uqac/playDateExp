import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/crank"
import "obstacles"
import "game_constants"
import "ui"
import "plant"
import "bonus"
import "audio"

local gfx = playdate.graphics
local C = GameConstants

local gameState = C.STATE_MENU

-- Section sur l'enregistrement des scores sur la console
local function saveBestScore(newBest)
    local data = { highscore = newBest }
    playdate.datastore.write(data, "saveData")
end

local function loadBestScore()
    local data = playdate.datastore.read("saveData")
    if data and data.highscore then
        return data.highscore
    end
    return 0
end

-- Score variables
local score = 0
local bestScore = loadBestScore()

-- Player visuals and collision
local playerImage = nil
local hitboxRadius = C.PLAYER_HITBOX_RADIUS

local loadedImage = gfx.image.new(C.PLAYER_IMAGE_PATH)
if loadedImage then
    playerImage = loadedImage:scaledImage(C.PLAYER_SCALE)
end

local backgroundImage = nil
local backgroundImageWidth = 0
local backgroundImageHeight = 0
local backgroundClouds = {}
local cloudSpawnAccumulator = 0

local loadedBackgroundImage = gfx.image.new(C.BACKGROUND_IMAGE_PATH)
if loadedBackgroundImage then
    backgroundImage = loadedBackgroundImage:scaledImage(C.BACKGROUND_IMAGE_SCALE)
    backgroundImageWidth, backgroundImageHeight = backgroundImage:getSize()
end

-- Pour le background
local bgScrollY = 0

local function randomBackgroundCloudY()
    return math.random(-backgroundImageHeight, C.SCREEN_HEIGHT - backgroundImageHeight)
end

local function randomBackgroundCloudX()
    return math.random(-backgroundImageWidth, C.SCREEN_WIDTH - backgroundImageWidth)
end

local function cloudsOverlap(x1, y1, x2, y2)
    local margin = C.BG_CLOUD_MARGIN
    return not (
        x1 + backgroundImageWidth + margin < x2 or
        x2 + backgroundImageWidth + margin < x1 or
        y1 + backgroundImageHeight + margin < y2 or
        y2 + backgroundImageHeight + margin < y1
    )
end

local function buildBackgroundCloudSlots(minY, maxY)
    local slots = {}
    local stepX = backgroundImageWidth + (C.BG_CLOUD_MARGIN * 2)
    local stepY = backgroundImageHeight + (C.BG_CLOUD_MARGIN * 2)
    local yMin = minY or (-backgroundImageHeight)
    local yMax = maxY or (C.SCREEN_HEIGHT - backgroundImageHeight)

    for y = yMin, yMax, stepY do
        for x = -backgroundImageWidth, C.SCREEN_WIDTH, stepX do
            slots[#slots + 1] = { x = x, y = y }
        end
    end

    for i = #slots, 2, -1 do
        local j = math.random(i)
        slots[i], slots[j] = slots[j], slots[i]
    end

    return slots
end

local function placeBackgroundCloud(cloud, minY, maxY)
    local slots = buildBackgroundCloudSlots(minY, maxY)

    for _, slot in ipairs(slots) do
        local overlaps = false

        for _, otherCloud in ipairs(backgroundClouds) do
            if otherCloud ~= cloud and cloudsOverlap(slot.x, slot.y, otherCloud.x, otherCloud.y) then
                overlaps = true
                break
            end
        end

        if not overlaps then
            cloud.x = slot.x
            cloud.y = slot.y
            return true
        end
    end

    return false
end

local function resetBackgroundClouds()
    backgroundClouds = {}

    if not backgroundImage then
        return
    end

    local cloudCount = math.random(C.BG_CLOUD_COUNT_MIN, C.BG_CLOUD_COUNT_MAX)
    for i = 1, cloudCount do
        local cloud = {}
        backgroundClouds[i] = cloud
        placeBackgroundCloud(cloud)
        cloud.speed = 0.7 + (math.random() * 0.6)
    end
end

local function respawnBackgroundCloud(cloud)
    local placed = placeBackgroundCloud(cloud, -backgroundImageHeight * 4, -backgroundImageHeight)
    if not placed then
        cloud.x = randomBackgroundCloudX()
        cloud.y = math.random(-backgroundImageHeight * 4, -backgroundImageHeight)
    end
    cloud.speed = 0.7 + (math.random() * 0.6)
end

local function spawnCloudFromTop()
    if #backgroundClouds >= C.BG_CLOUD_HARD_CAP then
        return
    end

    local cloud = {}
    backgroundClouds[#backgroundClouds + 1] = cloud

    respawnBackgroundCloud(cloud)
end

--Pour l'audio
Audio.load()

-- Pour les bonus
local activeBonuses = {}
local bonusEffect = nil
local nextBonusScore = 800
local scoreMultiplier = 1


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
        local collisionActive = true
        if o.canCollide and not o:canCollide() then
            collisionActive = false
        end

        if collisionActive then
            local closestX = clamp(smoothHeadX, o.x, o.x + o.w)
            local closestY = clamp(smoothHeadY, o.y, o.y + o.h)

            local dx = smoothHeadX - closestX
            local dy = smoothHeadY - closestY
            local distanceSquared = (dx * dx) + (dy * dy)

            if distanceSquared < (hitboxRadius * hitboxRadius) then
                return true
            end
        end
    end

    return false
end

local function updateBonuses(dt, scrollOffset)
    local px, py = Plant.getSmoothHeadPosition()
    for i = #activeBonuses, 1, -1 do
        local b = activeBonuses[i]
        b:update(dt, scrollOffset)
        if not b.collected and b:checkCollision(px, py, hitboxRadius) then
            b.collected = true
            local effect = b:onCollect()
            if effect then
                bonusEffect = { type = effect.type, multiplier = effect.multiplier, timer = effect.duration }
                scoreMultiplier = effect.multiplier
            end
        end

        if b.collected or b:isOffscreen() then
            table.remove(activeBonuses, i)
        end
    end
    if bonusEffect then
        bonusEffect.timer = bonusEffect.timer - dt
        if bonusEffect.timer <= 0 then
            bonusEffect = nil
            scoreMultiplier = 1
        end
    end
end

local function drawBonuses(gfx)
    for _, b in ipairs(activeBonuses) do
        b:draw(gfx)
    end
end

local function trySpawnBonus()
    if score >= nextBonusScore then
        nextBonusScore = nextBonusScore + C.BONUS_SPAWN_INTERVAL
        local x = math.random(20, C.SCREEN_WIDTH - 20)
        table.insert(activeBonuses, ScoreBonus.new(x, -20))
    end
end

function playdate.update()
    gfx.clear()

    if gameState == C.STATE_MENU then
        Audio.playMenuMusic()
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

    if backgroundImage then
        if climbDelta > 0 then
            cloudSpawnAccumulator = cloudSpawnAccumulator + climbDelta
            while cloudSpawnAccumulator >= C.BG_CLOUD_SPAWN_CLIMB do
                cloudSpawnAccumulator = cloudSpawnAccumulator - C.BG_CLOUD_SPAWN_CLIMB
                spawnCloudFromTop()
            end
        end

        bgScrollY = bgScrollY + (scrollOffset * C.BG_PARALLAX_SPEED)

        for i = 1, #backgroundClouds do
            local cloud = backgroundClouds[i]
            cloud.y = cloud.y + (scrollOffset * C.BG_PARALLAX_SPEED * cloud.speed)

            if cloud.y < -backgroundImageHeight - 20 or cloud.y > C.SCREEN_HEIGHT + 20 then
                respawnBackgroundCloud(cloud)
            end

            backgroundImage:draw(cloud.x, cloud.y + C.BG_VERTICAL_OFFSET)
        end
    end

    updateObstacles(dt, scrollOffset)
    score = score + (climbDelta * scoreMultiplier)

    if offscreenLoss then
        gameOver()
        return
    end
    
    Plant.drawStem(gfx)
    --Plant.drawLeaves(gfx)
    UI.drawHUD(gfx, score, bonusEffect)
    drawObstacles()
    Plant.drawHead(gfx, playerImage)

    trySpawnBonus()
    updateBonuses(dt, scrollOffset)
    drawBonuses(gfx)

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
    cloudSpawnAccumulator = 0
    resetBackgroundClouds()
    activeBonuses = {}
    bonusEffect = nil
    scoreMultiplier = 1
    nextBonusScore = C.BONUS_SPAWN_INTERVAL
end

startGame = function()
    resetGame()
    gameState = C.STATE_PLAYING
    playdate.resetElapsedTime()
    Audio.playGameMusic()
end

gameOver = function()
    gameState = C.STATE_GAMEOVER
    if score > bestScore then
        bestScore = score
        saveBestScore(bestScore)
    end
    Audio.playGameOver()
end

-- Pour enregistrer quand on quitte le jeu
function playdate.gameWillTerminate()
    saveBestScore(bestScore)
end

function playdate.deviceWillSleep()
    saveBestScore(bestScore)
end
