local logging = require("logging")

local tg_logger = logging.new(
    function(self, level, msg)
	if type(bot) == "table" then
	        bot.sendMessage(config.monitor, nil, ("*[%s]*\n```\n%s\n```"):format(level, msg), "Markdown")
	end
        return true
    end
)

tg_logger:setLevel(logging.WARN)

local logger = logging.new(
    function(self, level, msg)
        print(("%s | %-7s | %s"):format(
            os.date("%Y-%m-%d %H:%M:%S", os.time() + 8 * 3600),
            level,
            msg:gsub("%s+", " ")
        ))
        tg_logger:log(level, msg)
        return true
    end
)

logger:setLevel(logging.DEBUG)

return logger
