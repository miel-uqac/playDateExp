import "game_constants"

UI = {}

local C = GameConstants

function UI.drawHUD(gfx, score, bonusEffect)
    local padding = 4
    local boxHeight = 20
    local scoreFloor = math.floor(score)
    local scoreText = "Score: " .. tostring(scoreFloor)
    local numberOfDigits = string.len(tostring(scoreFloor))
    local boxWidth = 65 + (numberOfDigits * 12)

    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(4, 2, boxWidth, boxHeight)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRect(4, 2, boxWidth, boxHeight)
    gfx.drawText(scoreText, 6 + padding, 4)

    -- Gestion de la boite de bonus
    if bonusEffect then
        local bonusText = "x2 " .. tostring(math.ceil(bonusEffect.timer)) .. "s"
        local bonusBoxWidth = boxWidth

        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(4, 26, bonusBoxWidth, boxHeight)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(4, 26, bonusBoxWidth, boxHeight)
        gfx.drawText(bonusText, 6 + padding, 28)
    end
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