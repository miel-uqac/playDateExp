import "game_constants"

Bonus = {}
Bonus.__index = Bonus
local C = GameConstants

function Bonus.new(x, y)
    local self = setmetatable({}, Bonus)
    self.x = x
    self.y = y
    self.w = C.BONUS_SIZE
    self.h = C.BONUS_SIZE
    self.collected = false
    return self
end

function Bonus:update(dt, scrollOffset)
    self.y = self.y + scrollOffset
end

function Bonus:draw(gfx)
end

function Bonus:onCollect()
end

function Bonus:isOffscreen()
    return self.y > C.SCREEN_HEIGHT
end

function Bonus:checkCollision(px, py, radius)
    local dx = px - self.x
    local dy = py - self.y
    return (dx * dx + dy * dy) < ((radius + self.w / 2) * (radius + self.w / 2))
end


-- Bonus de score 
ScoreBonus = setmetatable({}, {__index = Bonus})
ScoreBonus.__index = ScoreBonus

local DURATION = 6.0

function ScoreBonus.new(x, y)
    local self = Bonus.new(x, y)
    return setmetatable(self, ScoreBonus)
end

function ScoreBonus:draw(gfx)
    if self.collected then return end

    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(self.x, self.y, self.w / 2)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawCircleAtPoint(self.x, self.y, self.w / 2)
    local label = "x2"
    local textWidth, textHeight = gfx.getTextSize(label)
    local textX = math.floor(self.x - (textWidth / 2))
    local textY = math.floor(self.y - (textHeight / 2)) + 2
    gfx.drawText(label, textX, textY)
end

function ScoreBonus:onCollect()
    return { type = "score_multiplier", multiplier = 2, duration = DURATION }
end
