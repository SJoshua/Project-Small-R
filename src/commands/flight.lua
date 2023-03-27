local utils = require("utils")

local flight = {
    func = function(msg)
        local fnum = msg.text:match("/flight%s*(%a+%d+)"):upper()
        local page = utils.wget("http://m.baidu.com/s?word=" .. fnum)

        if not page then
            return bot.sendMessage(msg.chat.id, nil, "Sorry, network error.")
        end

        local html = page:match(("<em>.-%s</em>.-航班动态(.-flight.-)飞常准"):format(fnum))

        if not html then
            return bot.sendMessage(msg.chat.id, nil, "Sorry, not found.")
        end

        local t = {}

        for k in html:gmatch(">([^<>]+)<") do
            table.insert(t, k)
        end

        -- return bot.sendMessage(msg.chat.id, table.encode(t))

        -- local divMark = html:match("(flight%-deptime%-text%S+)")
        -- local status = html:match("flight%-status%-text[^>]+>(.-)<")
        -- local depTime = html:match(divMark .. " c%-span3\"[^>]+>(%d%d:%d%d)")
        -- local arrTime = html:match(divMark .. " flight[^>]+>(%d%d:%d%d)")
        -- local planDepTime, planArrTime = html:match("计划(%d%d%d%d%-%d%d%-%d%d %d%d:%d%d).-计划(%d%d%d%d%-%d%d%-%d%d %d%d:%d%d)")

        --[[
            {
                [1] = "预计起飞",
                [2] = "预计到达",
                [3] = "15:15",
                [4] = "-计划-",
                [5] = "17:53",
                [6] = "计划2020-09-12 15:15",
                [7] = "计划2020-09-12 18:20",
                [8] = "天津滨海T2",
                [9] = "广州白云T2",
                [10] = "晴天 24℃",
                [11] = "少云 28℃",
                [12] = "值机柜台",
                [13] = "G13-G18,H03-H08",
                [14] = "登机口",
                [15] = "221",
                [16] = "到达口",
                [17] = "--",
                [18] = "行李转盘",
                [19] = "--",
                [20] = "综合准点率：26.67%",
                [21] = "平均晚点：139分钟",
                [22] = "前序航班：CZ3301 计划",
            }
        ]]

        if not t[22] then
            return bot.sendMessage(msg.chat.id, nil, "Sorry, not found.")
        end

        local resp = {
            "*[Flight@" .. fnum .. "]*",
            "",
            "*" .. t[4] .. "*",
            "From *" .. t[8] .. "* (" .. t[10] .. ") To *" .. t[9] .. "* (" .. t[11] ..")",
            "`Departure Time   `: `" .. t[3] .. "` _" .. t[6] .. "_",
            "`Arrival Time     `: `" .. t[5] .. "` _" .. t[7] .. "_",
            "`Check-in Counter `: `" .. t[13] .. "`",
            "`Boarding Gate    `: `" .. t[15] .. "`",
            "`Arrival Gate     `: `" .. t[17] .. "`",
            "`Baggage Claim    `: `" .. t[19] .. "`",
            "",
            "\\[\\*] " .. t[20],
            "\\[\\*] " .. t[21],
            "\\[\\*] " .. t[22],
        }

        bot.sendMessage(msg.chat.id, nil, table.concat(resp, "\n"), "Markdown")
    end,
    desc = "Query flight information.",
    form = "/flight <flight_number>",
    help = "e.g. `/flight CZ3305`",
    limit = {
        match = "/flight%s*(%a+%d+)"
    }
}

return flight
