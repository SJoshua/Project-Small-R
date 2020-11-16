local utils = require("utils")

local rand = {
    func = function()
        t = {}
        s = msg.text:match("^/rand(.+)$")
        for opt in s:gmatch("(%S+)") do
            table.insert(t, opt)
        end
        bot.sendMessage(msg.chat.id, string.format("*[rand]*\n```%s```", utils.rand(unpack(t))), "Markdown")
    end,
    form = "/rand option1 option2 ...",
    limit = {
        match = "/rand%s*%S+%s*%S+"
    },
    desc = "Roll 'n' roll!"
}

return rand
