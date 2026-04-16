import "game_constants"

UI = {}
UI.hudScorePanelWidth = 0
UI.hudBonusPanelWidth = 0

local Config = GameConstants

function UI.drawHUD(graphics, score, activeBonusEffect)
    local horizontalPadding = 6
    local verticalPadding = 3
    local safetyMargin = 1
    local panelHeight = 20
    local panelX = 4
    local panelY = 2
    local panelSpacing = 1

    local scoreText = "Score: " .. tostring(math.floor(score))
    local scoreTextWidth = graphics.getTextSize(scoreText)
    local desiredScorePanelWidth = scoreTextWidth + (horizontalPadding * 2)
    UI.hudScorePanelWidth = math.max(UI.hudScorePanelWidth, desiredScorePanelWidth)
    local scorePanelWidth = UI.hudScorePanelWidth + safetyMargin

    graphics.setColor(graphics.kColorWhite)
    graphics.fillRect(panelX, panelY, scorePanelWidth, panelHeight)
    graphics.setColor(graphics.kColorBlack)
    graphics.drawRect(panelX, panelY, scorePanelWidth, panelHeight)
    graphics.drawText(scoreText, panelX + horizontalPadding, panelY + verticalPadding)

    -- La ligne de bonus est affichée seulement lorsqu'un effet est actif.
    if activeBonusEffect then
        local bonusText = "x2 " .. tostring(math.ceil(activeBonusEffect.timer)) .. "s"
        local bonusTextWidth = graphics.getTextSize(bonusText)
        local desiredBonusPanelWidth = bonusTextWidth + (horizontalPadding * 2)
        UI.hudBonusPanelWidth = math.max(UI.hudBonusPanelWidth, desiredBonusPanelWidth)
        local bonusPanelWidth = UI.hudBonusPanelWidth + safetyMargin
        local bonusPanelY = panelY + panelHeight + panelSpacing

        graphics.setColor(graphics.kColorWhite)
        graphics.fillRect(panelX, bonusPanelY, bonusPanelWidth, panelHeight)
        graphics.setColor(graphics.kColorBlack)
        graphics.drawRect(panelX, bonusPanelY, bonusPanelWidth, panelHeight)
        graphics.drawText(bonusText, panelX + horizontalPadding, bonusPanelY + verticalPadding)
    end
end

function UI.resetHUDLayout()
    UI.hudScorePanelWidth = 0
    UI.hudBonusPanelWidth = 0
end

function UI.drawStartMenu(graphics, bestScore)
    graphics.drawTextAligned("A : Jouer", Config.SCREEN_WIDTH / 2, 100, kTextAlignment.center)
    graphics.drawTextAligned("Best: " .. tostring(math.floor(bestScore)), Config.SCREEN_WIDTH / 2, 120, kTextAlignment.center)
end

function UI.drawGameOver(graphics, score, bestScore)
    graphics.clear()
    graphics.drawTextAligned("GAME OVER", Config.SCREEN_WIDTH / 2, 80, kTextAlignment.center)
    graphics.drawTextAligned("Score: " .. tostring(math.floor(score)), Config.SCREEN_WIDTH / 2, 110, kTextAlignment.center)
    graphics.drawTextAligned("Best:  " .. tostring(math.floor(bestScore)), Config.SCREEN_WIDTH / 2, 130, kTextAlignment.center)
    graphics.drawTextAligned("A : Rejouer", Config.SCREEN_WIDTH / 2, 170, kTextAlignment.center)
    graphics.drawTextAligned("B : Menu", Config.SCREEN_WIDTH / 2, 190, kTextAlignment.center)
end