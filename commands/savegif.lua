local savegif = {
    func = function(msg)
        if msg.reply_to_message.document and msg.reply_to_message.document.mime_type == "video/mp4" then
            if msg.reply_to_message.document.file_size <= 1024000 then
                bot.downloadFile(msg.reply_to_message.document.file_id, "tmp.mp4")
                os.remove("tmp.gif")
                os.execute("ffmpeg -i tmp.mp4 tmp.gif")
                os.execute("mv tmp.gif /var/www/server.sforest.in/output.gif")
                bot.sendMessage(msg.chat.id, "[Click to download](http://server.sforest.in/output.gif)", "Markdown", nil, nil, msg.message_id)
            else
                bot.sendMessage(msg.chat.id, "Sorry, size limit is 1M.")
            end
        else
            bot.sendMessage(msg.chat.id, "Not found.")
        end
    end,
    form = "/savegif",
    desc = "Convert gif.mp4 to gif.",
    limit = {
        reply = true
    }
}

return savegif
