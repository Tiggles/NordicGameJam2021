local m = {}
local debug_text = {}
function m.draw()
    for i = 1, #text do
        love.graphics.setColor(255, 255, 255, 255 - (i - 1) * 6)
        love.graphics.print(debug_text[#debug_text - (i - 1)], 10, i * 15)
    end
end
function m.sendMessage(message)
    debug_text[#debug_text + 1] = message
end
return m
