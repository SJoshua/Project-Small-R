local soul = {}

local conversation = require("conversation")
local utils = require("utils")
local lfs = require("lfs")

commands = {}
broadcasts = {}
triggers = {
    { 
        timestamp = os.time{year = 2021, month = 6, day = 25, hour = 11, min = 45},
        func = function() 
            bot.sendMessage{
                chat_id = -324653090,
                text = "吃饭啦！"
            }
        end
    },
    { 
        timestamp = os.time{year = 2021, month = 6, day = 25, hour = 11, min = 50},
        func = function() 
            bot.sendMessage{
                chat_id = -324653090,
                text = "吃饭啦！！"
            }
        end
    },
    { 
        timestamp = os.time{year = 2021, month = 6, day = 25, hour = 11, min = 55},
        func = function() 
            bot.sendMessage{
                chat_id = -324653090,
                text = "吃饭啦！！！"
            }
        end
    },
    { 
        timestamp = os.time{year = 2021, month = 6, day = 25, hour = 12, min = 0},
        func = function() 
            bot.sendMessage{
                chat_id = -324653090,
                text = "吃饭啦！！！吃饭啦！！！吃饭啦！！！"
            }
        end
    },
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
            local ret = bot.sendMessage{
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

    for k, v in pairs(commands) do
        if msg.text:find("^%s*/" .. k) and not msg.text:find("^%s*/" .. k .. "%S") then
            if v.limit then
                if v.limit.disable then
                    return bot.sendMessage{
                        chat_id = msg.chat.id, 
                        text = "Sorry, the command is disabled.",
                        reply_to_message_id = msg.message_id
                    }
                elseif v.limit.master and msg.from.username ~= config.master then
                    return bot.sendMessage{
                        chat_id = msg.chat.id, 
                        text = "Sorry, permission denied.",
                        reply_to_message_id = msg.message_id
                    }
                elseif (v.limit.match or v.limit.reply) and not ((v.limit.match and msg.text:find(v.limit.match)) or (v.limit.reply and msg.reply_to_message)) then
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
                return bot.sendMessage{
                    chat_id = msg.chat.id,
                    text = ans,
                    parse_mode = rep_type,
                    reply_to_message_id = rep
                }
            end
        end
    end
end

soul.ignore = function(msg) end

soul.onEditedMessageReceive = soul.ignore
soul.onLeftChatMembersReceive = soul.ignore
soul.onNewChatMembersReceive = soul.ignore
soul.onPhotoReceive = soul.ignore
soul.onAudioReceive = soul.ignore
soul.onVoiceReceive = soul.ignore
soul.onVideoReceive = soul.ignore
soul.onDocumentReceive = soul.ignore
soul.onGameReceive = soul.ignore
soul.onStickerReceive = soul.ignore
soul.onDiceReceive = soul.ignore
soul.onVideoNoteReceive = soul.ignore
soul.onContactReceive = soul.ignore
soul.onLocationReceive = soul.ignore
soul.onPinnedMessageReceive = soul.ignore
soul.onVoiceChatStartedReceive = soul.ignore
soul.onVoiceChatEndedReceive = soul.ignore

setmetatable(soul, {
    __index = function(t, key)
        logger:warn("called undefined processer " .. key)
        return (function() return false end)
    end
})

return soul