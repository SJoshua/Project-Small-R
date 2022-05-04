local utils = require("utils")

local addsticker = {
    func = function(msg)
        local info = bot.sendMessage{
            chat_id = msg.chat.id,
            text = "Roger. Wait a moment ...",
            reply_to_message_id = msg.message_id
        }

        local is_static = false
        local is_animated = false
        local is_video = false
        local field = ""

        output_fn = commands.resize.func(msg, true)
        if output_fn == "sticker.png" then
            is_static = true
            field = "png_sticker"
        elseif output_fn == "sticker.tgs" then
            is_animated = true
            field = "tgs_sticker"
        elseif output_fn == "sticker.webm" then
            is_video = true
            field = "webm_sticker"
        elseif not output_fn then -- already replied
            return
        end

        local sticker_content = utils.readFile(output_fn)

        local origin_title = msg.text:match("/addsticker%s*(%S.-)%s*$")
        local default_title = (output_fn == "sticker.png" and "" or "Animated ") .. ("Sticker Pack By " .. msg.from.first_name .. (msg.from.last_name and (" " .. msg.from.last_name) or ""))
        local title = origin_title or default_title

        local c = 1
        local url = "u" .. msg.from.id .. "_by_" .. bot.info.username
        local ret

        local try

        -- find a free url
        while c < 10 do
            local continue = false
            local ret = bot.getStickerSet(url)
            if not ret.ok then -- create new sticker set
                local args = {
                    user_id = msg.from.id,
                    name = url,
                    title = title,
                    emojis = "🍀"
                }
                args[field] = sticker_content
                ret = bot.createNewStickerSet(args)
            elseif (ret.result.is_animated and is_animated and #ret.result.stickers < 50)
                or (ret.result.is_video and is_video and #ret.result.stickers < 50)
                or (not ret.result.is_animated and not ret.result.is_video and is_static and #ret.result.stickers < 120) then
                local args = {
                    user_id = msg.from.id,
                    name = url,
                    emojis = "🍀"
                }
                args[field] = sticker_content
                ret = bot.createNewStickerSet(args)
            else
                continue = true
            end

            if continue then
                c = c + 1
                url = "u" .. msg.from.id .. "_" .. c .. "_by_" .. bot.info.username
                if (not origin_title) then
                    title = default_title .. " " .. c
                end
            else
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
                else
                    return bot.editMessageText{
                        chat_id = msg.chat.id,
                        message_id = info.result.message_id,
                        text = "Failed. (`" .. ret.description .. "`)\n" .. pack_url,
                        parse_mode = "Markdown"
                    }
                end
            end
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
