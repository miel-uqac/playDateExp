import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/crank"
import "obstacles"
import "game_constants"
import "ui"
import "plant"
import "bonus"
import "audio"

local graphics = playdate.graphics
local Config = GameConstants

local textFont = graphics.font.new("assets/Fonts/robkohr-mono-10x16")
if textFont then
    graphics.setFont(textFont)
else
    print("Erreur : Impossible de charger la police robkohr-mono-10x16")
end

local gameState = Config.STATE_MENU

-- Sauvegarde simple du meilleur score dans le stockage local de la console.
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

local score = 0
local bestScore = loadBestScore()

local playerImage = nil
local playerCollisionRadius = Config.PLAYER_HITBOX_RADIUS

local loadedImage = graphics.image.new(Config.PLAYER_IMAGE_PATH)
if loadedImage then
    playerImage = loadedImage:scaledImage(Config.PLAYER_SCALE)
end

local mountainImage = nil
local loadedMountain = graphics.image.new(Config.BG_MOUNTAINS_PATH)
if loadedMountain then
    mountainImage = loadedMountain:scaledImage(Config.BG_MOUNTAINS_SCALE)
end

-- Fond du menu principal.
local menuBackgroundImage = graphics.image.new(Config.BG_MENU_PATH)
local menuTitleImage = graphics.image.new(Config.BG_MENU_TITLE_PATH)
local menuLeftCloudImage = graphics.image.new(Config.BG_MENU_CLOUD_PATH)
local menuRightCloudImage = graphics.image.new(Config.BG_MENU_CLOUD_PATH)
local menuLeftCloudY = Config.MENU_CLOUD_LEFT_Y
local menuRightCloudY = Config.MENU_CLOUD_RIGHT_Y

-- Construit une couche de parallaxe avec plusieurs images réutilisables.
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
        local loaded = graphics.image.new(path)
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

local foregroundCloudLayer = createParallaxLayer({
    imagePaths = Config.BG_LAYER1_IMAGES,
    scale = Config.BG_LAYER1_SCALE,
    parallaxSpeed = Config.BG_LAYER1_PARALLAX_SPEED,
    margin = Config.BG_LAYER1_MARGIN,
    countMin = Config.BG_LAYER1_COUNT_MIN,
    countMax = Config.BG_LAYER1_COUNT_MAX,
    hardCap = Config.BG_LAYER1_HARD_CAP,
    spawnClimb = Config.BG_LAYER1_SPAWN_CLIMB,
})

-- Vérifie si deux nuages se chevauchent dans la même couche.
local function cloudsOverlap(layer, x1, y1, x2, y2)
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
    local yMax = maxY or (Config.SCREEN_HEIGHT - layer.imageHeight)

    for y = yMin, yMax, stepY do
        for x = -layer.imageWidth, Config.SCREEN_WIDTH, stepX do
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
            if other ~= cloud and cloudsOverlap(layer, slot.x, slot.y, other.x, other.y) then
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
        cloud.x = math.random(-layer.imageWidth, Config.SCREEN_WIDTH - layer.imageWidth)
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
            cloud.x = math.random(-layer.imageWidth, Config.SCREEN_WIDTH - layer.imageWidth)
            cloud.y = math.random(-layer.imageHeight, Config.SCREEN_HEIGHT - layer.imageHeight)
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

            if cloud.y < -h - 20 or cloud.y > Config.SCREEN_HEIGHT + 20 then
                respawnLayerCloud(layer, cloud)
            end

            local img = layer.images[cloud.imageIndex or 1]
            if img then
                img:draw(cloud.x, cloud.y)
            end
        end
    end
end

Audio.load()

local activeBonuses = {}
local activeBonusEffect = nil
local nextBonusThreshold = 800
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
                local distanceSquared = dx * dx + dy * dy
                local combinedRadius = playerCollisionRadius + obstacle.radius
                if distanceSquared < combinedRadius * combinedRadius then
                    return true
                end
            else
                local closestX = clamp(playerHeadX, obstacle.x, obstacle.x + obstacle.w)
                local closestY = clamp(playerHeadY, obstacle.y, obstacle.y + obstacle.h)
                local dx = playerHeadX - closestX
                local dy = playerHeadY - closestY
                local distanceSquared = dx * dx + dy * dy
                if distanceSquared < playerCollisionRadius * playerCollisionRadius then
                    return true
                end
            end
        end
    end

    return false
end

local function updateBonuses(deltaTime, scrollOffset)
    local playerHeadX, playerHeadY = Plant.getSmoothHeadPosition()
    for i = #activeBonuses, 1, -1 do
        local bonus = activeBonuses[i]
        bonus:update(deltaTime, scrollOffset)
        if not bonus.collected and bonus:checkCollision(playerHeadX, playerHeadY, playerCollisionRadius) then
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

local function drawBonuses(graphics)
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
        if menuBackgroundImage then
            menuBackgroundImage:draw(0, 0)
        else
            graphics.clear()
        end
        if menuLeftCloudImage then
            menuLeftCloudImage:draw(0, menuLeftCloudY)
        end
        if menuRightCloudImage then
            local rightCloudWidth = menuRightCloudImage:getSize()
            local rightCloudX = Config.SCREEN_WIDTH - rightCloudWidth
            menuRightCloudImage:draw(rightCloudX, menuRightCloudY)
        end
        if menuTitleImage then
            local titleWidth = menuTitleImage:getSize()
            local titleX = math.floor((Config.SCREEN_WIDTH - titleWidth) / 2)
            local titleY = 0
            menuTitleImage:draw(titleX, titleY)
        end
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

    if gameState ~= Config.STATE_PLAYING then
        return
    end

    if playdate.buttonJustPressed(playdate.kButtonB) then
        gameState = Config.STATE_MENU
        return
    end

    local deltaTime = playdate.getElapsedTime()
    playdate.resetElapsedTime()

    local crankDelta = playdate.getCrankChange()
    local scrollOffset, climbDelta, playerWentOffscreen = Plant.update(deltaTime, crankDelta)

    if mountainImage then
        mountainImage:draw(0, 0)
    end
    updateAndDrawLayer(foregroundCloudLayer, scrollOffset, climbDelta)

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
    drawBonuses(graphics)

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
    resetLayer(foregroundCloudLayer)
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
