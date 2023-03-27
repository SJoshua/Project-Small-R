local lisp = {
    func = function(msg, slient)
        local code = msg.text:match("(%(.+%))")
        local f = io.open("code.lisp", "w")
        f:write(code)
        f:close()
        os.execute("cat code.lisp | scheme -q > output")
        local f = io.open("output", "r")
        local res = f:read("*a")
        f:close()
        if not res:find("Exception") or not slient then
            bot.sendMessage(msg.chat.id, nil, "*[Result]*```\n" .. res .. "```", "Markdown", nil, nil, msg.message_id)
        end
    end,
    desc = "Execute code in scheme.",
    limit = {
        master = true
    }
}

return lisp
