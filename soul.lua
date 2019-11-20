-------------------------------------------
-- Project Small R
-- Soul
-- Au: SJoshua
-------------------------------------------
cjson = require("cjson")
socket = require("socket")
http = require("socket.http")
sqlite3_driver = require("luasql.sqlite3")
sqlite3_env = sqlite3_driver.sqlite3()

-------------------------------------------
-- config
-------------------------------------------
dofile("config.lua")

-------------------------------------------
-- utils
-------------------------------------------
dofile("utils.lua")
dofile("knowledge")

-------------------------------------------
-- commands
-------------------------------------------
-- command: {
--   func: function to call
--   desc: command description (short)
--   form: command format (for help)
--   help: command usage (for help)
--   limit: {
--     disable: even for master
--     master: master command
--     match: condition for command (pattern match)
--     reply: condition for command (boolean)
--   }
-- }
-------------------------------------------
commands = {
	start = {
		func = function()
			bot.sendMessage(msg.chat.id, "Hello, this is " .. bot.me.first_name .. ".")
		end,
		desc = "Start with me!"
	},
	
	help = {
		generate = function(all)
			local t = {}
			for cmd, v in pairs(commands) do
				if not (v.limit and v.limit.master) or all then
					table.insert(t, cmd)
				end
			end
			table.sort(t)
			local text = ""
			for i = 1, #t do
				text = text .. string.format("`%s` - %s\n", commands[t[i]].form or ("/" .. t[i]), commands[t[i]].desc)
			end
			return text
		end,
		func = function(cmd)
			local cmd = cmd or tostring(msg.text:match("/help%s*(%S+)%s*"))
			if commands[cmd] then
				bot.sendMessage(msg.chat.id,
					(commands[cmd].limit and commands[cmd].limit.master and "*[master command]*\n" or "") ..
					string.format("`%s`\n%s", commands[cmd].form or ("/" .. cmd), commands[cmd].help or commands[cmd].desc),
					"Markdown", nil, nil, msg.message_id)
			else
				bot.sendMessage(msg.chat.id, commands.help.generate(msg.text:find("_all")), "Markdown")
			end
		end,
		form = "/help <command>",
		desc = "Help.",
		help = "e.g. `/help find`"
	},
	
	reload = {
		func = function()
			local ret = bot.sendMessage(msg.chat.id, "reloading...", nil, nil, nil, msg.message_id)
			local s = ""

			local function reload(file, name)
				local sta, err = pcall(dofile, file)
				if not sta then
					s = s .. "error @ " .. name .. ":\n```\n" .. err .. "\n```\n"
				end
			end

			reload("utils.lua", "Utils")
			reload("api.lua", "API")
			reload("soul.lua", "Soul")

			bot.editMessageText(msg.chat.id, ret.result.message_id, nil, "reloading...\n" .. ((s == "") and "done." or s), "Markdown")
		end,
		desc = "Reload my soul."
	},
	
	cmdlist = {
		func = function ()
			local t = {}
			for cmd, v in pairs(commands) do
				if not (v.limit and v.limit.master) then
					table.insert(t, cmd)
				end
			end
			table.sort(t)
			local text = ""
			for i = 1, #t do
				text = text .. string.format("`%s` - %s\n", t[i] or ("/" .. t[i]), commands[t[i]].desc)
			end
			bot.sendMessage(msg.chat.id, text, "Markdown")
		end,
		desc = "Generate command list.",
		limit = {
			master = true
		}
	},
	
	upgrade = {
		func = function()
			local ret = bot.sendMessage(msg.chat.id, "upgrading...", nil, nil, nil, msg.message_id)
			os.execute("cp api.lua api.lua.bak")
			os.execute("lua generator.lua")
			local f = io.open("generate-api.lua", "r")
			local code = f:read("*a")
			f:close()
			local f = io.open("api.lua", "r")
			local source = f:read("*a")
			f:close()
			local f = io.open("api.lua", "w")
			f:write((source:gsub("(Mark @ Generator%s*).-$", "%1" .. code)))
			f:close()
			dofile("api.lua")
			bot.editMessageText(msg.chat.id, ret.result.message_id, nil, "upgrading...\ndone.", "Markdown")
		end,
		desc = "Upgrade Telegram Bot API Code."
	},
	
	delete = {
		func = function()
			bot.deleteMessage(msg.chat.id, msg.reply_to_message.message_id)
		end,
		desc = "Delete message.",
		limit = {
			master = true,
			reply = true
		}
	},
}

-------------------------------------------
-- Soul
-------------------------------------------
soul = setmetatable({}, {
	__index = function(t, key)
		local msgType = key:match("^on(.+)Receive$")
		if msgType then
			return function(msg)
				bot.sendMessage(config.masterid, string.format("I received a message (%s). \n```\n%s\n```", msgType, table.encode(msg)), "Markdown")
			end
		else
			return function(msg)
				bot.sendMessage(config.masterid, string.format("Attempted to index `bot.%s`.", key), "Markdown")
			end
		end
	end
})

soul.onMessageReceive = function (message)
	msg = message

	if os.time() - msg.date > config.ignore then
		return
	end

	if not msg.text then
		return bot.sendMessage(config.masterid, table.encode(msg))
	end

	msg.text = msg.text:gsub("@" .. bot.me.username, "")

	if msg.text:find("/(%S+)@(%S+)[Bb][Oo][Tt]") then
		return
	end
	
	for k, v in pairs(commands) do
		if msg.text:find("^%s*/" .. k) and not msg.text:find("^%s*/" .. k .. "%S") then
			if v.limit then
				if v.limit.disable then
					return bot.sendMessage(msg.chat.id, "Sorry, the command is disabled.", nil, nil, nil, msg.message_id)
				elseif v.limit.master and msg.from.username ~= config.master then
					return bot.sendMessage(msg.chat.id, "Sorry, permission denied.", nil, nil, nil, msg.message_id)
				elseif (v.limit.match or v.limit.reply) and not ((v.limit.match and msg.text:find(v.limit.match)) or (v.limit.reply and msg.reply_to_message)) then
					return commands.help.func(k)
				end
			end
			return v.func()
		end
	end

	if type(extra) == "function" then
		if extra() then
			return
		end
	end

	if config.mute then
		return
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
			match = keyword()
		end

		if match then
			local ans, rep
			if type(reply) == "string" then
				ans = reply
			elseif type(reply) == "table" then
				ans = rand(unpack(reply))
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

soul.onVenueReceive = function (msg)

end

soul.onNewChatTitleReceive = function (msg)

end

soul.onNewChatPhotoReceive = function (msg)

end

soul.onDeleteChatPhotoReceive = function (msg)

end

soul.onGroupChatCreatedReceive = function (msg)

end

soul.onSupergroupChatCreatedReceive = function (msg)

end

soul.onChannelChatCreatedReceive = function (msg)

end

soul.onMigrateToChatReceive = function (msg)

end

soul.onPinnedMessageReceive = function (msg)

end

soul.onInvoiceReceive = function (msg)

end

soul.onSuccessfulPaymentReceive = function (msg)

end

soul.onChannelMessageReceive = function (msg)

end

soul.onChannelPostReceive = function (msg)

end

soul.onEditedChannelPostReceive = function (msg)

end

soul.onInlineQueryReceive = function (msg)

end

soul.onChosenInlineResultReceive = function (msg)

end

soul.onCallbackQueryReceive = function (msg)

end

soul.onShippingQueryReceive = function (msg)

end

soul.onPreCheckoutQueryReceive = function (msg)

end

soul.onCallbackQueryReceive = function (msg)
	if not msg.from.username then
		msg.from.username = "$" .. msg.from.id
	end
	-- todo
end


for k, v in pairs(soul) do
	soul[k] = function (msg)
		if config.debug then
			print(os.date(), table.encode(msg))
		end
		if config.record then
			-- to-do process
			
		end
		local sta, err = pcall(v, msg)
		if not sta then
			bot.sendMessage(config.masterid, string.format("\\[ERROR]\nfunction: `%s`\n```\n%s```", k, tostring(err)), "Markdown")
		end
	end
end
