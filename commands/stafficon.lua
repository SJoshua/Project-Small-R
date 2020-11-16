local utils = require("utils")

local stafficon = {
    func = function(msg)
        local src = utils.wget("https://twitter.com/kancolle_staff")
        local url = src:match('ProfileAvatar%-image.-src="(.-)"')
        bot.sendPhoto(msg.chat.id, url)
    end,
    desc = "Get Kancolle Staff's icon."
}

return stafficon
