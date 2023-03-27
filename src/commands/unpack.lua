local utils = require("utils")

local unpack = {
    func = function(msg)
        bot.sendMessage(msg.chat.id, nil, "```\n" .. utils.encode(msg) .. "\n```", "Markdown")
    end,
    desc = "Unpack current message."
}

return unpack
