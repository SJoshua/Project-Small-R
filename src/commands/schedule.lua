local utils = require("utils")

local schedule = {
    func = function(msg)
        local tid = msg.text:match("/schedule%s*([ZTKDGCSYztkdgcsy]?%d+)")
        local page = utils.curl("http://search.huochepiao.net/checi/" .. tid)
        if not page then
            return bot.sendMessage(msg.chat.id, nil, "Sorry, network error.")
        end

        if page:find("不存在") then
            return bot.sendMessage(msg.chat.id, nil, "Sorry, not found.")
        end

        local trainNo = page:match("<td.->Train No.</td>.-<td.->(.-)</td>") or tid
        local travelTime = page:match("<td.->Travel Time</td>.-<td.->(.-)</td>") or "none"
        local arrival = page:match("<td.->Arrival</td>.-<td.->(.-)</td>") or "none"
        local departure = page:match("<td.->Departure</td>.-<td.->(.-)</td>") or "none"
        local arrTime = page:match("<td.->Arr. Time</td>.-<td.->(.-)</td>") or "none"
        local depTime = page:match("<td.->Dep. Time</td>.-<td.->(.-)</td>") or "none"
        local trainType = page:match("<td.->Train Types</td>.-<td.->(.-)</td>") or "none"
        local distance = page:match("<td.->Distance</td>.-<td.->(.-)</td>") or "none"

        local field = page:match('<table border="0" bgcolor="#0033cc".->.-</tr>(.-)</table>')

        if not field then
            return bot.sendMessage(msg.chat.id, nil, "Sorry, not found.")
        end

        -- stupid monkeys
        departure, depTime, arrival, arrTime = arrival, arrTime, departure, depTime

        local resp = {
            "*[Schedule@" .. trainNo .."(" .. trainType .. ")]*",
            "",
            "From " .. departure .. " (`" .. depTime .. "`) To " .. arrival .. " (`" .. arrTime .."`)",
            "`Travel Time `: " .. travelTime,
            "`Distance	`: " .. distance,
            ""
        }

        local record, mark = 0, 0
        local cHour, cMin = tonumber(os.date("%H")) + 8, tonumber(os.date("%M"))
        local cTime = cHour * 60 + cMin

        local cnt = 0

        for part in field:gmatch("<tr(.-)</tr>") do
            for id, station, arrive, depart, dist in part:gmatch("<td.->.-</td>.-<td.->(.-)</td>.-<td.->.-<br>(.-)</td>.-<td.->(.-)</td>.-<td.->(.-)</td>.-<td.->.-</td>.-<td.->.-</td>.-<td.->(.-)</td>.-<td.->.-</td>.-<td.->.-</td>.-<td.->.-</td>.-<td.->.-</td>") do
                cnt = cnt + 1
                local hour, min = arrive:match("(%d%d):(%d%d)")
                if not hour then
                    hour, min = depart:match("(%d%d):(%d%d)")
                end
                if hour * 60 + min < record then
                    mark = -1
                else
                    record = hour * 60 + min
                end
                if mark == 0 and cTime <= record then
                    mark = cnt
                end
                table.insert(resp, string.format("\\[`#%s`] %s \\[`%s`, `%s`] <%s>", id, station:gsub("<.->", ""), arrive, depart, dist))
            end
        end

        if mark > 0 then
            resp[mark + 6] = resp[mark + 6]:gsub("\\%[`(#%d+)`%](.-)\\%[", "*[%1]%2*\\[")
        end

        bot.sendMessage(msg.chat.id, nil, table.concat(resp, "\n"), "Markdown")
    end,
    desc = "Query schedule of subway in China.",
    form = "/schedule <number>",
    help = "e.g. `/schedule D2340`",
    limit = {
        match = "/schedule%s*([ZTKDGCSYztkdgcsy]?%d+)"
    }
}

return schedule
