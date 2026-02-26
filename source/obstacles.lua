local gfx <const> = playdate.graphics

obstacles = {}
local spawnTimer = 0
local spawnInterval = 4000 -- 4 secondes (en millisecondes)

function spawnObstacle(x, y, width, height)
    local obs = {
        x = x,
        y = y,
        w = width,
        h = height,
        type = "fixe"
    }
    table.insert(obstacles, obs)
end

function updateObstacles(dt, scrollOffset)
    -- Gestion du timer d'apparition
    spawnTimer += dt * 1000 -- conversion en ms
    if spawnTimer >= spawnInterval then
        spawnTimer = 0
        -- On crée un obstacle aléatoire en haut de l'écran
        -- Largeur entre 40 et 100, position X aléatoire pour laisser passer la plante
        local w = math.random(40, 100)
        local x = math.random(0, 400 - w)
        spawnObstacle(x, -50, w, 20) 
    end

    -- Mouvement et nettoyage
    for i = #obstacles, 1, -1 do
        local o = obstacles[i]
        o.y = o.y + scrollOffset
        if o.y > 240 then
            table.remove(obstacles, i)
        end
    end
end

function drawObstacles()
    gfx.setColor(gfx.kColorBlack)
    for _, o in ipairs(obstacles) do
        gfx.fillRect(o.x, o.y, o.w, o.h)
    end
end

-- À appeler quand on recommence une partie
function clearObstacles()
    obstacles = {}
    spawnTimer = 0
end