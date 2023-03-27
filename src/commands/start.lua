local start = {
    func = function(msg)
        bot.sendMessage(msg.chat.id, nil, "Hello, this is " .. bot.info.first_name .. ".")
    end,
    desc = "Start with me!"
}

return start