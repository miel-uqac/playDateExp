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

-- Couche 0 : montagnes (fixe)
local mountainImage = nil
local loadedMountain = gfx.image.new(C.BG_MOUNTAINS_PATH)
if loadedMountain then
    mountainImage = loadedMountain:scaledImage(C.BG_MOUNTAINS_SCALE)
end

-- Main menu background
local menuBackgroundImage = gfx.image.new(C.BG_MENU_PATH)
local menuTitleImage = gfx.image.new(C.BG_MENU_TITLE_PATH)
local menuCloudTopLeftImage = gfx.image.new("assets/Background/MoyenCloud2")
local menuCloudTopRightImage = gfx.image.new("assets/Background/MoyenCloud2")
local menuCloudYOffset = 12
local menuRightCloudYOffset = 95

-- Fonction générique pour initialiser une couche de parallax
local function createParallaxLayer(config)
    local layer = {
        images = {},
        clouds = {},
        spawnAccumulator = 0,
        config = config,
        imageWidth = 0,
        imageHeight = 0,
    }

    for _, path in ipairs(config.imagePaths) do
        local loaded = gfx.image.new(path)
        if loaded then
            local scaled = loaded:scaledImage(config.scale)
            table.insert(layer.images, scaled)
        end
    end

    if #layer.images > 0 then
        layer.imageWidth, layer.imageHeight = layer.images[1]:getSize()
    end

    return layer
end

local layer1 = createParallaxLayer({
    imagePaths = C.BG_LAYER1_IMAGES,
    scale = C.BG_LAYER1_SCALE,
    parallaxSpeed = C.BG_LAYER1_PARALLAX_SPEED,
    margin = C.BG_LAYER1_MARGIN,
    countMin = C.BG_LAYER1_COUNT_MIN,
    countMax = C.BG_LAYER1_COUNT_MAX,
    hardCap = C.BG_LAYER1_HARD_CAP,
    spawnClimb = C.BG_LAYER1_SPAWN_CLIMB,
})

-- Fonctions de gestion des couches parallax
local function layerCloudsOverlap(layer, x1, y1, x2, y2)
    local w = layer.imageWidth
    local h = layer.imageHeight
    local margin = layer.config.margin
    return not (
        x1 + w + margin < x2 or x2 + w + margin < x1 or
        y1 + h + margin < y2 or y2 + h + margin < y1
    )
end

local function buildLayerSlots(layer, minY, maxY)
    local slots = {}
    local stepX = layer.imageWidth + layer.config.margin * 2
    local stepY = layer.imageHeight + layer.config.margin * 2
    local yMin = minY or (-layer.imageHeight)
    local yMax = maxY or (C.SCREEN_HEIGHT - layer.imageHeight)

    for y = yMin, yMax, stepY do
        for x = -layer.imageWidth, C.SCREEN_WIDTH, stepX do
            slots[#slots + 1] = { x = x, y = y }
        end
    end

    for i = #slots, 2, -1 do
        local j = math.random(i)
        slots[i], slots[j] = slots[j], slots[i]
    end

    return slots
end

local function placeLayerCloud(layer, cloud, minY, maxY)
    local slots = buildLayerSlots(layer, minY, maxY)
    for _, slot in ipairs(slots) do
        local overlaps = false
        for _, other in ipairs(layer.clouds) do
            if other ~= cloud and layerCloudsOverlap(layer, slot.x, slot.y, other.x, other.y) then
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

local function respawnLayerCloud(layer, cloud)
    local h = layer.imageHeight
    local placed = placeLayerCloud(layer, cloud, -h * 4, -h)
    if not placed then
        cloud.x = math.random(-layer.imageWidth, C.SCREEN_WIDTH - layer.imageWidth)
        cloud.y = math.random(-h * 4, -h)
    end
    cloud.speed = 0.7 + math.random() * 0.6
    cloud.imageIndex = math.random(#layer.images)
end

local function resetLayer(layer)
    layer.clouds = {}
    layer.spawnAccumulator = 0
    if #layer.images == 0 then return end

    local count = math.random(layer.config.countMin, layer.config.countMax)
    for i = 1, count do
        local cloud = {}
        layer.clouds[i] = cloud
        local placed = placeLayerCloud(layer, cloud)
        if not placed then
            cloud.x = math.random(-layer.imageWidth, C.SCREEN_WIDTH - layer.imageWidth)
            cloud.y = math.random(-layer.imageHeight, C.SCREEN_HEIGHT - layer.imageHeight)
        end
        cloud.speed = 0.7 + math.random() * 0.6
        cloud.imageIndex = math.random(#layer.images)
    end
end

local function spawnLayerCloudFromTop(layer)
    if #layer.clouds >= layer.config.hardCap then return end
    local cloud = {}
    layer.clouds[#layer.clouds + 1] = cloud
    respawnLayerCloud(layer, cloud)
end

local function updateAndDrawLayer(layer, scrollOffset, climbDelta)
    if #layer.images == 0 then return end

    if climbDelta > 0 then
        layer.spawnAccumulator = layer.spawnAccumulator + climbDelta
        while layer.spawnAccumulator >= layer.config.spawnClimb do
            layer.spawnAccumulator = layer.spawnAccumulator - layer.config.spawnClimb
            spawnLayerCloudFromTop(layer)
        end
    end

    local h = layer.imageHeight
    for i = 1, #layer.clouds do
        local cloud = layer.clouds[i]
        if cloud.x and cloud.y and cloud.speed then
            cloud.y = cloud.y + (scrollOffset * layer.config.parallaxSpeed * cloud.speed)

            if cloud.y < -h - 20 or cloud.y > C.SCREEN_HEIGHT + 20 then
                respawnLayerCloud(layer, cloud)
            end

            local img = layer.images[cloud.imageIndex or 1]
            if img then
                img:draw(cloud.x, cloud.y)
            end
        end
    end
end

-- Pour l'audio
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
            if o.radius then
                local dx = smoothHeadX - o.centerX
                local dy = smoothHeadY - o.centerY
                local distanceSquared = dx * dx + dy * dy
                local combinedRadius = hitboxRadius + o.radius
                if distanceSquared < combinedRadius * combinedRadius then
                    return true
                end
            else
                local closestX = clamp(smoothHeadX, o.x, o.x + o.w)
                local closestY = clamp(smoothHeadY, o.y, o.y + o.h)
                local dx = smoothHeadX - closestX
                local dy = smoothHeadY - closestY
                local distanceSquared = dx * dx + dy * dy
                if distanceSquared < hitboxRadius * hitboxRadius then
                    return true
                end
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
        if menuBackgroundImage then
            menuBackgroundImage:draw(0, 0)
        else
            gfx.clear()
        end
        if menuCloudTopLeftImage then
            menuCloudTopLeftImage:draw(0, menuCloudYOffset)
        end
        if menuCloudTopRightImage then
            local rightCloudWidth = menuCloudTopRightImage:getSize()
            local rightCloudX = C.SCREEN_WIDTH - rightCloudWidth
            menuCloudTopRightImage:draw(rightCloudX, menuRightCloudYOffset)
        end
        if menuTitleImage then
            local titleWidth = menuTitleImage:getSize()
            local titleX = math.floor((C.SCREEN_WIDTH - titleWidth) / 2)
            local titleY = 0
            menuTitleImage:draw(titleX, titleY)
        end
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

    if mountainImage then
        mountainImage:draw(0, 0)
    end
    updateAndDrawLayer(layer1, scrollOffset, climbDelta)

    updateObstacles(dt, scrollOffset, score)
    score = score + (climbDelta * scoreMultiplier)

    if offscreenLoss then
        gameOver()
        return
    end

    Plant.drawStem(gfx)
    Plant.drawLeaves(gfx)
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
    UI.resetHUDLayout()
    clearObstacles()
    Plant.reset()
    resetLayer(layer1)
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
