local forward = {
    func = function(msg)
        local mid = tonumber(msg.text:match("/forward%s*(%d+)%s*"))
        local chat_id = tonumber(msg.text:match("@(%-?%d+)")) or msg.chat.id
        local res = bot.forwardMessage(msg.chat.id, chat_id, false, mid)
        if not res.ok then
            bot.sendMessage(msg.chat.id, "Sorry, not found.")
        end
    end,
    form = "/forward <msgID> [@chatID]",
    desc = "Forward specific message.",
    help = "e.g. `/forward 2333`",
    limit = {
        match = "/forward%s*(%d+)%s*",
        master = true
    }
}

return forward
