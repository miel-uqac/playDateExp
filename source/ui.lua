import "game_constants"

UI = {}

local C = GameConstants

function UI.drawHUD(gfx, score)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawText("Score: " .. tostring(math.floor(score)), 6, 4)
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
