local start = {
    func = function(msg)
        bot.sendMessage(msg.chat.id, "Hello, this is " .. bot.info.first_name .. ".")
    end,
    desc = "Start with me!"
}

return start