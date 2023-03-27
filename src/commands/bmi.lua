local bmi = {
    func = function(msg)
        local tall, weight = msg.text:match("/bmi%s*([%d%.]+)%s+([%d%.]+)")
        tall = tonumber(tall)
        weight = tonumber(weight)
        if not tall or not weight or tall <= 0 or weight <= 0 then
            return bot.sendMessage(msg.chat.id, nil, "Wrong data.")
        else
            local bmi = weight / (tall ^ 2)
            local rank = "Underweight"
            if bmi >= 30 then
                rank = "Overweight: Severely Obese"
            elseif bmi >= 28 then
                rank = "Overweight: Moderately Obese"
            elseif bmi >= 24 then
                rank = "Overweight: At Risk"
            elseif bmi >= 18.5 then
                rank = "Normal"
            end
            return bot.sendMessage(msg.chat.id, nil, string.format("*[BMI]*\n`tall  `: `%.2f m`\n`weight`: `%.2f kg`\n`BMI   `: `%.2f`\n`Rank  `: *%s*", tall, weight, bmi, rank), "Markdown")
        end
    end,
    desc = "Calculate your BMI.",
    form = "/bmi <tall/m> <weight/kg>",
    help = "BMI: kg/(m^2)",
    limit = {
        match = "/bmi%s*[%d%.]+%s+[%d%.]+"
    }
}

return bmi
