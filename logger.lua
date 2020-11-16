
local logging = require("logging")

local logger = logging.new(
    function(self, level, msg)
        io.write(os.date(), " | ", level, " | ", msg:gsub("%s+", " "), "\n")
        return true
    end
)

logger:setLevel(logging.INFO)

return logger