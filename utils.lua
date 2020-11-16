local utils = {}

function utils.curl(url)
    local f = io.popen(('curl -s -m 5 "%s"'):format(url))
    local r = f:read("*a")
    f:close()
    return r
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

return utils