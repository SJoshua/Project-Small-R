local utils = require("utils")

local resize = {
    func = function(msg, silent)
        if msg.reply_to_message.sticker then
            bot.downloadFile(msg.reply_to_message.sticker.file_id, "sticker")
            os.execute("dwebp sticker -o sticker.png")
        elseif msg.reply_to_message.photo then
            bot.downloadFile(msg.reply_to_message.photo[#msg.reply_to_message.photo].file_id, "sticker")
            os.execute("convert -resize 512x512 sticker sticker.png")
        elseif msg.reply_to_message.document then
            if msg.reply_to_message.document.file_size > 10485760 then
                bot.sendMessage(msg.chat.id, "No more than 10M.", nil, nil, nil, msg.message_id)
                return false
            end
            bot.downloadFile(msg.reply_to_message.document.file_id, "sticker")
            if msg.reply_to_message.document.mime_type:find("video") then
                os.remove("flame.png")
                os.execute("ffmpeg -i sticker -vframes 1 flame.png")
                os.execute("convert -resize 512x512 flame.png sticker.png")
            else
                os.execute("convert -resize 512x512 sticker sticker.png")
            end
        else
            bot.sendMessage(msg.chat.id, "Sticker not found.", nil, nil, nil, msg.message_id)
            return false
        end

        local f = io.open("sticker.png", "r")
        if not f then
            bot.sendMessage(msg.chat.id, "Not a sticker.", nil, nil, nil, msg.message_id)
            return false
        end
        f:close()

        if silent then
            return true
        end

        bot.sendDocument(msg.chat.id, utils.readFile("sticker.png"))
        return true
    end,
    desc = "Convert sticker/gif/picture to sticker png.",
    help = "Reply to sticker/picture.",
    limit = {
        reply = true
    }
}

return resize
