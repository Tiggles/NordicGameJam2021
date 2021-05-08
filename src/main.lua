function lerp(a, b, t)
    return a + b * t
end

require("stamp_hero")
require("rpg")

function love.load()
    rpg.load()
    stampHero.load()
end

local minigameActive = nil
local tweenValue = 0

function love.update(delta)
    if love.keyboard.isDown("escape") then
        love.event.quit()
    end

    if love.keyboard.isDown("r") then
        love.event.quit("restart")
    end

    rpg.update(delta, minigameActive)
    if rpg.selectionMade() ~= nil then
        minigameActive = "stamp_hero"
        tweenValue = 0
    end

    if minigameActive ~= nil then
        if minigameActive == "stamp_hero" then
            stampHero.update(delta)
        end
    end
end

function love.draw()
    love.graphics.translate(0, 0)
    love.graphics.scale(1)
    if minigameActive ~= nil then
        stampHero.draw()
        tweenValue = math.min(tweenValue + love.timer.getDelta() * 2, 1)
        love.graphics.translate(lerp(0, 10, tweenValue), lerp(0,540 - 540 / 8 - 10, tweenValue))
        love.graphics.scale(lerp(1, -7/8, tweenValue))
    end
    rpg.draw()
end