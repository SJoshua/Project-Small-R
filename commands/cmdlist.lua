local cmdlist = {
    func = function (msg)
        local t = {}
        for cmd, v in pairs(commands) do
            if not (v.limit and v.limit.master) then
                table.insert(t, cmd)
            end
        end
        table.sort(t)
        local text = ""
        for i = 1, #t do
            text = text .. string.format("`%s` - %s\n", t[i] or ("/" .. t[i]), commands[t[i]].desc)
        end
        bot.sendMessage(msg.chat.id, text, "Markdown")
    end,
    desc = "Generate command list.",
    limit = {
        master = true
    }
}

return cmdlist
