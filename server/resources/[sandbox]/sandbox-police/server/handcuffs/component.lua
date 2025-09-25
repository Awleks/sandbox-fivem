AddEventHandler("Characters:Server:PlayerLoggedOut", function(source, cData)
	local playerState = Player(source).state
	playerState.isCuffed = false
	playerState.isHardCuffed = false
end)

AddEventHandler("Core:Shared:Ready", function()
	HandcuffItems()
end)

function DoCuff(source, target, isHardCuffed, isForced)
	TriggerClientEvent("Handcuffs:Client:CuffingAnim", source)
	exports["sandbox-base"]:ClientCallback(target, "Handcuffs:DoCuff", {
		cuffer = source,
		isHardCuffed = isHardCuffed,
		forced = isForced,
	}, function(result)
		if result == -1 then
			exports['sandbox-base']:ExecuteClient(source, "Notification", "Error", "Unable To Cuff Player")
		else
			local playerState = Player(target).state
			local ped = GetPlayerPed(target)
			if result then
				ClearPedTasksImmediately(GetPlayerPed(target))
				ClearPedTasksImmediately(GetPlayerPed(source))

				exports['sandbox-base']:ExecuteClient(source, "Notification", "Error", "Suspect Broke Out Of The Cuffs")
				exports["sandbox-sounds"]:PlayDistance(target, 10, "handcuff_break.ogg", 0.35)
				--exports["sandbox-sounds"]:PlayOne(target, "handcuff_break.ogg", 0.35)
				playerState.isCuffed = false
				playerState.isHardCuffed = false
				SetPedConfigFlag(ped, 120, false)
				SetPedConfigFlag(ped, 121, false)
			else
				exports['sandbox-base']:ExecuteClient(source, "Notification", "Success", "You Cuffed A Player")
				exports["sandbox-sounds"]:PlayDistance(target, 10, "handcuff_on.ogg", 0.55)
				CreateThread(function()
					Wait(1050)
					exports["sandbox-sounds"]:PlayDistance(target, 10, "handcuff_on.ogg", 0.55)
				end)
				SetPedConfigFlag(ped, 120, true)
				SetPedConfigFlag(ped, 121, isHardCuffed)
				playerState.isCuffed = true
				playerState.isHardCuffed = isHardCuffed
				--FreezeEntityPosition(ped, false)
				TriggerClientEvent("Handcuffs:Client:CuffThread", target)
			end
		end
	end)
end

RegisterNetEvent("Handcuffs:Server:HardCuff", function(target)
	local src = source

	if not target then
		return
	end

	local mPos = GetEntityCoords(GetPlayerPed(src))
	local tPos = GetEntityCoords(GetPlayerPed(target))

	if #(vector3(mPos.x, mPos.y, mPos.z) - vector3(tPos.x, tPos.y, tPos.z)) <= 1.5 then
		if exports['sandbox-inventory']:ItemsHasAnyItems(src, Config.CuffItems) then
			if
				not Player(target).state.isCuffed
				or (Player(target).state.isCuffed and not Player(target).state.isHardCuffed)
			then
				exports['sandbox-police']:HardCuffTarget(src, target, false)
			else
				exports['sandbox-base']:ExecuteClient(source, "Notification", "Error", "Target Already Hard Cuffed")
			end
		end
	else
		exports['sandbox-base']:ExecuteClient(source, "Notification", "Error", "Target Too Far")
	end
end)

RegisterNetEvent("Handcuffs:Server:SoftCuff", function(target)
	local src = source

	if not target then
		return
	end

	local mPos = GetEntityCoords(GetPlayerPed(src))
	local tPos = GetEntityCoords(GetPlayerPed(target))

	if #(vector3(mPos.x, mPos.y, mPos.z) - vector3(tPos.x, tPos.y, tPos.z)) <= 1.5 then
		if exports['sandbox-inventory']:ItemsHasAnyItems(src, Config.CuffItems) then
			local pState = Player(target).state
			if not pState.isCuffed or (pState.isCuffed and pState.isHardCuffed) then
				exports['sandbox-police']:SoftCuffTarget(src, target, false)
			end
		else
			--missing items
		end
	else
		--target too far
	end
end)

RegisterNetEvent("Handcuffs:Server:Uncuff", function(target)
	local src = source

	if not target then
		return
	end

	local mPos = GetEntityCoords(GetPlayerPed(src))
	local tPos = GetEntityCoords(GetPlayerPed(target))

	if #(vector3(mPos.x, mPos.y, mPos.z) - vector3(tPos.x, tPos.y, tPos.z)) <= 1.5 then
		if exports['sandbox-inventory']:ItemsHasAnyItems(src, Config.CuffItems) then
			if Player(target).state.isCuffed then
				exports['sandbox-police']:UncuffTarget(src, target)
			end
		end
	else
		--target too far
	end
end)

exports('SelfToggle', function(source)
	if source ~= nil then
		if not Player(source).state.isCuffed then
			DoCuff(source, source, false, false)
			exports['sandbox-base']:ExecuteClient(source, "Notification", "Error", "Nobody Around To Cuff")
		else
			exports['sandbox-police']:UncuffTarget(source, source)
		end
	else
		exports['sandbox-base']:ExecuteClient(source, "Notification", "Error", "Nobody To Cuff")
	end
end)

exports('ToggleCuffs', function(source)
	exports["sandbox-base"]:ClientCallback(source, "HUD:GetTargetInfront", {}, function(target)
		if target ~= nil then
			if not Player(target).state.isCuffed then
				local myPos = GetEntityCoords(GetPlayerPed(source))
				local pos = GetEntityCoords(GetPlayerPed(target))
				if #(vector3(myPos.x, myPos.y, myPos.z) - vector3(pos.x, pos.y, pos.z)) <= 1.25 then
					DoCuff(source, target, false, false)
					return
				end
				exports['sandbox-base']:ExecuteClient(source, "Notification", "Error", "Nobody Around To Cuff")
			else
				exports['sandbox-police']:UncuffTarget(source, target)
			end
		else
			exports['sandbox-base']:ExecuteClient(source, "Notification", "Error", "Nobody To Cuff")
		end
	end)
end)

exports('SoftCuff', function(source)
	exports["sandbox-base"]:ClientCallback(source, "HUD:GetTargetInfront", {}, function(target)
		if target ~= nil then
			if not Player(target).state.isCuffed then
				local myPos = GetEntityCoords(GetPlayerPed(source))
				local pos = GetEntityCoords(GetPlayerPed(target))
				if #(vector3(myPos.x, myPos.y, myPos.z) - vector3(pos.x, pos.y, pos.z)) <= 1.25 then
					DoCuff(source, target, false, false)
					return
				end
				exports['sandbox-base']:ExecuteClient(source, "Notification", "Error", "Nobody Around To Cuff")
			else
				exports['sandbox-base']:ExecuteClient(source, "Notification", "Error", "Player Already Cuffed")
			end
		else
			exports['sandbox-base']:ExecuteClient(source, "Notification", "Error", "Nobody To Cuff")
		end
	end)
end)

exports('SoftCuffTarget', function(source, target, forced)
	local myPos = GetEntityCoords(GetPlayerPed(source))
	local pos = GetEntityCoords(GetPlayerPed(target))
	if #(vector3(myPos.x, myPos.y, myPos.z) - vector3(pos.x, pos.y, pos.z)) <= 1.25 then
		DoCuff(source, target, false, forced)
		return
	end
	exports['sandbox-base']:ExecuteClient(source, "Notification", "Error", "Nobody Around To Cuff")
end)

exports('HardCuff', function(source)
	exports["sandbox-base"]:ClientCallback(source, "HUD:GetTargetInfront", {}, function(target)
		if target ~= nil then
			if not Player(target).state.isCuffed then
				local myPos = GetEntityCoords(GetPlayerPed(source))
				local pos = GetEntityCoords(GetPlayerPed(target))
				if #(vector3(myPos.x, myPos.y, myPos.z) - vector3(pos.x, pos.y, pos.z)) <= 1.25 then
					DoCuff(source, target, true, false)
					return
				end
				exports['sandbox-base']:ExecuteClient(source, "Notification", "Error", "Nobody Around To Cuff")
			else
				exports['sandbox-base']:ExecuteClient(source, "Notification", "Error", "Player Already Cuffed")
			end
		else
			exports['sandbox-base']:ExecuteClient(source, "Notification", "Error", "Nobody To Cuff")
		end
	end)
end)

exports('HardCuffTarget', function(source, target, forced)
	local myPos = GetEntityCoords(GetPlayerPed(source))
	local pos = GetEntityCoords(GetPlayerPed(target))
	if #(vector3(myPos.x, myPos.y, myPos.z) - vector3(pos.x, pos.y, pos.z)) <= 1.25 then
		DoCuff(source, target, true, forced)
		return
	end
	exports['sandbox-base']:ExecuteClient(source, "Notification", "Error", "Nobody Around To Cuff")
end)

exports('Uncuff', function(source)
	exports["sandbox-base"]:ClientCallback(source, "HUD:GetTargetInfront", {}, function(target)
		if target ~= nil then
			if Player(target).state.isCuffed then
				exports['sandbox-police']:UncuffTarget(source, target)
			else
				exports['sandbox-base']:ExecuteClient(source, "Notification", "Error", "Player Is Not Cuffed")
			end
		else
			exports['sandbox-base']:ExecuteClient(source, "Notification", "Error", "Nobody To Cuff")
		end
	end)
end)

exports('UncuffTarget', function(source, target)
	exports["sandbox-base"]:ClientCallback(target, "Handcuffs:VehCheck", {}, function(inVeh)
		if not inVeh then
			if source ~= -1 then
				TriggerClientEvent("Handcuffs:Client:UncuffingAnim", source)
				Wait(2200)
			end
			exports["sandbox-sounds"]:PlayDistance(target, 10, "handcuff_remove.ogg", 0.15)
			local playerState = Player(target).state
			local ped = GetPlayerPed(target)
			FreezeEntityPosition(ped, false)
			playerState.isCuffed = false
			playerState.isHardCuffed = false
			SetPedConfigFlag(ped, 120, false)
			SetPedConfigFlag(ped, 121, false)
		else
			if source ~= -1 then
				exports['sandbox-base']:ExecuteClient(source, "Notification", "Error", "Unable To Uncuff Player")
			end
		end
	end)
end)
