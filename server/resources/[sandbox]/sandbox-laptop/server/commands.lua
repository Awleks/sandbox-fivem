function RegisterChatCommands()
    exports["sandbox-chat"]:RegisterAdminCommand("boostingevent", function(source, args, rawCommand)
        if _boostingEvent then
            _boostingEvent = false
            exports["sandbox-chat"]:SendSystemSingle(source, "Boosting Event Disabled")
        else
            _boostingEvent = true
            exports["sandbox-chat"]:SendSystemSingle(source, "Boosting Event Enabled")
        end
    end, {
        help = "[Admin] Toggle Boosting Event Mode",
    }, 0)

    exports["sandbox-chat"]:RegisterAdminCommand("boostingevent2", function(source, args, rawCommand)
        local char = exports['sandbox-characters']:FetchBySID(tonumber(args[1]))
        if char then
            local profiles = char:GetData("Profiles")
            if profiles?.redline then
                exports["sandbox-chat"]:SendSystemSingle(source,
                    string.format("%s %s (%s) - Alias %s", char:GetData("First"), char:GetData("Last"),
                        char:GetData("SID"), profiles.redline.name))
            end
        end
    end, {
        help = "[Admin] Get Racing Alias",
        params = {
            {
                name = "SID",
                help = "SID",
            },
        }
    }, 1)
end
