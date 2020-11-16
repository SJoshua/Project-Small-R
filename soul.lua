local soul = {}

local utils = require("utils")

soul.onMessageReceive = function(msg)
    utils.encode(msg)
    if msg.text:find("ping") then
        bot.sendMessage(msg.chat.id, "pong!")
    end
end

setmetatable(soul, {
    __index = function(t, key)
        logger:warn("called undefined processer " .. key)
        return (function() return false end)
    end
})

return soul