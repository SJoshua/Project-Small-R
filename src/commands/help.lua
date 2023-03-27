local help = {
    generate = function(all)
        local t = {}
        for cmd, v in pairs(commands) do
            if not (v.limit and v.limit.master) or all then
                table.insert(t, cmd)
            end
        end
        table.sort(t)
        local text = ""
        for i = 1, #t do
            text = text .. string.format("`%s` - %s\n", commands[t[i]].form or ("/" .. t[i]), commands[t[i]].desc)
        end
        return text
    end,
    func = function(msg, cmd)
        local cmd = cmd or tostring(msg.text:match("/help%s*(%S+)%s*"))
        if commands[cmd] then
            bot.sendMessage(msg.chat.id, nil,
                (commands[cmd].limit and commands[cmd].limit.master and "*[master command]*\n" or "") ..
                string.format("`%s`\n%s", commands[cmd].form or ("/" .. cmd), commands[cmd].help or commands[cmd].desc),
                "Markdown", nil, nil, msg.message_id)
        else
            bot.sendMessage(msg.chat.id, nil, commands.help.generate(msg.text:find("_all")), "Markdown")
        end
    end,
    form = "/help <command>",
    desc = "Help.",
    help = "e.g. `/help find`"
}

return help
