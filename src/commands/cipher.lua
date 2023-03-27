local cipher = {
    func = function(msg)
        local code = msg.text:match("([%d%s]+)")
        local t = {}
        local flag1 = true
        local flag2 = true
        for part in code:gmatch("(%d+)") do
            table.insert(t, tonumber(part))
            if t[#t] < 0 or t[#t] > 26 then
                flag1 = false
            end
            if t[#t] < 0 or t[#t] > 128 or not string.char(t[#t]):find("[A-Za-z0-9]") then
                flag2 = false
            end
        end
        local extra = ""
        if flag1 then
            extra = "\nDetected Cipher Pattern: `"
            for i = 1, #t do
                extra = extra .. string.char(string.byte('A') + t[i] - 1)
            end
            extra = extra .. '`'
        end
        if flag2 then
            extra = extra .. "\nDetected Cipher Pattern: `"
            for i = 1, #t do
                extra = extra .. string.char(t[i])
            end
            extra = extra .. '`'
        end
        bot.sendMessage(msg.chat.id, nil, "*[Result]*" .. extra, "Markdown", nil, nil, msg.message_id)
    end,
    desc = "decode cipher.",
    limit = {
        match = "/cipher%s*%d+"
    }
}

return cipher
