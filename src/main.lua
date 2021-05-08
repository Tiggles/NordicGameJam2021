function lerp(a, b, t)
    return a + b * t
end

function lerp2(a, b, t)
    return (a + (b - a) * t)
end

local stampHero = require("stamp_hero")
local rpg = require("rpg")
local trolley = require("trolley")

local minigame_frame = nil
local icons = {}
local player_won = false
local game_victory = false

screen_width = 960
screen_height = 540

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    rpg.load()
    stampHero.load()
    trolley.load()
    font = love.graphics.newFont("assets/OpenSansEmoji.ttf", 20)
    paper = love.graphics.newImage("gpx/paper_red.png")
    minigame_frame = love.graphics.newImage("gpx/minigame_frame.png")
    icons.foot = love.graphics.newImage("gpx/postman_foot_temp.png")
    icons.stamp = love.graphics.newImage("gpx/stamp_blue.png")
    icons.trolley = love.graphics.newImage("gpx/mailtrolley.png")
    icons.trolley_quad = love.graphics.newQuad(0, 0, 50, 70, 100, 70)
    icons.check = love.graphics.newImage("gpx/checkmark_temp.png")
    icons.cross = love.graphics.newImage("gpx/cross_temp.png")
    icons.arrow = love.graphics.newImage("gpx/arrow_temp.png")
end

local states = {
    MENU = 0,
    RPG = 1,
    MINIGAME_ANIMATION_1 = 2,
    MINIGAME_ANIMATION_2 = 3,
    MINIGAME_ANIMATION_3 = 4,
    MINIGAME_ANIMATION_4 = 5,
    MINIGAME_ACTIVE = 6,
    MINIGAME_EXIT = 7,
}

local active_minigame = -1
local game_state = states.RPG

local minigameActive = nil
local tweenValue = 0

local animationValue = 0

function love.update(delta)
    local won, lost = rpg.gameWon(), rpg.gameLost()

    if love.keyboard.isDown("escape") then
        love.event.quit()
    end

    if love.keyboard.isDown("r") and love.keyboard.isDown("lctrl") then
        love.event.quit("restart")
    end

    if won or lost then
        if love.keyboard.isDown("return") then
           love.event.quit("restart")
        end
    end

    rpg.update(delta, minigameActive or won or lost)
    if rpg.selectionMade() ~= nil then
        local result = math.random(1, 2)
        if (result == 1) then
            minigameActive = trolley
        else
            minigameActive = stampHero
        end
        active_minigame = result
        game_state = states.MINIGAME_ANIMATION_1
        tweenValue = 0
        animationValue = 0
    end

    if (game_state == states.MINIGAME_ANIMATION_1) then
        if animationValue > 1.5 then
            game_state = states.MINIGAME_ANIMATION_2
            animationValue = 0
        end
    elseif game_state == states.MINIGAME_ANIMATION_2 then
        if animationValue > 1.5 then
            game_state = states.MINIGAME_ANIMATION_3
            resetIconsLerp()
            animationValue = 0
        end
    elseif game_state == states.MINIGAME_ANIMATION_3 then
        if animationValue > 1.5 then
            game_state = states.MINIGAME_ANIMATION_4
            animationValue = 0
        end
    elseif game_state == states.MINIGAME_ANIMATION_4 then
        if animationValue > 1.5 then
            game_state = states.MINIGAME_ACTIVE
            animationValue = 0
        end
    elseif game_state == states.MINIGAME_EXIT then
        if animationValue > 1.5 then
            if player_won then
                rpg.damageEnemy()
            else
                rpg.damagePlayer()
            end
            game_state = states.RPG
            animationValue = 0
        end
    end


    animationValue = animationValue + delta

    if (game_state ~= states.MINIGAME_ACTIVE) then return end

    if minigameActive ~= nil then
        minigameActive.update(delta)
        if not minigameActive.isRunning() then
            minigameActive.getWinCondition()

            if not minigameActive.isRunning() then
                player_won = minigameActive.getWinCondition()
                minigameActive.reset()
                rpg.setNextActionTimeRemaining(0.2)
                game_state = states.MINIGAME_EXIT
                animationValue = 0
                minigameActive = nil
            end
        end
    end
end

function love.draw()
    love.graphics.setFont(font)
    love.graphics.translate(0, 0)
    love.graphics.scale(1)

    if minigameActive ~= nil and game_state == states.MINIGAME_ACTIVE then
        minigameActive.draw()
        tweenValue = math.min(tweenValue + love.timer.getDelta() * 2, 1)
        love.graphics.translate(lerp(0, 10, tweenValue), lerp(0,540 - 540 / 8 - 10, tweenValue))
        love.graphics.scale(lerp(1, -7/8, tweenValue))
    end
    rpg.draw()

    drawAnimation()

    if game_state == states.MINIGAME_ACTIVE or game_state == states.MINIGAME_ANIMATION_2 or game_state == states.MINIGAME_ANIMATION_3 or game_state == states.MINIGAME_ANIMATION_4 then
        love.graphics.print("Your combat application is pending", screen_width / 2 - 150, 20)
    end
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



-- Transition animations
local iconLerp = 0

function drawIcons(delta)
    iconLerp = math.min(iconLerp + delta * 2, 1)
    drawPostman(iconLerp)
    drawTrolley(iconLerp)
    drawStampHero(iconLerp)
end

function drawPostman(lerpValue)
    local x = lerp2(-20, (screen_width / 3), lerpValue)
    local y = lerp2(screen_height + 40, screen_height / 2, lerpValue)
    love.graphics.draw(icons.foot, x, y, 0, 2, 2)
    love.graphics.draw(minigame_frame, x, y, 0, 2, 2)
end

function drawTrolley(lerpValue)
    local x = screen_width / 2 - 50
    local y = lerp2(screen_height + 40, screen_height / 2, lerpValue)
    love.graphics.draw(icons.trolley, icons.trolley_quad, x, y)
    love.graphics.draw(minigame_frame, x, y, 0, 2, 2)
end

function drawStampHero(lerpValue)
    local x = lerp2(screen_width + 20, screen_width / 2 + 50, lerpValue)
    local y = lerp2(screen_height + 40, screen_height / 2, lerpValue)
    love.graphics.draw(icons.stamp, x + 15, y + 15)
    love.graphics.draw(minigame_frame, x, y, 0, 2, 2)
end

function drawMarks()
     love.graphics.draw(icons.check, screen_width / 3 + 10, screen_height / 2 - 50, 0 , 2, 2)
    if active_minigame == 1 then
        love.graphics.draw(icons.arrow, screen_width / 2, screen_height / 2 - 50, 3.14/2)
    else
        love.graphics.draw(icons.check,screen_width / 2 - 50 + 10, screen_height / 2 - 50, 0, 2, 2)
        love.graphics.draw(icons.arrow, screen_width / 2 + 100, screen_height / 2 - 50, 3.14/2)
    end
end

function resetIconsLerp()
    iconLerp = 0
end

function drawAnimation()
    if game_state == states.MINIGAME_ANIMATION_1 then
        local x = lerp2(-50, screen_width / 2 - 25, math.min(animationValue, 1))
        local y = screen_height / 2
        love.graphics.draw(paper, x, y, math.max(1 - animationValue, 0))
    elseif game_state == states.MINIGAME_ANIMATION_2 then
        local x = screen_width / 2 - 25
        local y = lerp2(screen_height / 2, -100, math.min(animationValue * 1.5, 1))
        love.graphics.draw(paper, x, y)
    elseif game_state == states.MINIGAME_ANIMATION_3 then
        drawIcons(love.timer.getDelta())
    elseif game_state == states.MINIGAME_ANIMATION_4 then
        drawIcons(love.timer.getDelta())
        drawMarks(active_minigame)
    elseif game_state == states.MINIGAME_EXIT then
        local x = 0
        if player_won then
            x = lerp2(screen_width / 2, screen_width - 120, math.min(animationValue, 1))
        else
            x = lerp2(screen_width / 2, 120, math.min(animationValue, 1))
        end
        local y = lerp2(screen_height / 2, 100, math.min(animationValue, 1))
        love.graphics.draw(paper, x, y, 0, 1, 1)
    end
end