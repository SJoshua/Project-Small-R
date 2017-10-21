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

youdao_error = {
	[101] = "缺少必填的参数，出现这个情况还可能是et的值和实际加密方式不对应",
	[102] = "不支持的语言类型",
	[103] = "翻译文本过长",
	[104] = "不支持的API类型",
	[105] = "不支持的签名类型",
	[106] = "不支持的响应类型",
	[107] = "不支持的传输加密类型",
	[108] = "appKey无效",
	[109] = "batchLog格式不正确",
	[110] = "无相关服务的有效实例",
	[111] = "开发者账号无效，可能是账号为欠费状态",
	[201] = "解密失败，可能为DES,BASE64,URLDecode的错误",
	[202] = "签名检验失败",
	[203] = "访问IP地址不在可访问IP列表",
	[301] = "辞典查询失败",
	[302] = "翻译查询失败",
	[303] = "服务端的其它异常",
	[401] = "账户已经欠费",
	[1001] = "无效的OCR类型",
	[1002] = "不支持的OCR image类型",
	[1003] = "不支持的OCR Language类型",
	[1004] = "识别图片过大",
	[1201] = "图片base64解密失败",
	[1301] = "OCR段落识别失败",
	[1411] = "访问频率受限",
	[1412] = "超过最大识别字节数"
}
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
function tprint(t)
	local s, r = pcall(cjson.encode, t)
	if s then
		return r
	else
		return "failed: " .. r
	end
end

function rand(...)
	local t = {...}
	return t[math.random(#t)]
end

function encodeVar(var)
	if type(var) == "string" then
		return '"' .. var:gsub("\\", "\\\\"):gsub('"', [[\"]]):gsub("\n", [[\n]]):gsub("\r", [[\r]]) .. '"'
	elseif type(var) == "number" then
		return var
	elseif type(var) == "table" then
		return table.encode(var)
	else
		return tostring(var)
	end
end

function url_encode(str)
	if (str) then
		str = str:gsub("([^%w %-%_%.%~])", function (c) return string.format ("%%%02X", string.byte(c)) end):gsub(" ", "+")
	end
	return str
end

function table.encode(t, n)
	assert(type(t) == "table")
	if type(n) ~= "number" then
		n = 0
	end
	local tabs = string.rep("\t", n)
	local ret = "{\n"
	for k, v in pairs(t) do
		ret = ret .. tabs .. '\t[' .. encodeVar(k) .. '] = ' .. (type(v) == "table" and table.encode(v, n + 1) or encodeVar(v)) .. ",\n"
	end
	ret = ret .. tabs .. "}"
	return ret
end

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

function updateMahjong(msg)
	local msgid = msg.message.message_id
	local m = mahjong[msgid]

	local keyboard = {{}, {}, {
		{
			text = "チー",
			callback_data = "chii"
		},
		{
			text = "ポン",
			callback_data = "pon"
		},
		{
			text = "カン",
			callback_data = "kan"
		},
		{
			text = "リーチ",
			callback_data = "riichi"
		}},
		{{
			text = "ロン",
			callback_data = "ron"
		},
		{
			text = "ツモ",
			callback_data = "tsumo"
		},
		{
			text = "パス",
			callback_data = "pass"
		},
		{
			text = "手牌",
			callback_data = "update"
		},
	}}
	for k = 1, 14 do
		keyboard[k <= 7 and 1 or 2][k <= 7 and k or (k - 7)] = {
			text = tostring(k),
			callback_data = tostring(k)
		}
	end

	local function idToCard(n, sub)
		local s = sub and " <" or "["
		local cur = math.floor(n / 10)
		if cur == 0 then
			s = s .. ({"东", "南", "西", "北", "中", "白", "发"})[n]
		else
			s = s .. (n % 10) .. ({"s", "m", "p"})[cur]
		end
		s = s .. (sub and "> " or "]")
		return s
	end

	local function setToString(t)
		local s = ""
		for k = 1, #t do
			if t.plus == k then
				s = s .. "<"
			end
			if t[k] <= 7 then
				s = s .. ({"东", "南", "西", "北", "中", "白", "发"})[n]
			else
				s = s .. (t[k] % 10)
			end
			if t.plus == k then
				s = s .. ">"
			end
		end
		if t[1] > 7 then
			s = s .. ({"s", "m", "p"})[math.floor(t[1] / 10)]
		end
		return s
	end

	local function handToString(t, show)
		local s = ""
		for k = 1, #t do
			s = s .. (show and idToCard(t[k]) or "[]")
			if #t % 3 == 2 and k == #t - 1 then
				s = s .. " "
			end
		end
		for k = 1, #t.foo do
			s = s .. " [" .. setToString(t.foo[k]) .. "]"
		end
		return s
	end

	local function queryHand(t)
		local s = "Remain Time: " .. (20 - (os.time() - m.lastCommand)) .. "s\n"
		for k = 1, #t do
			s = s .. idToCard(t[k])
			if k == 3 or k == 10 then
				s = s .. "　"
			elseif k == 7 then
				s = s .. "\n"
			end
		end
		return s
	end

	local function deskToString(t)
		local s = ""
		for k = 1, #t do
			s = s .. idToCard(t[k], t.riich == k)
			if k % 6 == 0 and k ~= #t then
				s = s .. "\n"
			end
		end
		return s
	end

	local function updateMessage(out)
		local doraList = ""
		for k = 1, m.dora_num do
			doraList = doraList .. idToCard(m.yama[k]) .. (out and idToCard(m.yama[k + 5]) or "")
		end
		local current = string.format("山: %d\n王: %s\n\n东 (%s)\n%s\n%s\n\n南 (%s)\n%s\n%s\n\n西 (%s)\n%s\n%s\n\n北 (%s)\n%s\n%s",
			#m.cards, doraList,
			"@" .. m.player[1], handToString(m.hand[1], out == 1), deskToString(m.desk[1]),
			"@" .. m.player[2], handToString(m.hand[2], out == 2), deskToString(m.desk[2]),
			"@" .. m.player[3], handToString(m.hand[3], out == 3), deskToString(m.desk[3]),
			"@" .. m.player[4], handToString(m.hand[4], out == 4), deskToString(m.desk[4])
		)
		bot.editMessageText(m.chat, msgid, nil, string.format("[Mahjong#%d]<%s>\n%s", msgid, m.status, current), "", nil, cjson.encode({inline_keyboard = keyboard}))
	end

	local function selectCard(p, c)
		if c <= #m.hand[p] then
			table.insert(m.desk[p], m.hand[p][c])
			table.remove(m.hand[p], c)
			return true
		end
		return false
	end

	local function endGame(p)
		m.status = "end"
		updateMessage(p)
	end

	local function getCard(p)
		if #m.cards == 0 then
			endGame()
		end
		table.sort(m.hand[p])
		table.insert(m.hand[p], m.cards[#m.cards])
		table.remove(m.cards, #m.cards)
	end

	local function nextPlayer()
		m.current = m.current + 1
		if m.current == 5 then
			m.current = 1
		end
		getCard(m.current)
		m.lastCommand = os.time()
	end

	local function botAction()
		while m.player[m.current] == "$Bot" do
			selectCard(m.current, #m.hand[m.current])
			nextPlayer()
			updateMessage()
		end
	end

	-- update status

	if m.status == "going" then
		if os.time() - m.lastCommand > 20 then
			selectCard(m.current, #m.hand[m.current])
			nextPlayer()
		end
		updateMessage()
		botAction()
	elseif m.status == "end" then
		return bot.answerCallbackQuery(msg.id, "Failed - Game Ended.")
	end

	-- process command
	if msg.data == "join" then
		if m.status == "going" then
			return bot.answerCallbackQuery(msg.id, "Failed - Game Started.")
		end
		for _, v in pairs(m.player) do
			if v == msg.from.username then
				return bot.answerCallbackQuery(msg.id, "Success - You are in.")
			end
		end
		if #m.player == 4 then
			return bot.answerCallbackQuery(msg.id, "Failed - It's full.")
		end
		table.insert(m.player, msg.from.username)
		local list = ""
		for _, v in pairs(m.player) do
			list = list .. "\n@" .. v
		end
		bot.editMessageText(m.chat, msgid, nil, string.format("[Mahjong#%d]<wait>\nPlayer: %d/4%s", msgid, #m.player, list), "", nil, cjson.encode({inline_keyboard = {
			{
				{
					text = "Join",
					callback_data = "join"
				},
				{
					text = "Start",
					callback_data = "start"
				}
			}
		}}))
		return bot.answerCallbackQuery(msg.id, "Success - You are in.")
	elseif msg.data == "start" then
		if #m.player == 0 then
			return bot.answerCallbackQuery(msg.id, "Failed - No player.")
		elseif m.status == "going" then
			return bot.answerCallbackQuery(msg.id, "Failed - Playing.")
		end
		m.status = "going"
		local total = {}
		for color = 1, 3 do
			for card = 1, 9 do
				for number = 1, card == 5 and 3 or 4 do
					table.insert(total, color * 10 + card)
				end
				if card == 5 then
					table.insert(total, color * 10)
				end
			end
		end
		for k = 1, 7 do
			for i = 1, 4 do
				table.insert(total, k)
			end
		end
		shuffle(total)
		for k = 1, 4 do
			if not m.player[k] then
				m.player[k] = "$Bot"
			end
		end
		shuffle(m.player)
		for k = 1, 4 do
			for v = 1, 13 do
				m.hand[k][v] = total[#total]
				table.remove(total, #total)
			end
			m.hand[k].foo = {}
		end
		m.hand[1][14] = total[#total]
		for k = 1, 14 do
			m.yama[k] = total[#total]
			table.remove(total, #total)
		end
		m.cards = total
		updateMessage()
		bot.answerCallbackQuery(msg.id, "Game Start!")
		botAction()
	elseif msg.data == "update" then
		updateMessage()
		for k = 1, 4 do
			if m.player[k] == msg.from.username then
				return bot.answerCallbackQuery(msg.id, queryHand(m.hand[k]), true)
			end
		end
		return bot.answerCallbackQuery(msg.id, "Failed - You are not a player.")
	elseif tonumber(msg.data) then
		if m.player[m.current] == msg.from.username then
			if m.desk[m.current].riich then
				selectCard(m.current, #m.hand[m.current])
				updateMessage()
				nextPlayer()
				botAction()
				return bot.answerCallbackQuery(msg.id, "Success")
			end
			local ok = selectCard(m.current, tonumber(msg.data))
			if ok then
				bot.answerCallbackQuery(msg.id, "Success.")
				updateMessage()
				nextPlayer()
				botAction()
			else
				return bot.answerCallbackQuery(msg.id, "Failed - Not exist.")
			end
		else
			return bot.answerCallbackQuery(msg.id, "Failed - It's not your turn.")
		end
	elseif msg.data == "riichi" then
		if m.player[m.current] == msg.from.username and not m.desk[m.current].riich then
			m.desk[m.current].riich = #m.hand[m.current] + 1
			-- check?
			m.lastCommand = os.time()
		end
	elseif msg.data == "tsumo" then
		if m.player[m.current] == msg.from.username then
			endGame(m.current)
		end
	else
		return bot.answerCallbackQuery(msg.id, "Failed - Not Available.")
	end

	-- bot.sendMessage(msg.message.chat.id, "```\n" .. table.encode(msg) .. "\n```", "Markdown")
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
			bot.sendMessage(msg.chat.id, "Hello. This is Small R.")
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
				bot.sendMessage(msg.chat.id, commands.help.generate(msg.text:find("_ALL")), "Markdown")
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
			--[[
			package.loaded["lua-bot-api"] = nil
			local sta, api = pcall(require, "lua-bot-api")
			if not sta then
				s = s .. "error @ API:\n```\n" .. api .. "\n```"
			else
				bot, extension = api.configure(token)
			end
			]]
			local sta, err = pcall(dofile, "soul.lua")
			if not sta then
				s = s .. "error @ Soul:\n```\n" .. err .. "\n```\n"
			end
			bot.editMessageText(msg.chat.id, ret.result.message_id, nil, "reloading...\n" .. ((s == "") and "done." or s), "Markdown")
		end,
		desc = "Reload my soul."
	},
	lastlog = {
		func = function()
			if not lastlog then
				bot.sendMessage(msg.chat.id, "All is well.")
			else
				bot.sendMessage(msg.chat.id, "lastlog at " .. os.date("%x %X", etime + 3600*8) .. ":\n" .. lastlog)
			end
		end,
		desc = "The death information."
	},
	update = {
		func = function()
			kandata = ensei
			local ret = bot.sendMessage(msg.chat.id, "updating...", nil, nil, nil, msg.message_id)
			local content = wget("https://zh.moegirl.org/zh-hans/Template:%E8%88%B0%E9%98%9FCollection:%E5%AF%BC%E8%88%AA")
			bot.editMessageText(msg.chat.id, ret.result.message_id, nil, "updating...\nprocessing...", "HTML")
			local notice = "done."
			content = content:match('class="navbox"(.-)暁の水平線に勝利を刻みなさい')
			if (not content) then
				notice = "failed."
			else
				while content:find('<div style="padding:0em 0.25em">(.-)</div>') do
					local mat = content:match('<div style="padding:0em 0.25em">(.-)</div>')
					content = content:gsub('<div style="padding:0em 0.25em">(.-)</div>', '', 1)
					while mat:find('<a href="(.-)".->(.-)</a>') do
						local url, name = mat:match('<a href="(.-)".->(.-)</a>')
						name = name:gsub("<.->", "")
						kandata[name] = url
						mat = mat:gsub('<a href="(.-)".->(.-)</a>', '', 1)
					end
				end
			end
			bot.editMessageText(msg.chat.id, ret.result.message_id, nil, "updating...\n" .. notice, "HTML")
		end,
		desc = "Update kancolle database.",
	},
	query = {
		func = function(query)
			if not kandata then
				commands.update.func()
			end
			local query = query or msg.text:match("/query%s*(%S.-)%s*$")
			if tonumber(query) and kandata[tonumber(query)] then
				local ref = kandata[tonumber(query)]
				bot.sendMessage(msg.chat.id, string.format("【远征 #%s - %s】(%s)\n所需时间 - %s\n等级限制 - *%s*\n队伍编成 - %s\n获得资源 - %s\n消耗燃油 *%s* 及 弹药 *%s*", query, ref.name, ref.hard, ref.time, ref.level, ref.team, ref.bonus, ref.spend_a, ref.spend_b), "Markdown")
				return
			end
			local result = "maybe: "
			local cnt = 0
			if kandata[query] then
				local info = wget("https://zh.moegirl.org/zh-hans" .. kandata[query])
				local content = info:match('<table class="wikitable.-style="text%-align:center.->(.-)</table>')
				if content then
					result = content:gsub("\n", ""):gsub("<b>", "【"):gsub("</b>", "】"):gsub('<td style="background:DarkCyan;color:White">%s*(%S+)%s*</td>', "【%1】"):gsub("</tr>", "\n"):gsub("<.->", ""):gsub("\n ", "\n"):gsub("\n", "\n　　"):gsub("　　【", "【"):gsub("&amp;", "&")
					while result:find("&#(%d+);") do
						local ascii = tonumber(result:match("&#(%d+);"))
						if ascii > 128 then
							ascii = 10
						end
						result = result:gsub("&#(%d+);", string.char(ascii), 1)
					end
				else
					result = "failed."
				end
			elseif query ~= "" then
				local last = ""
				for k, v in pairs(kandata) do
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
	translate = {
		func = function (text, slient)
			local text = text or msg.text:match("/translate%s*(%S.+)%s*$") or msg.reply_to_message.text or msg.reply_to_message.caption
			if not text then
				return bot.sendMessage(msg.chat.id, "Huh?")
			end
			if #text > 1000 and not slient then
				return bot.sendMessage(msg.chat.id, "Too long, too naive.")
			end
			local raw = text:find("^_raw%s*(.-)$")
			if raw then
				text = text:match("^_raw%s*(.-)$")
			end
			salt = math.random(1024768)
			sign = md5.sumhexa(settings.youdao_id .. text .. salt .. settings.youdao_key)
			local ret = wget(string.format("http://openapi.youdao.com/api?q=%s&from=auto&to=auto&appKey=%s&salt=%d&sign=%s", url_encode(text), settings.youdao_id, salt, sign))
			local sta, dec = pcall(cjson.decode, ret)
			if sta then
				local res = table.encode(dec)
				if dec.errorCode == "0" then
					if slient then
						return dec.translation[1]
					end
					local ret = "[translate]\n" .. dec.translation[1]
					if dec.basic and dec.basic.explains then
						ret = ret .. "\n[dictionary]\n" .. table.concat(dec.basic.explains, ", ")
					end
					bot.sendMessage(msg.chat.id, ret)
				else
					if slient then
						return "failed(" .. (youdao_error[tonumber(dec.errorCode)] or "Unknown error") .. ")."
					end
					bot.sendMessage(msg.chat.id, "Oops, failed to translate.\n[" .. (youdao_error[tonumber(dec.errorCode)] or "Unknown error") .. "]")
				end
			else
				if slient then
					return "failed."
				end
				bot.sendMessage(msg.chat.id, string.format("[error] failed to decode. \n`%s`\nraw data: ```\n%s\n```", tostring(dec), tostring(ret)), "Markdown")
			end
		end,
		form = "/translate <text>",
		desc = "Translate something.",
		help = "e.g.\n  `/translate hello, world.`\nor reply to message.",
		limit = {
			match = "/translate%s*(%S.+)%s*$",
			reply = true
		}
	},
	scan = {
		func = function (pic, slient)
			if slient and not settings.ocr then return "(disabled)" end
			if not pic and not msg.reply_to_message.photo then
				return bot.sendMessage(msg.chat.id, "Nothing to scan.")
			end
			local pic = pic or msg.reply_to_message.photo[#msg.reply_to_message.photo].file_id
			bot.downloadFile(pic, "picture")
			local f = io.open("picture", "rb")
			local img
			if f then
				img = base64.enc(f:read("*a"))
				f:close()
			else
				return slient and "failed" or bot.sendMessage(msg.chat.id, "Failed to download.")
			end
			salt = math.random(1024768)
			sign = string.upper(md5.sumhexa(settings.youdao_id .. img .. salt .. settings.youdao_key))
			local ret = bot.postRequest("http://openapi.youdao.com/ocrapi", {
				img = img,
				langType = "zh-en",
				detectType = "10011",
				imageType = "1",
				appKey = settings.youdao_id,
				salt = salt,
				sign = sign,
				docType = "json"
			})
			if ret.success == 1 then
				local sta, res = pcall(cjson.decode, ret.body)
				if sta then
					local out = "[scan]"
					if res.errorCode ~= "0" then
						return bot.sendMessage(settings.masterid, "[error] " .. youdao_error[tonumber(res.errorCode)] or "unknown")
					end
					for i = 1, #res.Result.regions do
						local line = res.Result.regions[i].lines
						for j = 1, #line do
							out = out .. "\n"
							local words = line[j].words
							for k = 1, #words do
								out = out .. words[k].text
							end
						end
					end
					return slient and out:match("^%[scan%]%s*(.-)$") or bot.sendMessage(msg.chat.id, out)
				else
					return slient and "failed" or bot.sendMessage(msg.chat.id, "Failed to decode.")
				end
			else
				return slient and "failed" or bot.sendMessage(msg.chat.id, "Failed to scan.")
			end
		end,
		desc = "Scan a picture.",
		help = "Reply to picture.",
		limit = {
			reply = true
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
			notice = notice .. "\ntranslating..."
			bot.editMessageText(msg.chat.id, ret.result.message_id, nil, notice, "HTML")
			for k = 1, #origin do
				origin[k] = "\t" .. origin[k] .. "\n" --  .. commands.translate.func(origin[k], true)
			end
			current = ""
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
	newvote = {
		func = function()
			local info, opt, lim = msg.text:match("/newvote%s*(%S.-)%s*%[(.+)%]%s*%((%d+)%)")
			local sel
			local t = {}
			local a = {}
			opt = opt .. "|"
			while (opt:find("|")) do
				sel, opt = opt:match("^(.-)|(.*)$")
				table.insert(t, {{text = sel, callback_data = tostring(#t+1)}})
				table.insert(a, sel)
			end
			local res = bot.sendMessage(msg.chat.id, "[Vote] " .. info, nil, nil, nil, nil, cjson.encode({inline_keyboard = t}))
			votes[res.result.message_id] = {now = 0, limit = tonumber(lim), info = info, sel = a, votes = {}, chat = msg.chat.id}
		end,
		form = "/newvote <text>[<option1|option2|...>](<vote_limit>)",
		desc = "Start a new vote.",
		help = "e.g. `/newvote Do you like apples?[Yes|No](5)`",
		limit = {
			match = "/newvote%s*(%S.-)%s*%[(.+)%]%s*%((%d+)%)"
		}
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
				return bot.sendMessage(msg.chat.id, "[Message]\n" .. clickMsg[id][1], nil, nil, nil, nil, cjson.encode({inline_keyboard = {{
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
	mahjong = {
		func = function()
			local keyboard = {
				{
					{
						text = "Join",
						callback_data = "join"
					},
					{
						text = "Start",
						callback_data = "start"
					}
				}
			}
			local res = bot.sendMessage(msg.chat.id, "[Mahjong]\nPlayer: 0/4", nil, nil, nil, nil, cjson.encode({inline_keyboard = keyboard}))
			if not res then return end
			bot.editMessageText(msg.chat.id, res.result.message_id, nil, "[Mahjong#" .. res.result.message_id .. "]<wait>\nPlayer: 0/4", "", nil, cjson.encode({inline_keyboard = keyboard}))
			mahjong[res.result.message_id] = {
				chat = msg.chat.id,
				cards = {},
				player = {},
				yama = {},
				dora_num = 1,
				current = 1,
				desk = {
					{}, {}, {}, {}
				},
				hand = {
					{}, {}, {}, {}
				},
				lastCommand = os.time(),
				status = "wait"
			}
		end,
		desc = "Let's play mahjong."
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
	unpack = {
		func = function()
			bot.sendMessage(msg.chat.id, "```\n" .. table.encode(msg) .. "\n```", "Markdown")
		end,
		desc = "Unpack current message."
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
	dictmode = {
		func = function ()
			dictLog[msg.from.id] = true
			bot.sendMessage(msg.chat.id, "Okay, `exit` to exit.", "Markdown")
		end,
		desc = "Translate anything you send."
	},
	exit = {
		func = function ()
			dictLog[msg.from.id] = false
			bot.sendMessage(msg.chat.id, "I see.")
		end,
		desc = "Exit dictmode."
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
	release = {
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
	train = {
		func = function()
			local query, ans, OCROnly, replyTo = msg.text:match("/train%s+(%S+)%s*(%S+)%s*(#?)(%%?)")
			local t = {[1] = {}, [2] = {}, [3] = OCROnly == "#" and true or false, [4] = replyTo == "%"}
			for w in query:gmatch("([^|]+)") do
				table.insert(t[1], w)
			end
			for w in ans:gmatch("([^|]+)") do
				table.insert(t[2], w)
			end
			table.insert(conversation, t)
		bot.sendMessage(msg.chat.id, "Ja.")
		end,
		form = "/train <trigger> <answer> [onlyOCR(#)] [replyTo(%)]",
		desc = "Train me.",
		limit = {
		  master = true,
		  match = "/train%s+(%S+)%s+(%S+)%s*(#?)(%%?)"
		}
	},
	fatal_error = {
		func = function()
			error("fatal error.")
		end,
		desc = "Make an error.",
		limit = {
			master = true
		}
	},
	backup = {
		func = function()
			local ret = bot.sendMessage(msg.chat.id, "processing...", nil, nil, nil, msg.message_id)
			save()
			backup()
			bot.editMessageText(msg.chat.id, ret.result.message_id, nil, "processing...\ndone.", "HTML")
		end,
		desc = "Backup the database."
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
	info = {
		func = function()
			bot.sendMessage(msg.chat.id, "[Memory] " .. math.floor(#table.encode({msgList, votes, mahjong, naiveList}) / 1024 * 100) / 100 .. " KB")
		end,
		desc = "Check the memory usage."
	},
	resize = {
		func = function(silent)
			if msg.reply_to_message.sticker then
				bot.downloadFile(msg.reply_to_message.sticker.file_id, "sticker")
				os.execute("dwebp sticker -o sticker.png")
			elseif msg.reply_to_message.photo then
				bot.downloadFile(msg.reply_to_message.photo[#msg.reply_to_message.photo].file_id, "sticker")
				os.execute("convert -resize 512 sticker sticker.png")
			elseif msg.reply_to_message.document then
				if msg.reply_to_message.document.file_size > 10485760 then
					return bot.sendMessage(msg.chat.id, "No more than 10M.", nil, nil, nil, msg.message_id)
				end
				bot.downloadFile(msg.reply_to_message.document.file_id, "sticker")
				if msg.reply_to_message.document.mime_type:find("video") then
					os.execute("ffmpeg -i sticker -vframes 1 flame.png")
					os.execute("convert -resize 512 flame.png sticker.png")
				else
					os.execute("convert -resize 512 sticker sticker.png")
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

			bot.sendDocument(msg.chat.id, "sticker.png")
		end,
		desc = "Convert sticker/gif/picture to sticker png.",
		help = "Reply to sticker/picture.",
		limit = {
			reply = true
		}
	},
	setpack = {
		func = function()
			local title = msg.text:match("/setpack%s*(%S.-)%s*$") or ("Sticker Pack By " .. msg.from.first_name .. (msg.from.last_name and (" " .. msg.from.last_name) or ""))

			commands.resize.func(true)
			local fid = bot.uploadStickerFile(msg.from.id, "sticker.png").result.file_id
			os.remove("sticker.png")

			local ret = bot.createNewStickerSet(msg.from.id, "u" .. msg.from.id .. "_by_small_robot", title, fid, "🍀")

			local pack_url = "[" .. title .. "](https://t.me/addstickers/u" .. msg.from.id .. "_by_small_robot" .. ")"

			if ret.ok then
				local r = bot.sendMessage(msg.chat.id, "All right.\n" .. pack_url, "Markdown", nil, nil, msg.message_id)
			else
				local r = bot.sendMessage(msg.chat.id, "Failed. (`" .. ret.description .. "`)\nTry `/addsticker`.\n" .. pack_url, "Markdown", nil, nil, msg.message_id)
			end
		end,
		desc = "Create a sticker pack for you.",
		form = "/setpack [title]",
		help = "Reply to sticker/picture.",
		limit = {
			reply = true
		}
	},
	addsticker = {
		func = function()
			commands.resize.func(true)
			local fid = bot.uploadStickerFile(msg.from.id, "sticker.png").result.file_id
			os.remove("sticker.png")

			local ret = bot.addStickerToSet(msg.from.id, "u" .. msg.from.id .. "_by_small_robot", fid, "🍀")

			local pack_url = "[Sticker Pack](https://t.me/addstickers/u" .. msg.from.id .. "_by_small_robot" .. ")"

			if ret.ok then
				local r = bot.sendMessage(msg.chat.id, "All right.\n" .. pack_url, "Markdown", nil, nil, msg.message_id)
			else
				local r = bot.sendMessage(msg.chat.id, "Failed. (`" .. ret.description .. "`)\nTry `/setpack` for first use.\n" .. pack_url, "Markdown", nil, nil, msg.message_id)
			end
		end,
		desc = "Add a sticker to your sticker pack.",
		form = "/addsticker",
		help = "Reply to sticker/picture.",
		limit = {
			reply = true
		}
	},
	revive = {
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
	-- print("New Message 	 " .. msg.from.first_name)
	msg = message

	if settings.record then
		msgList[msg.chat.id][msg.message_id][1].text = msg.text
	end

	if settings.debug then
--		print(os.date() .. " " .. msg.text)
	end

	-- if dead_flag then os.exit() end

	if settings.naive then
		local str = string.lower(msg.text)
		if str:find("+%d+[Ss]") or str:find("naive") or str:find("excit") or str:find("too%s*young") or str:find("长者") or (str:find("报道") and str:find("偏差")) or str:find("人生经验") or str:find("too%s*simple") or str:find("蛤") or str:find("续一秒") or str:find("续1秒") or str:find("续1s") or str:find("香港记者") or str:find("华莱士") or (str:find("江") and str:find("泽") and str:find("民")) or str:find("续命") or str:find("呱") then
			naiveList[msg.from.id] = naiveList[msg.from.id] or {second = 0}
			naiveList[msg.from.id].username = msg.from.username
			naiveList[msg.from.id].second = naiveList[msg.from.id].second + 1
		end
	end

	msg.text = msg.text:gsub("@small_robot", "")

	if msg.text:find("/(%S+)@(%S+)[Bb][Oo][Tt]") then
		return
	end

	for k, v in pairs(commands) do
		if msg.text:find("^%s*/" .. k) then
			if v.limit then
				if v.limit.disable then
					return bot.sendMessage(msg.chat.id, "Sorry, the command is disabled.", nil, nil, nil, msg.message_id)
				elseif v.limit.master and msg.from.id ~= settings.masterid then
					return bot.sendMessage(msg.chat.id, "Sorry, permission is required.", nil, nil, nil, msg.message_id)
				elseif (v.limit.match or v.limit.reply) and not ((v.limit.match and msg.text:find(v.limit.match)) or (v.limit.reply and msg.reply_to_message)) then
					return commands.help.func(k)
				end
			end
			return v.func()
		end
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

	if msg.text:find("1%D-1%D-4%D-5%D-1%D-4") then
		return bot.sendSticker(msg.chat.id, "CAADBQADLAAD1vXIAYjCdJop7aEIAg")
	end

	if type(extra) == "function" then
		if extra() then
			return
		end
	end

	if dictLog[msg.from.id] then
		return commands.translate.func(msg.text)
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

	if settings.record then
		msgList[msg.chat.id][msg.message_id][1].text = msg.caption or "(photo)"
		msgList[msg.chat.id][msg.message_id][1].file = msg.photo[#msg.photo].file_id
		msgList[msg.chat.id][msg.message_id][1].ocr = text
	end
	if type(text) ~= "string"  then
		return
	end
	if text:find("爆裂啊") then
		return bot.sendPhoto(msg.chat.id, "AgADBAAD0Eo5G5wZZAdzduT_urgR1TQX4xkABDK8a0EkmwJy_ksBAAEC", nil, nil, msg.message_id)
	end

	for _, v in pairs(conversation) do
		for i = 1, #v[1] do
			if text:find(v[1][i]) then
				return bot.sendMessage(msg.chat.id, rand(unpack(v[2])), "Markdown")
			end
		end
	end
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
	if settings.record then
		msgList[msg.chat.id][msg.message_id][1].text = msg.sticker.emoji
	end
	local typSticker = {
		["CAADBQADOgAD1zRtDuv35HmxAAE42AI"] = true,
		["CAADBQAD1wADCyI8Dis9fpEKYnGgAg"] = true
	}
	if (msg.from.id == 109409998) and (typSticker[msg.sticker.file_id]) then
		bot.forwardMessage(-1001129208155, msg.chat.id, false, msg.message_id)
	end
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
	if settings.record then
		msgList[msg.chat.id][msg.message_id][1].text = "[" .. msg.voice.mime_type .. "] " .. msg.voice.file_id
	end

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
	--bot.sendMessage(settings.masterid, "I received a message (LeftChatParticipant). \n" .. table.encode(msg))
	if msg.left_chat_member.username == "small_robot" then
		bot.sendMessage(settings.masterid, "I have been kicked from group [" .. msg.chat.title .. "] by [" .. msg.from.first_name .. " " .. msg.from.last_name .. "](@" .. msg.from.username .. ").")
		bot.sendMessage(msg.from.id, "Operation finished.")
	end
end

extension.onNewChatParticipant = function (msg)
	--bot.sendMessage(settings.masterid, "I received a message (NewChatParticipant). \n" .. table.encode(msg))
	if msg.new_chat_member.username == "small_robot" then
		bot.sendMessage(settings.masterid, "I have been added to group [" .. msg.chat.title .. "] by [" .. msg.from.first_name .. " " .. (msg.from.last_name or "") .. "](@" .. msg.from.username .. ").")
		bot.sendMessage(msg.from.id, "Thanks for your invitation.")
		bot.sendMessage(msg.chat.id, "Hello everyone, I am Small R.")
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
	--bot.sendMessage(msg.chat.id, "I received a message (edited). \n" .. table.encode(msg))
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

extension.onInlineQueryReceive = function (msg)
	bot.sendMessage(settings.masterid, "I received a message (InlineQuery). \n" .. table.encode(msg))
	--local function answerInlineQuery(inline_query_id, results, cache_time, is_personal, next_offset, switch_pm_text, switch_pm_parameter)
end

extension.onChosenInlineQueryReceive = function (msg)
	bot.sendMessage(settings.masterid, "I received a message (ChosenInlineQuery). \n" .. table.encode(msg))
end

extension.onCallbackQueryReceive = function (msg)
	--bot.sendMessage(settings.masterid, "I received a message (CallbackQuery). \n" .. table.encode(msg))
	--bot.sendMessage(msg.message.chat.id, msg.data)
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
	elseif mahjong[msg.message.message_id] then
		updateMahjong(msg)
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
