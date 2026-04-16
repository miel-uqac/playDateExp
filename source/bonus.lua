import "game_constants"

Bonus = {}
Bonus.__index = Bonus

local Config = GameConstants
local graphics <const> = playdate.graphics

function Bonus.new(x, y)
    local self = setmetatable({}, Bonus)
    self.x = x
    self.y = y
    self.w = Config.BONUS_SIZE
    self.h = Config.BONUS_SIZE
    self.collected = false
    return self
end

function Bonus:update(deltaTime, scrollOffset)
    self.y = self.y + scrollOffset
end

function Bonus:draw(graphics)
end

function Bonus:onCollect()
end

function Bonus:isOffscreen()
    return self.y > Config.SCREEN_HEIGHT
end

function Bonus:checkCollision(headX, headY, collisionRadius)
    local dx = headX - self.x
    local dy = headY - self.y
    return (dx * dx + dy * dy) < ((collisionRadius + self.w / 2) * (collisionRadius + self.w / 2))
end


-- Bonus de score : double la valeur des points pendant une durée limitée.
ScoreBonus = setmetatable({}, {__index = Bonus})
ScoreBonus.__index = ScoreBonus

local BONUS_EFFECT_DURATION_SECONDS = Config.BONUS_DURATION_SECONDS

function ScoreBonus.new(x, y)
    local self = Bonus.new(x, y)
    return setmetatable(self, ScoreBonus)
end

function ScoreBonus:draw(graphics)
    if self.collected then return end

    graphics.setColor(graphics.kColorWhite)
    graphics.fillCircleAtPoint(self.x, self.y, self.w / 2)
    graphics.setColor(graphics.kColorBlack)
    graphics.drawCircleAtPoint(self.x, self.y, self.w / 2)
    local label = "x2"
    local textWidth, textHeight = graphics.getTextSize(label)
    local textX = math.floor(self.x - (textWidth / 2))
    local textY = math.floor(self.y - (textHeight / 2)) + 2
    graphics.drawText(label, textX, textY)
end

function ScoreBonus:onCollect()
    return {
        type = "score_multiplier",
        multiplier = Config.BONUS_SCORE_MULTIPLIER,
        duration = BONUS_EFFECT_DURATION_SECONDS,
    }
end
