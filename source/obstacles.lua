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

function FallingPot:canCollide()
    return self.state == "falling"
end

function FallingPot:update(dt, scrollOffset)
    if self.state == "warning" then
        self.timer = self.timer - (dt * 1000)
        if self.timer <= 0 then
            self.state = "falling"
            self.y = -self.h 
        end
    elseif self.state == "falling" then
        self.y = self.y + (self.speed * dt) + scrollOffset
    end
end

function FallingPot:draw()
    if self.state == "warning" then
        if math.floor(self.timer / 100) % 2 == 0 then
            gfx.setColor(gfx.kColorBlack)
            
            local warningSize = 25
            local centerX = self.x + self.w / 2
            local warningX = centerX - (warningSize / 2)
            local warningY = 10 
            
            gfx.drawRect(warningX, warningY, warningSize, warningSize)
            gfx.drawTextAligned("!", centerX, warningY + 1, kTextAlignment.center)
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


-- Classe fille : Saw (scie circulaire)
Saw = setmetatable({}, {__index = Obstacle})
Saw.__index = Saw

local sawImage = nil
local loadedSaw = gfx.image.new(C.SAW_IMAGE_PATH)
if loadedSaw then
    sawImage = loadedSaw
    print("Image scie chargee !")
else
    print("Erreur : Impossible de charger la scie a : " .. C.SAW_IMAGE_PATH)
end

function Saw.new(x, y, scale)
    local baseW, baseH = 32, 32
    local scaledSaw = nil

    if sawImage then
        scaledSaw = sawImage:scaledImage(scale)
        baseW, baseH = scaledSaw:getSize()
    end

    local self = Obstacle.new(x - baseW / 2, y, baseW, baseH)
    self.scale = scale
    self.angle = 0
    self.centerX = x
    self.centerY = y + baseH / 2
    self.radius = baseW / 2
    self.scaledImage = scaledSaw
    return setmetatable(self, Saw)
end

function Saw:update(dt, scrollOffset)
    self.y = self.y + scrollOffset
    self.centerY = self.centerY + scrollOffset
    self.angle = (self.angle + C.SAW_ROTATION_SPEED * dt) % 360
end

function Saw:draw()
    if self.scaledImage then
        self.scaledImage:drawRotated(self.centerX, self.centerY, self.angle)
    else
        gfx.setColor(gfx.kColorBlack)
        gfx.drawCircleAtPoint(self.centerX, self.centerY, self.w / 2)
        gfx.drawLine(self.centerX - self.w / 2, self.centerY, self.centerX + self.w / 2, self.centerY)
        gfx.drawLine(self.centerX, self.centerY - self.h / 2, self.centerX, self.centerY + self.h / 2)
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

        local roll = math.random()
        if roll > 0.75 then
            local scale = C.SAW_SIZE_MIN + math.random() * (C.SAW_SIZE_MAX - C.SAW_SIZE_MIN)
            local x = math.random(30, C.SCREEN_WIDTH - 30)
            table.insert(obstacles, Saw.new(x, -80, scale))
        elseif roll > 0.25 then
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
