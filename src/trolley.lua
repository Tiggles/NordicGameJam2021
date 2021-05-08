local m = {}

--region Util
local function hexColor(hex, alpha)
    if alpha == nil then
        alpha = 1
    end
    hex = hex:gsub("#", "")
    return {
        tonumber("0x" .. hex:sub(1, 2)) / 255,
        tonumber("0x" .. hex:sub(3, 4)) / 255,
        tonumber("0x" .. hex:sub(5, 6)) / 255,
        alpha
    }
end

-- This is similar to love.graphics.rectangle, except that the rectangle has
-- rounded corners. r = radius of the corners, n ~ #points used in the polygon.
function rounded_rectangle(mode, x, y, w, h, r, n)
    n = n or 20  -- Number of points in the polygon.
    if n % 4 > 0 then
        n = n + 4 - (n % 4)
    end  -- Include multiples of 90 degrees.
    local pts, c, d, i = {}, { x + w / 2, y + h / 2 }, { w / 2 - r, r - h / 2 }, 0
    while i < n do
        local a = i * 2 * math.pi / n
        local p = { r * math.cos(a), r * math.sin(a) }
        for j = 1, 2 do
            table.insert(pts, c[j] + d[j] + p[j])
            if p[j] * d[j] <= 0 and (p[1] * d[2] < p[2] * d[1]) then
                d[j] = d[j] * -1
                i = i - 1
            end
        end
        i = i + 1
    end
    love.graphics.polygon(mode, pts)
end
--endregion Util

--region Button
---@class Button
local Button = {}

---@param key string
function Button:new(key, x, y, color, keyColor)
    local t = setmetatable({}, { __index = Button })
    t.key = key
    t.x = x
    t.y = y
    t.color = color
    t.keyColor = keyColor
    return t
end

function Button:draw()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)

    love.graphics.setColor(self.color)
    rounded_rectangle("fill", 0, 0, 64, 64, 8, 20)

    love.graphics.setColor(self.keyColor)
    love.graphics.print(self.key, 10, 5)

    love.graphics.pop()
end

--endregion Button

local DIRECTION_LEFT = 1
local DIRECTION_RIGHT = 2
local DIRECTION_HALLWAY = 3

local blockInput = false

local randomSignatures = {
    "fie",
    "hund",
    "gooddog"
}

local emotions = {}

local mailColors = {
    hexColor("#0e82ce"),
    hexColor("#509b4b"),
    hexColor("#f7ac37"),
    hexColor("#c42c36")
}

local papers = {}

local tickSpeedI = 1
local tickSpeeds = {
    300,
    250,
    200,
    180,
    150,
    120,
}

local nColumnsX = 24
local nColumnsY = 14
local columnSize = love.graphics.getWidth() / nColumnsX

--region Timer
local tickSpeedDefault = 300
local currentTickSpeed = tickSpeedDefault
local allTimers = {}

---@class Timer
local Timer = {}
function Timer:new(timeRemaining)
    local t = setmetatable({}, { __index = Timer })
    t.originalTimer = timeRemaining
    t.previousWholeRemaining = -1
    t.timeRemaining = math.ceil(timeRemaining)
    t.wholeRemaining = math.ceil(timeRemaining)
    table.insert(allTimers, t)
    return t
end

function Timer:set(timeRemaining)
    self.originalTimer = timeRemaining
    self.previousWholeRemaining = -1
    self.timeRemaining = math.ceil(timeRemaining)
    self.wholeRemaining = math.ceil(timeRemaining)
end

function Timer:reset()
    self:set(self.originalTimer)
end

function Timer:didTrigger(wholeRemaining)
    return self.previousWholeRemaining ~= self.wholeRemaining and self.wholeRemaining == wholeRemaining
end

local function timers_update(dt)
    local fractionalTick = (dt * 1000) / currentTickSpeed
    for i, timer in ipairs(allTimers) do
        timer.previousWholeRemaining = timer.wholeRemaining
        timer.wholeRemaining = math.ceil(timer.timeRemaining)
        timer.timeRemaining = timer.timeRemaining - fractionalTick
    end
end
--endregion Timer

--region GameTimers
local officeTimer = Timer:new(6)
local speedTimer = Timer:new(12)
--endregion GameTimers

--region Office
local officeMarginX = 1
local officeColumns = 6
local officeWidth = officeColumns - officeMarginX * 2
local officeHeight = 2
local offices = {}

---@class Office
local Office = {}
function Office:new()
    local t = setmetatable({}, { __index = Office })
    t.timer = Timer:new(14)
    t.type = love.math.random(4)
    t.side = love.math.random(2)
    t.pointsAwarded = -1
    t.requiresSignature = love.math.random(4) == 1
    return t
end

function Office:location()
    return {
        self.side == DIRECTION_LEFT and
                (officeMarginX * columnSize) or
                love.graphics.getWidth() - officeMarginX * columnSize - officeWidth * columnSize,
        (14 - self.timer.timeRemaining) * columnSize
    }
end

function Office:draw()
    love.graphics.push()
    love.graphics.setColor(mailColors[self.type])
    local loc = self:location()
    love.graphics.translate(loc[1], loc[2])
    love.graphics.rectangle("fill", 0, 0, officeWidth * columnSize, officeHeight * columnSize)

    if self.pointsAwarded >= 0 then
        love.graphics.setColor(255, 255, 255)

        if not self.correctMail then
            love.graphics.draw(emotions[5], 20, 20)
        elseif self.pointsAwarded == 0 then
            love.graphics.draw(emotions[1], 20, 20)
        elseif self.pointsAwarded == 10 then
            love.graphics.draw(emotions[2], 20, 20)
        elseif self.pointsAwarded == 20 then
            love.graphics.draw(emotions[3], 20, 20)
        elseif self.pointsAwarded == 30 then
            love.graphics.draw(emotions[4], 20, 20)
        end
    end

    -- Button
    love.graphics.translate(officeWidth * columnSize - 32 - 10, officeHeight * columnSize - 32 - 10)
    love.graphics.scale(0.5, 0.5)
    local buttonRequired
    if self.type == 1 then
        buttonRequired = "Q"
    elseif self.type == 2 then
        buttonRequired = "W"
    elseif self.type == 3 then
        buttonRequired = "E"
    elseif self.type == 4 then
        buttonRequired = "R"
    end
    Button:new(buttonRequired, 0, 0, hexColor("#454545"), hexColor("#ffffff")):draw()
    -- End button
    love.graphics.pop()
end

function Office:update(dt)

end
--endregion Office

--region Signature
local Signature = {
    signatureRequired = nil,
    signatureSoFar = "",
    timer = 0
}

function Signature:activate()
    self.signatureRequired = randomSignatures[love.math.random(#randomSignatures)]
    self.timer = 5
    self.signatureSoFar = ""
    blockInput = true

    currentTickSpeed = 800
end

function Signature:deactivate()
    currentTickSpeed = tickSpeeds[tickSpeedI]
    self.signatureRequired = nil
    blockInput = false
end

function Signature:update(dt)
    if self.signatureRequired == nil then
        return
    end

    if self.signatureRequired == self.signatureSoFar then
        self:deactivate()
    end

    self.timer = self.timer - dt
    if self.timer < 0 then
        self:deactivate()
    end
end

function Signature:draw()
    if self.signatureRequired == nil then
        return
    end

    love.graphics.push()
    local width = 400
    local height = 210
    love.graphics.translate((love.graphics.getWidth() - width) / 2, (love.graphics.getHeight() - height) / 2)
    love.graphics.setColor(hexColor("#393a56"))
    love.graphics.rectangle("fill", 0, 0, width, height)

    love.graphics.push()
    love.graphics.translate(10, 10)
    love.graphics.setColor(hexColor("#a3acbe"))
    love.graphics.print("Signature required:")

    love.graphics.push()
    love.graphics.translate(0, 50)
    for i = 1, string.len(self.signatureRequired) do
        local char = self.signatureRequired:sub(i, i)
        local charInput = nil
        if string.len(self.signatureSoFar) >= i then
            charInput = self.signatureSoFar:sub(i, i)
        end

        if charInput ~= nil and charInput ~= char then
            love.graphics.setColor(hexColor("#c42c36"))
            love.graphics.print(char, 0, 0)
        elseif charInput ~= nil then
            love.graphics.setColor(hexColor("#509b4b"))
            love.graphics.print(char, 0, 0)
        else
            love.graphics.setColor(hexColor("#a3acbe"))
            love.graphics.print(char, 0, 0)
        end
        love.graphics.translate(20, 0)
    end
    love.graphics.pop()
    love.graphics.pop()

    love.graphics.setColor(hexColor("#c42c36"))
    love.graphics.rectangle("fill", 0, height - 10, (self.timer / 5) * width, 10)

    love.graphics.pop()
end

function Signature:keypressed(key)
    if key == "backspace" then
        local strlen = string.len(self.signatureSoFar)
        if strlen >= 1 then
            self.signatureSoFar = string.sub(self.signatureSoFar, 1, strlen - 1)
        end
    end
end

function Signature:textinput(t)
    self.signatureSoFar = self.signatureSoFar .. t
end
--endregion Signature

--region Mail
local Mail = {}
---@class Mail
---@param target Office
function Mail:new(sx, sy, target, type)
    local t = setmetatable({}, { __index = Mail })
    t.sx = sx
    t.sy = sy
    t.target = target
    t.initial_time = 0.4
    t.timer = t.initial_time
    t.type = type
    return t
end
function Mail:draw()
    love.graphics.push()
    local targetLoc = self.target:location()
    love.graphics.setColor(255, 255, 255)
    love.graphics.translate(
            lerp2(self.sx, targetLoc[1], (self.initial_time - self.timer) / self.initial_time),
            lerp2(self.sx, targetLoc[2], (self.initial_time - self.timer) / self.initial_time)
    )
    love.graphics.draw(papers[self.type])
    love.graphics.pop()
end
function Mail:update(dt)
    self.timer = self.timer - dt
end
--endregion

--region Trolley
local trolleyWidth = 3
local trolleyMarginX = (nColumnsX - officeColumns * 2 - trolleyWidth) / 2
local trolleyMarginY = 2
local trolleyHeight = 2

local trolleyTexture
local trolleyAnimation = {}

local Trolley = {}
function Trolley:new()
    local t = setmetatable({}, { __index = Trolley })
    t.mailTypeSelected = 1
    t.deliverDirection = nil
    t.trolleyAnimTimer = Timer:new(2)
    t.animFrame = 1
    t.score = 0
    t.mails = {}
    return t
end

function Trolley:location()
    return {
        (officeColumns + trolleyMarginX) * columnSize,
        love.graphics.getHeight() - trolleyMarginY * columnSize - trolleyHeight * columnSize
    }
end

function Trolley:update(dt)
    if not blockInput then
        if love.keyboard.isDown("q") then
            self.mailTypeSelected = 1
        elseif love.keyboard.isDown("w") then
            self.mailTypeSelected = 2
        elseif love.keyboard.isDown("e") then
            self.mailTypeSelected = 3
        elseif love.keyboard.isDown("r") then
            self.mailTypeSelected = 4
        end

        if love.keyboard.isDown("i") then
            self.deliverDirection = DIRECTION_LEFT
        elseif love.keyboard.isDown("o") then
            self.deliverDirection = DIRECTION_HALLWAY
        elseif love.keyboard.isDown("p") then
            self.deliverDirection = DIRECTION_RIGHT
        else
            self.deliverDirection = nil
        end
    else
        self.deliverDirection = nil
    end

    if self.trolleyAnimTimer.timeRemaining <= 0 then
        self.animFrame = self.animFrame == 1 and 2 or 1
        self.trolleyAnimTimer:reset()
    end

    if self.deliverDirection ~= nil and #offices >= 1 then
        if offices[1].pointsAwarded == -1 then
            offices[1].correctMail = offices[1].type == self.mailTypeSelected

            local points = 0
            local t = offices[1].timer.wholeRemaining
            if offices[1].side ~= self.deliverDirection then
                points = 0
                offices[1].correctMail = true
            elseif not offices[1].correctMail then
                points = 0
            elseif t == 2 or t == 6 then
                points = 10
            elseif t == 3 or t == 5 then
                points = 20
            elseif t == 2 or t == 4 then
                points = 30
            end

            if points > 0 and offices[1].requiresSignature then
                Signature:activate()
            end

            if points > 0 then
                local loc = self:location()
                print(loc[1])
                table.insert(self.mails, Mail:new(loc[1], loc[2], offices[1], self.mailTypeSelected))
            end

            offices[1].pointsAwarded = points
        end
    end

    for i, mail in ipairs(self.mails) do
        mail:update(dt)
        if mail.timer <= 0 then
            table.remove(self.mails, i)
        end
    end
end

function Trolley:draw()
    -- The score
    love.graphics.setColor(255, 255, 255)
    love.graphics.print("Score: " .. self.score, 300, 30)

    -- The trolley
    love.graphics.push()
    local loc = self:location()
    love.graphics.translate(loc[1], loc[2])

    love.graphics.setColor(255, 255, 255)
    love.graphics.push()
    love.graphics.translate(7, 0)
    love.graphics.scale(2, 2)
    love.graphics.draw(trolleyTexture, trolleyAnimation[self.animFrame], 0, 0)
    love.graphics.pop()

    love.graphics.setColor(hexColor("#ffffff"))
    if self.deliverDirection == DIRECTION_LEFT then
        love.graphics.print("👈", -35, trolleyHeight / 2 * columnSize - 15)
    elseif self.deliverDirection == DIRECTION_RIGHT then
        love.graphics.print("👉", trolleyWidth * columnSize + 10, trolleyHeight / 2 * columnSize - 15)
    elseif self.deliverDirection == DIRECTION_HALLWAY then
        love.graphics.print("👆", trolleyWidth / 2 * columnSize - 7, -35)
    end

    love.graphics.setColor(mailColors[self.mailTypeSelected])

    -- The buttons
    love.graphics.push()
    love.graphics.scale(0.5, 0.5)
    love.graphics.translate(0, -100)
    Button:new("Q", 0, self.mailTypeSelected == 1 and -16 or 0, mailColors[1], hexColor("#000000")):draw()
    love.graphics.translate(80, 0)
    Button:new("W", 0, self.mailTypeSelected == 2 and -16 or 0, mailColors[2], hexColor("#000000")):draw()
    love.graphics.translate(80, 0)
    Button:new("E", 0, self.mailTypeSelected == 3 and -16 or 0, mailColors[3], hexColor("#000000")):draw()
    love.graphics.translate(80, 0)
    Button:new("R", 0, self.mailTypeSelected == 4 and -16 or 0, mailColors[4], hexColor("#000000")):draw()
    love.graphics.pop()

    love.graphics.pop()

    for i, mail in ipairs(self.mails) do
        mail:draw()
    end
end

local player = Trolley:new()
--endregion Trolley

function m.draw()
    love.graphics.clear(hexColor("#bf6f4a"))

    player:draw()

    for i, office in ipairs(offices) do
        office:draw()
    end

    Button:new("I", 88, love.graphics.getHeight() - (64 + 32), hexColor("#454545"), hexColor("#ffffff")):draw()
    Button:new("P", love.graphics.getWidth() - 240 + 88, love.graphics.getHeight() - (64 + 32), hexColor("#454545"), hexColor("#ffffff")):draw()
    Signature:draw()
end

function m.update(dt)
    if love.keyboard.isDown("lctrl") and love.keyboard.isDown("r") then
        love.event.quit("restart")
    end

    timers_update(dt)

    if officeTimer.timeRemaining <= 0 then
        table.insert(offices, Office:new())
        officeTimer:reset()
    end

    if speedTimer.timeRemaining <= 0 and tickSpeedI < #tickSpeeds and Signature.signatureRequired == nil then
        tickSpeedI = tickSpeedI + 1
        currentTickSpeed = tickSpeeds[tickSpeedI]
        speedTimer:reset()
    end

    for i, office in ipairs(offices) do
        office:update()
        if office.timer.timeRemaining <= 0 then
            table.remove(offices, i)
        end
    end

    player:update(dt)
    Signature:update(dt)
end

function m.load()
    trolleyTexture = love.graphics.newImage("gpx/mailtrolley.png")
    table.insert(trolleyAnimation, love.graphics.newQuad(0, 0, 50, 70, trolleyTexture))
    table.insert(trolleyAnimation, love.graphics.newQuad(50, 0, 50, 70, trolleyTexture))

    table.insert(emotions, love.graphics.newImage("gpx/emote_faceAngry.png"))
    table.insert(emotions, love.graphics.newImage("gpx/emote_faceSad.png"))
    table.insert(emotions, love.graphics.newImage("gpx/emote_faceHappy.png"))
    table.insert(emotions, love.graphics.newImage("gpx/emote_heart.png"))
    table.insert(emotions, love.graphics.newImage("gpx/emote_question.png"))

    table.insert(papers, love.graphics.newImage("gpx/paper_blue.png"))
    table.insert(papers, love.graphics.newImage("gpx/paper_green.png"))
    table.insert(papers, love.graphics.newImage("gpx/paper_orange.png"))
    table.insert(papers, love.graphics.newImage("gpx/paper_red.png"))

    love.keyboard.setKeyRepeat(true)
end

function m.keypressed(key)
    Signature:keypressed(key)
end

function m.textinput(t)
    Signature:textinput(t)
end

return m
