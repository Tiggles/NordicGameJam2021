local scale = 1.5
local stamp_width = 128
-- Temporary (as if)
local margin_stamp = 32
local initial_stamp_offset = 180
local y_offset_stamp = 52
local next_form = 0.5
local paused = false

local form_speed = 400
local form_height = 60 * scale
local beltSpeed = 0.8
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
    [0] = {x = initial_stamp_offset, y = y_offset_stamp, color = {r = 255, g = 0, b = 0}, forms = {}, accepted_forms = {}},
    [1] = {x = initial_stamp_offset + (1 * stamp_width) + (1 * margin_stamp), y = y_offset_stamp, color = {r = 0, g = 255, b = 0}, forms = {}},
    [2] = {x = initial_stamp_offset + (2 * stamp_width) + (2 * margin_stamp), y = y_offset_stamp, color = {r = 0, g = 0, b = 255}, forms = {}},
    [3] = {x = initial_stamp_offset + (3 * stamp_width) + (3 * margin_stamp), y = y_offset_stamp, color = {r = 255, g = 165, b = 0}, forms = {}},
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
    p = 0,
    a = 0,
    s = 0,
    d = 0,
    f = 0
}

function drawStampsAndForms()
    love.graphics.setColor(191 / 255, 111 / 255, 74 / 255, 1)
    love.graphics.rectangle("fill", 0, 0, 960, 540)
    love.graphics.setColor(255, 255, 255, 1)

    for i = 0, #grid do
        local row = grid[i]

        for k = 1, 24 do
            love.graphics.draw(gfx.belt, gfx.beltQuads[(i + math.floor(beltValue)) % #gfx.beltQuads], row.x - 16, 24 * k - 24, 0, 1.5, 1.5)
            if not getWinCondition() then
                beltValue = beltValue + love.timer.getDelta() * beltSpeed
            end

        end

        local paper = gfx.paper[i]
        for j = 1, #row.forms do
            local form = row.forms[j]
            love.graphics.draw(paper, row.x - 8, form.y, 0, scale, scale)
            if form.accepted ~= -1 then
                love.graphics.setColor(0, 255, 0, 1)
                love.graphics.rectangle("fill", row.x + 2, form.y + form.accepted, 35, 5)
                love.graphics.setColor(255, 255, 255, 1)
            end
        end

        local key = ""
        if colorEnum.BLUE == i then
            key = "a"
        elseif colorEnum.RED == i then
            key = "s"
        elseif colorEnum.GREEN == i then
            key = "d"
        elseif colorEnum.ORANGE == i then
            key = "f"
        end

        love.graphics.print(key, row.x + 25, row.y - 30)
        love.graphics.draw(gfx.stamps[i], row.x, lerp(row.y, row.y + 80, math.max(key_cooldowns[key], 0)), 0, scale, scale)
    end

    if paused then
        love.graphics.print("Paused", 960 / 2, 540 / 2)
    end

    love.graphics.print(stats.success .. "/" .. stats.missed + stats.success, 5, 10)
end

function draw()
    drawStampsAndForms()
end

function isKeyPressed(key, cooldowns)
    return love.keyboard.isDown(key) and cooldowns[key] <= 0
end

function updateKeyCooldowns(keys, delta)
    keys["p"] = keys["p"] - delta;
    keys["a"] = keys["a"] - delta;
    keys["s"] = keys["s"] - delta;
    keys["d"] = keys["d"] - delta;
    keys["f"] = keys["f"] - delta;
end

function setKeyCooldown(key, cooldowns, cooldown_time)
    cooldowns[key] = cooldown_time
end

function updateFormsOnCollision(stamp)
    for i = #stamp.forms, 1, -1 do
        if (isColliding(stamp.y, stamp.forms[i].y)) then
            stats.success = stats.success + 1
            stamp.forms[i].accepted = stamp.y + 20
        end
    end
end

function isColliding(stamp_y, form_y)
    return math.abs(stamp_y - form_y) <= form_height;
end

function update(delta)
    updateKeyCooldowns(key_cooldowns, delta)

    if getWinCondition() then
        if love.keyboard.isDown("space") and love.timer.getTime() > time_finish_allowed then
            running = false
        end
        return
    end

    if isKeyPressed("p", key_cooldowns) then
        paused = not paused
        setKeyCooldown("p", key_cooldowns, 0.5)
    end

    if paused then return end

    if isKeyPressed("a", key_cooldowns) then
        -- BLUE
        updateFormsOnCollision(grid[colorEnum.BLUE])

        love.audio.newSource(sfx[sfxEnum.STAMP]):play()
        setKeyCooldown("a", key_cooldowns, 0.2)
    end

    if isKeyPressed("s", key_cooldowns) then
        -- RED
        updateFormsOnCollision(grid[colorEnum.RED])

        love.audio.newSource(sfx[sfxEnum.STAMP]):play()
        setKeyCooldown("s", key_cooldowns, 0.2)
    end

    if isKeyPressed("d", key_cooldowns) then
        -- GREEN
        updateFormsOnCollision(grid[colorEnum.GREEN])

        love.audio.newSource(sfx[sfxEnum.STAMP]):play()
        setKeyCooldown("d", key_cooldowns, 0.2)
    end

    if isKeyPressed("f", key_cooldowns) then
        -- ORANGE
        updateFormsOnCollision(grid[colorEnum.ORANGE])

        love.audio.newSource(sfx[sfxEnum.STAMP]):play()
        setKeyCooldown("f", key_cooldowns, 0.2)
    end


    for i = 0, #grid do
        for j = 1, #grid[i].forms do
            grid[i].forms[j].y = grid[i].forms[j].y - form_speed * delta
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
    return stats.missed == 0 and stats.success >= 5
end

stampHero = {
    draw = draw,
    update = update,
    load = load,
    running = true,
    getWinCondition = getWinCondition
}