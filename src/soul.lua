local soul = {}

local conversation = require("conversation")
local utils = require("utils")
local lfs = require("lfs")

commands = {}
broadcasts = {}
triggers = {}

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

    for k, v in pairs(triggers) do
        if os.time() + 8 * 60 * 60 > v.timestamp then
            v.timestamp = v.timestamp + 24 * 60 * 60
            v.func()
        end
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
    if (msg.chat.id == -1001497094866 or msg.chat.id == -1001103633366) and
        not (msg.forward_from and msg.forward_from.id and msg.forward_from.id ~= msg.from.id) then
        local date_weekday = os.date("%Y-%m-%a", os.time() + 8 * 3600)
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
        elseif date_weekday == "2021-10-Fri" then
            -- chinese-only day
            if detect_language():find("JP") or filtered_text:find("[%a%p ]") then
                return bot.sendMessage {
                    chat_id = msg.chat.id,
                    text = "检测到您的发言中含有非中文字段。",
                    reply_to_message_id = msg.message_id
                }
            end
        elseif date_weekday == "2021-11-Fri" then
            -- paraquat day
            local grass_list = {
                "kusa", "grass", "ｗ", "くさ", "ｃ", "ｖｖ", "ＶＶ", "クサ", "ｇｒａｓｓ", "ｋｕｓａ", "草", "曹", "操", "槽", "艹", "糙", "超", "艸", "🌿", "🍀", "🌱"
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

soul.onStickerReceive = function(msg)
    -- special event: enabled in 7ua / bot area.
    if (msg.chat.id == -1001497094866 or msg.chat.id == -1001103633366) and
        not (msg.forward_from and msg.forward_from.id and msg.forward_from.id ~= msg.from.id) then
        local date_weekday = os.date("%Y-%m-%a", os.time() + 8 * 3600)
        
        if date_weekday == "2021-11-Fri" then
            -- paraquat day
            local grass_list = {
                "🌿", "🌱"
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
