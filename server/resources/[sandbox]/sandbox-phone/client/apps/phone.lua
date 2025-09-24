_call = nil
local _calling = false

function StartCallTimeout()
	if _calling then
		return
	end
	_calling = true
	if LocalPlayer.state.phoneOpen then
		PhoneTextToCall()
	else
		PhonePlayCall(false)
	end
	CreateThread(function()
		local count = 0
		while _calling do
			Wait(1)
			if count < 3000 then
				count = count + 1
			else
				exports['sandbox-phone']:CallEnd()
				_calling = false
			end
		end
	end)
end

function fucksound()
	exports["sandbox-sounds"]:StopDistance(GetPlayerServerId(LocalPlayer.state.PlayerID),
		_settings.ringtone or "ringtone1.ogg")
	exports["sandbox-sounds"]:StopOne("ringing.ogg")
	exports["sandbox-sounds"]:StopOne("vibrate.ogg")
end

exports("CallCreate", function(data)
	local p = promise.new()
	exports["sandbox-sounds"]:LoopOne("ringing.ogg", 0.1 * (_settings.volume / 100))
	SendNUIMessage({ type = "SET_CALL_PENDING", data = { number = data.number } })
	data.limited = _limited

	if _payphone then
		data.isAnon = true
	end
	exports["sandbox-base"]:ServerCallback("Phone:Phone:CreateCall", data, function(status)
		if status then
			_call = {
				id = 1,
				state = 0,
				number = data.number,
				duration = -1,
				method = 1,
			}

			StartCallTimeout()
			p:resolve(true)
		else
			p:resolve(false)
		end
	end)
	return Citizen.Await(p)
end)

exports("CallReceive", function(id, number, limited)
	_call = {
		id = id,
		state = 1,
		number = number,
		duration = -1,
		method = 0,
	}
	SendNUIMessage({ type = "SET_CALL_INCOMING", data = { number = number, limited = limited } })
	if _settings and _settings.volume > 0 then
		exports["sandbox-sounds"]:LoopDistance(10, _settings.ringtone or "ringtone1.ogg",
			0.1 * (_settings.volume / 100))
	else
		exports["sandbox-sounds"]:LoopOne("vibrate.ogg", 0.1)
	end
end)

exports("CallAccept", function()
	fucksound()
	if LocalPlayer.state.phoneOpen then
		PhoneTextToCall()
	end
	exports["sandbox-base"]:ServerCallback("Phone:Phone:AcceptCall", _call)
end)

exports("CallEnd", function()
	_calling = false
	fucksound()
	exports["sandbox-base"]:ServerCallback("Phone:Phone:EndCall")
end)

exports("CallRead", function()
	exports["sandbox-base"]:ServerCallback("Phone:Phone:ReadCalls")
end)

exports("CallStatus", function()
	return _call ~= nil
end)

AddEventHandler("Characters:Client:Updated", function(key)
	if key == "States" and _call ~= nil then
		exports['sandbox-phone']:CallEnd()
	end
end)

AddEventHandler("Phone:Client:RemovePhone", function()
	if _call ~= nil then
		exports['sandbox-phone']:CallEnd()
	end
end)

AddEventHandler("Ped:Client:Died", function()
	if _call ~= nil then
		exports['sandbox-phone']:CallEnd()
	end
end)

RegisterNetEvent("Jail:Client:Jailed", function()
	if _call ~= nil then
		exports['sandbox-phone']:CallEnd()
	end
end)

RegisterNetEvent("Hospital:Client:ICU:Sent", function()
	if _call ~= nil then
		exports['sandbox-phone']:CallEnd()
	end
end)

RegisterNetEvent("Characters:Client:Logout", function()
	if _call ~= nil then
		exports['sandbox-phone']:CallEnd()
	end
end)

RegisterNetEvent("Phone:Client:Phone:EndCall", function()
	SendNUIMessage({ type = "END_CALL" })
	_call = nil

	fucksound()

	CreateThread(function()
		Wait(100)
		exports["sandbox-sounds"]:PlayOne("ended.ogg", 0.15)
	end)

	if LocalPlayer.state.phoneOpen then
		PhoneCallToText()
	else
		PhonePlayOut()
	end
end)

RegisterNetEvent("Phone:Client:Phone:RecieveCall", function(id, number, limited)
	if Jail:IsJailed() then
		TriggerEvent("Phone:Nui:Phone:EndCall")
	else
		exports['sandbox-phone']:CallReceive(id, number, limited)
	end
end)

RegisterNetEvent("Phone:Client:Phone:AcceptCall", function(number)
	_calling = false
	_call.state = 2
	_call.duration = 0
	fucksound()
	SendNUIMessage({ type = "SET_CALL_ACTIVE" })
	PhonePlayCall(false)
end)

AddEventHandler("Phone:Nui:Phone:AcceptCall", function()
	fucksound()
	exports['sandbox-phone']:CallAccept()
end)

AddEventHandler("Phone:Nui:Phone:EndCall", function()
	fucksound()
	exports['sandbox-phone']:CallEnd()
end)

RegisterNUICallback("CreateCall", function(data, cb)
	cb(exports['sandbox-phone']:CallCreate(data))
end)

RegisterNUICallback("AcceptCall", function(data, cb)
	cb("OK")
	fucksound()
	exports['sandbox-phone']:CallAccept()
end)

RegisterNUICallback("EndCall", function(data, cb)
	cb("OK")
	fucksound()
	exports['sandbox-phone']:CallEnd()
end)

RegisterNUICallback("ReadCalls", function(data, cb)
	cb("OK")
	exports['sandbox-phone']:CallRead()
end)
