local soul = {}

local conversation = require("conversation")
local utils = require("utils")
local lfs = require("lfs")

commands = {}
broadcasts = {}
records = {
    recording = false
}

for file in lfs.dir("commands") do
    local command = file:match("^(.+).lua")
    if (command) then
        local path = "commands." .. command
        package.loaded[path] = nil
        local status, ret = pcall(require, path)
        if (status) then
            commands[command] = ret
            logger:info("loaded " .. path)
        else
            logger:error(ret)
        end
    end
end

soul.tick = function()
    local group_list = {
        -1001497094866,
        -1001126076013,
        -1001103633366,
        -1001208316368,
        -1001487484295
    }
    if io.open("/home/share/.emergency", "r") then
        os.execute("rm /home/share/.emergency")
        for k, v in pairs(group_list) do
            local ret =
                bot.sendMessage {
                chat_id = v,
                text = "有人向 @SJoshua 发起了紧急联络请求。如果您能够（在线下）联系到 Master 的话，麻烦使用 /emergency_informed 来删除广播信息，非常感谢。"
            }
            table.insert(broadcasts, {chat_id = v, message_id = ret.result.message_id})
        end
    end
end

soul.globalMessageHandler = function(msg)
    -- No Replica Day
    local date_weekday = os.date("%Y-%m-%a", os.time() + 8 * 3600)
    if
        ((msg.chat.id == -1001497094866 and date_weekday == "2021-11-Wed") or
            (msg.chat.id == -1001103633366) and date_weekday == "2021-11-Tue")
     then
        if not records[msg.chat.id] then
            records[msg.chat.id] = {
                text = {},
                file = {},
                nick = {}
            }
        end
        if not records[msg.chat.id].nick[msg.from.id] then
            records[msg.chat.id].nick[msg.from.id] =
                msg.from.username and ("@" .. msg.from.username) or (msg.from.first_name or msg.from.id)
        end
        local text = msg.text or msg.caption
        local file_id = nil
        for k, v in pairs(msg) do
            if type(v) == "table" then
                if v.file_unique_id then
                    file_id = v.file_unique_id
                    break
                elseif type(v[1]) == "table" then
                    if v[1].file_unique_id then
                        file_id = v[1].file_unique_id
                        break
                    end
                end
            end
        end
        if file_id then
            logger:info("received message with file_id: " .. file_id)
        end
        local function check(field, index)
            if index then
                local current_record = records[msg.chat.id][field][index]
                if current_record then
                    bot.forwardMessage {
                        chat_id = -1001202409693,
                        from_chat_id = msg.chat.id,
                        message_id = msg.message_id
                    }
                    bot.sendMessage {
                        chat_id = -1001202409693,
                        text = string.format(
                            "[Hit @ %s]\n%s (%s) -> %s (%s)",
                            msg.chat.title,
                            records[msg.chat.id].nick[msg.from.id],
                            os.date("%x %X", msg.date + 8 * 3600),
                            records[msg.chat.id].nick[current_record.from],
                            os.date("%x %X", current_record.date + 8 * 3600)
                        )
                    }
                else
                    logger:info("new record: " .. field .. " - " .. index)
                    records[msg.chat.id][field][index] = {
                        message_id = msg.message_id,
                        date = msg.date,
                        from = msg.from.id
                    }
                end
            end
        end

        check("text", text)
        check("file", file_id)
    end
end

soul.onMessageReceive = function(msg)
    if not msg.text then
        error("Cannot handle this message: " .. utils.encode(msg))
    end

    msg.text = msg.text:gsub("@" .. bot.info.username, "")

    msg.chat.id = math.floor(msg.chat.id)
    msg.from.id = math.floor(msg.from.id)

    if msg.text:find("/(%S+)@(%S+)[Bb][Oo][Tt]") then
        return true
    end

    if os.time() - msg.date > config.ignore then
        return true
    end

    -- special event: enabled in 7ua / bot area.
    local date_weekday = os.date("%Y-%m-%a", os.time() + 8 * 3600)

    soul.globalMessageHandler(msg)

    if (msg.chat.id == -1001497094866 or msg.chat.id == -1001103633366) then
        if not (msg.forward_from and msg.forward_from.id and msg.forward_from.id ~= msg.from.id) then
            local filtered_text = msg.text:gsub("%s*@%w+%s*", "")
            local detect_language = function()
                local f = io.open("text_tmp", "w")
                f:write(filtered_text)
                f:close()
                f = io.popen("python3 test.py", "r")
                res = f:read() or ""
                f:close()
                return res
            end

            if date_weekday == "2021-10-Wed" then
                -- no-chinese day
                if detect_language():find("CN") then
                    return bot.sendMessage {
                        chat_id = msg.chat.id,
                        text = "Detected Chinese text in your message.",
                        reply_to_message_id = msg.message_id
                    }
                end
            elseif date_weekday == "2021-01-Mon" then
                -- chinese-only day
                if detect_language():find("JP") or filtered_text:find("[%a%p ]") then
--                     return bot.sendMessage {
--                         chat_id = msg.chat.id,
--                         text = "检测到您的发言中含有非中文字段。",
--                         reply_to_message_id = msg.message_id
--                     }
                        bot.forwardMessage {
                            chat_id = -1001202409693,
                            from_chat_id = msg.chat.id,
                            message_id = msg.message_id
                        }
                end
            elseif date_weekday == "2021-11-Fri" then
                -- paraquat day
                local grass_list = {
                    "kusa",
                    "grass",
                    "^w+$",
                    "^c+$",
                    "ｗ",
                    "くさ",
                    "ｃ",
                    "ｖｖ",
                    "ＶＶ",
                    "クサ",
                    "ｇｒａｓｓ",
                    "ｋｕｓａ",
                    "草",
                    "曹",
                    "操",
                    "槽",
                    "艹",
                    "糙",
                    "超",
                    "艸",
                    "🌿",
                    "🍀",
                    "🌱"
                }
                for _, key in pairs(grass_list) do
                    if filtered_text:lower():find(key) then
                        return bot.sendMessage {
                            chat_id = msg.chat.id,
                            text = "草",
                            reply_to_message_id = msg.message_id
                        }
                    end
                end
            end
        end
    end

    for k, v in pairs(commands) do
        if msg.text:find("^%s*/" .. k) and not msg.text:find("^%s*/" .. k .. "%S") then
            if v.limit then
                if v.limit.disable then
                    return bot.sendMessage {
                        chat_id = msg.chat.id,
                        text = "Sorry, the command is disabled.",
                        reply_to_message_id = msg.message_id
                    }
                elseif v.limit.master and msg.from.username ~= config.master then
                    return bot.sendMessage {
                        chat_id = msg.chat.id,
                        text = "Sorry, permission denied.",
                        reply_to_message_id = msg.message_id
                    }
                elseif
                    (v.limit.match or v.limit.reply) and
                        not ((v.limit.match and msg.text:find(v.limit.match)) or
                            (v.limit.reply and msg.reply_to_message))
                 then
                    return commands.help.func(msg, k)
                end
            end
            return v.func(msg)
        end
    end

    for keyword, reply in pairs(conversation) do
        local match = false
        if type(keyword) == "string" then
            match = msg.text:find(keyword)
        elseif type(keyword) == "table" then
            for i = 1, #keyword do
                match = match or msg.text:find(keyword[i])
            end
            if keyword.reply and not msg.reply_to_message then
                match = false
            end
        elseif type(keyword) == "function" then
            match = keyword(msg.text)
        end

        if match then
            local ans, rep
            local rep_type = "Markdown"
            if type(reply) == "string" then
                ans = reply
            elseif type(reply) == "table" then
                ans = utils.rand(table.unpack(reply))
                if reply.reply then
                    rep = msg.message_id
                elseif reply.reply_to_reply and msg.reply_to_message then
                    rep = msg.reply_to_message.message_id
                end
                if reply.type then
                    rep_type = reply.type
                end
            elseif type(reply) == "function" then
                ans = tostring(reply())
            end

            if ans:find("^sticker#%S-$") then
                return bot.sendSticker(msg.chat.id, ans:match("^sticker#(%S-)$"), nil, rep)
            elseif ans:find("^document#%S-$") then
                return bot.sendDocument(msg.chat.id, ans:match("^document#(%S-)$"), nil, nil, rep)
            else
                return bot.sendMessage {
                    chat_id = msg.chat.id,
                    text = ans,
                    parse_mode = rep_type,
                    reply_to_message_id = rep
                }
            end
        end
    end
end

soul.ignore = function(msg)
    soul.globalMessageHandler(msg)
end

soul.onEditedMessageReceive = soul.ignore
soul.onLeftChatMembersReceive = soul.ignore
soul.onNewChatMembersReceive = soul.ignore
soul.onPhotoReceive = soul.ignore
soul.onAudioReceive = soul.ignore
soul.onVoiceReceive = soul.ignore
soul.onVideoReceive = soul.ignore
soul.onPollReceive = soul.ignore
soul.onDocumentReceive = soul.ignore
soul.onGameReceive = soul.ignore
soul.onChannelPostReceive = soul.ignore
soul.onEditedChannelPostReceive = soul.ignore

soul.onStickerReceive = function(msg)
    soul.globalMessageHandler(msg)
    -- special event: enabled in 7ua / bot area.
    if
        (msg.chat.id == -1001497094866 or msg.chat.id == -1001103633366) and
            not (msg.forward_from and msg.forward_from.id and msg.forward_from.id ~= msg.from.id)
     then
        local date_weekday = os.date("%Y-%m-%a", os.time() + 8 * 3600)

        if date_weekday == "2021-11-Fri" then
            -- paraquat day
            local grass_list = {
                "🌿",
                "🌱"
            }
            for _, key in pairs(grass_list) do
                if msg.sticker.emoji == key then
                    return bot.sendMessage {
                        chat_id = msg.chat.id,
                        text = "草",
                        reply_to_message_id = msg.message_id
                    }
                end
            end
        end
    end
end

soul.onDiceReceive = soul.ignore
soul.onVideoNoteReceive = soul.ignore
soul.onContactReceive = soul.ignore
soul.onLocationReceive = soul.ignore
soul.onPinnedMessageReceive = soul.ignore
soul.onVoiceChatStartedReceive = soul.ignore
soul.onVoiceChatEndedReceive = soul.ignore

soul.onUnknownReceive = function(msg)
    logger:warn("Received message with unknown type: " .. utils.encode(msg))
end

setmetatable(
    soul,
    {
        __index = function(t, key)
            logger:warn("called undefined processer " .. key)
            return (function()
                return false
            end)
        end
    }
)

return soul
