local utils = require("utils")

local addsticker = {
    func = function(msg)
        local origin_title = msg.text:match("/addsticker%s*(%S.-)%s*$") 
        local default_title = ("Sticker Pack By " .. msg.from.first_name .. (msg.from.last_name and (" " .. msg.from.last_name) or ""))
        
        local title = origin_title or default_title

        if not commands.resize.func(msg, true) then
            return
        end

        local ret = bot.uploadStickerFile(msg.from.id, utils.readFile("sticker.png"))
        if not ret.ok then
            return bot.sendMessage(msg.chat.id, "Sorry, something was wrong. Please try again. ")
        end
        local fid = ret.result.file_id
        os.remove("sticker.png")
        
        local c = 1
        local url = "u" .. msg.from.id .. "_by_" .. bot.info.username
        local ret 

        try = function()
            ret = bot.createNewStickerSet{
                user_id = msg.from.id, 
                name = url, 
                title = title, 
                png_sticker = fid,
                emojis = "🍀"
            }

            if ret.description == "Bad Request: PEER_ID_INVALID" then
                return bot.sendMessage(msg.chat.id, "Please /start with me in private chat first.")
            elseif ret.error_code == 403 then
                return bot.sendMessage(msg.chat.id, "Sorry, you have blocked me.")
            end

            local pack_url = "[" .. title .. "](https://t.me/addstickers/" .. url .. ")"

            if ret.ok then
                return bot.sendMessage(msg.chat.id, "All right.\n" .. pack_url, "Markdown", nil, nil, msg.message_id)
            end

            ret = bot.addStickerToSet{
                user_id = msg.from.id, 
                name = url, 
                png_sticker = fid, 
                emojis = "🍀"
            }

            if ret.ok then
                return bot.sendMessage(msg.chat.id, "All right.\n" .. pack_url, "Markdown", nil, nil, msg.message_id)
            elseif ret.description == "Bad Request: STICKERS_TOO_MUCH" then
                c = c + 1
                url = "u" .. msg.from.id .. "_" .. c .. "_by_" .. bot.info.username
                if (not origin_title) then
                    title = default_title .. " " .. c
                end
                return try()
            else
                return bot.sendMessage(msg.chat.id, "Failed. (`" .. ret.description .. "`)\n" .. pack_url, "Markdown", nil, nil, msg.message_id)
            end
        end
        
        try()
    end,
    desc = "Add a sticker to your sticker pack.",
    form = "/addsticker [title]",
    help = "Reply to sticker/picture.",
    limit = {
        reply = true,
    }
}

return addsticker
