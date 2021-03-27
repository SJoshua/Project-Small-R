local emergency_informed = {
    func = function(msg)
        if broadcasts then
            for k, v in pairs(broadcasts) do
                bot.deleteMessage(v)
            end
            broadcasts = {}
        end
    end,
    desc = "Delete all broadcast messages."
}

return emergency_informed