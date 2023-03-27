local base64 = require("base64")

local debase64_command = {
    func = function(msg)
        local txt = msg.text:match("/debase64%s*(%S.-)$")
        return bot.sendMessage(msg.chat.id, nil, "*[Decode]*\n```\n" .. tostring(base64.dec(txt)) .. "\n```", "Markdown")
    end,
    form = "/debase64 <text>",
    desc = "Decode with base64.",
    limit = {
        match = "/debase64%s*(%S.-)$"
    }
}

return debase64_command
