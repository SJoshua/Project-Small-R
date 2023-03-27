local reboot = {
    func = function(msg)
        local ret = bot.sendMessage(msg.chat.id, nil, "rebooting...", nil, nil, nil, msg.message_id)

        os.execute("nohup lua main.lua > ../log/" .. os.date("%Y_%m_%d") .. ".log &")

        bot.editMessageText(msg.chat.id, ret.result.message_id, nil, "rebooting...\ndone.", "Markdown")

        os.exit()
    end,
    desc = "Reboot myself.",
    limit = {
        master = true
    }
}

return reboot
