-- import "game_constants"

-- ATTENTION !!!!
-- Fichier a remplacer dans Plant pour ajouter les feuilles, quand on aura un asset correct






Plant = {}

local C = GameConstants
local gfx = playdate.graphics

local points = {}
local leaves = {}
local headX, headY = C.SCREEN_WIDTH / 2, 200
local smoothHeadX, smoothHeadY = C.SCREEN_WIDTH / 2, 200
local dir = -math.pi / 2
local leafSide = 1
local totalTime = 0
local leafImage = nil
local loadedLeaf = gfx.image.new(C.LEAF_IMAGE_PATH)
if loadedLeaf then
    leafImage = loadedLeaf
    print("Image feuille chargee !")
else
    print("Erreur : Impossible de charger la feuille a : " .. C.LEAF_IMAGE_PATH)
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function clamp(x, minValue, maxValue)
    if x < minValue then return minValue end
    if x > maxValue then return maxValue end
    return x
end

local function drawStemSegment(gfx, x1, y1, x2, y2, radius)
    local dx = x2 - x1
    local dy = y2 - y1
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist < 0.001 then
        gfx.fillCircleAtPoint(math.floor(x1 + 0.5), math.floor(y1 + 0.5), radius)
        return
    end

    local step = math.max(1, radius * 0.8)
    local steps = math.max(1, math.floor(dist / step))

    for s = 0, steps do
        local t = s / steps
        local x = x1 + dx * t
        local y = y1 + dy * t
        gfx.fillCircleAtPoint(math.floor(x + 0.5), math.floor(y + 0.5), radius)
    end
end

local function trySpawnLeaf(x, y)
    if math.random(C.LEAF_SPAWN_CHANCE) == 1 then
        -- Angle de base perpendiculaire selon le côté
        local baseAngle = leafSide == 1 and (math.pi / 2) or (-math.pi / 2)
        local leaf = {
            x = x,
            y = y,
            side = leafSide,
            baseAngle = baseAngle,
            timeOffset = math.random() * math.pi * 2  -- phase aléatoire pour varier l'oscillation
        }
        table.insert(leaves, leaf)
        leafSide = -leafSide  -- alterne le côté
    end
end

local function updateStemPath()
    local last = points[#points]
    if not last then return end

    local dx = smoothHeadX - last.x
    local dy = smoothHeadY - last.y

    if (dx * dx + dy * dy) >= (C.MIN_STEP_DISTANCE * C.MIN_STEP_DISTANCE) then
        points[#points + 1] = { x = smoothHeadX, y = smoothHeadY }

        -- Tentative de spawn d'une feuille sur ce nouveau point
        trySpawnLeaf(smoothHeadX, smoothHeadY)

        if #points > C.MAX_STEM_POINTS or (points[1] and points[1].y > C.SCREEN_HEIGHT + 50) then
            table.remove(points, 1)
        end
    end
end

function Plant.reset()
    points = {}
    leaves = {}
    leafSide = 1
    totalTime = 0
    headX, headY = C.SCREEN_WIDTH / 2, 200
    smoothHeadX, smoothHeadY = headX, headY
    dir = -math.pi / 2

    points[1] = { x = headX, y = C.SCREEN_HEIGHT }
    points[2] = { x = headX, y = headY }
end

function Plant.update(dt, crankDelta)
    totalTime = totalTime + dt
    local prevHeadY = headY
    local scrollOffset = C.SCROLL_SPEED * dt

    for i = 1, #points do
        points[i].y = points[i].y + scrollOffset
    end

    -- Scroll des feuilles + nettoyage hors écran
    for i = #leaves, 1, -1 do
        leaves[i].y = leaves[i].y + scrollOffset
        if leaves[i].y > C.SCREEN_HEIGHT + 20 then
            table.remove(leaves, i)
        end
    end

    headY = headY + scrollOffset
    smoothHeadY = smoothHeadY + scrollOffset

    local targetDir = dir + crankDelta * C.TURN_RATE
    dir = lerp(dir, targetDir, C.SMOOTH_DIR)

    local vx = math.cos(dir) * C.SPEED
    local vy = math.sin(dir) * C.SPEED

    headX = headX + vx * dt
    headY = headY + vy * dt

    headX = clamp(headX, C.HEAD_CLAMP_X_MARGIN, C.SCREEN_WIDTH - C.HEAD_CLAMP_X_MARGIN)
    headY = clamp(headY, C.HEAD_CLAMP_TOP, C.SCREEN_HEIGHT + C.HEAD_CLAMP_BOTTOM_PADDING)

    local offscreenLoss = headY > C.SCREEN_HEIGHT

    smoothHeadX = smoothHeadX + (headX - smoothHeadX) * C.PATH_SMOOTH
    smoothHeadY = smoothHeadY + (headY - smoothHeadY) * C.PATH_SMOOTH
    smoothHeadX = clamp(smoothHeadX, C.HEAD_CLAMP_X_MARGIN, C.SCREEN_WIDTH - C.HEAD_CLAMP_X_MARGIN)

    updateStemPath()

    local worldDeltaY = (headY - prevHeadY) - scrollOffset
    local climbDelta = 0
    if worldDeltaY < 0 then
        climbDelta = -worldDeltaY
    end

    return scrollOffset, climbDelta, offscreenLoss
end

function Plant.drawStem(gfx)
    for i = 1, #points - 1 do
        local p1 = points[i]
        local p2 = points[i + 1]
        drawStemSegment(gfx, p1.x, p1.y, p2.x, p2.y, C.STEM_RADIUS)
    end
end

function Plant.drawLeaves(gfx)
    if not leafImage then return end

    for _, leaf in ipairs(leaves) do
        -- Angle oscillant autour de l'angle de base
        local oscillation = math.sin(totalTime * C.LEAF_OSCILLATION_SPEED + leaf.timeOffset)
                            * C.LEAF_OSCILLATION_AMOUNT
        local angle = leaf.baseAngle + oscillation

        gfx.pushContext()
            -- Translate au point d'attache, rotate, dessine centré
            gfx.setDrawOffset(math.floor(leaf.x + 0.5), math.floor(leaf.y + 0.5))
            leafImage:drawRotated(0, 0, math.deg(angle))
        gfx.popContext()
    end
end

function Plant.drawHead(gfx, playerImage)
    if playerImage then
        playerImage:drawCentered(smoothHeadX, smoothHeadY)
    else
        gfx.fillCircleAtPoint(math.floor(smoothHeadX + 0.5), math.floor(smoothHeadY + 0.5), 6)
    end
end

function Plant.getSmoothHeadPosition()
    return smoothHeadX, smoothHeadY
end