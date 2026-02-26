import "CoreLibs/graphics"
import "CoreLibs/crank"
import "obstacles"

local gfx = playdate.graphics

-- =========================
-- ETATS DU JEU
-- =========================
local STATE_MENU = 0
local STATE_PLAYING = 1
local gameState = STATE_MENU

local W, H = 400, 240

-- =========================
-- Paramètres visuels (fleur)
-- =========================
local scale = 0.08
local playerImage = nil

local loadedImage = gfx.image.new("assets/Fleur")
if loadedImage then
    playerImage = loadedImage:scaledImage(scale)
end

-- =========================
-- Gameplay
-- =========================
local speed = 60          -- px/s
local turnRate = 0.02     -- sensibilité manivelle
local smoothDir = 0.18    -- lissage direction
local scrollSpeed = 28    -- vitesse de scrolling
local waterY = H + 50
local waterSpeed = 40     -- Vitesse de l'eau

-- Courbe
local minStepDist = 3
local maxPoints = 260
local pathSmooth = 0.25   -- lissage du tracé

-- =========================
-- Etat plante
-- =========================
local points = {}
local headX, headY = 200, 200
local smoothHeadX, smoothHeadY = 200, 200
local dir = -math.pi / 2 -- vers le haut

-- =========================
-- Utils
-- =========================
local function lerp(a, b, t)
    return a + (b - a) * t
end

local function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

-- =========================
-- Reset plante
-- =========================
local function resetPlant()
    points = {}

    headX, headY = 200, 200
    smoothHeadX, smoothHeadY = headX, headY
    dir = -math.pi / 2

    -- Base + premier segment
    points[1] = { x = headX, y = H }
    points[2] = { x = headX, y = headY }
end

-- IMPORTANT : on reset APRÈS la définition
resetPlant()

local function drawStemSegment(x1, y1, x2, y2, radius)
    -- Dessine une "capsule" simple : plein de petits cercles entre 2 points
    local dx = x2 - x1
    local dy = y2 - y1
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist < 0.001 then
        gfx.fillCircleAtPoint(math.floor(x1 + 0.5), math.floor(y1 + 0.5), radius)
        return
    end

    -- Pas entre les cercles (plus petit = plus lisse mais plus coûteux)
    local step = math.max(1, radius * 0.8)
    local steps = math.max(1, math.floor(dist / step))

    for s = 0, steps do
        local t = s / steps
        local x = x1 + dx * t
        local y = y1 + dy * t
        gfx.fillCircleAtPoint(math.floor(x + 0.5), math.floor(y + 0.5), radius)
    end
end

local function drawPlant(points)
    -- Tige organique (plus joli qu'une simple ligne sur écran 1-bit)
    local stemRadius = 2   -- essaie 2 ou 3 selon le rendu voulu

    for i = 1, #points - 1 do
        local p1 = points[i]
        local p2 = points[i + 1]
        drawStemSegment(p1.x, p1.y, p2.x, p2.y, stemRadius)
    end
end

-- =========================
-- Update principal
-- =========================
function playdate.update()
    gfx.clear()

    -- -------- MENU --------
    if gameState == STATE_MENU then
        gfx.drawTextAligned("Appuie sur A pour commencer", W / 2, 100, kTextAlignment.center)

        if playdate.buttonJustPressed(playdate.kButtonA) then
            resetPlant()
            gameState = STATE_PLAYING
            playdate.resetElapsedTime() -- évite le gros saut de dt
        end
        return
    end

    -- -------- JEU --------
    if gameState == STATE_PLAYING then
        -- Retour menu 
        if playdate.buttonJustPressed(playdate.kButtonB) then
            gameState = STATE_MENU
            return
        end

        local dt = playdate.getElapsedTime()
        playdate.resetElapsedTime()

        -- 0) SCROLLING (Appliqué avant le mouvement)
        local scrollOffset = scrollSpeed * dt
        for i = 1, #points do
            points[i].y = points[i].y + scrollOffset
        end

        updateObstacles(dt, scrollOffset)
        
        -- On fait descendre la tête pour suivre le scroll
        headY = headY + scrollOffset
        smoothHeadY = smoothHeadY + scrollOffset

        -- 1) Manivelle (rotation relative)
        local dDeg = playdate.getCrankChange()
        local targetDir = dir + dDeg * turnRate
        dir = lerp(dir, targetDir, smoothDir)

        -- 2) Mouvement de la tête
        local vx = math.cos(dir) * speed
        local vy = math.sin(dir) * speed

        headX = headX + vx * dt
        headY = headY + vy * dt

        -- Clamp de la vraie tête (Modifié pour le scrolling)
        headX = clamp(headX, 5, W - 5)
        -- On ne clamp plus le bas (H-5) pour permettre de perdre si l'eau nous rattrape
        headY = clamp(headY, 10, H + 100)

        -- Condition de défaite si la plante sort par le bas
        if headY > H then
            gameState = STATE_MENU
        end

        -- Lissage visuel
        smoothHeadX = smoothHeadX + (headX - smoothHeadX) * pathSmooth
        smoothHeadY = smoothHeadY + (headY - smoothHeadY) * pathSmooth

        -- Clamp visuel
        smoothHeadX = clamp(smoothHeadX, 5, W - 5)

        -- 3) Ajouter des points si distance suffisante
        local last = points[#points]
        if last then
            local dx = smoothHeadX - last.x
            local dy = smoothHeadY - last.y
            if (dx * dx + dy * dy) >= (minStepDist * minStepDist) then
                points[#points + 1] = { x = smoothHeadX, y = smoothHeadY }

                -- Nettoyage des points (maxPoints ou sortie d'écran)
                if #points > maxPoints or (points[1] and points[1].y > H + 50) then
                    table.remove(points, 1)
                end
            end
        end

        -- 4) Dessin de la plante
        drawPlant(points)
        drawObstacles()
        
        -- 5) Fleur / tête
        if playerImage then
            playerImage:drawCentered(smoothHeadX, smoothHeadY)
        else
            gfx.fillCircleAtPoint(math.floor(smoothHeadX + 0.5), math.floor(smoothHeadY + 0.5), 6)
        end

        -- DETECTION DE COLLISION OBSTACLES
        for _, o in ipairs(obstacles) do
            -- Vérifie si le point (smoothHeadX, smoothHeadY) est à l'intérieur du rectangle de l'obstacle
            if smoothHeadX > o.x and smoothHeadX < o.x + o.w and
                smoothHeadY > o.y and smoothHeadY < o.y + o.h then
                gameState = STATE_MENU -- GAME OVER
            end
        end

        -- 6) L'EAU (Rectangle fixe de 20px en bas)
        local waterHeight = 20
        local waterTop = H - waterHeight
        
        gfx.fillRect(0, waterTop, W, waterHeight)

        -- 7) DETECTION DE COLLISION AVEC L'EAU
        -- Si le bas de la fleur (y + environ 5px de rayon) touche le haut de l'eau
        if smoothHeadY + 5 > waterTop then
            gameState = STATE_MENU
        end

        -- Debug
        gfx.drawText(string.format("dDeg: %.2f", dDeg), 10, 10)
        gfx.drawText("B: menu", 10, 24)
    end
end