-------------------------------------------
-- Project Small R
-- Soul
-- Au: SJoshua
-------------------------------------------
cjson = require("cjson")
socket = require("socket")
http = require("socket.http")
md5 = require("md5")

-------------------------------------------
-- settings
-------------------------------------------
dofile("config.lua")

math.randomseed(os.time())

-------------------------------------------
-- info
-------------------------------------------
local dead_flag = false
votes = votes or {}
msgList = msgList or {}
mahjong = mahjong or {}
dictLog = dictLog or {}
clickMsg = clickMsg or {}
naiveList = naiveList or {}
forwardCnt = forwardCnt or {}
forwardLog = forwardLog or {}
conversation = conversation or {}

dofile("knowledge")

-------------------------------------------
-- utils
-------------------------------------------
dofile("utils")

function save()
	local f = io.open("database", "w")
	f:write("msgList = ", table.encode(msgList),
		"\n\nvotes = ", table.encode(votes),
		"\n\nnaiveList = ", table.encode(naiveList),
		"\n\nmahjong = ", table.encode(mahjong),
		"\n\nconversation = ", table.encode(conversation),
		"\n\ndictLog = ", table.encode(dictLog),
		"\n\nclickMsg = ", table.encode(clickMsg),
		"\n\nforwardCnt = ", table.encode(forwardCnt),
		"\n\nforwardLog = ", table.encode(forwardLog))
	f:close()
end

function load()
	dofile(database)
end

function backup()
	os.execute("rm database.bak")
	os.execute("cp database database.bak")
end

function sandbox(t)
	local ret = {}
	for _, name in pairs(t) do
		if _G[name] then
			if type(_G[name]) == "table" then
				ret[name] = {}
				for k, v in pairs(_G[name]) do
					if type(v) == "function" then
						ret[name][k] = function (...)
							return v(...)
						end
					else
						ret[name][k] = v
					end
				end
			elseif type(_G[name]) == "function" then
				ret[name] = function (...)
					return _G[name](...)
				end
			else
				ret[name] = _G[name]
			end
		end
	end
	return ret
end

function wget(url)
	os.execute('wget -O wget.tmp "' .. url .. '"')
	local f = io.open("wget.tmp", "r")
	local ret = f:read("*a")
	f:close()
	return ret
end

base64 = {
	b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/',
	enc = function(data)
		local b = base64.b
		return ((data:gsub('.', function(x)
			local r,b='',x:byte()
			for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
			return r;
		end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
			if (#x < 6) then return '' end
			local c=0
			for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
			return b:sub(c+1,c+1)
		end)..({ '', '==', '=' })[#data%3+1])
	end,
	dec = function(data)
		local b = base64.b
		data = string.gsub(data, '[^'..b..'=]', '')
		return (data:gsub('.', function(x)
			if (x == '=') then return '' end
			local r,f='',(b:find(x)-1)
			for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
			return r;
		end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
			if (#x ~= 8) then return '' end
			local c=0
			for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
			return string.char(c)
		end))
	end
}

function shuffle(t)
	local nums = {}
	local ret = {}
	for k = 1, #t do
		nums[k] = k
	end
	for k = 1, #t do
		local rnd = math.random(#nums)
		table.insert(ret, t[nums[rnd]])
		table.remove(nums, rnd)
	end
	for k = 1, #t do
		t[k] = ret[k]
	end
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
			local sta, err = pcall(dofile, "soul.lua")
			if not sta then
				s = s .. "error @ Soul:\n```\n" .. err .. "\n```\n"
			end
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
			if msg.from.username == settings.master then
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
			elseif settings.dolua then
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
			settings.mute = true
			bot.sendMessage(msg.chat.id, "Okay.", nil, nil, nil, msg.message_id)
		end,
		desc = "Stop talking.",
		limit = {
			master = true
		}
	},
 	unmute = {
		func = function()
			settings.mute = true
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
				return extension.onTextReceive(msg.reply_to_message)
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
-- process
-------------------------------------------
extension.onTextReceive = function (message)
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
				elseif v.limit.master and msg.from.id ~= settings.masterid then
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

	if settings.mute then
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

extension.onPhotoReceive = function (msg)
	local text = commands.scan.func(msg.photo[#msg.photo].file_id, true)
end

extension.onAudioReceive = function (msg)
	if msg.chat.type == "private" then
		bot.sendMessage(msg.chat.id, "I received a message (audio). \n" .. table.encode(msg))
	end
end

extension.onDocumentReceive = function (msg)
	if msg.chat.type == "private" then
		bot.sendMessage(msg.chat.id, "I received a message (document). \n" .. table.encode(msg))
	end
end

extension.onStickerReceive = function (msg)
	if msg.chat.type == "private" then
		bot.sendMessage(msg.chat.id, "I received a message (sticker). \n" .. table.encode(msg))
	end
end

extension.onVideoReceive = function (msg)
	if msg.chat.type == "private" then
		bot.sendMessage(msg.chat.id, "I received a message (video). \n" .. table.encode(msg))
	end
end

extension.onVoiceReceive = function (msg)
	if msg.chat.type == "private" then
		bot.sendMessage(msg.chat.id, "I received a message (voice). \n" .. table.encode(msg))
	end
end

extension.onContactReceive = function (msg)
	if msg.chat.type == "private" then
		bot.sendMessage(msg.chat.id, "I received a message (contact). \n" .. table.encode(msg))
	end
end

extension.onLocationReceive = function (msg)
	if msg.chat.type == "private" then
		bot.sendMessage(msg.chat.id, "I received a message (location). \n" .. table.encode(msg))
	end
end

extension.onLeftChatParticipant = function (msg)
	if msg.left_chat_member.username == "Project_Small_Robot" then
		bot.sendMessage(settings.masterid, "I have been kicked from group [" .. msg.chat.title .. "] by [" .. msg.from.first_name .. " " .. msg.from.last_name .. "](@" .. msg.from.username .. ").")
		bot.sendMessage(msg.from.id, "Operation finished.")
	end
end

extension.onNewChatParticipant = function (msg)
	if msg.new_chat_member.username == "Project_Small_Robot" then
		bot.sendMessage(settings.masterid, "I have been added to group [" .. msg.chat.title .. "] by [" .. msg.from.first_name .. " " .. (msg.from.last_name or "") .. "](@" .. msg.from.username .. ").")
		bot.sendMessage(msg.from.id, "Thanks for your invitation.")
		bot.sendMessage(msg.chat.id, "Hello everyone, I am Project Small R.")
	end
end

extension.onNewChatPhoto = function (msg)
	if msg.chat.type == "private" then
		bot.sendMessage(msg.chat.id, "I received a message (NewChatPhoto). \n" .. table.encode(msg))
	end
end

extension.onDeleteChatPhoto = function (msg)
	if msg.chat.type == "private" then
		bot.sendMessage(msg.chat.id, "I received a message (DeleteChatPhoto). \n" .. table.encode(msg))
	end
end

extension.onGroupChatCreated = function (msg)
	bot.sendMessage(settings.masterid, "I received a message (GroupChatCreated). \n" .. table.encode(msg))
end

extension.onSupergroupChatCreated = function (msg)
	bot.sendMessage(settings.masterid, "I received a message (SupergroupChatCreated). \n" .. table.encode(msg))
end

extension.onChannelChatCreated = function (msg)
	if msg.chat.type == "private" then
		bot.sendMessage(msg.chat.id, "I received a message (ChannelChatCreated). \n" .. table.encode(msg))
	end
end

extension.onMigrateToChatId = function (msg)
	if msg.chat.type == "private" then
		bot.sendMessage(msg.chat.id, "I received a message (MigrateToChatId). \n" .. table.encode(msg))
	end
end

extension.MigrateFromChatId = function (msg)
	if msg.chat.type == "private" then
		bot.sendMessage(msg.chat.id, "I received a message (MigrateFromChatId). \n" .. table.encode(msg))
	end
end

extension.onUnknownTypeReceive = function (msg)
	bot.sendMessage(settings.masterid, "I received a message (unknown). \n" .. table.encode(msg))
end

extension.onEditedMessageReceive = function (msg)

end

extension.onInlineQueryReceive = function (msg)
	bot.sendMessage(settings.masterid, "I received a message (InlineQuery). \n" .. table.encode(msg))
end

extension.onChosenInlineQueryReceive = function (msg)
	bot.sendMessage(settings.masterid, "I received a message (ChosenInlineQuery). \n" .. table.encode(msg))
end

extension.onCallbackQueryReceive = function (msg)
	if not msg.from.username then
		msg.from.username = "$" .. msg.from.id
	end
	bot.answerCallbackQuery(msg.id, "Received.")
end

-- to-do: Use metatable instead.
for k, v in pairs(extension) do
	if k:find("on.+Receive") then
		extension[k] = function (msg)
			if settings.record then
				if msg.chat and msg.chat.id then
					msgList[msg.chat.id] = msgList[msg.chat.id] or {}
					if msg.message_id and not msgList[msg.chat.id][msg.message_id] then
						msgList[msg.chat.id][msg.message_id] = {
							{
								timestamp = msg.date
							},
							sender = msg.from.username or (" " .. (msg.from.first_name or "unknown") .. " " .. (msg.from.last_name or "")),
							from = msg.chat.type == "private" and "private" or "group: " .. tostring(msg.chat.title),
							chat_id = msg.chat.id,
							type = k:match("on(.+)Receive")
						}
					end
				end
			end
			if settings.debug then
				print(os.date(), table.encode(msg))
			end
			local sta, err = pcall(v, msg)
			if (not sta) then
				bot.sendMessage(settings.masterid, "[ERROR]\nfunction: " .. k .. "\n" .. tostring(err))
				if settings.warning and msg.chat then
					bot.sendMessage(msg.chat.id, "[ERROR]\nfunction: " .. k .. "\n" .. tostring(err))
				end
				lastlog = err
				etime = os.time()
			end
			lastSave = lastSave or os.time()
			if os.time() - lastSave > 24*60*60 then
				save()
				lastSave = os.time()
			end
		end
	end
end
