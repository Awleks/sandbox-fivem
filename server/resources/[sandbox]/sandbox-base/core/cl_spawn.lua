-- CreateThread(function()
-- 	exports["spawnmanager"]:setAutoSpawn(false)
-- end)

local firstLoad = true

AddEventHandler("onClientResourceStart", function(resource)
	if resource == GetCurrentResourceName() then
		Wait(1000)
		if firstLoad then
			exports['sandbox-characters']:SpawnInitCamera()
			exports['sandbox-characters']:SpawnInit()
			firstLoad = false
		end
		return
	end
end)
