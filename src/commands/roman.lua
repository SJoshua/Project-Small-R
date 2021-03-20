local roman = require("roman")

local roman_command = {
    func = function(msg)
        local code = msg.text:match("/roman%s*([IVXLCDM%s]+)")
        local t = {}
        local flag1 = true
        local flag2 = true
        for part in code:gmatch("([IVXLCDM]+)") do
            table.insert(t, roman.decode(part))
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
        bot.sendMessage(msg.chat.id, "*[Result]*\n`" .. table.concat(t, " ") .. "`" .. extra, "Markdown", nil, nil, msg.message_id)
    end,
    desc = "translate roman numerals to dec numbers.",
    limit = {
        match = "/roman%s*[%sIVXLCDM]+"
    }
}

return roman_command
