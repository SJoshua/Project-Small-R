-------------------------------------------
-- Project Small R
-- Telegram Bot API Generator
-- Au: SJoshua
-------------------------------------------
function get(url)
	assert(type(url) == "string")
	os.execute("wget -O tmp " .. url)
	local f = io.open("tmp", "rb")
	assert(f)
	local s = f:read("*a")
	f:close()
	return s
end

local entities = {
	["&#34;"] = [["]],
	["&quot;"] = [["]],
	["&#39;"] = [[']],
	["&apos;"] = [[']],
	["&#38;"] = [[&]],
	["&amp;"] = [[&]],
	["&#60;"] = [[<]],
	["&lt;"] = [[<]],
	["&#62;"] = [[>]],
	["&gt;"] = [[>]]
}

local html = get("sforest.in/api"):match("Available methods(.+)$")

for k, v in pairs(entities) do
	html = html:gsub(k, v)
end

os.remove("generate-api.lua")
local f = io.open("generate-api.lua", "a")

local template = [[
-------------------------------------------
-- function @ %s
-- %s
-------------------------------------------
-- Parameters
%s
-------------------------------------------
function bot.%s(%s)
%s	local body = {}
%s	return makeRequest("%s", body)
end

]]

for method, content in html:gsub("<h4>", "<h4><h4>"):gmatch('<h4>[^\n]-</i></a>([a-z]%S-)</h4>(.-)<h4>') do
	local list = {}
	local para = {}
	local check, make = "", ""
	local description, parameter
	if content:find("table") then
		description, parameter = content:match('%s*(.-)%s*<table class="table">.-</tr>(.-)</table>')
	else
		description = content:match("^%s*(.-)%s*$")
		parameter = ""
		para[1] = "-- none."
	end
	description = description:gsub("<.->", ""):gsub("\n\n", "\n"):gsub("\n", "\n-- ")
	for name, var, req, des in parameter:gmatch('<tr>%s*<td>(.-)</td>%s*<td>(.-)</td>%s*<td>(.-)</td>%s*<td>(.-)</td>%s*</tr>') do
		table.insert(list, name)
		table.insert(para, string.format("-- %s (%s) [%s]: %s", name, var:gsub("<.->", ""), req, des:gsub("<.->", "")))
		if req == "Yes" then
			check = check .. string.format('\tif not %s then\n\t\treturn nil, "%s is required."\n\tend\n', name, name)
		end
		make = make .. string.format("\tbody.%s = %s\n", name, name)
	end
	f:write(template:format(method, description, table.concat(para, "\n"), method, table.concat(list, ", "), check, make, method))
end

f:close()
