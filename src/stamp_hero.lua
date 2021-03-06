local scale = 1.5
local stamp_width = 128

local rpg = require("rpg")
-- Temporary (as if)
local margin_stamp = 32
local initial_stamp_offset = 180
local y_offset_stamp = 52
local next_form = 0.5
local running = true
local time_finish_allowed = 0

local form_speed = 400
local form_height = 60 * scale
local beltSpeed = 0.5
local beltValue = 0
local colorEnum = {
    BLUE = 0,
    RED = 1,
    GREEN = 2,
    ORANGE = 3
}

local stats = {
    missed = 0,
    success = 0
}

local sfxEnum = {
    STAMP = 0
}

local gfx = {}
gfx.paper = {}
gfx.stamps = {}
gfx.beltQuads = {}
sfx = {}

local grid = {
    [0] = {x = initial_stamp_offset, y = y_offset_stamp, forms = {}, accepted_forms = {}},
    [1] = {x = initial_stamp_offset + (1 * stamp_width) + (1 * margin_stamp), y = y_offset_stamp, forms = {}},
    [2] = {x = initial_stamp_offset + (2 * stamp_width) + (2 * margin_stamp), y = y_offset_stamp, forms = {}},
    [3] = {x = initial_stamp_offset + (3 * stamp_width) + (3 * margin_stamp), y = y_offset_stamp, forms = {}},
}
function load()
    gfx.paper[colorEnum.BLUE] = love.graphics.newImage("gpx/paper_blue.png")
    gfx.paper[colorEnum.RED] = love.graphics.newImage("gpx/paper_red.png")
    gfx.paper[colorEnum.GREEN] = love.graphics.newImage("gpx/paper_green.png")
    gfx.paper[colorEnum.ORANGE] = love.graphics.newImage("gpx/paper_orange.png")

    gfx.stamps[colorEnum.BLUE] = love.graphics.newImage("gpx/stamp_blue.png")
    gfx.stamps[colorEnum.RED] = love.graphics.newImage("gpx/stamp_red.png")
    gfx.stamps[colorEnum.GREEN] = love.graphics.newImage("gpx/stamp_green.png")
    gfx.stamps[colorEnum.ORANGE] = love.graphics.newImage("gpx/stamp_orange.png")

    gfx.belt = love.graphics.newImage("gpx/belt.png");

    for i = 0, 8 do
        gfx.beltQuads[i] = love.graphics.newQuad(i * 60, 0, 60, 16, 480, 16)
    end

    sfx[sfxEnum.STAMP] = love.sound.newSoundData("sfx/stamp.wav")
end

local key_cooldowns = {
    q = 0,
    w = 0,
    e = 0,
    r = 0
}

function isGameOver()
    return stats.missed > 0 or stats.success >= 5
end

function drawStampsAndForms()
    love.graphics.setColor(191 / 255, 111 / 255, 74 / 255, 1)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    love.graphics.setColor(1, 1, 1, 1)

    for i = 0, #grid do
        local row = grid[i]

        for k = 1, 24 do
            love.graphics.draw(gfx.belt, gfx.beltQuads[(i + math.floor(beltValue)) % #gfx.beltQuads], row.x - 16, 24 * k - 24, 0, 1.5, 1.5)
            if not isGameOver() then
                beltValue = beltValue + love.timer.getDelta() * beltSpeed
            end

        end

        local paper = gfx.paper[i]
        for j = 1, #row.forms do
            local form = row.forms[j]
            love.graphics.draw(paper, row.x - 8, form.y, 0, scale, scale)
            if form.accepted ~= -1 then
                love.graphics.setColor(0, 1, 0, 1)
                love.graphics.rectangle("fill", row.x + 2, form.y + form.accepted, 50, 8)
                love.graphics.setColor(1, 1, 1, 1)
            end
        end

        local key = ""
        if colorEnum.BLUE == i then
            key = "q"
        elseif colorEnum.RED == i then
            key = "w"
        elseif colorEnum.GREEN == i then
            key = "e"
        elseif colorEnum.ORANGE == i then
            key = "r"
        end

        love.graphics.print(key, row.x + 22, row.y - 30)
        love.graphics.draw(gfx.stamps[i], row.x, lerp(row.y, row.y + 80, math.max(key_cooldowns[key], 0)), 0, scale, scale)
    end

    love.graphics.print(stats.success .. "/" .. 5, 5, 10)

    if isGameOver() then

        if (resultText ~= "") then
            local text
            if getWinCondition() then
                text = love.graphics.newText(font, "Application approved.\nPress SPACE to continue")
            else
                text = love.graphics.newText(font, "Application rejected.\nPress SPACE to continue")
            end

            love.graphics.setColor(255, 255, 255)
            love.graphics.draw(
                    text,
                    (love.graphics.getWidth() - text:getWidth()) / 2,
                    (love.graphics.getHeight() - text:getHeight()) / 2
            )
        end
    end
end

function draw()
    drawStampsAndForms()
end

function isKeyPressed(key, cooldowns)
    return love.keyboard.isDown(key) and cooldowns[key] <= 0
end

function updateKeyCooldowns(keys, delta)
    keys["q"] = keys["q"] - delta;
    keys["w"] = keys["w"] - delta;
    keys["e"] = keys["e"] - delta;
    keys["r"] = keys["r"] - delta;
end

function setKeyCooldown(key, cooldowns, cooldown_time)
    cooldowns[key] = cooldown_time
end

function updateFormsOnCollision(stamp)
    for i = #stamp.forms, 1, -1 do
        if isColliding(stamp.y, stamp.forms[i].y) and stamp.forms[i].accepted == -1 then
            stats.success = stats.success + 1
            stamp.forms[i].accepted = stamp.y + 20
        end
    end
end

function isColliding(stamp_y, form_y)
    return stamp_y + 80 > form_y and stamp_y < form_y + form_height
end

function update(delta)
    updateKeyCooldowns(key_cooldowns, delta)

    if isGameOver() then
        if time_finish_allowed == 0 then
            time_finish_allowed = love.timer.getTime() + 0.2
        end
        if love.keyboard.isDown("space") and love.timer.getTime() > time_finish_allowed then
            running = false
        end
        return
    end

    if paused then return end

    if isKeyPressed("q", key_cooldowns) then
        -- BLUE
        updateFormsOnCollision(grid[colorEnum.BLUE])

        love.audio.newSource(sfx[sfxEnum.STAMP]):play()
        setKeyCooldown("q", key_cooldowns, 0.2)
    end

    if isKeyPressed("w", key_cooldowns) then
        -- RED
        updateFormsOnCollision(grid[colorEnum.RED])

        love.audio.newSource(sfx[sfxEnum.STAMP]):play()
        setKeyCooldown("w", key_cooldowns, 0.2)
    end

    if isKeyPressed("e", key_cooldowns) then
        -- GREEN
        updateFormsOnCollision(grid[colorEnum.GREEN])

        love.audio.newSource(sfx[sfxEnum.STAMP]):play()
        setKeyCooldown("e", key_cooldowns, 0.2)
    end

    if isKeyPressed("r", key_cooldowns) then
        -- ORANGE
        updateFormsOnCollision(grid[colorEnum.ORANGE])

        love.audio.newSource(sfx[sfxEnum.STAMP]):play()
        setKeyCooldown("r", key_cooldowns, 0.2)
    end


    for i = 0, #grid do
        for j = 1, #grid[i].forms do
            grid[i].forms[j].y = grid[i].forms[j].y - form_speed * delta * ((rpg.difficulty() + 1) / 2)
        end
    end

    next_form = next_form - love.timer.getDelta()

    if next_form <= 0 then
        local row = math.random(0, 3)
        next_form = 0.2 + math.random()
        table.insert(grid[row].forms, { y = 545, accepted = -1 })
    end

    for i = 0, #grid do
        local stamp = grid[i]
        for j = #stamp.forms, 1, -1 do
            if stamp.forms[j].y + form_height < 0 then
                if (stamp.forms[j].accepted == -1) then
                    stats.missed = stats.missed + 1
                end
                table.remove(stamp.forms, j)
            end
        end
    end
end

function getWinCondition()
    return stats.missed == 0 and stats.success == 5
end

function isRunning()
    return running
end

function reset()
    stats.success = 0
    stats.missed = 0
    running = true
    beltValue = 0
    grid[colorEnum.BLUE].forms = {}
    grid[colorEnum.RED].forms = {}
    grid[colorEnum.GREEN].forms = {}
    grid[colorEnum.ORANGE].forms = {}
end

return {
    draw = draw,
    update = update,
    load = load,
    isRunning = isRunning,
    reset = reset,
    getWinCondition = getWinCondition
}