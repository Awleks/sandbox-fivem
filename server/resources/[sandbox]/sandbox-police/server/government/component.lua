_licenses = {
	drivers = { key = "Drivers", price = 1000 },
	weapons = { key = "Weapons", price = 2000 },
	hunting = { key = "Hunting", price = 800 },
	fishing = { key = "Fishing", price = 800 },
}

AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		Wait(1000)
		exports["sandbox-base"]:RegisterServerCallback("Government:BuyID", function(source, data, cb)
			local char = exports['sandbox-characters']:FetchCharacterSource(source)
			if exports['sandbox-finance']:WalletModify(source, -500) then
				exports['sandbox-inventory']:AddItem(char:GetData("SID"), "govid", 1, {}, 1)
			else
				exports['sandbox-hud']:NotifError(source, "Not Enough Cash")
			end
		end)

		exports["sandbox-base"]:RegisterServerCallback("Government:BuyLicense", function(source, data, cb)
			if _licenses[data] ~= nil then
				local char = exports['sandbox-characters']:FetchCharacterSource(source)
				local licenses = char:GetData("Licenses")
				if exports['sandbox-finance']:WalletModify(source, -_licenses[data].price) then
					if licenses[_licenses[data].key] ~= nil and not licenses[_licenses[data].key].Active then
						licenses[_licenses[data].key].Active = true
						char:SetData("Licenses", licenses)

						exports['sandbox-base']:MiddlewareTriggerEvent("Characters:ForceStore", source)
					else
						exports['sandbox-hud']:NotifError(source,
							"Unable To Purchase License")
					end
				else
					exports['sandbox-hud']:NotifError(source, "Not Enough Cash")
				end
			else
				exports['sandbox-base']:LoggerError(
					"Government",
					string.format("%s Tried To Buy Invalid License Type %s", char:GetData("SID"), data),
					{
						console = true,
						discord = true,
					}
				)
				exports['sandbox-hud']:NotifError(source, "Unable To Purchase License")
			end
		end)

		exports["sandbox-base"]:RegisterServerCallback("Government:Client:DoWeaponsLicenseBuyPolice",
			function(source, data, cb)
				local char = exports['sandbox-characters']:FetchCharacterSource(source)
				if exports['sandbox-jobs']:HasJob(source, "police") and char then
					local licenses = char:GetData("Licenses")
					if exports['sandbox-finance']:WalletModify(source, -20) then
						licenses["Weapons"].Active = true
						char:SetData("Licenses", licenses)
						exports['sandbox-base']:MiddlewareTriggerEvent("Characters:ForceStore", source)
					else
						exports['sandbox-hud']:NotifError(source, "Not Enough Cash")
					end
				else
					exports['sandbox-hud']:NotifError(source, "You are Not PD")
				end
			end)

		-- exports['sandbox-inventory']:PolyCreate({
		-- 	id = "doj-chief-justice-safe",
		-- 	type = "box",
		-- 	coords = vector3(-586.32, -213.18, 42.84),
		-- 	width = 0.6,
		-- 	length = 1.0,
		-- 	options = {
		-- 		heading = 30,
		-- 		--debugPoly=true,
		-- 		minZ = 41.84,
		-- 		maxZ = 44.24,
		-- 	},
		-- 	data = {
		-- 		inventory = {
		-- 			invType = 46,
		-- 			owner = "doj-chief-justice-safe",
		-- 		},
		-- 	},
		-- })

		exports['sandbox-inventory']:PolyCreate({
			id = "doj-storage",
			type = "box",
			coords = vector3(-586.64, -203.5, 38.23),
			length = 0.8,
			width = 1.4,
			options = {
				heading = 30,
				--debugPoly=true,
				minZ = 37.23,
				maxZ = 39.43,
			},
			data = {
				inventory = {
					invType = 116,
					owner = "doj-storage",
				},
			},
		})
	end
end)

RegisterNetEvent("Government:Server:Gavel", function()
	TriggerClientEvent("Government:Client:Gavel", -1)
end)
