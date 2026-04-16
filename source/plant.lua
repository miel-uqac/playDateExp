import "game_constants"

Plant = {}

local Config = GameConstants
local graphics <const> = playdate.graphics

local stemPoints = {}
local attachedLeaves = {}
local plantHeadX, plantHeadY = Config.SCREEN_WIDTH / 2, 200
local smoothedHeadX, smoothedHeadY = Config.SCREEN_WIDTH / 2, 200
local growthDirection = -math.pi / 2

local leafSprites = {}

local leafSpawnTimer = 0
local LEAF_SPAWN_INTERVAL = 1.0

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function clamp(x, minValue, maxValue)
    if x < minValue then return minValue end
    if x > maxValue then return maxValue end
    return x
end

local function drawStemSegment(graphics, x1, y1, x2, y2, radius)
    local dx = x2 - x1
    local dy = y2 - y1
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist < 0.001 then
        graphics.fillCircleAtPoint(math.floor(x1 + 0.5), math.floor(y1 + 0.5), radius)
        return
    end

    local step = math.max(1, radius * 0.8)
    local steps = math.max(1, math.floor(dist / step))

    for s = 0, steps do
        local t = s / steps
        local x = x1 + dx * t
        local y = y1 + dy * t
        graphics.fillCircleAtPoint(math.floor(x + 0.5), math.floor(y + 0.5), radius)
    end
end

local function getLeafFlipForSpawn(x, y)
    local isLeftSide = x < (Config.SCREEN_WIDTH * 0.5)
    local isBottomSide = y > (Config.SCREEN_HEIGHT * 0.5)

    if isLeftSide and isBottomSide then
        return graphics.kImageFlippedXY
    end
    if isLeftSide then
        return graphics.kImageFlippedX
    end
    if isBottomSide then
        return graphics.kImageFlippedY
    end
    return graphics.kImageUnflipped
end

local function maybeSpawnLeaf(x, y)
    if not leafSprite then
        return
    end

    attachedLeaves[#attachedLeaves + 1] = {
        x = x,
        y = y,
        flip = getLeafFlipForSpawn(x, y),
    }
end

local function appendStemPointIfNeeded()
    local last = stemPoints[#stemPoints]
    if not last then
        return
    end

    local dx = smoothedHeadX - last.x
    local dy = smoothedHeadY - last.y

    if (dx * dx + dy * dy) >= (Config.MIN_STEP_DISTANCE * Config.MIN_STEP_DISTANCE) then
        stemPoints[#stemPoints + 1] = { x = smoothedHeadX, y = smoothedHeadY }
        if leafSpawnTimer >= LEAF_SPAWN_INTERVAL then
            leafSpawnTimer = 0
            
            -- On choisit un index aléatoire parmi les feuilles chargées
            local randomSpriteIndex = 1
            if #leafSprites > 0 then
                randomSpriteIndex = math.random(1, #leafSprites)
            end

            attachedLeaves[#attachedLeaves + 1] = {
                x = smoothedHeadX,
                y = smoothedHeadY,
                flip = getLeafFlipForSpawn(smoothedHeadX, smoothedHeadY),
                spriteIndex = randomSpriteIndex -- On sauvegarde quelle feuille c'est
            }
        end

        if #stemPoints > Config.MAX_STEM_POINTS or (stemPoints[1] and stemPoints[1].y > Config.SCREEN_HEIGHT + 50) then
            table.remove(stemPoints, 1)
        end
    end
end

function Plant.reset()
    stemPoints = {}
    attachedLeaves = {}
    leafSpawnTimer = 0 
    plantHeadX, plantHeadY = Config.SCREEN_WIDTH / 2, 200
    smoothedHeadX, smoothedHeadY = plantHeadX, plantHeadY
    growthDirection = -math.pi / 2

    leafSprites = {}
    if Config.LEAF_IMAGE_PATHS then
        for i, path in ipairs(Config.LEAF_IMAGE_PATHS) do
            local loadedLeaf = graphics.image.new(path)
            if loadedLeaf then
                table.insert(leafSprites, loadedLeaf)
            end
        end
    end

    stemPoints[1] = { x = plantHeadX, y = Config.SCREEN_HEIGHT }
    stemPoints[2] = { x = plantHeadX, y = plantHeadY }
end

function Plant.update(deltaTime, crankDelta)
    local previousHeadY = plantHeadY
    leafSpawnTimer = leafSpawnTimer + deltaTime
    local scrollOffset = Config.SCROLL_SPEED * deltaTime

    for i = 1, #stemPoints do
        stemPoints[i].y = stemPoints[i].y + scrollOffset
    end

    for i = #attachedLeaves, 1, -1 do
        local leaf = attachedLeaves[i]
        leaf.y = leaf.y + scrollOffset
        
        -- On récupère la hauteur de la feuille spécifique
        local h = 0
        if leafSprites[leaf.spriteIndex] then
            h = select(2, leafSprites[leaf.spriteIndex]:getSize())
        end

        if leaf.y - h > Config.SCREEN_HEIGHT + 20 then
            table.remove(attachedLeaves, i)
        end
    end

    plantHeadY = plantHeadY + scrollOffset
    smoothedHeadY = smoothedHeadY + scrollOffset

    local targetDirection = growthDirection + crankDelta * Config.TURN_RATE
    growthDirection = lerp(growthDirection, targetDirection, Config.SMOOTH_DIR)

    local velocityX = math.cos(growthDirection) * Config.SPEED
    local velocityY = math.sin(growthDirection) * Config.SPEED

    plantHeadX = plantHeadX + velocityX * deltaTime
    plantHeadY = plantHeadY + velocityY * deltaTime

    plantHeadX = clamp(plantHeadX, Config.HEAD_CLAMP_X_MARGIN, Config.SCREEN_WIDTH - Config.HEAD_CLAMP_X_MARGIN)
    plantHeadY = clamp(plantHeadY, Config.HEAD_CLAMP_TOP, Config.SCREEN_HEIGHT + Config.HEAD_CLAMP_BOTTOM_PADDING)

    local offscreenLoss = plantHeadY > Config.SCREEN_HEIGHT

    smoothedHeadX = smoothedHeadX + (plantHeadX - smoothedHeadX) * Config.PATH_SMOOTH
    smoothedHeadY = smoothedHeadY + (plantHeadY - smoothedHeadY) * Config.PATH_SMOOTH
    smoothedHeadX = clamp(smoothedHeadX, Config.HEAD_CLAMP_X_MARGIN, Config.SCREEN_WIDTH - Config.HEAD_CLAMP_X_MARGIN)

    appendStemPointIfNeeded()

    local worldDeltaY = (plantHeadY - previousHeadY) - scrollOffset
    local climbDelta = 0
    if worldDeltaY < 0 then
        climbDelta = -worldDeltaY
    end

    return scrollOffset, climbDelta, offscreenLoss
end

function Plant.drawStem(graphics)
    for i = 1, #stemPoints - 1 do
        local pointA = stemPoints[i]
        local pointB = stemPoints[i + 1]
        drawStemSegment(graphics, pointA.x, pointA.y, pointB.x, pointB.y, Config.STEM_RADIUS)
    end
end

function Plant.drawLeaves(graphics)
    if #leafSprites == 0 then
        return
    end

    for i = 1, #attachedLeaves do
        local leaf = attachedLeaves[i]
        local sprite = leafSprites[leaf.spriteIndex]

        if sprite then
            -- On récupère la taille exacte de ce sprite précis
            local w, h = sprite:getSize()
            local drawX = leaf.x
            local drawY = leaf.y - h

            -- On ajuste le point d'ancrage pour que la feuille reste collée à la tige.
            if leaf.flip == graphics.kImageFlippedX or leaf.flip == graphics.kImageFlippedXY then
                drawX = drawX - w + 1
            end
            if leaf.flip == graphics.kImageFlippedY or leaf.flip == graphics.kImageFlippedXY then
                drawY = leaf.y
            end

            sprite:draw(math.floor(drawX + 0.5), math.floor(drawY + 0.5), leaf.flip)
        end
    end
end

function Plant.drawHead(graphics, playerImage)
    if playerImage then
        playerImage:drawCentered(smoothedHeadX, smoothedHeadY)
    else
        graphics.fillCircleAtPoint(math.floor(smoothedHeadX + 0.5), math.floor(smoothedHeadY + 0.5), 6)
    end
end

function Plant.getSmoothHeadPosition()
    return smoothedHeadX, smoothedHeadY
end
