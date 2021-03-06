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
local sfx = {}
local attackCount = 4
local selectedAttack = attacks.SWING

local player = {x = 50, y = screen_height / 2, health = 5}
local enemy = {x = screen_width - 64 - 50 , y = screen_height / 2, health = 3, kind = 0}

local arrow = nil

local function gameWon()
    return enemy.kind == 3
end

local function gameLost()
    return player.health == 0
end

local function difficulty()
    return enemy.kind
end

local input_disabled

local function keypressed(key)
    if input_disabled then
        return
    end

    if key == "down" then
        selectedAttack = (selectedAttack + 1) % attackCount
    elseif key == "up" then
        selectedAttack = (selectedAttack - 1) % attackCount
    elseif key == "space" or key == "return" then
        selectionMade = selectedAttack
    end
end

local function update(delta, should_disable_input)
    input_disabled = should_disable_input
end


local function draw()
    love.graphics.setColor(255, 255, 255, 1)
    love.graphics.draw(gfx.background, 0, 0, 0, 4, 4)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(gfx.player, player.x, player.y, 0, 4, 4)

    for i = 1, player.health do
        love.graphics.draw(gfx.heart, i * gfx.heart:getWidth() * 3 - 30, 10, 0, 3, 3)
    end

    if enemy.kind < 3 then
        local enemyImg = nil
        if enemy.kind == 0 then
            enemyImg = gfx.enemy0
        elseif enemy.kind == 1 then
            enemyImg = gfx.enemy1
        elseif enemy.kind == 2 then
            enemyImg = gfx.enemy2
        end
        love.graphics.draw(enemyImg, enemy.x, enemy.y, 0, 4, 4)
        for i = 1, enemy.health do
            love.graphics.draw(gfx.heart, screen_width + 30 - i * gfx.heart:getWidth() * 3 - gfx.heart:getWidth() * 3, 10, 0, 3, 3)
        end
    end


    love.graphics.setColor(0, 0, 0, 1)

    love.graphics.rectangle("fill", movebox.x, movebox.y, movebox.width, movebox.height)
    love.graphics.draw(arrow, lerp(movebox.x - 60, 10, math.cos(love.timer.getTime())), movebox.y + 24 * selectedAttack + 8)

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Swing sword", movebox.x + 10, movebox.y + attacks.SWING * 24 + 16)
    love.graphics.print("Bash shield", movebox.x + 10, movebox.y + attacks.BASH * 24 + 16)
    love.graphics.print("Kick", movebox.x + 10, movebox.y + attacks.KICK * 24 + 16)
    love.graphics.print("Just Chill", movebox.x + 10, movebox.y + attacks.CHILL * 24 + 16)

    love.graphics.rectangle("line", -1, -1, screen_width + 2, screen_height + 2)

    love.graphics.setColor(0, 0, 0, 1)
    if gameWon() then
        love.graphics.print("\t\t\t You won! \n Press Enter to play again", screen_width / 2 - 120, screen_height / 2 - 50)
    elseif gameLost() then
        love.graphics.print("\t\t\t\t You lost. \n Press Enter to play again", screen_width / 2 - 120, screen_height / 2 - 50)
    end
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
        enemy.kind = enemy.kind + 1
        enemy.health = 3
    end
end

local function load()
    arrow = love.graphics.newImage("gpx/arrow_temp.png")
    gfx.player = love.graphics.newImage("gpx/mono_sprites/character0.png")
    gfx.enemy0 = love.graphics.newImage("gpx/mono_sprites/enemy0.png")
    gfx.enemy1 = love.graphics.newImage("gpx/mono_sprites/enemy1.png")
    gfx.enemy2 = love.graphics.newImage("gpx/mono_sprites/enemy2.png")
    gfx.heart = love.graphics.newImage("gpx/mono_sprites/heart2.png")
    gfx.background = love.graphics.newImage("gpx/bg.png")
end

return {
    update = update,
    draw = draw,
    keypressed = keypressed,
    load = load,
    selectionMade = getSelection,
    damageEnemy = damageEnemy,
    damagePlayer = damagePlayer,
    gameWon = gameWon,
    gameLost = gameLost,
    difficulty = difficulty
}