local utils = require("utils")

local addcountdown = {
    func = function(msg)
        local list = dofile("countdown_list.lua")

        local year, month, day, hour, min, title = msg.text:match("/addcountdown%s*(%d%d%d%d)%-(%d%d)%-(%d%d)%s*(%d%d):(%d%d)%s*(%S.-)%s*$")

        table.insert(list, {
            year = tonumber(year),
            month = tonumber(month),
            day = tonumber(day),
            hour = tonumber(hour),
            min = tonumber(min),
            title = "`[" .. title .. "]` "
        })

        table.sort(list, function(a, b) 
            return os.time(a) < os.time(b)
        end)

        utils.save(list, "countdown_list.lua")

        bot.sendMessage{
            chat_id = msg.chat.id, 
            text = "Roger.",
            reply_to_message_id = msg.message_id
        }
    end,
    desc = "Add countdown for ...",
    limit = {
        master =  true,
        match = "/addcountdown%s*(%d%d%d%d)%-(%d%d)%-(%d%d)%s*(%d%d):(%d%d)%s*(%S.-)%s*$"
    }
}

return addcountdown
