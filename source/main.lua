import "CoreLibs/graphics"
import "CoreLibs/crank"
import "obstacles"

local gfx = playdate.graphics

-- ETATS DU JEU
local STATE_MENU = 0
local STATE_PLAYING = 1
local gameState = STATE_MENU
local W, H = 400, 240

-- Paramètres visuels (fleur)
local scale = 0.05
local playerImage = nil
local hitboxRadius = 10

local loadedImage = gfx.image.new("assets/Fleur3")
if loadedImage then
    playerImage = loadedImage:scaledImage(scale)
end

local speed = 60          -- px/s
local turnRate = 0.02     -- sensibilité manivelle
local smoothDir = 0.18    -- lissage direction
local scrollSpeed = 28    -- vitesse de scrolling
local minStepDist = 3
local maxPoints = 260     -- Nb de point max pour la tige
local pathSmooth = 0.25   -- lissage du tracé

-- Etat plante
local points = {}
local headX, headY = 200, 200
local smoothHeadX, smoothHeadY = 200, 200
local dir = -math.pi / 2 -- vers le haut

-- Utils
local function lerp(a, b, t)
    return a + (b - a) * t
end

local function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

-- Reset plante
local function resetPlant()
    points = {}
    headX, headY = 200, 200
    smoothHeadX, smoothHeadY = headX, headY
    dir = -math.pi / 2
    
    clearObstacles() -- Indispensable pour vider la table des obstacles !

    points[1] = { x = headX, y = H }
    points[2] = { x = headX, y = headY }
end

resetPlant()

local function drawStemSegment(x1, y1, x2, y2, radius)
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

local function drawPlant(points)
    local stemRadius = 2
    for i = 1, #points - 1 do
        local p1 = points[i]
        local p2 = points[i + 1]
        drawStemSegment(p1.x, p1.y, p2.x, p2.y, stemRadius)
    end
end

function playdate.update()
    gfx.clear()

    if gameState == STATE_MENU then
        gfx.drawTextAligned("Appuie sur A pour commencer", W / 2, 100, kTextAlignment.center)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            resetPlant()
            gameState = STATE_PLAYING
            playdate.resetElapsedTime()
        end
        return
    end

    if gameState == STATE_PLAYING then
        if playdate.buttonJustPressed(playdate.kButtonB) then
            gameState = STATE_MENU
            return
        end

        local dt = playdate.getElapsedTime()
        playdate.resetElapsedTime()

        local scrollOffset = scrollSpeed * dt
        for i = 1, #points do
            points[i].y = points[i].y + scrollOffset
        end
        updateObstacles(dt, scrollOffset)
        
        headY = headY + scrollOffset
        smoothHeadY = smoothHeadY + scrollOffset

        local dDeg = playdate.getCrankChange()
        local targetDir = dir + dDeg * turnRate
        dir = lerp(dir, targetDir, smoothDir)

        local vx = math.cos(dir) * speed
        local vy = math.sin(dir) * speed

        headX = headX + vx * dt
        headY = headY + vy * dt

        headX = clamp(headX, 5, W - 5)
        headY = clamp(headY, 10, H + 100)

        if headY > H then
            gameState = STATE_MENU
        end

        smoothHeadX = smoothHeadX + (headX - smoothHeadX) * pathSmooth
        smoothHeadY = smoothHeadY + (headY - smoothHeadY) * pathSmooth
        smoothHeadX = clamp(smoothHeadX, 5, W - 5)

        local last = points[#points]
        if last then
            local dx = smoothHeadX - last.x
            local dy = smoothHeadY - last.y
            if (dx * dx + dy * dy) >= (minStepDist * minStepDist) then
                points[#points + 1] = { x = smoothHeadX, y = smoothHeadY }
                if #points > maxPoints or (points[1] and points[1].y > H + 50) then
                    table.remove(points, 1)
                end
            end
        end

        drawPlant(points)
        drawObstacles()
        
        if playerImage then
            playerImage:drawCentered(smoothHeadX, smoothHeadY)
        else
            gfx.fillCircleAtPoint(math.floor(smoothHeadX + 0.5), math.floor(smoothHeadY + 0.5), 6)
        end

        -- DETECTION DE COLLISION AMÉLIORÉE (Hitbox Cercle vs Rectangle)
        for _, o in ipairs(obstacles) do
            -- On cherche le point du rectangle le plus proche du centre de la fleur
            local closestX = clamp(smoothHeadX, o.x, o.x + o.w)
            local closestY = clamp(smoothHeadY, o.y, o.y + o.h)
            
            -- On calcule la distance entre le centre de la fleur et ce point proche
            local dx = smoothHeadX - closestX
            local dy = smoothHeadY - closestY
            local distanceSquared = (dx * dx) + (dy * dy)
            
            -- Si la distance est plus petite que le rayon de la fleur, on touche !
            if distanceSquared < (hitboxRadius * hitboxRadius) then
                gameState = STATE_MENU
            end
        end

        local waterHeight = 20
        local waterTop = H - waterHeight
        gfx.fillRect(0, waterTop, W, waterHeight)

        -- Collision Eau (incluant le rayon de la fleur)
        if smoothHeadY + hitboxRadius > waterTop then
            gameState = STATE_MENU
        end
    end
end