local bot = {}

local api = require("api")
local utils = require("utils")

function bot.run()
    logger:info("link start.")
    local t = api.fetch()
    for k, v in pairs(t) do
        bot[k] = v
    end
    print(utils.encode(bot.getMe()))
end

return bot