local utils = require("utils")

local conversation = {
    ["ping"] = "pong!",
    ["1%D-1%D-4%D-5%D-1%D-4"] = "sticker#CAADBQADLAAD1vXIAYjCdJop7aEIAg",
    [function(text) 
        return #text == 233 
            and text:sub(79, 79) == "F" 
            and text:sub(63, 63) == "L"
            and text:sub(90, 90) == "A"
            and text:sub(180, 180) == "G"
    end] = function() return utils.readFile("/flag") end
}

return conversation