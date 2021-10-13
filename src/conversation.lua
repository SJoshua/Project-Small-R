local utils = require("utils")

local conversation = {
    ["^%s*ping%s*$"] = "pong!",
    ["^%s*乒%s*$"] = "乓！",
    ["1%D-1%D-4%D-5%D-1%D-4"] = "sticker#CAADBQADLAAD1vXIAYjCdJop7aEIAg"
}

return conversation
