local utils = require("utils")

local resize = {
    func = function(msg, silent)
        local output_fn = "sticker.png"
        if msg.reply_to_message.sticker then
            if msg.reply_to_message.sticker.is_video then
                bot.downloadFile(msg.reply_to_message.sticker.file_id,
                                 "sticker.webm")
                output_fn = "sticker.webm"
            elseif msg.reply_to_message.sticker.is_animated then
                bot.downloadFile(msg.reply_to_message.sticker.file_id,
                                 "sticker.tgs")
                output_fn = "sticker.tgs"
            else
                bot.downloadFile(msg.reply_to_message.sticker.file_id, "sticker")
                os.execute("dwebp sticker -o sticker.png")
            end
        elseif msg.reply_to_message.photo then
            bot.downloadFile(msg.reply_to_message.photo[#msg.reply_to_message
                                 .photo].file_id, "sticker")
            os.execute("convert -resize 512x512 sticker sticker.png")
        elseif msg.reply_to_message.document or msg.reply_to_messagevideo then
            ref = msg.reply_to_message.document or msg.reply_to_message.video
            if ref.file_size > 10485760 then
                bot.sendMessage(msg.chat.id, nil, "No more than 10M.", nil, nil,
                                nil, msg.message_id)
                return false
            end
            bot.downloadFile(ref.file_id, "sticker")
            if ref.mime_type:find("video") then
                output_fn = "sticker.webm"
                os.remove(output_fn)
                os.execute(
                    [[ffmpeg -i sticker -t 3 -c:v libvpx-vp9 -fs 256K -vf 'scale=if(gte(iw\,ih)\,512\,-1):if(lt(iw\,ih)\,512\,-1),fps=30' -an sticker.webm]])
            else
                os.execute("convert -resize 512x512 sticker sticker.png")
            end
        else
            bot.sendMessage(msg.chat.id, nil, "Sticker not found.", nil, nil,
                            nil, msg.message_id)
            return false
        end

        local f = io.open(output_fn, "r")
        if not f then
            bot.sendMessage(msg.chat.id, nil, "Not a sticker.", nil, nil, nil,
                            msg.message_id)
            return false
        end
        f:close()

        if silent then
            return output_fn
        end

        bot.sendDocument(msg.chat.id, nil, utils.readFile(output_fn))
        return output_fn
    end,
    desc = "Convert sticker/gif/picture to sticker png.",
    help = "Reply to sticker/picture.",
    limit = {reply = true}
}

return resize
