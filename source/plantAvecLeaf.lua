import "game_constants"

-- Variante legacy de Plant avec des feuilles rotatives.
-- Ce fichier reste dans le dépôt comme référence, mais il n'est pas branché dans main.lua.

Plant = {}

local Config = GameConstants
local graphics <const> = playdate.graphics

local stemPoints = {}
local rotatingLeaves = {}
local plantHeadX, plantHeadY = Config.SCREEN_WIDTH / 2, 200
local smoothedHeadX, smoothedHeadY = Config.SCREEN_WIDTH / 2, 200
local growthDirection = -math.pi / 2
local spawnSide = 1
local elapsedTime = 0
local leafSprite = nil

local loadedLeaf = graphics.image.new(Config.LEAF_IMAGE_PATH)
if loadedLeaf then
    leafSprite = loadedLeaf
    print("Image feuille chargee !")
else
    print("Erreur : Impossible de charger la feuille a : " .. Config.LEAF_IMAGE_PATH)
end

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

local function spawnLeafIfNeeded(x, y)
    if math.random(Config.LEAF_SPAWN_CHANCE) == 1 then
        local baseAngle = spawnSide == 1 and (math.pi / 2) or (-math.pi / 2)
        local leaf = {
            x = x,
            y = y,
            side = spawnSide,
            baseAngle = baseAngle,
            timeOffset = math.random() * math.pi * 2,
        }
        table.insert(rotatingLeaves, leaf)
        spawnSide = -spawnSide
    end
end

local function appendStemPointIfNeeded()
    local last = stemPoints[#stemPoints]
    if not last then return end

    local dx = smoothedHeadX - last.x
    local dy = smoothedHeadY - last.y

    if (dx * dx + dy * dy) >= (Config.MIN_STEP_DISTANCE * Config.MIN_STEP_DISTANCE) then
        stemPoints[#stemPoints + 1] = { x = smoothedHeadX, y = smoothedHeadY }
        spawnLeafIfNeeded(smoothedHeadX, smoothedHeadY)

        if #stemPoints > Config.MAX_STEM_POINTS or (stemPoints[1] and stemPoints[1].y > Config.SCREEN_HEIGHT + 50) then
            table.remove(stemPoints, 1)
        end
    end
end

function Plant.reset()
    stemPoints = {}
    rotatingLeaves = {}
    spawnSide = 1
    elapsedTime = 0
    plantHeadX, plantHeadY = Config.SCREEN_WIDTH / 2, 200
    smoothedHeadX, smoothedHeadY = plantHeadX, plantHeadY
    growthDirection = -math.pi / 2

    stemPoints[1] = { x = plantHeadX, y = Config.SCREEN_HEIGHT }
    stemPoints[2] = { x = plantHeadX, y = plantHeadY }
end

function Plant.update(deltaTime, crankDelta)
    elapsedTime = elapsedTime + deltaTime
    local previousHeadY = plantHeadY
    local scrollOffset = Config.SCROLL_SPEED * deltaTime

    for i = 1, #stemPoints do
        stemPoints[i].y = stemPoints[i].y + scrollOffset
    end

    -- Nettoie les feuilles qui ont quitté l'écran.
    for i = #rotatingLeaves, 1, -1 do
        rotatingLeaves[i].y = rotatingLeaves[i].y + scrollOffset
        if rotatingLeaves[i].y > Config.SCREEN_HEIGHT + 20 then
            table.remove(rotatingLeaves, i)
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
    if not leafSprite then return end

    for _, leaf in ipairs(rotatingLeaves) do
        local oscillation = math.sin(elapsedTime * Config.LEAF_OSCILLATION_SPEED + leaf.timeOffset)
                            * Config.LEAF_OSCILLATION_AMOUNT
        local angle = leaf.baseAngle + oscillation

        graphics.pushContext()
            graphics.setDrawOffset(math.floor(leaf.x + 0.5), math.floor(leaf.y + 0.5))
            leafSprite:drawRotated(0, 0, math.deg(angle))
        graphics.popContext()
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