local trolley = require "trolley"
PI = 3.14159
RAD2DEG = 180.0 / PI
DEG2RAD = PI / 180

function lerp(a, b, t)
    return (a + (b - a) * t)
end

function love.draw(dt)
    love.graphics.setFont(font)
    trolley.draw()
end

function love.update(dt)
    trolley.update(dt)
end

function love.load(arg)
    font = love.graphics.newFont("assets/OpenSansEmoji.ttf", 20)
    trolley.load()
end

function love.keypressed(key)
    trolley.keypressed(key)
end

function love.textinput(t)
    trolley.textinput(t)
end