local locate = {
    func = function(msg)
        local mid = tonumber(msg.text:match("/locate%s*(%d+)%s*"))
        local res = bot.sendMessage(msg.chat.id, "Located.", nil, nil, nil, mid)
        if not res.ok then
            bot.sendMessage(msg.chat.id, "Sorry, not found.")
        end
    end,
    form = "/locate <msgID>",
    desc = "Locate specific message.",
    help = "e.g. `/locate 2333`",
    limit = {
        match = "/locate%s*(%d+)%s*"
    }
}

return locate
