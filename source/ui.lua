import "game_constants"

UI = {}
UI.hudScoreBoxWidth = 0
UI.hudBonusBoxWidth = 0

local C = GameConstants

function UI.drawHUD(gfx, score, bonusEffect)
    local textPaddingX = 6
    local textPaddingY = 3
    local widthSafetyMargin = 1
    local boxHeight = 20
    local boxX = 4
    local boxY = 2
    local boxGap = 1
    local scoreFloor = math.floor(score)
    local scoreText = "Score: " .. tostring(scoreFloor)
    local scoreTextWidth = gfx.getTextSize(scoreText)
    local desiredScoreBaseWidth = scoreTextWidth + (textPaddingX * 2)
    UI.hudScoreBoxWidth = math.max(UI.hudScoreBoxWidth, desiredScoreBaseWidth)
    local boxWidth = UI.hudScoreBoxWidth + widthSafetyMargin

    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(boxX, boxY, boxWidth, boxHeight)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(boxX, boxY, boxWidth, boxHeight)
    gfx.drawText(scoreText, boxX + textPaddingX, boxY + textPaddingY)

    -- Gestion de la boite de bonus
    if bonusEffect then
        local bonusText = "x2 " .. tostring(math.ceil(bonusEffect.timer)) .. "s"
        local bonusTextWidth = gfx.getTextSize(bonusText)
        local desiredBonusBaseWidth = bonusTextWidth + (textPaddingX * 2)
        UI.hudBonusBoxWidth = math.max(UI.hudBonusBoxWidth, desiredBonusBaseWidth, UI.hudScoreBoxWidth)
        local bonusBoxWidth = UI.hudBonusBoxWidth + widthSafetyMargin
        local bonusBoxY = boxY + boxHeight + boxGap

        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(boxX, bonusBoxY, bonusBoxWidth, boxHeight)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(boxX, bonusBoxY, bonusBoxWidth, boxHeight)
        gfx.drawText(bonusText, boxX + textPaddingX, bonusBoxY + textPaddingY)
    end
end

function UI.resetHUDLayout()
    UI.hudScoreBoxWidth = 0
    UI.hudBonusBoxWidth = 0
end

function UI.drawStartMenu(gfx, bestScore)
    gfx.clear()
    gfx.drawTextAligned("PLANT CLIMBER", C.SCREEN_WIDTH / 2, 90, kTextAlignment.center)
    gfx.drawTextAligned("A : Jouer", C.SCREEN_WIDTH / 2, 120, kTextAlignment.center)
    gfx.drawTextAligned("Best: " .. tostring(math.floor(bestScore)), C.SCREEN_WIDTH / 2, 180, kTextAlignment.center)
end

function UI.drawGameOver(gfx, score, bestScore)
    gfx.clear()
    gfx.drawTextAligned("GAME OVER", C.SCREEN_WIDTH / 2, 80, kTextAlignment.center)
    gfx.drawTextAligned("Score: " .. tostring(math.floor(score)), C.SCREEN_WIDTH / 2, 110, kTextAlignment.center)
    gfx.drawTextAligned("Best:  " .. tostring(math.floor(bestScore)), C.SCREEN_WIDTH / 2, 130, kTextAlignment.center)
    gfx.drawTextAligned("A : Rejouer", C.SCREEN_WIDTH / 2, 170, kTextAlignment.center)
    gfx.drawTextAligned("B : Menu", C.SCREEN_WIDTH / 2, 190, kTextAlignment.center)
end