local reload = {
    func = function(msg)
        local ret = bot.sendMessage(msg.chat.id, "reloading...", nil, nil, nil, msg.message_id)
        
        local status, err = pcall(bot.reload)

        bot.editMessageText(msg.chat.id, ret.result.message_id, nil, "reloading...\n" .. (status and "done." or err), "Markdown")
    end,
    desc = "Reload my soul.",
    limit = {
        master = true
    }
}

return reload
