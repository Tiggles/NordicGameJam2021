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
local gfx = {}
local attackCount = 4
local selectedAttack = attacks.SWING

local player = {x = 50, y = screen_height / 2, health = 5}
local enemy = {x = screen_width - 50 - 25 / 2 - 15, y = screen_height / 2, health = 3}

local arrow = nil

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

function setNextActionTimeRemaining(time)
    nextActionTimeRemaining = time
end

local function draw()
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill",0, 0, screen_width, screen_height)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gfx.player, player.x, player.y, 0, 4, 4)

    love.graphics.draw(gfx.enemy0, enemy.x, enemy.y, 0, 4, 4)

    for i = 1, player.health do
        love.graphics.draw(gfx.heart, i * gfx.heart:getWidth() * 3 - 30, 10, 0, 3, 3)
    end

    for i = 1, enemy.health do
        love.graphics.draw(gfx.heart, screen_width + 30 - i * gfx.heart:getWidth() * 3 - gfx.heart:getWidth() * 3, 10, 0, 3, 3)
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

    if enemy.health == 0 then
        -- TODO next enemy
    end
end

local function load()
    arrow = love.graphics.newImage("gpx/arrow_temp.png")
    gfx.player = love.graphics.newImage("gpx/mono_sprites/character0.png")
    gfx.enemy0 = love.graphics.newImage("gpx/mono_sprites/enemy0.png")
    gfx.enemy1 = love.graphics.newImage("gpx/mono_sprites/enemy1.png")
    gfx.enemy2 = love.graphics.newImage("gpx/mono_sprites/enemy2.png")
    gfx.heart = love.graphics.newImage("gpx/mono_sprites/heart2.png")
end

return {
    update = update,
    draw = draw,
    load = load,
    selectionMade = getSelection,
    damageEnemy = damageEnemy,
    damagePlayer = damagePlayer,
    setNextActionTimeRemaining = setNextActionTimeRemaining,
}