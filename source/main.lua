import "CoreLibs/graphics"
import "CoreLibs/crank"

local gfx = playdate.graphics

local W, H = 400, 240

-- Gameplay
local speed = 60            -- px/s : vitesse de croissance
local turnRate = 0.02       -- radians par degré de crank (sensibilité)
local smoothDir = 0.18      -- lissage (0..1), optionnel

-- Courbe / "spline-like"
local minStepDist = 3
local maxPoints = 260

-- Etat
local points = {}
local headX, headY = 200, 200
local dir = -math.pi / 2    -- vers le haut

local function lerp(a, b, t) return a + (b - a) * t end
local function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

points[1] = { x = headX, y = H }    -- base
points[2] = { x = headX, y = headY }

function playdate.update()
    gfx.clear()

    local dt = playdate.getElapsedTime()
    playdate.resetElapsedTime()

    -- 1) Manivelle RELATIVE: delta degrés depuis la dernière frame
    local dDeg = playdate.getCrankChange() -- positif / négatif
    local targetDir = dir + dDeg * turnRate

    -- Option: lissage direction (plus doux)
    dir = lerp(dir, targetDir, smoothDir)

    -- 2) Avancer la tête dans la direction
    local vx = math.cos(dir) * speed
    local vy = math.sin(dir) * speed
    headX = headX + vx * dt
    headY = headY + vy * dt

    -- 3) Clamp écran (proto)
    headX = clamp(headX, 5, W - 5)
    headY = clamp(headY, 5, H - 5)

    -- 4) Ajouter un point si distance suffisante
    local last = points[#points]
    local dx, dy = headX - last.x, headY - last.y
    if (dx*dx + dy*dy) >= (minStepDist * minStepDist) then
        points[#points + 1] = { x = headX, y = headY }
        if #points > maxPoints then
            table.remove(points, 1)
        end
    end

    -- 5) Dessin polyline
    gfx.setLineWidth(3)
    for i = 1, #points - 1 do
        gfx.drawLine(points[i].x, points[i].y, points[i+1].x, points[i+1].y)
    end
    gfx.fillCircleAtPoint(headX, headY, 6)

    -- Debug
    gfx.drawText(string.format("dDeg: %.2f", dDeg), 10, 10)
end
