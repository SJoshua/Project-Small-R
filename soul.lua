-------------------------------------------
-- Project Small R
-- Soul
-- Au: SJoshua
-------------------------------------------
cjson = require("cjson")
socket = require("socket")
http = require("socket.http")

-------------------------------------------
-- config
-------------------------------------------
dofile("config.lua")

-------------------------------------------
-- info
-------------------------------------------
local dead_flag = false

dofile("knowledge")

-------------------------------------------
-- utils
-------------------------------------------
dofile("utils.lua")

function save()
	local f = io.open("database", "w")
	-- todo
	f:close()
end

function load()
	dofile(database)
end

function backup()
	os.execute("rm database.bak")
	os.execute("cp database database.bak")
end

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
--     match: condition for command
--     reply: condition for command
--   }
-- }
-------------------------------------------
commands = {
	start = {
		func = function()
			bot.sendMessage(msg.chat.id, "Hello. This is Project Small R.")
		end,
		desc = "Just start."
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
	base64 = {
		func = function()
			local txt = msg.text:match("/base64%s*(%S.-)$")
			return bot.sendMessage(msg.chat.id, "[Encode]\n" .. tostring(base64.enc(txt)))
		end,
		form = "/base64 <text>",
		desc = "Encode with base64.",
		limit = {
			match = "/base64%s*(%S.-)$"
		}
	},
	debase64 = {
		func = function()
			local txt = msg.text:match("/debase64%s*(%S.-)$")
			return bot.sendMessage(msg.chat.id, "[Decode]\n" .. tostring(base64.dec(txt)))
		end,
		form = "/debase64 <text>",
		desc = "Decode with base64.",
		limit = {
			match = "/debase64%s*(%S.-)$"
		}
	},
	unpack = {
		func = function()
			bot.sendMessage(msg.chat.id, "```\n" .. table.encode(msg) .. "\n```", "Markdown")
		end,
		desc = "Unpack current message."
	},
	shutdown = {
		func = function()
			bot.sendMessage(msg.chat.id, "Okay. Send me any message to shutdown.")
			dead_flag = true
		end,
		desc = "Stop me.",
		limit = {
			master = true
		}
	},
	exec = {
		func = function()
			message = msg
			if msg.from.username == config.master then
				if msg.text:find("os.exit") then
					bot.sendMessage(msg.chat.id, "[WARNING]\nPlease use /shutdown instead.")
					return
				end
				local t = {pcall(loadstring(string.match(msg.text, "/exec(.*)")))}
				local ts = string.format("[status] %s\n", tostring(t[1]))
				for i = 2, table.maxn(t) do
					ts = ts .. string.format("[return %d] %s\n", i-1, tostring(t[i]))
				end
				bot.sendMessage(msg.chat.id, ts .. "[END]")
			elseif config.dolua then
				if msg.text:find("for") or msg.text:find("while") or msg.text:find("until") then
					bot.sendMessage(msg.chat.id, "Sorry, but no looping.")
				else
					local t = {pcall(loadstring("_ENV = sandbox{'math', 'string', 'pairs', 'cjson', 'table', 'message', 'base64', 'md5'}; string.dump = nil; " .. string.match(msg.text, "/exec(.*)")))}
					local ts = string.format("[status] %s\n", tostring(t[1]))
					for i = 2, table.maxn(t) do
						ts = ts .. string.format("[return %d] %s\n", i-1, tostring(t[i]))
					end
					bot.sendMessage(msg.chat.id, ts .. "[END]")
				end
				--bot.sendMessage(msg.from.id, "Who are you?")
			end
		end,
		form = "/exec <code>",
		desc = "Execute code in lua.",
		help = "`string`, `math`, `table`, `base64` and `md5` are available.\ne.g.\n  `/exec return 1+1`\n  `/exec return string.rep(\"233\\n\", 5)`\n  `/exec return table.encode(base64)`",
		limit = {
			match = "/exec%s*(%S.+)"
		}
	},
	mute = {
		func = function()
			config.mute = true
			bot.sendMessage(msg.chat.id, "Okay.", nil, nil, nil, msg.message_id)
		end,
		desc = "Stop talking.",
		limit = {
			master = true
		}
	},
 	unmute = {
		func = function()
			config.mute = true
			bot.sendMessage(msg.chat.id, "Okay.", nil, nil, nil, msg.message_id)
		end,
		desc = "Let's go!",
		limit = {
			master = true
		}
	},
	shell = {
		func = function()
			local cmd = msg.text:match("/shell%s*(.-)%s*$")
			os.execute(cmd .. " > tmp")
			local f = io.open("tmp", "r")
			local res
			if f then
				res = f:read("*a")
				f:close()
			else
				res = "failed to read."
			end
			bot.sendMessage(msg.chat.id, "[result]\n" .. tostring(res), nil, nil, nil, msg.message_id)
		end,
		form = "/shell <command>",
		desc = "Execute shell.",
		help = "e.g. `/shell echo hey`",
		limit = {
			master = true,
			match = "/shell%s*(.-)%s*$"
		}
	},
	review = {
		func = function()
			if not msg.reply_to_message.text:find("/revive") then
				return soul.onTextReceive(msg.reply_to_message)
			end
		end,
		desc = "Process a message again.",
		help = "Reply to message.",
		limit = {
			reply = true,
			master = true
		}
	}
}

-------------------------------------------
-- Soul
-------------------------------------------
soul = setmetatable({}, {
	__index = function(t, key)
		local msgType = key:match("^on(.+)Receive$")
		if msgType then
			return function(msg)
				bot.sendMessage(config.masterid, string.format("I received a message \(%s). \n```\n%s\n```", msgType, table.encode(msg)), "Markdown")
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

	-- To-do: Use entities instead
	msg.text = msg.text:gsub("@Project_Small_Robot", "")

	if msg.text:find("/(%S+)@(%S+)[Bb][Oo][Tt]") then
		return
	end

	for k, v in pairs(commands) do
		if msg.text:find("^%s*/" .. k) then
			if v.limit then
				if v.limit.disable then
					return bot.sendMessage(msg.chat.id, "Sorry, the command is disabled.", nil, nil, nil, msg.message_id)
				elseif v.limit.master and msg.from.id ~= config.masterid then
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

	for _, v in pairs(conversation) do
		for i = 1, #v[1] do
			if msg.text:find(v[1][i]) and (not v[3]) then
				if v[4] then
					if msg.reply_to_message then
						return bot.sendMessage(msg.chat.id, rand(unpack(v[2])), nil, nil, nil, msg.reply_to_message.message_id)
					end
				else
					return bot.sendMessage(msg.chat.id, rand(unpack(v[2])), "Markdown")
				end
			end
		end
	end
end

soul.onLeftChatParticipantReceive = function (msg)
	if msg.left_chat_member.username == "Project_Small_Robot" then
		bot.sendMessage(config.masterid, "I have been kicked from group [" .. msg.chat.title .. "] by [" .. msg.from.first_name .. " " .. msg.from.last_name .. "](@" .. msg.from.username .. ").")
		bot.sendMessage(msg.from.id, "Operation finished.")
	end
end

soul.onNewChatParticipantReceive = function (msg)
	if msg.new_chat_member.username == "Project_Small_Robot" then
		bot.sendMessage(config.masterid, "I have been added to group [" .. msg.chat.title .. "] by [" .. msg.from.first_name .. " " .. (msg.from.last_name or "") .. "](@" .. msg.from.username .. ").")
		bot.sendMessage(msg.from.id, "Thanks for your invitation.")
		bot.sendMessage(msg.chat.id, "Hello everyone, I am Project Small R.")
	end
end

soul.onCallbackQueryReceive = function (msg)
	if not msg.from.username then
		msg.from.username = "$" .. msg.from.id
	end
	bot.answerCallbackQuery(msg.id, "Received.")
end

for k, v in pairs(soul) do
	soul[k] = function (msg)
		if config.debug then
			print(os.date(), table.encode(msg))
		end
		local sta, err = pcall(v, msg)
		if (not sta) then
			bot.sendMessage(config.masterid, string.format("[ERROR]\nfunction: `%s`\n```\n%s```", k, tostring(err)), "Markdown")
			if config.warning and msg.chat then
				bot.sendMessage(config.masterid, string.format("[ERROR]\nfunction: `%s`\n```\n%s```", k, tostring(err)), "Markdown")
			end
		end
	end
end
