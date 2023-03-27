local utils = require("utils")

local countdown = {
    func = function(msg)
        local now = os.time() + 8 * 3600 -- UTC+8

        local cd = function (target)
            local note
            local delta = target - now
            local hour = math.floor(delta / 3600)
            local minute = math.floor((delta % 3600) / 60)
            local second = delta % 60
            if hour > 0 then
                note = string.format("*%d hour%s %d minute%s %d second%s* left.", hour, hour > 1 and "s" or "", minute, minute > 1 and "s" or "", second, second > 1 and "s" or "")
            elseif minute > 0 then
                note = string.format("*%d minute%s %d second%s* left.", minute, minute > 1 and "s" or "", second, second > 1 and "s" or "")
            else
                note = string.format("*%d second%s* left.", second, second > 1 and "s" or "")
            end
            return note
        end

        local list = dofile("countdown_list.lua")
        local countdown_rec = dofile("countdown_rec.lua")

        local text = "*All set.*\nCongratulations!"

        for i = 1, #list do
            if now < os.time(list[i]) then
                text = list[i].title .. cd(os.time(list[i]))
                break
            end
        end

        if countdown_rec[msg.chat.id] then
            bot.deleteMessage(msg.chat.id, countdown_rec[msg.chat.id].query_id)
            bot.deleteMessage(msg.chat.id, countdown_rec[msg.chat.id].response_id)
        end

        local res = bot.sendMessage(msg.chat.id, nil, text, "Markdown")

        countdown_rec[msg.chat.id] = {
            query_id = msg.message_id,
            response_id = res.result.message_id
        }

        utils.save(countdown_rec, "countdown_rec.lua")
    end,
    desc = "Countdown for ..."
}

return countdown
