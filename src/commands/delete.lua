local delete = {
    func = function(msg)
        bot.deleteMessage(msg.chat.id, msg.reply_to_message.message_id)
    end,
    desc = "Delete message.",
    limit = {
        master = true,
        reply = true
    }
}

return delete
