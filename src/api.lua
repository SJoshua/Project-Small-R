local api = {}

local http = require("socket.http")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local cjson = require("cjson")
local encode = require("multipart-post").encode

https.TIMEOUT = 5

local utils = require("utils")

---@param method string
---@param parameters table
function api.makeRequest(method, parameters)
    local response = {}

    local empty = true

    for k, v in pairs(parameters) do
        if (type(v) == "integer" or type(v) == "number" or type(v) == "boolean") then
            parameters[k] = tostring(v)
        end
        empty = false
    end

    local success, code, headers, status

    if empty then
        success, code, headers, status = https.request{
            url = "https://api.telegram.org/bot" .. config.token .. "/" .. method,
            method = "GET",
            sink = ltn12.sink.table(response),
        }
    else
        local body, boundary = encode(parameters)

        success, code, headers, status = https.request{
            url = "https://api.telegram.org/bot" .. config.token .. "/" .. method,
            method = "POST",
            headers = {
                ["Content-Type"] =  "multipart/form-data; boundary=" .. boundary,
                ["Content-Length"] = string.len(body),
            },
            source = ltn12.source.string(body),
            sink = ltn12.sink.table(response),
        }
    end

    pcall(coroutine.yield)

    if success then
        local status, msg = pcall(cjson.decode, table.concat(response))
        if status then
            logger:debug("response " .. utils.encode(msg))
            return msg
        else
            logger:debug("failed to decode: " .. msg)
        end
    else
        logger:debug("failed to request: " .. code)
    end
end

function api.fetch()
    logger:info("fetching latest API ...")
    local html = utils.curl("https://core.telegram.org/bots/api")
    html = html:match("Available methods(.+)$")
    html = utils.htmlDecode(html)
    local apis = {}

    for method, content in html:gsub("<h4>", "<h4><h4>"):gmatch('<h4>[^\n]-</i></a>([a-z]%S-)</h4>(.-)<h4>') do
        logger:debug(method)
        local t = {
            parameters = {},
            order = {}
        }

        setmetatable(t, {
            __call = function(t, ...)
                local args = {...}
                local body = {}
                local named = (#args == 1 and type(args[1]) == "table")

                logger:debug("call " .. method .. " with " .. utils.encode(args))

                for i = 1, #t.order do
                    body[t.order[i]] = named and args[1][t.order[i]] or args[i]
                    if (t.parameters[t.order[i]].required and not body[t.order[i]]) then
                        logger:error("method " .. method .. " missing parameter " .. t.order[i])
                        return false
                    end
                end

                return api.makeRequest(method, body)
            end,

            __tostring = function()
                return table.concat({
                    "[method] ", method, "\n",
                    "[description] ", t.description, "\n",
                    "[parameters] ", table.concat(t.order, ", "),
                })
            end
        })

        local description, parameter

        if content:find("table") then
            description, parameter = content:match('%s*(.-)%s*<table class="table">.-</tr>(.-)</table>')
        else
            description = content:match("^%s*(.-)%s*$")
            parameter = ""
        end

        t.description = description:gsub("<.->", ""):gsub("\n\n", "\n")

        for name, var, req, des in parameter:gmatch('<tr>%s*<td>(.-)</td>%s*<td>(.-)</td>%s*<td>(.-)</td>%s*<td>(.-)</td>%s*</tr>') do
            table.insert(t.order, name)
            t.parameters[name] = {
                type = var:gsub("<.->", ""),
                required = req == "Yes",
                description = des:gsub("<.->", "")
            }
        end

        apis[method] = t
    end

    return apis
end

return api