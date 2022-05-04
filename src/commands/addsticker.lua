local utils = require("utils")

local addsticker = {
    func = function(msg)
        local origin_title = msg.text:match("/addsticker%s*(%S.-)%s*$")
        local default_title = ("Sticker Pack By " .. msg.from.first_name .. (msg.from.last_name and (" " .. msg.from.last_name) or ""))

        local title = origin_title or default_title

        local info = bot.sendMessage{
            chat_id = msg.chat.id,
            text = "Roger. Wait a moment ...",
            reply_to_message_id = msg.message_id
        }

        output_fn = commands.resize.func(msg, true)
        if not output_fn then -- already replied
            return
        end
        local sticker_content = utils.readFile(output_fn)

        -- local ret = bot.uploadStickerFile(msg.from.id, )
        -- if not ret.ok then
        --     return bot.editMessageText{
        --         chat_id = msg.chat.id,
        --         message_id = info.result.message_id,
        --         text = "Sorry, something was wrong. Please try again."
        --     }
        -- end
        -- local fid = ret.result.file_id
        -- os.remove("sticker.png")

        local c = 1
        local url = "u" .. msg.from.id .. "_by_" .. bot.info.username
        local ret

        local try

        try = function()
            local args = {
                user_id = msg.from.id,
                name = url,
                title = title,
                emojis = "🍀"
            }
            if output_fn == "sticker.png" then
                args.png_sticker = sticker_content
            elseif output_fn == "sticker.webm" then
                args.webm_sticker = sticker_content
            end
            ret = bot.createNewStickerSet(args)

            if ret.description == "Bad Request: PEER_ID_INVALID" then
                return bot.editMessageText{
                    chat_id = msg.chat.id,
                    message_id = info.result.message_id,
                    text = "Please /start with me in private chat first."
                }
            elseif ret.error_code == 403 then
                return bot.editMessageText{
                    chat_id = msg.chat.id,
                    message_id = info.result.message_id,
                    text = "Sorry, you have blocked me."
                }
            end

            local pack_url = "[" .. title .. "](https://t.me/addstickers/" .. url .. ")"

            if ret.ok then
                return bot.editMessageText{
                    chat_id = msg.chat.id,
                    message_id = info.result.message_id,
                    text = "All right.\n" .. pack_url,
                    parse_mode = "Markdown"
                }
            end

            local args = {
                user_id = msg.from.id,
                name = url,
                emojis = "🍀"
            }
            if output_fn == "sticker.png" then
                args.png_sticker = sticker_content
            elseif output_fn == "sticker.webm" then
                args.webm_sticker = sticker_content
            end
            ret = bot.addStickerToSet(args)

            if ret.ok then
                return bot.editMessageText{
                    chat_id = msg.chat.id,
                    message_id = info.result.message_id,
                    text = "All right.\n" .. pack_url,
                    parse_mode = "Markdown"
                }
            elseif ret.description == "Bad Request: STICKERS_TOO_MUCH" then
                c = c + 1
                url = "u" .. msg.from.id .. "_" .. c .. "_by_" .. bot.info.username
                if (not origin_title) then
                    title = default_title .. " " .. c
                end
                return try()
            else
                return bot.editMessageText{
                    chat_id = msg.chat.id,
                    message_id = info.result.message_id,
                    text = "Failed. (`" .. ret.description .. "`)\n" .. pack_url,
                    parse_mode = "Markdown"
                }
            end
        end

        local status, err = pcall(try)
        if not status then
            return bot.editMessageText{
                chat_id = msg.chat.id,
                message_id = info.result.message_id,
                text = "Unexpected error occurred. (`" .. err .. "`)\nCC: @SJoshua",
                parse_mode = "Markdown"
            }
        end
    end,
    desc = "Add a sticker to your sticker pack.",
    form = "/addsticker [title]",
    help = "Reply to sticker/picture.",
    limit = {
        reply = true,
    }
}

return addsticker
