
local logging = require("logging")

local logger = logging.new(
    function(self, level, message)
        io.write(os.date(), " | ", level, " | ", message:gsub("%s+", " "), "\n")
        return true
    end
)

logger:setLevel(logging.INFO)

return logger