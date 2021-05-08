function lerp(a, b, t)
    return a + b * t
end

function lerp2(a, b, t)
    return (a + (b - a) * t)
end

require("stamp_hero")
require("rpg")
local trolley = require("trolley")

screen_width = 960
screen_height = 540

function love.load()
    rpg.load()
    stampHero.load()
    trolley.load()
    font = love.graphics.newFont("assets/OpenSansEmoji.ttf", 20)
end

local states = {
    MENU = 0,
    RPG = 1,
    MINIGAME_ANIMATION = 2,
    MINIGAME_ACTIVE = 3
}

local game_state = states.MENU

local minigameActive = nil
local tweenValue = 0

function love.update(delta)
    if love.keyboard.isDown("escape") then
        love.event.quit()
    end

    if love.keyboard.isDown("r") and love.keyboard.isDown("lctrl") then
        love.event.quit("restart")
    end

    rpg.update(delta, minigameActive)
    if rpg.selectionMade() ~= nil then
        local result = math.random(1, 2)
        if (result == 1) then
            minigameActive = trolley
        else
            minigameActive = stampHero
        end
        tweenValue = 0
    end

    if minigameActive ~= nil then
        minigameActive.update(delta)
        if not minigameActive.isRunning() then
            minigameActive.getWinCondition()

            if not stampHero.isRunning() then
                local didWin = stampHero.getWinCondition()
                if didWin then
                    rpg.damageEnemy()
                else
                    rpg.damagePlayer()
                end
                minigameActive.reset()
                minigameActive = nil
            end
        end
    end
end

function love.draw()
    love.graphics.setFont(font)
    love.graphics.translate(0, 0)
    love.graphics.scale(1)
    if minigameActive ~= nil then
        minigameActive.draw()
        tweenValue = math.min(tweenValue + love.timer.getDelta() * 2, 1)
        love.graphics.translate(lerp(0, 10, tweenValue), lerp(0,540 - 540 / 8 - 10, tweenValue))
        love.graphics.scale(lerp(1, -7/8, tweenValue))
    end
    rpg.draw()
    -- drawIcons(love.timer.getDelta())
end

function love.textinput(t)
    if minigameActive ~= nil and minigameActive["textinput"] ~= nil then
        minigameActive.textinput(t)
    end
end

function love.keypressed(key)
    if minigameActive ~= nil and minigameActive["keypressed"] ~= nil then
        minigameActive.keypressed(key)
    end
end
