local savegif = {
    func = function(msg)
        local target = msg.reply_to_message.video or msg.reply_to_message.document
        if target and target.mime_type == "video/mp4" then
            if target.file_size <= 20480000 then
                local sent_msg = bot.sendMessage{
                    chat_id = msg.chat.id,
                    text = "Roger. Wait a moment ...",
                    parse_mode = "Markdown",
                    reply_to_message_id = msg.message_id
                }
                bot.downloadFile(target.file_id, "tmp.mp4")
                os.remove("tmp.gif")
                local factor = tonumber(msg.text:match("([%d%.]+)")) or 1
                os.execute("gifski tmp.mp4 --output tmp.gif --fast-forward " .. factor)
                local fn = os.time() .. ".gif"
                os.execute("mv tmp.gif /var/www/server.sforest.in/" .. fn)
                bot.editMessageText{
                    chat_id = msg.chat.id,
                    message_id = sent_msg.result.message_id,
                    text = "[Click to download](https://server.sforest.in/" .. fn .. ")",
                    parse_mode = "Markdown"
                }
            else
                bot.sendMessage(msg.chat.id, "Sorry, size limit is 20M.")
            end
        else
            bot.sendMessage(msg.chat.id, "Sorry, gif not found.")
        end
    end,
    form = "/savegif [speed=1]",
    desc = "Convert gif.mp4 to gif.",
    help = "e.g. `/savegif 0.5`",
    limit = {
        reply = true
    }
}

return savegif
