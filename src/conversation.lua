local utils = require("utils")

local conversation = {
    ["^%s*ping%s*$"] = "pong!",
    -- ["^%s*乒%s*$"] = "乓！",
    -- ["1%s-1%s-4%s-5%s-1%s-4"] = "sticker#CAADBQADLAAD1vXIAYjCdJop7aEIAg"
}

return conversation
