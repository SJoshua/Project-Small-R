local utils = require("utils")

local exec = {
    func = function(msg)
        if msg.from.username == config.master then
            local t = {pcall(load(string.match(msg.text, "/exec(.*)")))}
            local ts = string.format("[status] %s\n", tostring(t[1]))
            for i = 2, #t do
                ts = ts .. string.format("[return %d] %s\n", i-1, tostring(t[i]))
            end
            bot.sendMessage(msg.chat.id, nil, ts .. "[END]")
        elseif config.dolua then
            if msg.text:find("for") or msg.text:find("while") or msg.text:find("until") or msg.text:find("goto") or msg.text:find("function") then
                bot.sendMessage(msg.chat.id, nil, "Sorry, but no looping.")
            else
                local t = {pcall(load("local utils = require('utils'); _ENV = utils.sandbox{'math', 'string', 'pairs', 'cjson', 'table', 'message', 'base64', 'md5'}; string.dump = nil; " .. string.match(msg.text, "/exec(.*)")))}

                local ts = string.format("[status] %s\n", tostring(t[1]))
                for i = 2, #t do
                    ts = ts .. string.format("[return %d] %s\n", i-1, tostring(t[i]))
                end
                if #ts > 4096 then
                    ts = "[status] false\n"
                end
                bot.sendMessage(msg.chat.id, nil, ts .. "[END]")
            end
        end
    end,
    form = "/exec <code>",
    desc = "Execute code in lua.",
    help = "`string`, `math`, `table`, `base64` and `md5` are available.\ne.g.\n  `/exec return 1+1`\n  `/exec return string.rep(\"233\\n\", 5)`\n  `/exec return table.encode(base64)`",
    limit = {
        match = "/exec%s*(%S.+)"
    }
}

return exec
