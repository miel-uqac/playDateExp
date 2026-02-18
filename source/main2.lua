import "CoreLibs/graphics"
import "CoreLibs/crank"

local gfx = playdate.graphics

local W, H = 400, 240

-- Paramètres
local speed = 60                  -- pixels/seconde (vitesse de croissance)
local minStepDist = 3             -- distance min entre deux points (évite trop de points)
local maxPoints = 250             -- limite mémoire / perf
local smoothDir = 0.15            -- lissage direction (0..1)

-- Plante = liste de points
local points = {}

-- Position actuelle de la tête
local headX, headY = 200, 200

-- Direction actuelle (en radians)
--  -pi/2 = vers le haut
local dir = -math.pi / 2

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

-- Init : point de base + tête
points[1] = {x = headX, y = H}     -- base “au sol”
points[2] = {x = headX, y = headY}

function playdate.update()
    gfx.clear()

    -- dt
    local dt = playdate.getElapsedTime()
    playdate.resetElapsedTime()

    -- 1) Manivelle -> direction
    -- On mappe 0..360° -> -180..+180° autour du "haut"
    -- Exemple: 0° = vers le haut, 90° = vers la droite, 180° = vers le bas, 270° = vers la gauche
    local crankDeg = playdate.getCrankPosition() -- peut être float
    local targetDeg = crankDeg
    local targetRad = math.rad(targetDeg) - math.pi/2

    -- 2) Lissage direction (évite les snaps)
    dir = lerp(dir, targetRad, smoothDir)

    -- 3) Avancer la tête
    local vx = math.cos(dir) * speed
    local vy = math.sin(dir) * speed

    headX = headX + vx * dt
    headY = headY + vy * dt

    -- 4) Clamp écran (pour proto)
    headX = clamp(headX, 5, W - 5)
    headY = clamp(headY, 5, H - 5)

    -- 5) Ajouter un point si on a avancé assez
    local last = points[#points]
    local dx = headX - last.x
    local dy = headY - last.y
    local dist2 = dx*dx + dy*dy

    if dist2 >= (minStepDist * minStepDist) then
        points[#points + 1] = {x = headX, y = headY}

        -- limiter le nombre de points
        if #points > maxPoints then
            table.remove(points, 1)
        end
    end

    -- 6) Dessiner la plante (polyline)
    gfx.setLineWidth(3)
    for i = 1, #points - 1 do
        gfx.drawLine(points[i].x, points[i].y, points[i+1].x, points[i+1].y)
    end

    -- “fleur” / tête
    gfx.fillCircleAtPoint(headX, headY, 6)

    -- debug léger
    gfx.drawText(string.format("points: %d", #points), 10, 10)
end
