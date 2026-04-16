-- Gestion des obstacles et de leur cycle de vie.
local graphics <const> = playdate.graphics
import "game_constants"
local Config <const> = GameConstants


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
    return self.y > Config.SCREEN_HEIGHT
end


-- Classe fille : FallingPot
FallingPot = setmetatable({}, {__index = Obstacle})
FallingPot.__index = FallingPot

local potImage = nil
local loadedPot = graphics.image.new(Config.POT_IMAGE_PATH)
if loadedPot then
    potImage = loadedPot
    print("Image du pot chargee avec succes !")
else
    print("Erreur : Impossible de charger l'image du pot a : " .. Config.POT_IMAGE_PATH)
end

function FallingPot.new(x)
    local potWidth, potHeight
    if potImage then
        potWidth, potHeight = potImage:getSize()
    else
        potWidth = Config.POT_DEFAULT_SIZE
        potHeight = Config.POT_DEFAULT_SIZE
    end

    local self = Obstacle.new(x, 10, potWidth, potHeight)
    self.state = "warning"
    self.warningTimeRemainingMs = Config.POT_WARNING_DURATION_MS
    self.fallSpeed = Config.POT_FALL_SPEED
    return setmetatable(self, FallingPot)
end

function FallingPot:canCollide()
    return self.state == "falling"
end

function FallingPot:update(dt, scrollOffset)
    if self.state == "warning" then
        self.warningTimeRemainingMs = self.warningTimeRemainingMs - (dt * 1000)
        if self.warningTimeRemainingMs <= 0 then
            self.state = "falling"
            self.y = -self.h 
        end
    elseif self.state == "falling" then
        self.y = self.y + (self.fallSpeed * dt) + scrollOffset
    end
end

function FallingPot:draw()
    if self.state == "warning" then
        if math.floor(self.warningTimeRemainingMs / 100) % 2 == 0 then
            graphics.setColor(graphics.kColorBlack)
            
            local warningSize = Config.POT_WARNING_BOX_SIZE
            local centerX = self.x + self.w / 2
            local warningX = centerX - (warningSize / 2)
            local warningY = Config.POT_WARNING_BOX_Y
            
            graphics.drawRect(warningX, warningY, warningSize, warningSize)
            graphics.drawTextAligned("!", centerX, warningY + 1, kTextAlignment.center)
        end
    elseif self.state == "falling" then
        graphics.setColor(graphics.kColorBlack)
        if potImage then
            potImage:draw(self.x, self.y)
        else
            graphics.fillRect(self.x, self.y, self.w, self.h)
            graphics.fillRect(self.x - 3, self.y, self.w + 6, 6)
        end
    end
end


-- Classe fille : Saw (scie circulaire)
Saw = setmetatable({}, {__index = Obstacle})
Saw.__index = Saw

local sawImage = nil
local loadedSaw = graphics.image.new(Config.SAW_IMAGE_PATH)
if loadedSaw then
    sawImage = loadedSaw
    print("Image scie chargee !")
else
    print("Erreur : Impossible de charger la scie a : " .. Config.SAW_IMAGE_PATH)
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
    self.rotationAngle = 0
    self.centerX = x
    self.centerY = y + baseH / 2
    self.radius = baseW / 2
    self.scaledImage = scaledSaw
    return setmetatable(self, Saw)
end

function Saw:update(dt, scrollOffset)
    self.y = self.y + scrollOffset
    self.centerY = self.centerY + scrollOffset
    self.rotationAngle = (self.rotationAngle + Config.SAW_ROTATION_SPEED * dt) % 360
end

function Saw:draw()
    if self.scaledImage then
        self.scaledImage:drawRotated(self.centerX, self.centerY, self.rotationAngle)
    else
        graphics.setColor(graphics.kColorBlack)
        graphics.drawCircleAtPoint(self.centerX, self.centerY, self.w / 2)
        graphics.drawLine(self.centerX - self.w / 2, self.centerY, self.centerX + self.w / 2, self.centerY)
        graphics.drawLine(self.centerX, self.centerY - self.h / 2, self.centerX, self.centerY + self.h / 2)
    end
end

-- Liste globale utilisée par main.lua pour dessiner et tester les collisions.
activeObstacles = {}
local spawnElapsedMs = 0

function updateObstacles(deltaTime, scrollOffset, score)
    local difficultyLevel = math.floor(score / Config.OBSTACLE_DIFFICULTY_STEP)
    local reduction = difficultyLevel * Config.OBSTACLE_DIFFICULTY_REDUCTION
    local spawnIntervalMs = math.max(
        Config.OBSTACLE_SPAWN_INTERVAL_MIN,
        Config.OBSTACLE_SPAWN_INTERVAL_START - reduction
    )

    spawnElapsedMs = spawnElapsedMs + deltaTime * 1000
    if spawnElapsedMs >= spawnIntervalMs then
        spawnElapsedMs = 0

        if math.random() < Config.OBSTACLE_SAW_SPAWN_CHANCE then
            local scale = Config.SAW_SIZE_MIN + math.random() * (Config.SAW_SIZE_MAX - Config.SAW_SIZE_MIN)
            local x = math.random(30, Config.SCREEN_WIDTH - 30)
            table.insert(activeObstacles, Saw.new(x, -80, scale))
        else
            local x = math.random(10, Config.SCREEN_WIDTH - 34)
            table.insert(activeObstacles, FallingPot.new(x))
        end
    end

    for i = #activeObstacles, 1, -1 do
        local obstacle = activeObstacles[i]
        obstacle:update(deltaTime, scrollOffset)
        if obstacle:isOffscreen() then
            table.remove(activeObstacles, i)
        end
    end
end

function drawObstacles()
    for _, obstacle in ipairs(activeObstacles) do
        obstacle:draw()
    end
end

function clearObstacles()
    activeObstacles = {}
    spawnElapsedMs = 0
end
