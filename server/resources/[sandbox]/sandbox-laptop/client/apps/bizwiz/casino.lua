RegisterNUICallback("CasinoGetBigWins", function(data, cb)
    exports["sandbox-base"]:ServerCallback("Casino:GetBigWins", {}, function(penis)
        if penis then
            cb(penis)
        else
            cb(false)
        end
    end)
end)
