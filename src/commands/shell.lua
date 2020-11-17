local shell = {
    func = function(msg)
        local cmd = msg.text:match("/shell%s*(.-)%s*$")"
        local f = io.popen(cmd, "r")
        local res = f:read("*a")
        f:close()
        bot.sendMessage(msg.chat.id, "[result]\n" .. tostring(res), nil, nil, nil, msg.message_id)
    end,
    form = "/shell <command>",
    desc = "Execute shell.",
    help = "e.g. `/shell echo hey`",
    limit = {
        master = true,
        match = "/shell%s*(.-)%s*$"
    }
}

return shell
