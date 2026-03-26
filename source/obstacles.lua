local gfx <const> = playdate.graphics
import "game_constants"
local C <const> = GameConstants


-- Classe de base : Obstacle
Obstacle = {}
Obstacle.__index = Obstacle

function Obstacle.new(x, y, w, h)
    local self = setmetatable({}, Obstacle)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    return self
end

function Obstacle:update(dt, scrollOffset)
end

function Obstacle:draw()
end

function Obstacle:isOffscreen()
    return self.y > C.SCREEN_HEIGHT
end


-- Classe fille : FixedObstacle
FixedObstacle = setmetatable({}, {__index = Obstacle})
FixedObstacle.__index = FixedObstacle

function FixedObstacle.new(x, y, w, h)
    local self = Obstacle.new(x, y, w, h)
    return setmetatable(self, FixedObstacle)
end

function FixedObstacle:update(dt, scrollOffset)
    self.y = self.y + scrollOffset
end

function FixedObstacle:draw()
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(self.x, self.y, self.w, self.h)
end


-- Classe fille : FallingPot
FallingPot = setmetatable({}, {__index = Obstacle})
FallingPot.__index = FallingPot

local potImage = nil
local loadedPot = gfx.image.new(C.POT_IMAGE_PATH)
if loadedPot then
    potImage = loadedPot
    print("Image du pot chargee avec succes !")
else
    print("Erreur : Impossible de charger l'image du pot a : " .. C.POT_IMAGE_PATH)
end

function FallingPot.new(x)
    local potWidth, potHeight
    if potImage then
        potWidth, potHeight = potImage:getSize()
    else
        potWidth = 24
        potHeight = 24
    end

    local self = Obstacle.new(x, 10, potWidth, potHeight)
    self.state = "warning"
    self.timer = 1500
    self.speed = 180
    return setmetatable(self, FallingPot)
end

function FallingPot:update(dt, scrollOffset)
    if self.state == "warning" then
        self.timer = self.timer - (dt * 1000)
        if self.timer <= 0 then
            self.state = "falling"
            self.y = -30
        end
    elseif self.state == "falling" then
        self.y = self.y + (self.speed * dt) + scrollOffset
    end
end

function FallingPot:draw()
    if self.state == "warning" then
        if math.floor(self.timer / 100) % 2 == 0 then
            gfx.setColor(gfx.kColorBlack)
            gfx.drawRect(self.x, self.y, self.w, self.h)
            gfx.drawTextAligned("*!*", self.x + self.w / 2, self.y + 2, kTextAlignment.center)
        end
    elseif self.state == "falling" then
        gfx.setColor(gfx.kColorBlack)
        if potImage then
            potImage:draw(self.x, self.y)
        else
            gfx.fillRect(self.x, self.y, self.w, self.h)
            gfx.fillRect(self.x - 3, self.y, self.w + 6, 6)
        end
    end
end


-- Gestion globale des obstacles
obstacles = {}
local spawnTimer = 0
local spawnInterval = 5000

function updateObstacles(dt, scrollOffset)
    spawnTimer = spawnTimer + dt * 1000
    if spawnTimer >= spawnInterval then
        spawnTimer = 0
        if math.random() > 0.3 then
            local w = math.random(50, 120)
            local x = math.random(0, C.SCREEN_WIDTH - w)
            table.insert(obstacles, FixedObstacle.new(x, -50, w, 25))
        else
            local x = math.random(10, C.SCREEN_WIDTH - 34)
            table.insert(obstacles, FallingPot.new(x))
        end
    end

    for i = #obstacles, 1, -1 do
        local o = obstacles[i]
        o:update(dt, scrollOffset)
        if o:isOffscreen() then
            table.remove(obstacles, i)
        end
    end
end

function drawObstacles()
    for _, o in ipairs(obstacles) do
        o:draw()
    end
end

function clearObstacles()
    obstacles = {}
    spawnTimer = 0
end
