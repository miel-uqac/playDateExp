import "CoreLibs/graphics"
import "CoreLibs/crank"

local gfx = playdate.graphics

-- ETATS DU JEU
local STATE_MENU = 0
local STATE_PLAYING = 1
local gameState = STATE_MENU -- On commence par le menu

-- Paramètres de l'image
local scale = 0.08
local playerImage = nil

local loadedImage = gfx.image.new("assets/Fleur")
if loadedImage then
    playerImage = loadedImage:scaledImage(scale)
end

local W, H = 400, 240

-- Gameplay (Code de ton collègue)
local speed = 60            -- px/s
local turnRate = 0.02       
local smoothDir = 0.18      

-- Courbe
local minStepDist = 3
local maxPoints = 260

-- Etat
local points = {}
local headX, headY = 200, 200
local dir = -math.pi / 2    

local function lerp(a, b, t) return a + (b - a) * t end
local function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

-- Initialisation de la base
points[1] = { x = headX, y = H }    
points[2] = { x = headX, y = headY }


function playdate.update()
    gfx.clear()

    -- --- LOGIQUE DU MENU ---
    if gameState == STATE_MENU then
        
        -- Affichage simple du menu
        gfx.drawTextAligned("Appuie sur *A* pour commencer", 200, 100, kTextAlignment.center)
        
        -- Si on appuie sur A, on lance le jeu
        if playdate.buttonJustPressed(playdate.kButtonA) then
            gameState = STATE_PLAYING
            playdate.resetElapsedTime() -- Très important pour que la plante ne fasse pas un bond géant
        end

    -- --- LOGIQUE DU JEU (Code de ton collègue conservé) ---
    elseif gameState == STATE_PLAYING then

        local dt = playdate.getElapsedTime()
        playdate.resetElapsedTime()

        -- 1) Manivelle
        local dDeg = playdate.getCrankChange() 
        local targetDir = dir + dDeg * turnRate
        dir = lerp(dir, targetDir, smoothDir)

        -- 2) Mouvement
        local vx = math.cos(dir) * speed
        local vy = math.sin(dir) * speed
        headX = headX + vx * dt
        headY = headY + vy * dt

        -- 3) Clamp
        headX = clamp(headX, 5, W - 5)
        headY = clamp(headY, 5, H - 5)

        -- 4) Logique des points
        local last = points[#points]
        local dx, dy = headX - last.x, headY - last.y
        if (dx*dx + dy*dy) >= (minStepDist * minStepDist) then
            points[#points + 1] = { x = headX, y = headY }
            if #points > maxPoints then
                table.remove(points, 1)
            end
        end

        -- 5) DESSIN
        -- Dessin de la ligne
        gfx.setLineWidth(3)
        for i = 1, #points - 1 do
            gfx.drawLine(points[i].x, points[i].y, points[i+1].x, points[i+1].y)
        end

        -- DESSIN DE L'IMAGE AU BOUT
        if playerImage then
            playerImage:drawCentered(headX, headY)
        else
            gfx.fillCircleAtPoint(headX, headY, 6)
        end

        -- Debug (optionnel, tu peux l'enlever pour que ce soit plus joli)
        gfx.drawText(string.format("dDeg: %.2f", dDeg), 10, 10)
    end
end