local base64 = require("base64")

local base64_command = {
    func = function(msg)
        local txt = msg.text:match("/base64%s*(%S.-)$")
        return bot.sendMessage(msg.chat.id, nil, "*[Encode]*\n```\n" .. tostring(base64.enc(txt)) .. "\n```", "Markdown")
    end,
    form = "/base64 <text>",
    desc = "Encode with base64.",
    limit = {
        match = "/base64%s*(%S.-)$"
    }
}

return base64_command
