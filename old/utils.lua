-------------------------------------------
-- Project Small R
-- Utils
-- Au: SJoshua
-------------------------------------------
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
    os.execute('wget --timeout=0 --waitretry=0 --tries=1 -O wget.tmp "' .. url .. '"')
    local f = io.open("wget.tmp", "r")
    local ret = f:read("*a")
    f:close()
    return ret
end

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

function table.rand(t)
    local c = 0
    for k, v in pairs(t) do
        c = c + 1
    end
    c = math.random(0, c)
    for k, v in pairs(t) do
        c = c - 1
        if c == 0 then
            return k, v
        end
    end
end

function htmlDecode(str)
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
        ["&gt;"] = [[>]],
        ["&#91;"] = "[",
        ["&#93;"] = "]",
        ["&#160;"] = [[ ]],
        ["&nbsp;"] = [[ ]],
    }
    for k, v in pairs(entities) do
        str = str:gsub(k, v)
    end
    return str
end

function readFile(fn)
    local f = io.open(fn, "rb")
    if not f then
        return "(Not found)"
    end
    local data = {
        filename = fn,
        data = f:read("*a")
    }
    f:close()
    return data
end

function reload(file, name)
    local sta, err = pcall(dofile, file)
    if not sta then
        s = s .. "error @ " .. name .. ":\n```\n" .. err .. "\n```\n"
    end
end

local map = {
    I = 1,
    V = 5,
    X = 10,
    L = 50,
    C = 100,
    D = 500,
    M = 1000,
}
local numbers = { 1, 5, 10, 50, 100, 500, 1000 }
local chars = { "I", "V", "X", "L", "C", "D", "M" }

roman = { }

function roman.encode(s)
    --s = tostring(s)
    s = tonumber(s)
    if not s or s ~= s then error"Unable to convert to number" end
    if s == math.huge then error"Unable to convert infinity" end
    s = math.floor(s)
    if s <= 0 then return s end
    local ret = ""
        for i = #numbers, 1, -1 do
        local num = numbers[i]
        while s - num >= 0 and s > 0 do
            ret = ret .. chars[i]
            s = s - num
        end
        --for j = i - 1, 1, -1 do
        for j = 1, i - 1 do
            local n2 = numbers[j]
            if s - (num - n2) >= 0 and s < num and s > 0 and num - n2 ~= n2 then
                ret = ret .. chars[j] .. chars[i]
                s = s - (num - n2)
                break
            end
        end
    end
    return ret
end

function roman.decode(s)
    s = s:upper()
    local ret = 0
    local i = 1
    while i <= s:len() do
    --for i = 1, s:len() do
        local c = s:sub(i, i)
        if c ~= " " then -- allow spaces
            local m = map[c]
        if not m then
            return "[?]"
        end

            local next = s:sub(i + 1, i + 1)
            local nextm = map[next]

            if next and nextm then
                if nextm > m then
                -- if string[i] < string[i + 1] then result += string[i + 1] - string[i]
                -- This is used instead of programming in IV = 4, IX = 9, etc, because it is
                -- more flexible and possibly more efficient
                    ret = ret + (nextm - m)
                    i = i + 1
                else
                    ret = ret + m
                end
            else
                ret = ret + m
            end
        end
        i = i + 1
    end
    return ret
end

