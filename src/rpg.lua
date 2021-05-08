local screen_width = 960
local screen_height = 540
local movebox = {
    width = 300,
    height = 200,
}
movebox.x = screen_width / 2 - movebox.width / 2
movebox.y = screen_height - movebox.height
local arrow_offset = 25
local selectionMade = nil
local attacks = {
    SWING = 0,
    BASH = 1,
    KICK = 2,
    CHILL = 3
}
local attackCount = 4
local selectedAttack = attacks.SWING

local player = {x = 50, y = screen_height / 2}
local enemy = {x = screen_width - 50 - 25 / 2, y = screen_height / 2}

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

local function draw()
    love.graphics.setColor(0, 255, 0, 1)
    love.graphics.rectangle("fill", player.x, player.y, 25, 40)
    love.graphics.setColor(255, 0, 0, 1)
    love.graphics.rectangle("fill", enemy.x, enemy.y, 25, 40)
    love.graphics.setColor(255, 255, 255, 1)

    love.graphics.rectangle("line", movebox.x, movebox.y, movebox.width, movebox.height)
    love.graphics.draw(arrow, lerp(movebox.x - 60, 10, math.cos(love.timer.getTime())), movebox.y + 24 * selectedAttack + 8)
    love.graphics.print("Swing sword", movebox.x + 10, movebox.y + attacks.SWING * 24 + 16)
    love.graphics.print("Bash shield", movebox.x + 10, movebox.y + attacks.BASH * 24 + 16)
    love.graphics.print("Kick", movebox.x + 10, movebox.y + attacks.KICK * 24 + 16)
    love.graphics.print("Just Chill", movebox.x + 10, movebox.y + attacks.CHILL * 24 + 16)
end

function getSelection()
    local temp = selectionMade
    selectionMade = nil
    return temp
end

local function load()
    arrow = love.graphics.newImage("gpx/arrow_temp.png")
end

rpg = {
    update = update,
    draw = draw,
    load = load,
    selectionMade = getSelection
}