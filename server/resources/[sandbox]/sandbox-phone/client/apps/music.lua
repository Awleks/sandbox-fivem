local _currentDuration = 0

RegisterNUICallback("Music:SendRoyalties", function(data, cb)
	-- cb("OK")
	exports["sandbox-base"]:ServerCallback("Music:Server:SendRoyalties", data, function(d)
		SendNUIMessage({
			type = "MUSIC_END",
		})
	end)
end)
