-------------------------------------------
-- Small R
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
knowledge = {
	"conversation",
	"kcInfo",
	"expList"
}

memory = {
	"msgList",
	"votes",
	"naiveList",
	"clickMsg",
	"forwardLog",
	"forwardCnt"
}

-------------------------------------------
-- utils
-------------------------------------------
dofile("utils.lua")

function bot.save()
	local f = io.open("database", "w")
	f:write(string.format("-------------------------------------------\n-- Project Small R\n-- Database\n-- Update @ %s\n-------------------------------------------\n", os.date()))
	for k in pairs(memory) do
		if type(_G[k]) == "table" then
			f:write(string.format("%s = %s\n\n", k, table.encode(_G[k])))
		end
	end
	f:close()
end

function bot.load()
	dofile("knowledge")
	for _, k in pairs(knowledge) do
		_G[k] = _G[k] or {}
	end

	dofile("database")
	for _, k in pairs(memory) do
		_G[k] = _G[k] or {}
	end
end

function bot.backup()
	os.execute("rm database.bak")
	os.execute("cp database database.bak")
end

function updateVote(msgid)
	local t = {}
	if (votes[msgid].now == votes[msgid].limit) then
		for i = 1, #votes[msgid].sel do
			local cnt = 0
			for k, v in pairs(votes[msgid].votes) do
				if v == i then
					cnt = cnt + 1
				end
			end
			table.insert(t, {{text = votes[msgid].sel[i] .. " - " .. cnt, callback_data = tostring(i)}})
	    end
	else
		for i = 1, #votes[msgid].sel do
			table.insert(t, {{text = votes[msgid].sel[i], callback_data = tostring(i)}})
		end
	end
	bot.editMessageText(votes[msgid].chat, msgid, nil, "[vote] " .. votes[msgid].info .. string.format("\n(%d/%d)", votes[msgid].now, votes[msgid].limit), "HTML", nil, cjson.encode({inline_keyboard = t}))
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
			if not msg.reply_to_message.text:find("/review") then
				return soul.onMessageReceive(msg.reply_to_message)
			end
		end,
		desc = "Process a message again.",
		help = "Reply to message.",
		limit = {
			reply = true,
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
			bot.editMessageText(msg.chat.id, ret.result.message_id, nil, "upgrading...\n" .. "done.", "Markdown")
		end,
		desc = "Upgrade Telegram Bot API Code."
	},
	backup = {
		func = function()
			local ret = bot.sendMessage(msg.chat.id, "processing...", nil, nil, nil, msg.message_id)
			bot.save()
			bot.backup()
			bot.editMessageText(msg.chat.id, ret.result.message_id, nil, "processing...\ndone.", "HTML")
		end,
		desc = "Backup the database."
	},
	update = {
		func = function()
			local ret = bot.sendMessage(msg.chat.id, "updating...", nil, nil, nil, msg.message_id)
			local content = wget("https://zh.moegirl.org/zh-hans/Template:%E8%88%B0%E9%98%9FCollection:%E5%AF%BC%E8%88%AA")
			bot.editMessageText(msg.chat.id, ret.result.message_id, nil, "updating...\nprocessing...", "HTML")
			local notice = "done."
			content = content:match('class="navbox"(.-)暁の水平線に勝利を刻みなさい')
			if (not content) then
				notice = "failed."
			else
				for mat in content:gmatch('<div style="padding:0em 0.25em">(.-)</div>') do
					for url, name in mat:gmatch('<a href="(.-)".->(.-)</a>') do
						kcInfo[name:gsub("<.->", "")] = url
					end
				end
			end
			bot.editMessageText(msg.chat.id, ret.result.message_id, nil, "updating...\n" .. notice, "HTML")
		end,
		desc = "Update kancolle database.",
	},
	query = {
		func = function(query)
			if not kcInfo["岛风"] then
				commands.update.func()
			end
			local query = query or msg.text:match("/query%s*(%S.-)%s*$")
			if tonumber(query) and kcInfo[tonumber(query)] then
				local ref = kcInfo[tonumber(query)]
				bot.sendMessage(msg.chat.id, string.format("【远征 #%s - %s】(%s)\n所需时间 - %s\n等级限制 - *%s*\n队伍编成 - %s\n获得资源 - %s\n消耗燃油 *%s* 及 弹药 *%s*", query, ref.name, ref.hard, ref.time, ref.level, ref.team, ref.bonus, ref.spend_a, ref.spend_b), "Markdown")
				return
			end
			local result = "maybe: "
			local cnt = 0
			if kcInfo[query] then
				local info = wget("https://zh.moegirl.org/zh-hans" .. kcInfo[query])
				local content = info:match('<table class="wikitable.-style="text%-align:center.->(.-)</table>')
				if content then
					result = content:gsub("\n", ""):gsub("<b>", "【"):gsub("</b>", "】"):gsub('<td style="background:DarkCyan;color:White">%s*(%S+)%s*</td>', "【%1】"):gsub("</tr>", "\n"):gsub("<.->", ""):gsub("\n ", "\n"):gsub("\n", "\n　　"):gsub("　　【", "【"):gsub("&amp;", "&")
					result = htmlDecode(result)
				else
					result = "failed."
				end
			elseif query ~= "" then
				local last = ""
				for k, v in pairs(kcInfo) do
					if type(k) == "string" and k:find(query) then
						if cnt ~= 0 then
							result = result .. ", "
						end
						result = result .. k
						cnt = cnt + 1
						if cnt > 10 then
							result = result .. ", ..."
							break
						end
						last = k
					end
				end
				if cnt == 0 then
					result = "Sorry, not found."
				elseif cnt == 1 then
					bot.sendMessage(msg.chat.id, result)
					return commands.query.func(last)
				end
			end
			bot.sendMessage(msg.chat.id, result)
		end,
		form = "/query <name/id>",
		desc = "Kancolle wiki.",
		help = "e.g.\n  `/query 岛风` (舰船)\n  `/query 炮` (装备)\n  `/query 2` (远征)",
		limit = {
			match = "/query%s*(%S.-)%s*$"
		}
	},
	generate = {
		func = function ()
			local bangumi, number = msg.text:match("/generate%s*(%S.-)#(%d+)")
			local notice = "searching..."
			local ret = bot.sendMessage(msg.chat.id, notice, nil, nil, nil, msg.message_id)
			local query = wget("http://anicobin.ldblog.jp/search?q=" .. url_encode(bangumi))
			local reg = '<h2 class="top%-article%-title entry%-title"><a href="([^\n]-)"[^\n]-rel="bookmark">([^\n]-BGM_NUM)[^\n]-</a></h2>'
			if not query then
				return bot.editMessageText(msg.chat.id, ret.result.message_id, nil, notice .. "\nnetwork error.", "HTML")
			end
			local url, title = query:match(reg:gsub("BGM_NUM", "第" .. number .. "話"))
			if not url then
				return bot.editMessageText(msg.chat.id, ret.result.message_id, nil, notice .. "\nnot found", "HTML")
			end
			notice = notice .. "\nloading " .. title .. "..."
			bot.editMessageText(msg.chat.id, ret.result.message_id, nil, notice, "HTML")
			local page = wget(url)
			if not page then
				return bot.editMessageText(msg.chat.id, ret.result.message_id, nil, notice .. "\nnetwork error.", "HTML")
			end
			notice = notice .. "\nmatching..."
			bot.editMessageText(msg.chat.id, ret.result.message_id, nil, notice, "HTML")
			local mat = '<span%s*style="[^"]-">[^<>]-<b>([^<>]-)</b>[^<>]-</span>'
			local origin = {}
			page = page:gsub("。", "\n"):gsub("！", "\n"):gsub("？", "\n"):gsub("\r\n", "\n"):gsub("\n+", "\n")
			for current in page:gmatch(mat) do
				for sentence in current:gmatch("([^\n]+)") do
					local tmp = sentence:gsub("^.-「", ""):gsub("^.-『", ""):gsub("」", ""):gsub("』", "")
					if tmp ~= "" then
						origin[#origin + 1] = tmp
					end
				end
			end
			current = "\t"
			for k = 1, #origin do
				if #(current .. origin[k]) < 4096 then
					current = current .. origin[k] .. "\n"
				else
					bot.sendMessage(msg.chat.id, current)
					current = "\t" .. origin[k] .. "\n"
				end
			end
			bot.sendMessage(msg.chat.id, current)
			bot.editMessageText(msg.chat.id, ret.result.message_id, nil, notice .. "\ndone.", "HTML")
		end,
		form = "/generate <bangumi>#<number>",
		desc = "Search script for bangumi.",
		help = "e.g. `/generate サクラクエスト#1`",
		limit = {
			match = "/generate%s*(%S.-)#(%d+)"
		}
	},
	vote = {
		func = function()
			local info, opt, lim = msg.text:match("/vote%s*(%S.-)%s*%[(.+)%]%s*%((%d+)%)")
			local sel
			local t = {}
			local a = {}
			for sel in opt:gmatch("([^|]+)") do
				table.insert(t, {{text = sel, callback_data = tostring(#t + 1)}})
				table.insert(a, sel)
			end
			print( cjson.encode({inline_keyboard = t}))
			local res = bot.sendMessage(msg.chat.id, "[Vote] " .. info, nil, nil, nil, nil, cjson.encode({inline_keyboard = t}))
			-- todo: id
			votes[res.result.message_id] = {now = 0, limit = tonumber(lim), info = info, sel = a, votes = {}, chat = msg.chat.id}
		end,
		form = "/vote <text>[<option1|option2|...>](<vote_limit>)",
		desc = "Start a new vote.",
		help = "e.g. `/vote Do you like apples?[Yes|No](5)`",
		limit = {
			match = "/vote%s*(%S.-)%s*%[(.+)%]%s*%((%d+)%)"
		}
	},
	setmsg = {
		func = function()
			local des, txt = msg.text:match("/setmsg%s*(%S.-)%s*@%s*(%S.-)$")
			table.insert(clickMsg, {des, txt})
			bot.sendMessage(msg.chat.id, "Okay. The message id is " .. #clickMsg .. ".")
		end,
		form = "/setmsg <desc>@<text>",
		desc = "Set up a message.",
		help = "e.g. `/setmsg Click to view.@Look!`",
		limit = {
			match = "/setmsg%s*(%S.-)%s*@%s*(%S.-)$"
		}
	},
	sendmsg = {
		func = function()
			local id = tonumber(msg.text:match("/sendmsg%s*(%d+)"))
			if not clickMsg[id] then
				return bot.sendMessage(msg.chat.id, "Not found.")
			else
				return bot.sendMessage(msg.chat.id, "\\[Message]\n" .. clickMsg[id][1], "Markdown", nil, nil, nil, cjson.encode({inline_keyboard = {{
					{
						text = "View",
						callback_data = tostring(id)
					}
				}}}))
			end
		end,
		form = "/sendmsg <message_id>",
		desc = "Send a message.",
		help = "e.g. `/sendmsg 1`",
		limit = {
			match = "/sendmsg%s*(%d+)"
		}
	},
	history = {
		func = function()
			local mid = tonumber(msg.text:match("/history%s*(%d+)%s*")) or msg.reply_to_message.message_id
			local chat_id = tonumber(msg.text:match("@(%-?%d+)%s*")) or msg.chat.id
			local ref = msgList[chat_id][mid]
			if ref then
				local res = "Message from @" .. ref.sender .. " (" .. ref.from .. ")\n"
				for k = 1, #ref do
					res = res .. "[#" .. k .. "][" .. os.date("%x %X", (ref[k].timestamp or os.time()) + 3600*8) .. "]\n" .. ref[k].text .. "\n"
				end
				bot.sendMessage(msg.chat.id, res .. "[That's all.]")
			else
				bot.sendMessage(msg.chat.id, "Sorry, not found.")
			end
		end,
		form = "/history <msgID> [@chatID]",
		desc = "Query specific message.",
		help = "e.g. `/history 2333`\nor reply to message.",
		limit = {
			reply = true,
			match = "/history%s*(%d+)%s*"
		}
	},
	forward = {
		func = function()
			local mid = tonumber(msg.text:match("/forward%s*(%d+)%s*"))
			local chat_id = tonumber(msg.text:match("@(%-?%d+)")) or msg.chat.id
			local res = bot.forwardMessage(msg.chat.id, chat_id, false, mid)
			if not res.ok then
				bot.sendMessage(msg.chat.id, "Sorry, not found.")
			end
		end,
		form = "/forward <msgID> [@chatID]",
		desc = "Forward specific message.",
		help = "e.g. `/forward 2333`",
		limit = {
			match = "/forward%s*(%d+)%s*"
		}
	},
	locate = {
		func = function()
			local mid = tonumber(msg.text:match("/locate%s*(%d+)%s*"))
			local res = bot.sendMessage(msg.chat.id, "Located.", nil, nil, nil, mid)
			if not res.ok then
				bot.sendMessage(msg.from.id, "Sorry, not found.")
			end
		end,
		form = "/locate <msgID>",
		desc = "Locate specific message.",
		help = "e.g. `/locate 2333`",
		limit = {
			match = "/locate%s*(%d+)%s*"
		}
	},
	find = {
		func = function()
			count = 0
			str = msg.text:match("/find%s*(.+)%s*$") .. " "
			keys = {}
			while str:find("^%S+%s+") do
				table.insert(keys, str:match("^(%S+)%s+"))
				str = str:gsub("^%S+%s+", "")
			end
			res = "[result - (" .. table.concat(keys, ", ") .. ")]\n"
			local t = {}
			for _, c in pairs(msgList) do
				if type(c) == "table" then
					for mid, v in pairs(c) do
						if type(v) == "table" then
							v.mid = mid
							table.insert(t, v)
						end
					end
				end
			end
			table.sort(t, function(a, b) return a[#a].timestamp > b[#b].timestamp end)
			for i = 1, #t do
				v = t[i]
				local s = cjson.encode(v)
				local flag = true
				for _, key in pairs(keys) do
					if not s:find(key) then
						flag = false
						break
					end
				end
				if flag then
					count = count + 1
					res = res .. "[#" .. count .. "](" .. v.mid .. ") @" .. v.sender .. " (" .. v.from .. ") at " .. os.date("%x %X", (v[#v].timestamp or os.time()) + 3600*8) .. "\n> " .. tostring(v[#v].text) .. "\n"
				end
				if count == 10 then
					res = res .. "Reached limit. Please specify keywords.\n"
					break
				end
			end
			res = res .. "You can use `/history <msgID> <@chatID>` to check the message."
			bot.sendMessage(msg.chat.id, count == 0 and "Sorry, no found." or res)
		end,
		form = "/find <keywords>",
		desc = "Search in history.",
		help = "Keywords can be type or name.\ne.g.\n  `/find hello world`\n  `/find private Voice`",
		limit = {
			match = "/find%s*(.+)%s*$"
		}
	},
	ranking = {
		func = function()
			local t = {}
			for k, v in pairs(naiveList) do
				table.insert(t, {username = v.username, second = v.second})
			end
			table.sort(t, function(a, b) return a.second > b.second end)
			local s = "[RANKING]\n"
			for k = 1, math.min(#t, 5) do
				s = s .. "[#" .. k .. "] @" .. t[k].username .. " +" .. t[k].second .. "s!\n"
			end
			bot.sendMessage(msg.chat.id, s .. rand("Sometimes naive.", "Too young, too simple.", "+1s.", "Excited!"))
		end,
		desc = "A ranking for something."
	},
	close = {
		func = function()
			if msg.reply_to_message and votes[msg.reply_to_message.message_id] then
				votes[msg.reply_to_message.message_id].limit = votes[msg.reply_to_message.message_id].now
				updateVote(msg.reply_to_message.message_id)
				bot.sendMessage(msg.chat.id, "Vote is closed.", nil, nil, nil, msg.reply_to_message.message_id)
			else
				bot.sendMessage(msg.chat.id, "It's not a vote.", nil, nil, nil, msg.reply_to_message.message_id)
			end
		end,
		desc = "Close a vote.",
		help = "Reply to a vote to close it.",
		limit = {
			reply = true
		}
	},
	exp = {
		func = function()
			local from, to = msg.text:match("/exp%D*(%d+)%D+(%d+)%D*")
			from, to = tonumber(from), tonumber(to)
			if from and to and expList[from] and expList[to] and from <= to then
				local extra = ""
				if from <= 99 and to > 99 then
					extra = "<code>money</code>: <b>700円</b>\n"
				end
				bot.sendMessage(msg.chat.id, string.format("<b>[Lv. %d to Lv. %d]</b>\n%s<code>EXP  </code>: <b>%d</b>\n<code>3-2-1</code>: <b>%d回</b> (S)", from, to, extra, expList[to] - expList[from], math.floor((expList[to] - expList[from]) / 384 + 0.99)), "HTML")
			else
				bot.sendMessage(msg.chat.id, "usage: /exp (now) (target), 1 <= level <= 165, now <= target.")
			end
		end,
		form = "/exp <current_level> <target_level>",
		desc = "Kancolle calculator.",
		help = "e.g. `/exp 90 110`",
		limit = {
			match = "/exp%D*(%d+)%D+(%d+)%D*"
		}
	},
	resize = {
		func = function(silent)
			if msg.reply_to_message.sticker then
				bot.downloadFile(msg.reply_to_message.sticker.file_id, "sticker")
				os.execute("dwebp sticker -o sticker.png")
			elseif msg.reply_to_message.photo then
				bot.downloadFile(msg.reply_to_message.photo[#msg.reply_to_message.photo].file_id, "sticker")
				os.execute("convert -resize 512x512 sticker sticker.png")
			elseif msg.reply_to_message.document then
				if msg.reply_to_message.document.file_size > 10485760 then
					return bot.sendMessage(msg.chat.id, "No more than 10M.", nil, nil, nil, msg.message_id)
				end
				bot.downloadFile(msg.reply_to_message.document.file_id, "sticker")
				if msg.reply_to_message.document.mime_type:find("video") then
					os.execute("ffmpeg -i sticker -vframes 1 flame.png")
					os.execute("convert -resize 512x512 flame.png sticker.png")
				else
					os.execute("convert -resize 512x512 sticker sticker.png")
				end
			end

			local f = io.open("sticker.png", "r")
			if not f then
				return bot.sendMessage(msg.chat.id, "Not a sticker.", nil, nil, nil, msg.message_id)
			end
			f:close()

			if silent then
				return
			end

			bot.sendDocument(msg.chat.id, readFile("sticker.png"))
		end,
		desc = "Convert sticker/gif/picture to sticker png.",
		help = "Reply to sticker/picture.",
		limit = {
			reply = true
		}
	},
	addsticker = {
		func = function()
			local title = msg.text:match("/addsticker%s*(%S.-)%s*$") or ("Sticker Pack By " .. msg.from.first_name .. (msg.from.last_name and (" " .. msg.from.last_name) or ""))

			commands.resize.func(true)
			local fid = bot.uploadStickerFile(msg.from.id, readFile("sticker.png")).result.file_id
			os.remove("sticker.png")

			local ret = bot.createNewStickerSet(msg.from.id, "u" .. msg.from.id .. "_by_Project_Small_Robot", title, fid, "🍀")
			-- after debug: fix
			local pack_url = "[" .. title .. "](https://t.me/addstickers/u" .. msg.from.id .. "_by_Project_Small_Robot" .. ")"

			if ret.ok then
				return bot.sendMessage(msg.chat.id, "All right.\n" .. pack_url, "Markdown", nil, nil, msg.message_id)
			end

			local ret = bot.addStickerToSet(msg.from.id, "u" .. msg.from.id .. "_by_Project_Small_Robot", fid, "🍀")

			if ret.ok then
				return bot.sendMessage(msg.chat.id, "All right.\n" .. pack_url, "Markdown", nil, nil, msg.message_id)
			else
				return bot.sendMessage(msg.chat.id, "Failed. (`" .. ret.description .. "`)\n" .. pack_url, "Markdown", nil, nil, msg.message_id)
			end
		end,
		desc = "Add a sticker to your sticker pack.",
		form = "/addsticker [title]",
		help = "Reply to sticker/picture.",
		limit = {
			reply = true
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

	if config.naive then
		local str = string.lower(msg.text)
		if str:find("+%d+[Ss]") or str:find("naive") or str:find("excit") or str:find("too%s*young") or str:find("长者") or (str:find("报道") and str:find("偏差")) or str:find("人生经验") or str:find("too%s*simple") or str:find("蛤") or str:find("续一秒") or str:find("续1秒") or str:find("续1s") or str:find("香港记者") or str:find("华莱士") or (str:find("江") and str:find("泽") and str:find("民")) or str:find("续命") or str:find("呱") then
			naiveList[msg.from.id] = naiveList[msg.from.id] or {second = 0}
			naiveList[msg.from.id].username = msg.from.username
			naiveList[msg.from.id].second = naiveList[msg.from.id].second + 1
		end
	end

	if os.time() - msg.date > 60 then
		return
	end

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

	if (msg.from.id == 109409998) and (msg.text:find("穷") or ((msg.text:find("没") and (msg.text:find("钱") or msg.text:find("余额") or msg.text:find("饭"))))) then
		local ident = msg.chat.id .."|" .. msg.message_id
		for k, v in pairs(forwardLog) do
			if k == msg.text then
				if forwardCnt[v] >= 2 then
					bot.forwardMessage(-1001129208155, msg.chat.id, false, msg.message_id)
				end
				return
			end
		end
		forwardLog[msg.text] = ident
		forwardCnt[ident] = 0
		return bot.sendMessage(msg.chat.id, "#TYP哭穷了吗", nil, nil, nil, msg.message_id, cjson.encode({inline_keyboard = {{
			{
				text = "哭穷了",
				callback_data = "typ+|" .. ident
			},
			{
				text = "没哭穷",
				callback_data = "typ-|" .. ident
			}
		}}}))
	end

	for keyword, reply in pairs(conversation) do
		local match = false
		if type(keyword) == "string" then
			match = msg.text:find(keyword)
		elseif type(keyword) == "table" then
			for _, keys in pairs(keyword) do
				match = match or msg.text:find(keyword)
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
			else
				return bot.sendMessage(msg.chat.id, ans, reply.type or "Markdown", nil, nil, rep)
			end
		end
	end
end

soul.onEditedMessageReceive = function (msg)
	msgList[msg.chat.id][msg.message_id] = msgList[msg.chat.id][msg.message_id] or {
		{
			text = "(lost)",
			timestamp = msg.date
		},
		sender = msg.from.username,
		from = msg.chat.type == "private" and "private" or "group: " .. tostring(msg.chat.title),
		chat_id = msg.chat.id,
		type = "Text"
	}

	table.insert(msgList[msg.chat.id][msg.message_id], {
		text = msg.text,
		timestamp = msg.edit_date
	})
end

soul.onLeftChatMembersReceive = function (msg)
	if msg.left_chat_member.username == "Project_Small_Robot" then
		bot.sendMessage(config.masterid, "I have been kicked from group [" .. msg.chat.title .. "] by [" .. msg.from.first_name .. " " .. msg.from.last_name .. "](@" .. msg.from.username .. ").")
		bot.sendMessage(msg.from.id, "Operation finished.")
	end
end

soul.onNewChatMembersReceive = function (msg)
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
	if (votes[msg.message.message_id]) then
		if (votes[msg.message.message_id].now < votes[msg.message.message_id].limit) then
			bot.answerCallbackQuery(msg.id, "Success.")
			local updated = false
			if (not votes[msg.message.message_id].votes[msg.from.id]) then
				updated = true
				votes[msg.message.message_id].now = votes[msg.message.message_id].now + 1
			end
			votes[msg.message.message_id].votes[msg.from.id] = tonumber(msg.data)
			if (updated) then
				updateVote(msg.message.message_id)
			end
		else
			bot.answerCallbackQuery(msg.id, "Failed - Closed.")
		end
	elseif tonumber(msg.data) and clickMsg[tonumber(msg.data)] then
		bot.editMessageText(msg.message.chat.id, msg.message.message_id, nil, "[message]\n" .. clickMsg[tonumber(msg.data)][2] or "Nothing.", "HTML")
		bot.answerCallbackQuery(msg.id, "Updated.")
	elseif msg.data:find("^typ[%+%-]|(.-)|(.-)$") then
		local vote, chat_id, msg_id = msg.data:match("^typ([%+%-])|(.-)|(.-)$")
		local k = chat_id .. "|" .. msg_id
		if math.abs(forwardCnt[k]) >= 2 then
			return bot.answerCallbackQuery(msg.id, "Failed - Processed.")
		end
		forwardCnt[k] = (forwardCnt[k] or 0) + (vote == "+" and 1 or -1)
		bot.answerCallbackQuery(msg.id, "Confirmed. (" .. forwardCnt[k] .. " of ±2)")
		if forwardCnt[k] >= 2 then
			bot.forwardMessage(-1001129208155, tonumber(chat_id), false, tonumber(msg_id))
		end
		if math.abs(forwardCnt[k]) >= 2 then
			local ret = bot.deleteMessage(msg.message.chat_id, msg.message.message_id)
			if not ret then
				bot.sendMessage(settings.masterid, "Request Failed.")
			end
		end
	else
		bot.answerCallbackQuery(msg.id, "Failed - Not Found.")
	end
end

soul.onPhotoReceive = function(msg)
	if config.record then
		msgList[msg.chat.id][msg.message_id][1].text = msg.caption or "(photo)"
		msgList[msg.chat.id][msg.message_id][1].file = msg.photo[#msg.photo].file_id
	end
end

for k, v in pairs(soul) do
	soul[k] = function (msg)
		if config.debug then
			print(os.date(), table.encode(msg))
		end
		if config.record then
			if msg.chat and msg.chat.id then
				msgList[msg.chat.id] = msgList[msg.chat.id] or {}
				if msg.message_id and not msgList[msg.chat.id][msg.message_id] then
					msgList[msg.chat.id][msg.message_id] = {
						{
							text = msg.text,
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
		local sta, err = pcall(v, msg)
		if (not sta) then
			bot.sendMessage(config.masterid, string.format("\\[ERROR]\nfunction: `%s`\n```\n%s```", k, tostring(err)), "Markdown")
			if config.warning and msg.chat then
				bot.sendMessage(config.masterid, string.format("\\[ERROR]\nfunction: `%s`\n```\n%s```", k, tostring(err)), "Markdown")
			end
		end
	end
end
