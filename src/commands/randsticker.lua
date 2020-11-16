local randsticker = {
    func = function(msg)
        -- bot.sendSticker(msg.chat.id, sticker.get())
    end,
    desc = "Want a sticker?",
    limit = {
        disable = true,
    }
}

return randsticker
