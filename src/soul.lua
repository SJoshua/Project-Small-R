local soul = {}

local conversation = require("conversation")
local utils = require("utils")
local lfs = require("lfs")

commands = {}

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

soul.onMessageReceive = function(msg)
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
            if type(reply) == "string" then
                ans = reply
            elseif type(reply) == "table" then
                ans = utils.rand(table.unpack(reply))
            elseif type(reply) == "function" then
                ans = tostring(reply())
            end

            if reply.reply then
                rep = msg.message_id
            elseif reply.reply_to_reply and msg.reply_to_message then
                rep = msg.reply_to_message.message_id
            end

            if ans:find("^sticker#%S-$") then
                return bot.sendSticker(msg.chat.id, ans:match("^sticker#(%S-)$"), nil, rep)
            elseif ans:find("^document#%S-$") then
                return bot.sendDocument(msg.chat.id, ans:match("^document#(%S-)$"), nil, nil, rep)
            else
                return bot.sendMessage(msg.chat.id, ans, reply.type or "Markdown", nil, nil, rep)
            end
        end
    end
end

soul.onEditedMessageReceive = function (msg)
    -- process
end

soul.onLeftChatMembersReceive = function (msg)
    
end

soul.onNewChatMembersReceive = function (msg)
    
end

soul.onPhotoReceive = function(msg)
    -- process
end

soul.onAudioReceive = function (msg)
    -- process
end

soul.onVideoReceive = function (msg)
    -- process
end

soul.onDocumentReceive = function (msg)
    -- process
end

soul.onGameReceive = function (msg)
    -- process
end

soul.onStickerReceive = function (msg)
    
end

soul.onVideoNoteReceive = function (msg)

end

soul.onContactReceive = function (msg)

end

soul.onLocationReceive = function (msg)

end

setmetatable(soul, {
    __index = function(t, key)
        logger:warn("called undefined processer " .. key)
        return (function() return false end)
    end
})

return soul