local shell = {
    func = function()
        local cmd = msg.text:match("/shell%s*(.-)%s*$")
        os.execute(cmd .. " > tmp")
        local f = io.open("tmp", "r")
        local res
        if f then
            res = f:read("*a")
            f:close()
        else
            res = "failed to read."
        end
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
