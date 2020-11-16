local utils = require("utils")

local generate = {
    func = function (msg)
        local bangumi, mark, number = msg.text:match("/generate%s*(%S.-)([@#])([%d%.]+)")
        local notice = "searching..."
        local ret = bot.sendMessage(msg.chat.id, notice, nil, nil, nil, msg.message_id)
        local query = utils.wget("http://anicobin.ldblog.jp/search?q=" .. url_encode(bangumi))
        local reg = '<h2 class="top%-article%-title entry%-title"><a href="([^\n]-)"[^\n]-rel="bookmark">([^\n]-BGM_NUM)[^\n]-</a></h2>'
        if not query then
            return bot.editMessageText(msg.chat.id, ret.result.message_id, nil, notice .. "\nnetwork error.", "HTML")
        end
        local url, title = query:match(reg:gsub("BGM_NUM", "第" .. number .. "話"))
        if not url then
            return bot.editMessageText(msg.chat.id, ret.result.message_id, nil, notice .. "\nnot found", "HTML")
        end
        notice = notice .. "\nloading " .. title .. "..."
        bot.editMessageText(msg.chat.id, ret.result.message_id, nil, notice, "HTML")
        local page = utils.wget(url)
        if not page then
            return bot.editMessageText(msg.chat.id, ret.result.message_id, nil, notice .. "\nnetwork error.", "HTML")
        end
        
        notice = notice .. "\nmatching..."
        bot.editMessageText(msg.chat.id, ret.result.message_id, nil, notice, "HTML")
        local mat = '<span%s*style="[^"]-">[^<>]-<b>([^<>]-)</b>[^<>]-</span>'
        local origin = {}
        --page = htmlDecode(page)
        --page = page:match("tw_matome bold(.-)<!%-%-.-%++▼予備▼%++") or "Not Found"
        page = page:gsub("<b>[^<>]-<span[^<>]->[^<>]-<b>[^<>]-<span[^<>]->[^<>]-<b>[^<>]-<span[^<>]->[^<>]-<b>([^<>]-)</b>[^<>]-</span>[^<>]-</b>[^<>]-</span>[^<>]-</b>[^<>]-</span>", "<b>%1")
        page = page:gsub("<b>[^<>]-<span[^<>]->[^<>]-<b>[^<>]-<span[^<>]->[^<>]-<b>([^<>]-)</b>[^<>]-</span>[^<>]-</b>[^<>]-</span>", "<b>%1")
        --page = page:gsub("<a%s*rel=\"nofollow.-</a>", "\n"):gsub("<div%s*[^<>]-%s*class=\"tw.-</div>", "\n")
        page = page:gsub("<b><span[^<>]-><b>[^<>]-</b></span>([^<>]-)</b>", "<b>%1</b>")
        page = page:gsub("。", "\n"):gsub("！", "\n"):gsub("？", "\n"):gsub("\r\n", "\n"):gsub("\n+", "\n")
        
        local f=io.open("tes", "w") f:write(page) f:close()
        
        for current in page:gmatch(mat) do
            for sentence in current:gmatch("([^\n]+)") do
                local tmp = sentence:gsub("^.-「", ""):gsub("^.-『", ""):gsub("^.-《", ""):gsub("^.-（", ""):gsub("」", ""):gsub("》", ""):gsub("』", ""):gsub("）", "")
                if tmp ~= "" then
                    origin[#origin + 1] = tmp
                end
            end
        end
        if mark == "#" then
            current = "\t"
            for k = 1, #origin do
                if #(current .. origin[k]) < 4096 then
                    current = current .. origin[k] .. "\n"
                else
                    bot.sendMessage(msg.chat.id, current)
                    current = "\t" .. origin[k] .. "\n"
                end
            end
            bot.sendMessage(msg.chat.id, current)
        else
            local f = io.open("script.txt", "w")
            f:write(table.concat(origin, "\n"))
            f:close()
            bot.sendDocument(msg.chat.id, readFile("script.txt"))
        end
        bot.editMessageText(msg.chat.id, ret.result.message_id, nil, notice .. "\ndone.", "HTML")
    end,
    form = "/generate <bangumi>[#/@]<number>",
    desc = "Search script for bangumi.",
    help = "e.g. `/generate サクラクエスト#1`",
    limit = {
        match = "/generate%s*(%S.-)[#@](%d+)"
    }
}

return generate
