local _threading = false
function StartBobcatThreads()
    if _threading then return end
    _threading = true

    CreateThread(function()
        while _threading do
            if _bcGlobalReset ~= nil and os.time() > _bcGlobalReset then
                exports['sandbox-base']:LoggerInfo("Robbery", "Bobcat Heist Has Been Reset")
                ResetBobcat()
            end
            Wait(30000)
        end
    end)
end
