local fetch = {
    func = function(msg)
        local f = io.popen("cd ~/small-r/Project-Small-R/ && git pull", "r")
        local s = f:read("*a")
        f:close()

        if (s:find("Already up to date")) then
            bot.sendMessage{
                chat_id = msg.chat.id,
                reply_to_message_id = msg.message_id,
                text = "Already up to date."
            }
        else 
            local f = io.popen("cd ~/small-r/Project-Small-R/ && git log -1", "r")
            local s = f:read("*a")
            f:close()

            bot.sendMessage{
                chat_id = msg.chat.id,
                reply_to_message_id = msg.message_id,
                text = "*[latest commit]*\n```\n" .. s .. "\n```",
                parse_mode = "Markdown"
            }

            return commands.reload.func(msg)
        end
    end,
    desc = "fetch latest code.",
    limit = {
        master = true
    }
}

return fetch