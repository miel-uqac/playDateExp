local gfx <const> = playdate.graphics

import "game_constants"
local C <const> = GameConstants

obstacles = {}
local spawnTimer = 0
local spawnInterval = 5000
local potImage = nil
local loadedPot = gfx.image.new(C.POT_IMAGE_PATH)

if loadedPot then
    potImage = loadedPot
    print("Image du pot chargee avec succes !")
else
    print("Erreur : Impossible de charger l'image du pot a : " .. C.POT_IMAGE_PATH)
end

function spawnFixedObstacle(x, y, width, height)
    local obs = {x = x, y = y, w = width, h = height, type = "fixe"}
    table.insert(obstacles, obs)
end

function spawnFallingPot()
    local potWidth, potHeight
    
    if potImage then
        potWidth, potHeight = potImage:getSize()
    else
        potWidth = 24
        potHeight = 24
    end

    local startX = math.random(10, C.SCREEN_WIDTH - potWidth - 10)
    local obs = {x = startX, y = 10, w = potWidth, h = potHeight, type = "falling", state = "warning", timer = 1500, speed = 180}
    table.insert(obstacles, obs)
end

function updateObstacles(dt, scrollOffset)
    spawnTimer = spawnTimer + dt * 1000
    if spawnTimer >= spawnInterval then
        spawnTimer = 0
        if math.random() > 0.3 then
            local w = math.random(50, 120)
            local x = math.random(0, 400 - w)
            spawnFixedObstacle(x, -50, w, 25) 
        else
            spawnFallingPot()
        end
    end

    for i = #obstacles, 1, -1 do
        local o = obstacles[i]
        if o.type == "fixe" then
            o.y = o.y + scrollOffset
            
        elseif o.type == "falling" then
            if o.state == "warning" then
                o.timer = o.timer - (dt * 1000)
                if o.timer <= 0 then
                    o.state = "falling"
                    o.y = -30
                end
            elseif o.state == "falling" then
                o.y = o.y + (o.speed * dt) + scrollOffset
            end
        end

        if o.y > C.SCREEN_HEIGHT then
            table.remove(obstacles, i)
        end
    end
end

function drawObstacles()
    for _, o in ipairs(obstacles) do
        if o.type == "fixe" then
            gfx.setColor(gfx.kColorBlack)
            gfx.fillRect(o.x, o.y, o.w, o.h)
        elseif o.type == "falling" then
            if o.state == "warning" then
                if math.floor(o.timer / 100) % 2 == 0 then
                    gfx.setColor(gfx.kColorBlack)
                    gfx.drawRect(o.x, o.y, o.w, o.h)
                    gfx.drawTextAligned("*!*", o.x + o.w / 2, o.y + 2, kTextAlignment.center)
                end
            elseif o.state == "falling" then
                gfx.setColor(gfx.kColorBlack)

                if potImage then
                    potImage:draw(o.x, o.y)
                else
                    gfx.fillRect(o.x, o.y, o.w, o.h)
                    gfx.fillRect(o.x - 3, o.y, o.w + 6, 6)
                end
            end
        end
    end
end

function clearObstacles()
    obstacles = {}
    spawnTimer = 0
end