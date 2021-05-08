local screen_width = 960
local screen_height = 540
local movebox = {
    width = 300,
    height = 200,
}
movebox.x = screen_width / 2 - movebox.width / 2
movebox.y = screen_height - movebox.height
local selectionMade = nil
local attacks = {
    SWING = 0,
    BASH = 1,
    KICK = 2,
    CHILL = 3
}
local attackCount = 4
local selectedAttack = attacks.SWING

local player = {x = 50, y = screen_height / 2, health = 5}
local enemy = {x = screen_width - 50 - 25 / 2, y = screen_height / 2, health = 2}

local arrow = nil
local minigame_frame = nil
local icons = {}

local nextActionTimeRemaining = 0

local function update(delta, input_disabled)
    if not input_disabled then
        if nextActionTimeRemaining <= 0 then
            if love.keyboard.isDown("down") then
                selectedAttack = (selectedAttack + 1) % attackCount
            elseif love.keyboard.isDown("up") then
                selectedAttack = (selectedAttack - 1) % attackCount
            elseif love.keyboard.isDown("space") then
                selectionMade = selectedAttack
            end

            nextActionTimeRemaining = 0.08
        end

        nextActionTimeRemaining = nextActionTimeRemaining - delta
    end
end

local function draw()
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill",0, 0, screen_width, screen_height)

    love.graphics.setColor(0, 255, 0, 1)


    love.graphics.rectangle("fill", player.x, player.y, 25, 40)

    love.graphics.setColor(255, 0, 0, 1)
    love.graphics.rectangle("fill", enemy.x, enemy.y, 25, 40)

    love.graphics.setColor(1, 0, 0, 1)
    for i = 0, player.health do
        love.graphics.rectangle("fill", 10 + i * 10, 10, 8, 8)
    end

    for i = 0, enemy.health do
        love.graphics.rectangle("fill", screen_width - 10 - i * 10 - 8, 10, 8, 8)
    end
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.rectangle("line", movebox.x, movebox.y, movebox.width, movebox.height)
    love.graphics.draw(arrow, lerp(movebox.x - 60, 10, math.cos(love.timer.getTime())), movebox.y + 24 * selectedAttack + 8)
    love.graphics.print("Swing sword", movebox.x + 10, movebox.y + attacks.SWING * 24 + 16)
    love.graphics.print("Bash shield", movebox.x + 10, movebox.y + attacks.BASH * 24 + 16)
    love.graphics.print("Kick", movebox.x + 10, movebox.y + attacks.KICK * 24 + 16)
    love.graphics.print("Just Chill", movebox.x + 10, movebox.y + attacks.CHILL * 24 + 16)


    love.graphics.rectangle("line", -1, -1, screen_width + 2, screen_height + 2)
end

local iconLerp = 0

function drawIcons(delta)
    iconLerp = math.min(iconLerp + delta * 2, 1)
    drawPostman(iconLerp)
    drawTrolley(iconLerp)
    drawStampHero(iconLerp)
end

function drawPostman(lerpValue)
    local x = lerp(-20, (screen_width / 3), lerpValue)
    local y = lerp(screen_height + 50, -screen_height / 2 - 70, lerpValue)
    love.graphics.draw(icons.foot, x, y, 0, 2, 2)
    love.graphics.draw(minigame_frame, x, y, 0, 2, 2)
end

function drawTrolley(lerpValue)
    local x = screen_width / 2 - 50
    local y = lerp(screen_height + 50, -screen_height / 2 - 70, lerpValue)
    love.graphics.draw(icons.trolley, icons.trolley_quad, x, y)
    love.graphics.draw(minigame_frame, x, y, 0, 2, 2)
end

function drawStampHero(lerpValue)
    local x = lerp(screen_width + 20, -(screen_width / 3 + 100), lerpValue)
    local y = lerp(screen_height + 50, -screen_height / 2 - 70, lerpValue)
    love.graphics.draw(icons.stamp, x + 15, y + 15)
    love.graphics.draw(minigame_frame, x, y, 0, 2, 2)
end

function resetIconsLerp()
    iconLerp = 0
end

function getSelection()
    local temp = selectionMade
    selectionMade = nil
    return temp
end

function damagePlayer()
    player.health = player.health - 1
end

function damageEnemy()
    enemy.health = enemy.health - 1
end

local function load()
    minigame_frame = love.graphics.newImage("gpx/minigame_frame.png")
    icons.foot = love.graphics.newImage("gpx/postman_foot_temp.png")
    icons.stamp = love.graphics.newImage("gpx/stamp_blue.png")
    icons.trolley = love.graphics.newImage("gpx/mailtrolley.png")
    icons.trolley_quad = love.graphics.newQuad(0, 0, 50, 70, 100, 70)
    arrow = love.graphics.newImage("gpx/arrow_temp.png")
end

rpg = {
    update = update,
    draw = draw,
    load = load,
    selectionMade = getSelection,
    damageEnemy = damageEnemy,
    damagePlayer = damagePlayer
}