local bot = {}

local api = require("api")
local soul = require("soul")

function bot.analyzeMessageType(upd)
    if upd.message then
        local msg = upd.message
        if msg.audio then
            return "Audio"
        elseif msg.voice then
            return "Voice"
        elseif msg.video then
            return "Video"
        elseif msg.document then
            return "Document"
        elseif msg.game then
            return "Game"
        elseif msg.photo then
            return "Photo"
        elseif msg.sticker then
            return "Sticker"
        elseif msg.dice then
            return "Dice"
        elseif msg.video_note then
            return "VideoNote"
        elseif msg.contact then
            return "Contact"
        elseif msg.location then
            return "Location"
        elseif msg.venue then
            return "Venue"
        elseif msg.poll then
            return "Poll"
        elseif msg.new_chat_members or msg.new_chat_member then
            return "NewChatMembers"
        elseif msg.left_chat_member then
            return "LeftChatMembers"
        elseif msg.new_chat_title then
            return "NewChatTitle"
        elseif msg.new_chat_photo then
            return "NewChatPhoto"
        elseif msg.delete_chat_title then
            return "DeleteChatPhoto"
        elseif msg.group_chat_created then
            return "GroupChatCreated"
        elseif msg.supergroup_chat_created then
            return "SupergroupChatCreated"
        elseif msg.channel_chat_created then
            return "ChannelChatCreated"
        elseif msg.migrate_to_chat_id or msg.migrate_from_chat_id then
            return "MigrateToChat"
        elseif msg.pinned_message then
            return "PinnedMessage"
        elseif msg.invoice then
            return "Invoice"
        elseif msg.successful_payment then
            return "SuccessfulPayment"
        elseif msg.chat.type == "channel" then
            return "ChannelMessage"
        elseif msg.voice_chat_started then
            return "VoiceChatStarted"
        elseif msg.voice_chat_ended then
            return "VoiceChatEnded"
        else
            return "Message"
        end
    elseif upd.edited_message then
        return "EditedMessage"
    elseif upd.channel_post then
        return "ChannelPost"
    elseif upd.edited_channel_post then
        return "EditedChannelPost"
    elseif upd.inline_query then
        return "InlineQuery"
    elseif upd.chosen_inline_result then
        return "ChosenInlineResult"
    elseif upd.callback_query then
        return "CallbackQuery"
    elseif upd.shipping_query then
        return "ShippingQuery"
    elseif upd.pre_checkout_query then
        return "PreCheckoutQuery"
    else
        return "Unknown"
    end
end

-- reload soul only
function bot.reload()
    package.loaded.soul = nil
    package.loaded.utils = nil
    package.loaded.conversation = nil

    soul = require("soul")

    return true
end

function bot.getUpdates(offset, limit, timeout, allowed_updates)
    local body = {}
    body.offset = offset
    body.limit = limit
    body.timeout = timeout
    body.allowed_updates = allowed_updates
    return api.makeRequest("getUpdates", body)
end

function bot.downloadFile(file_id, path)
    local ret = bot.getFile(file_id)
    if ret and ret.ok then
        os.execute(string.format("wget --timeout=5 -O %s https://api.telegram.org/file/bot%s/%s", path or "tmp", config.token, ret.result.file_path))
    end
end

function bot.run()
    logger:info("link start.")

    local t = api.fetch()
    for k, v in pairs(t) do
        bot[k] = v
    end

    local ret = bot.getMe()
    if ret then
        bot.info = ret.result
        logger:info("bot online. I am " .. bot.info.first_name .. ".")
    end

    local offset = 0
    local threads = {
        tick = coroutine.create(function()
            while true do
                pcall(soul.tick)
                coroutine.yield()
            end
        end)
    }

    while true do
        local updates = bot.getUpdates(offset, config.limit, config.timeout)
        if updates and updates.result then
            for key, upd in pairs(updates.result) do
                threads[upd.update_id] = coroutine.create(function()
                    soul[("on%sReceive"):format(bot.analyzeMessageType(upd))](
                        upd.message or upd.edited_message or upd.channel_post or upd.edited_channel_post 
                        or upd.inline_query or upd.chosen_inline_result or upd.callback_query 
                        or upd.shipping_query or upd.pre_checkout_query
                    )
                end)
                offset = upd.update_id + 1
            end
        end
        
        for uid, thread in pairs(threads) do
            local status, res = coroutine.resume(thread)
            if not status then
                threads[uid] = nil
                if (res ~= "cannot resume dead coroutine") then
                    logger:error("coroutine #" .. uid .. " crashed, reason: " .. res)
                end
            end
        end
    end
end

setmetatable(bot, {
    __index = function(t, key)
        logger:warn("called undefined method " .. key)
    end
})

return bot
