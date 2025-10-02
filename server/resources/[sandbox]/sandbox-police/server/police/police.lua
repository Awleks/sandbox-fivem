local _breached = {}
local _swabCounter = 1

local _generatedNames = {}

AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		Wait(1000)
		PoliceItems()
		RegisterCommands()

		GlobalState["PrisonLockdown"] = false
		GlobalState["PrisonCellsLocked"] = false
		GlobalState["PoliceCars"] = Config.PoliceCars
		GlobalState["EMSCars"] = Config.EMSCars

		for k, v in pairs(Config.Armories) do
			exports['sandbox-base']:LoggerTrace("Police",
				string.format("Registering Poly Inventory ^2%s^7 For ^3%s^7", v.id, v.name))
			exports['sandbox-inventory']:PolyCreate(v)
		end

		exports['sandbox-inventory']:RegisterUse("spikes", "Police", function(source, slot, itemData)
			if GetVehiclePedIsIn(GetPlayerPed(source)) == 0 then
				exports["sandbox-base"]:ClientCallback(source, "Police:DeploySpikes", {}, function(data)
					if data ~= nil then
						TriggerClientEvent("Police:Client:AddDeployedSpike", -1, data.positions, data.h, source)

						local newValue = slot.CreateDate - math.ceil(itemData.durability / 4)
						if (os.time() - itemData.durability >= newValue) then
							exports['sandbox-inventory']:RemoveId(slot.Owner, slot.invType, slot)
						else
							exports['sandbox-inventory']:SetItemCreateDate(
								slot.id,
								newValue
							)
						end

						exports['sandbox-hud']:NotifSuccess(source,
							"You Deployed Spikes (Despawn In 20s)")
					end
				end)
			end
		end)

		exports["sandbox-base"]:RegisterServerCallback("Police:GSRTest", function(source, data, cb)
			local char = exports['sandbox-characters']:FetchCharacterSource(source)

			local pState = Player(source).state
			if pState.onDuty == "police" or pState.onDuty == "ems" then
				local target = Player(data)
				if target ~= nil then
					if target.state?.GSR ~= nil and (os.time() - target.state.GSR) <= (60 * 60) then
						exports["sandbox-chat"]:SendSystemSingle(source, "GSR: Positive")
					else
						exports["sandbox-chat"]:SendSystemSingle(source, "GSR: Negative")
					end
				else
					exports['sandbox-hud']:NotifError(source, "Invalid Target")
				end
			end
		end)

		exports["sandbox-base"]:RegisterServerCallback("Prison:SetLockdown", function(source, data, cb)
			local char = exports['sandbox-characters']:FetchCharacterSource(source)
			local pState = Player(source).state
			-- add PD Alert
			if char and (pState.onDuty == "prison" or pState.onDuty == "police") then
				GlobalState["PrisonLockdown"] = not GlobalState["PrisonLockdown"]
				GlobalState["PrisonCellsLocked"] = GlobalState["PrisonLockdown"]
				for i = 1, 27 do
					exports['sandbox-doors']:SetLock(string.format("prison_cell_%s", i), GlobalState
						["PrisonCellsLocked"])
				end
				exports['sandbox-hud']:NotifInfo(source,
					string.format("Cell Door State: %s", GlobalState["PrisonCellsLocked"]),
					GlobalState["PrisonCellsLocked"] and "Locked" or "Unlocked")
				cb(true, GlobalState["PrisonLockdown"])
			else
				cb(false)
			end
		end)

		exports["sandbox-base"]:RegisterServerCallback("Prison:SetCellState", function(source, data, cb)
			local char = exports['sandbox-characters']:FetchCharacterSource(source)
			local pState = Player(source).state

			if char and (pState.onDuty == "prison" or pState.onDuty == "police") then
				GlobalState["PrisonCellsLocked"] = not GlobalState["PrisonCellsLocked"]
				for i = 1, 27 do
					exports['sandbox-doors']:SetLock(string.format("prison_cell_%s", i), GlobalState
						["PrisonCellsLocked"])
				end
				exports['sandbox-hud']:NotifInfo(source,
					string.format("Cell Door State: %s", GlobalState["PrisonCellsLocked"]),
					GlobalState["PrisonCellsLocked"] and "Locked" or "Unlocked")
				cb(true, GlobalState["PrisonCellsLocked"])
			else
				cb(false)
			end
		end)

		exports["sandbox-base"]:RegisterServerCallback("Police:BACTest", function(source, data, cb)
			local char = exports['sandbox-characters']:FetchCharacterSource(source)

			local pState = Player(source).state
			if pState.onDuty == "police" or pState.onDuty == "ems" then
				local target = Player(data)
				if target ~= nil then
					-- Great Code Kapp
					if target.state.isDrunk and target.state.isDrunk > 0 then
						if target.state.isDrunk >= 70 then
							exports["sandbox-chat"]:SendSystemSingle(source, "BAC: 0.22% - Above Limit")
						elseif target.state.isDrunk >= 40 then
							exports["sandbox-chat"]:SendSystemSingle(source, "BAC: 0.13% - Above Limit")
						elseif target.state.isDrunk >= 30 then
							exports["sandbox-chat"]:SendSystemSingle(source, "BAC: 0.1% - Above Limit")
						elseif target.state.isDrunk >= 25 then
							exports["sandbox-chat"]:SendSystemSingle(source, "BAC: 0.085% - Above Limit")
						elseif target.state.isDrunk >= 15 then
							exports["sandbox-chat"]:SendSystemSingle(source, "BAC: 0.04% - Below Limit")
						else
							exports["sandbox-chat"]:SendSystemSingle(source, "BAC: 0.025% - Below Limit")
						end
					else
						exports["sandbox-chat"]:SendSystemSingle(source, "BAC: Not Drunk")
					end
				else
					exports['sandbox-hud']:NotifError(source, "Invalid Target")
				end
			end

			cb(true)
		end)

		exports["sandbox-base"]:RegisterServerCallback("Police:DNASwab", function(source, data, cb)
			local char = exports['sandbox-characters']:FetchCharacterSource(source)

			local pState = Player(source).state
			if char and pState.onDuty == "police" or pState.onDuty == "ems" then
				local tChar = exports['sandbox-characters']:FetchCharacterSource(data)
				if tChar ~= nil then
					local coords = GetEntityCoords(GetPlayerPed(data))
					_swabCounter += 1

					exports['sandbox-inventory']:AddItem(char:GetData('SID'), 'evidence-dna', 1, {
						EvidenceType = 'blood',
						EvidenceId = string.format('%s-%s', os.date('%d%m%y-%H%M%S', os.time()), 950000 + _swabCounter),
						EvidenceCoords = { x = coords.x, y = coords.y, z = coords.z },
						EvidenceDNA = tChar:GetData("SID"),
						EvidenceSwab = true,
						EvidenceDegraded = false,
					}, 1)

					return
				end

				exports['sandbox-hud']:NotifError(source, "Invalid Target")
			end
		end)

		exports["sandbox-base"]:RegisterServerCallback("Police:Breach", function(source, data, cb)
			local char = exports['sandbox-characters']:FetchCharacterSource(source)

			if (data?.type == nil or data?.property == nil) then
				cb(false)
				return
			end

			if Player(source).state.onDuty == "police" then
				_breached[data.type] = _breached[data.type] or {}

				if data.type == "property" then
					if (_breached[data.type][data.property] or 0) > os.time() then
						cb(true)
						exports['sandbox-properties']:ClientEnter(source, data.property)
					else
						exports["sandbox-base"]:ClientCallback(source, "Police:Breach", {}, function(s)
							if s then
								_breached[data.type][data.property] = os.time() + (60 * 10)
								exports['sandbox-properties']:ClientEnter(source, data.property)
								cb(true)
							else
								cb(false)
							end
						end)
					end
				elseif data.type == "robbery" then
					if (_breached[data.type][data.property] or 0) > os.time() then
						TriggerEvent("Labor:Server:HouseRobbery:Breach", source, data.property)

						cb(true)
					else
						exports["sandbox-base"]:ClientCallback(source, "Police:Breach", {}, function(s)
							if s then
								TriggerEvent("Labor:Server:HouseRobbery:Breach", source, data.property)

								cb(true)
							else
								cb(false)
							end
						end)
					end
				elseif data.type == "apartment" then
					local aptTier = exports['sandbox-characters']:FetchGetOfflineData(data.property, "Apartment")

					if aptTier ~= nil then
						local id = aptTier or 1
						if id == aptTier then
							if (_breached[data.type][data.property] or 0) > os.time() then
								exports['sandbox-apartments']:ClientEnter(aptTier, data.property)

								return cb(data.property)
							else
								exports["sandbox-base"]:ClientCallback(source, "Police:Breach", {}, function(s)
									if s then
										_breached[data.type][data.property] = os.time() + (60 * 10)
										exports['sandbox-apartments']:ClientEnter(aptTier, data.property)

										return cb(data.property)
									else
										cb(false)
									end
								end)
							end
						else
							exports['sandbox-hud']:NotifError(source,
								"Target Does Not Reside Here")
							return cb(false)
						end
					else
						exports['sandbox-hud']:NotifError(source, "Target Not Online")
						return cb(false)
					end
				end
			else
				cb(false)
			end
		end)

		exports["sandbox-base"]:RegisterServerCallback("Police:AccessRifleRack", function(source, data, cb)
			local char = exports['sandbox-characters']:FetchCharacterSource(source)
			if char ~= nil then
				local myDuty = Player(source).state.onDuty
				if myDuty == 'police' then
					local veh = GetVehiclePedIsIn(GetPlayerPed(source))
					if veh ~= 0 then
						if Config.PoliceCars[GetEntityModel(veh)] then
							local entState = Entity(veh).state
							if exports['sandbox-vehicles']:KeysHas(source, entState.VIN, 'police') then
								exports["sandbox-base"]:ClientCallback(source, "Inventory:Compartment:Open", {
									invType = 3,
									owner = ("pdrack:%s"):format(entState.VIN),
								}, function()
									exports['sandbox-inventory']:OpenSecondary(source, 3,
										("pdrack:%s"):format(entState.VIN))
								end)
							else
								exports['sandbox-hud']:NotifError(source,
									"Can't Access The Locked Compartment")
							end
						else
							exports['sandbox-hud']:NotifError(source,
								"Vehicle Not Outfitted With A Secured Compartment")
						end
					else
						exports['sandbox-hud']:NotifError(source, "Not In A Vehicle")
					end
				elseif myDuty == 'prison' then
					local veh = GetVehiclePedIsIn(GetPlayerPed(source))
					if veh ~= 0 then
						if Config.PoliceCars[GetEntityModel(veh)] then
							local entState = Entity(veh).state
							if exports['sandbox-vehicles']:KeysHas(source, entState.VIN, 'prison') then
								exports["sandbox-base"]:ClientCallback(source, "Inventory:Compartment:Open", {
									invType = 999,
									owner = ("pdrack:%s"):format(entState.VIN),
								}, function()
									exports['sandbox-inventory']:OpenSecondary(source, 999,
										("pdrack:%s"):format(entState.VIN))
								end)
							else
								exports['sandbox-hud']:NotifError(source,
									"Can't Access The Locked Compartment")
							end
						else
							exports['sandbox-hud']:NotifError(source,
								"Vehicle Not Outfitted With A Secured Compartment")
						end
					else
						exports['sandbox-hud']:NotifError(source, "Not In A Vehicle")
					end
				end
			end
		end)

		exports["sandbox-base"]:RegisterServerCallback("Police:RemoveMask", function(source, data, cb)
			local char = exports['sandbox-characters']:FetchCharacterSource(source)
			if char ~= nil and Player(source).state.onDuty == "police" then
				local tChar = exports['sandbox-characters']:FetchCharacterSource(data)
				if tChar ~= nil then
					exports['sandbox-ped']:MaskUnequip(data)
				end
			end
		end)

		exports["sandbox-base"]:RegisterServerCallback("Police:GetRadioChannel", function(source, data, cb)
			local char = exports['sandbox-characters']:FetchCharacterSource(source)
			if char ~= nil and Player(source).state.onDuty == "police" then
				local tState = Player(tonumber(data)).state
				if tState and tState?.onRadio then
					exports["sandbox-chat"]:SendSystemSingle(source, string.format("Radio Frequency: %s", tState.onRadio))
				else
					exports["sandbox-chat"]:SendSystemSingle(source, string.format("Not On Radio"))
				end
			end
		end)
	end
end)

RegisterNetEvent("Police:Server:Cuff", function()
	local src = source
	local char = exports['sandbox-characters']:FetchCharacterSource(src)
	local pState = Player(src).state
	if char ~= nil and (pState.onDuty == "police" or pState.onDuty == "prison") then
		exports['sandbox-police']:HardCuff(src)
	end
end)

RegisterNetEvent("Police:Server:Uncuff", function()
	local src = source
	local char = exports['sandbox-characters']:FetchCharacterSource(src)
	local pState = Player(src).state
	if char ~= nil and (pState.onDuty == "police" or pState.onDuty == "prison") then
		exports['sandbox-police']:Uncuff(src)
	end
end)

RegisterNetEvent("Police:Server:RunPlate", function(plate, VIN, model)
	local src = source
	local char = exports['sandbox-characters']:FetchCharacterSource(src)
	if char ~= nil then
		local myDuty = Player(src).state.onDuty
		if myDuty and myDuty == "police" then
			exports['sandbox-police']:RunPlate(src, plate, {
				VIN = VIN,
				model = model
			})
		end
	end
end)

RegisterNetEvent("Police:Server:Panic", function(isAlpha)
	local src = source
	local char = exports['sandbox-characters']:FetchCharacterSource(src)
	local pState = Player(src).state
	if pState.onDuty == "police" then
		local coords = GetEntityCoords(GetPlayerPed(src))
		exports["sandbox-base"]:ClientCallback(src, "EmergencyAlerts:GetStreetName", coords, function(location)
			if isAlpha then
				exports['sandbox-mdt']:EmergencyAlertsCreate("13-A", "Officer Down", { "police_alerts", "ems_alerts" },
					location, {
						icon = "circle-exclamation",
						details = string.format(
							"%s - %s %s | %s",
							char:GetData("Callsign"),
							char:GetData("First"),
							char:GetData("Last"),
							pState?.onRadio and string.format("Radio Freq: %s", pState.onRadio) or "Not On Radio"
						)
					}, true, {
						icon = 303,
						size = 1.2,
						color = 26,
						duration = (60 * 10),
					}, 1)
			else
				exports['sandbox-mdt']:EmergencyAlertsCreate("13-B", "Officer Down", { "police_alerts", "ems_alerts" },
					location, {
						icon = "circle-exclamation",
						details = string.format(
							"%s - %s %s",
							char:GetData("Callsign"),
							char:GetData("First"),
							char:GetData("Last"),
							pState?.onRadio and string.format("Radio Freq: %s", pState.onRadio) or "Not On Radio"
						)
					}, false, {
						icon = 303,
						size = 0.9,
						color = 26,
						duration = (60 * 10),
					}, 1)
			end
		end)
	elseif Player(src).state.onDuty == "prison" then
		local coords = GetEntityCoords(GetPlayerPed(src))
		exports["sandbox-base"]:ClientCallback(src, "EmergencyAlerts:GetStreetName", coords, function(location)
			if isAlpha then
				exports['sandbox-mdt']:EmergencyAlertsCreate("13-A", "Corrections Officer Down",
					{ "police_alerts", "doc_alerts", "ems_alerts" },
					location, {
						icon = "circle-exclamation",
						details = string.format(
							"%s - %s %s | %s",
							char:GetData("Callsign"),
							char:GetData("First"),
							char:GetData("Last"),
							pState?.onRadio and string.format("Radio Freq: %s", pState.onRadio) or "Not On Radio"
						)
					}, true, {
						icon = 303,
						size = 1.2,
						color = 26,
						duration = (60 * 10),
					}, 1)
			else
				exports['sandbox-mdt']:EmergencyAlertsCreate("13-B", "Corrections Officer Down",
					{ "police_alerts", "doc_alerts", "ems_alerts" },
					location, {
						icon = "circle-exclamation",
						details = string.format(
							"%s - %s %s | %s",
							char:GetData("Callsign"),
							char:GetData("First"),
							char:GetData("Last"),
							pState?.onRadio and string.format("Radio Freq: %s", pState.onRadio) or "Not On Radio"
						)
					}, false, {
						icon = 303,
						size = 0.9,
						color = 26,
						duration = (60 * 10),
					}, 1)
			end
		end)
	end
end)

RegisterNetEvent('Police:Server:Tackle', function(target)
	local src = source
	if #(GetEntityCoords(GetPlayerPed(src)) - GetEntityCoords(GetPlayerPed(target))) < 5.0 then
		TriggerClientEvent('Police:Client:GetTackled', target)
	end
end)

RegisterNetEvent("Prison:Server:Lockdown:AlertPolice", function(state)
	local src = source
	if state then
		exports['sandbox-robbery']:TriggerPDAlert(src, GetEntityCoords(GetPlayerPed(src)), "10-98",
			"Bolingbroke Penitentiary Lockdown", {
				icon = 526,
				size = 0.9,
				color = 1,
				duration = (60 * 5),
			})
	end
	TriggerClientEvent("Prison:Client:JailAlarm", -1, state)
end)

exports('IsInBreach', function(source, type, id, extraCheck)
	if Player(source)?.state?.onDuty == "police" and (not extraCheck or exports['sandbox-jobs']:HasPermissionInJob(source, 'police', 'PD_RAID')) then
		if _breached[type] and _breached[type][id] and ((_breached[type][id] or 0) > os.time()) then
			if extraCheck then
				local char = exports['sandbox-characters']:FetchCharacterSource(source)
				if char then
					exports['sandbox-base']:LoggerWarn(
						"Police",
						string.format(
							"Police Raid - Character %s %s (%s) - Accessing Property %s (%s)",
							char:GetData("First"),
							char:GetData("Last"),
							char:GetData("SID"),
							id,
							type
						),
						{
							console = true,
							discord = {
								embed = true,
								type = 'info',
							}
						}
					)
				end
			end

			return true
		end
	end

	return false
end)

exports('RunPlate', function(source, plate, wasEntity)
	local results = MySQL.query.await(
		"SELECT VIN, Type, Make, Model, RegisteredPlate, OwnerType, OwnerId, OwnerWorkplace, Properties FROM vehicles WHERE RegisteredPlate = ? OR JSON_EXTRACT(Properties, '$.FakePlate') = ?",
		{ plate, plate }
	)

	if not results or #results == 0 then
		local stolen = exports['sandbox-radar']:CheckPlate(plate)
		if stolen then
			if not _generatedNames[plate] then
				_generatedNames[plate] = string.format(
					"%s %s",
					exports['sandbox-base']:GeneratorNameFirst(),
					exports['sandbox-base']:GeneratorNameLast()
				)
			end

			if wasEntity then
				exports["sandbox-chat"]:SendDispatch(
					source,
					string.format(
						"<b>Owner</b>: %s<br /><b>VIN</b>: %s<br /><b>Make & Model</b>: %s<br /><b>Plate</b>: %s<br /><b>Class</b>: Unknown<br /><br />%s",
						_generatedNames[plate],
						wasEntity.VIN,
						wasEntity.model,
						plate,
						stolen
					)
				)
			else
				exports["sandbox-chat"]:SendDispatch(
					source,
					string.format(
						"<b>Owner</b>: %s<br /><b>VIN</b>: Unknown<br /><b>Make & Model</b>: Unknown<br /><b>Plate</b>: %s<br /><b>Class</b>: Unknown<br /><br />%s",
						_generatedNames[plate],
						plate,
						stolen
					)
				)
			end
		elseif wasEntity then
			if not _generatedNames[plate] then
				_generatedNames[plate] = string.format(
					"%s %s",
					exports['sandbox-base']:GeneratorNameFirst(),
					exports['sandbox-base']:GeneratorNameLast()
				)
			end

			exports["sandbox-chat"]:SendDispatch(
				source,
				string.format(
					"<b>Owner</b>: %s<br /><b>VIN</b>: %s<br /><b>Make & Model</b>: %s<br /><b>Plate</b>: %s<br /><b>Class</b>: Unknown",
					_generatedNames[plate],
					wasEntity.VIN,
					wasEntity.model,
					plate
				)
			)
		else
			exports["sandbox-chat"]:SendDispatch(source, "No Plate Match")
		end
		return
	end

	if #results > 1 then
		exports["sandbox-chat"]:SendDispatch(source, "Multiple Matches, Please Use MDT")
	else
		local vehicle = results[1]

		local properties = {}
		if vehicle.Properties then
			properties = json.decode(vehicle.Properties) or {}
		end

		if properties.FakePlate and properties.FakePlateData then
			local stolen = exports['sandbox-radar']:CheckPlate(plate)
			if stolen then
				exports["sandbox-chat"]:SendDispatch(
					source,
					string.format(
						"<b>Owner</b>: %s (%s)<br /><b>VIN</b>: %s<br /><b>Make & Model</b>: %s<br /><b>Plate</b>: %s<br /><b>Class</b>: Unknown<br /><br />%s",
						properties.FakePlateData.OwnerName,
						properties.FakePlateData.SID,
						properties.FakePlateData.VIN,
						properties.FakePlateData.Vehicle or string.format('%s %s', vehicle.Make, vehicle.Model),
						properties.FakePlate,
						stolen
					)
				)
			else
				exports["sandbox-chat"]:SendDispatch(
					source,
					string.format(
						"<b>Owner</b>: %s (%s)<br /><b>VIN</b>: %s<br /><b>Make & Model</b>: %s<br /><b>Plate</b>: %s<br /><b>Class</b>: Unknown",
						properties.FakePlateData.OwnerName,
						properties.FakePlateData.SID,
						properties.FakePlateData.VIN,
						properties.FakePlateData.Vehicle or string.format('%s %s', vehicle.Make, vehicle.Model),
						properties.FakePlate
					)
				)
			end
		else
			local ownerName = "Unknown"
			if vehicle.OwnerType == 0 then
				local owner = exports['sandbox-mdt']:PeopleView(vehicle.OwnerId)
				if owner then
					ownerName = string.format("%s %s", owner.First, owner.Last)
				end
			elseif vehicle.OwnerType == 1 then
				local jobData = exports['sandbox-jobs']:DoesExist(vehicle.OwnerId, vehicle.OwnerWorkplace)
				if jobData then
					if jobData.Workplace then
						ownerName = string.format('%s (%s)', jobData.Name, jobData.Workplace.Name)
					else
						ownerName = jobData.Name
					end
				end
			end

			local stolen = false
			if properties.Flags then
				for k, v in ipairs(properties.Flags) do
					if v.Type == "stolen" then
						stolen = v.Description
						break
					end
				end
			end

			if stolen then
				exports["sandbox-chat"]:SendDispatch(
					source,
					string.format(
						"<b>Owner</b>: %s (%s)<br /><b>VIN</b>: %s<br /><b>Make & Model</b>: %s %s<br /><b>Plate</b>: %s<br /><b>Class</b>: %s<br /><br /><b>Vehicle Reported Stolen</b>: %s",
						ownerName,
						vehicle.OwnerId,
						vehicle.VIN,
						vehicle.Make,
						vehicle.Model,
						vehicle.RegisteredPlate,
						vehicle.Type,
						stolen
					)
				)
			else
				exports["sandbox-chat"]:SendDispatch(
					source,
					string.format(
						"Owner: %s (%s)\nVIN: %s\nMake & Model: %s %s\nPlate: %s\nClass: %s",
						ownerName,
						vehicle.OwnerId,
						vehicle.VIN,
						vehicle.Make,
						vehicle.Model,
						vehicle.RegisteredPlate,
						vehicle.Type
					)
				)
			end
		end
	end
end)

exports('IsPdCar', function(model)
	return Config.PoliceCars[model]
end)

exports('IsEMSCar', function(model)
	return Config.EMSCars[model]
end)

RegisterNetEvent("Police:Server:RemoveSpikes", function()
	TriggerClientEvent("Police:Client:RemoveSpikes", -1, source)
end)

RegisterNetEvent("Police:Server:Slimjim", function()
	local src = source

	if Player(src).state.onDuty == "police" then
		exports["sandbox-base"]:ClientCallback(src, "Vehicles:Slimjim", true, function()

		end)
	end
end)
