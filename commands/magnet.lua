local magnet = {
    func = function(msg)
        return bot.sendMessage(msg.chat.id, string.format("*[Magnet Link]*\n`magnet:?xt=urn:btih:%s`", msg.text:match("/magnet%s*([%a%d]+)")), "Markdown")
    end,
    desc = "Generate magnet link.",
    form = "/magnet <hash>",
    limit = {
        match = "/magnet [%a%d]+"
    }
}

return magnet
