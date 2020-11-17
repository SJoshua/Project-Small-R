local utils = {}

function utils.curl(url)
    local f = io.popen(('curl -s -m 5 "%s"'):format(url))
    local r = f:read("*a")
    f:close()
    return r
end

function utils.wget(url)
    local fn = "/tmp/" ..tostring(math.random())
    os.execute('wget --timeout=0 --waitretry=0 --tries=1 -O ' .. fn .. ' "' .. url .. '"')
    local f = io.open(fn, "rb")
    local ret = f:read("*a")
    f:close()
    os.remove(fn)
    return ret
end

function utils.htmlDecode(str)
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


function utils.encodeVar(var)
    if type(var) == "string" then
        return '"' .. var:gsub("\\", "\\\\"):gsub('"', [[\"]]):gsub("\n", [[\n]]):gsub("\r", [[\r]]) .. '"'
    elseif type(var) == "number" then
        return var
    elseif type(var) == "table" then
        return utils.encode(var)
    else
        return tostring(var)
    end
end

function utils.encode(t, n)
    assert(type(t) == "table")
    if type(n) ~= "number" then
        n = 0
    end
    local tabs = string.rep("\t", n)
    local ret = "{\n"
    for k, v in pairs(t) do
        ret = ret .. tabs .. '\t[' .. utils.encodeVar(k) .. '] = ' .. (type(v) == "table" and utils.encode(v, n + 1) or utils.encodeVar(v)) .. ",\n"
    end
    ret = ret .. tabs .. "}"
    return ret
end

function utils.save(t, path)
    assert(type(t) == "table")
    local f = io.open(path, "w")
    f:write("return " .. utils.encode(t))
    f:close()
end

function utils.sandbox(t)
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

function utils.rand(...)
    local t = {...}
    return t[math.random(#t)]
end

function utils.url_encode(str)
    if (str) then
        str = str:gsub("([^%w %-%_%.%~])", function (c) return string.format ("%%%02X", string.byte(c)) end):gsub(" ", "+")
    end
    return str
end

function utils.shuffle(t)
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

function utils.readFile(fn)
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

return utils