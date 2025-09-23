function RegisterChatCommands()
	exports["sandbox-chat"]:RegisterAdminCommand("addprop", function(source, args, rawCommand)
		local ped = GetPlayerPed(source)
		local coords = GetEntityCoords(ped)
		local pos = {
			x = coords.x,
			y = coords.y,
			z = coords.z - 1.2,
			h = GetEntityHeading(ped),
		}

		Properties.Manage:Add(source, args[1], args[2], tonumber(args[3]), args[4], pos)
	end, {
		help = "Add New Property To Database (Enter Is Where You're At)",
		params = {
			{
				name = "Property Type",
				help = "Type of the property e.g. house, warehouse, office, container",
			},
			{
				name = "Interior ID",
				help = "ID of Which Interior This Will Spawn e.g. house_apartment1 or office1",
			},
			{
				name = "Property Price",
				help = "Cost of the property",
			},
			{
				name = "Property Label",
				help = "Name for the property",
			},
		},
	}, 4)

	exports["sandbox-chat"]:RegisterAdminCommand("delprop", function(source, args, rawCommand)
		if Properties.Manage:Delete(args[1]) then
			exports["sandbox-chat"]:SendServerSingle(source, "Property Has Been Deleted")
		end
	end, {
		help = "Delete Property",
		params = {
			{
				name = "Property ID",
				help = "Unique ID of the Property You Want To Delete",
			},
		},
	}, 1)

	exports["sandbox-chat"]:RegisterAdminCommand("addfd", function(source, args, rawCommand)
		local ped = GetPlayerPed(source)
		local coords = GetEntityCoords(ped)
		local pos = {
			x = coords.x + 0.0,
			y = coords.y + 0.0,
			z = coords.z - 1.2,
			h = GetEntityHeading(ped) + 0.0,
		}

		if Properties.Manage:AddFrontdoor(args[1], pos) then
			exports["sandbox-chat"]:SendServerSingle(source, "Frontdoor Added to Property: " .. args[1])
		else
			exports["sandbox-chat"]:SendServerSingle(source, "No Existing Property")
		end
	end, {
		help = "Set The Front Door Location Of A Property",
		params = { {
			name = "Property ID",
			help = "Unique ID of The Property",
		} },
	}, 1)

	exports["sandbox-chat"]:RegisterAdminCommand("addbd", function(source, args, rawCommand)
		local ped = GetPlayerPed(source)
		local coords = GetEntityCoords(ped)
		local pos = {
			x = coords.x + 0.0,
			y = coords.y + 0.0,
			z = coords.z - 1.2,
			h = GetEntityHeading(ped) + 0.0,
		}

		if Properties.Manage:AddBackdoor(args[1], pos) then
			exports["sandbox-chat"]:SendServerSingle(source, "Backdoor Added to Property: " .. args[1])
		else
			exports["sandbox-chat"]:SendServerSingle(source, "No Existing Property")
		end
	end, {
		help = "Set The Backdoor Location Of A Property",
		params = { {
			name = "Property ID",
			help = "Unique ID of The Property",
		} },
	}, 1)

	exports["sandbox-chat"]:RegisterAdminCommand("addgarage", function(source, args, rawCommand)
		local ped = GetPlayerPed(source)
		local coords = GetEntityCoords(ped)
		local pos = {
			x = coords.x + 0.0,
			y = coords.y + 0.0,
			z = coords.z + 0.0,
			h = GetEntityHeading(ped) + 0.0,
		}

		if Properties.Manage:AddGarage(args[1], pos) then
			exports["sandbox-chat"]:SendServerSingle(source, "Garage Added to Property: " .. args[1])
		else
			exports["sandbox-chat"]:SendServerSingle(source, "No Existing Property")
		end
	end, {
		help = "Set The Garage Location Of A Property",
		params = { {
			name = "Property ID",
			help = "Unique ID of The Property",
		} },
	}, 1)

	exports["sandbox-chat"]:RegisterAdminCommand("removegarage", function(source, args, rawCommand)
		if Properties.Manage:AddGarage(args[1], false) then
			exports["sandbox-chat"]:SendServerSingle(source, "Garage Removed From Property: " .. args[1])
		else
			exports["sandbox-chat"]:SendServerSingle(source, "No Existing Property")
		end
	end, {
		help = "Remove The Garage Location Of A Property",
		params = { {
			name = "Property ID",
			help = "Unique ID of The Property",
		} },
	}, 1)

	exports["sandbox-chat"]:RegisterAdminCommand("setint", function(source, args, rawCommand)
		if Properties.Upgrades:SetInterior(args[1], args[2]) then
			exports["sandbox-chat"]:SendServerSingle(source, "Interior Set For Property: " .. args[1])

			DeletePropertyFurniture(args[1])
			Properties:ForceEveryoneLeave(args[1])
		else
			exports["sandbox-chat"]:SendServerSingle(source, "No Existing Property")
		end
	end, {
		help = "Set The Interior Of A Property",
		params = {
			{
				name = "Property ID",
				help = "Unique ID of The Property",
			},
			{
				name = "Interior",
				help = "Interior ID",
			},
		},
	}, 2)

	exports["sandbox-chat"]:RegisterAdminCommand("setupgrade", function(source, args, rawCommand)
		local level = tonumber(args[3])
		if level and level > 0 then
			if Properties.Upgrades:Set(args[1], args[2], level) then
				exports["sandbox-chat"]:SendServerSingle(source, "Upgrade Set For Property: " .. args[1])
			else
				exports["sandbox-chat"]:SendServerSingle(source, "No Existing Property")
			end
		end
	end, {
		help = "Set The Interior Of A Property",
		params = {
			{
				name = "Property ID",
				help = "Unique ID of The Property",
			},
			{
				name = "Upgrade",
				help = "Upgrade ID (storage, garage)",
			},
			{
				name = "Level",
				help = "1-4 (or whatever it is for that upgrade)",
			},
		},
	}, 3)

	exports["sandbox-chat"]:RegisterAdminCommand("setlabel", function(source, args, rawCommand)
		if Properties.Manage:SetLabel(args[1], args[2]) then
			exports["sandbox-chat"]:SendServerSingle(source, "Label Set For Property: " .. args[1])
		else
			exports["sandbox-chat"]:SendServerSingle(source, "No Existing Property")
		end
	end, {
		help = "Set The Label Of A Property",
		params = {
			{
				name = "Property ID",
				help = "Unique ID of The Property",
			},
			{
				name = "Label",
				help = "The Label to Use",
			},
		},
	}, 2)

	exports["sandbox-chat"]:RegisterAdminCommand("setprice", function(source, args, rawCommand)
		local price = tonumber(args[2])
		if price and price > 0 then
			if Properties.Manage:SetPrice(args[1], price) then
				exports["sandbox-chat"]:SendServerSingle(source, "Price Set For Property: " .. args[1])
			else
				exports["sandbox-chat"]:SendServerSingle(source, "No Existing Property")
			end
		end
	end, {
		help = "Set The Price Of A Property",
		params = {
			{
				name = "Property ID",
				help = "Unique ID of The Property",
			},
			{
				name = "Price",
				help = "New Price",
			},
		},
	}, 2)

	exports["sandbox-chat"]:RegisterAdminCommand("setpropdata", function(source, args, rawCommand)
		if Properties.Manage:SetData(args[1], args[2], ParseCommandData(args[3])) then
			exports["sandbox-chat"]:SendServerSingle(source, "Data Set For Property: " .. args[1])
		else
			exports["sandbox-chat"]:SendServerSingle(source, "No Existing Property")
		end
	end, {
		help = "Set Data on a Property",
		params = {
			{
				name = "Property ID",
				help = "Unique ID of The Property",
			},
			{
				name = "Key",
				help = "Key",
			},
			{
				name = "Value",
				help = "Value",
			},
		},
	}, 3)

	exports["sandbox-chat"]:RegisterAdminCommand("ownproperty", function(source, args, rawCommand)
		local player = exports['sandbox-base']:FetchSource(source)
		if player.Permissions:GetLevel() >= 100 then
			local char = exports['sandbox-characters']:FetchBySID(tonumber(args[1]))
			if char then
				if _properties[args[2]] then
					if
						Properties.Commerce:Buy(args[2], {
							Char = char:GetData("ID"),
							SID = char:GetData("SID"),
							First = char:GetData("First"),
							Last = char:GetData("Last"),
							Owner = true,
						})
					then
						exports["sandbox-chat"]:SendSystemSingle(source, "Added Owned Property")
					else
						exports["sandbox-chat"]:SendSystemSingle(source, "Failed Adding Owned Property")
					end
				else
					exports["sandbox-chat"]:SendSystemSingle(source, "No Property With That ID")
				end
			end
		end
	end, {
		help = "Set Owner of a Property",
		params = {
			{
				name = "State ID",
				help = "State ID of New Owner",
			},
			{
				name = "Property ID",
				help = "Unique ID of The Property",
			},
		},
	}, 2)

	exports["sandbox-chat"]:RegisterAdminCommand("unownproperty", function(source, args, rawCommand)
		local player = exports['sandbox-base']:FetchSource(source)
		if player.Permissions:GetLevel() >= 100 then
			if _properties[args[1]] then
				if Properties.Commerce:Sell(args[1]) then
					exports["sandbox-chat"]:SendSystemSingle(source, "Removed property owner")
				else
					exports["sandbox-chat"]:SendSystemSingle(source, "Failed to remove property owner")
				end
			else
				exports["sandbox-chat"]:SendSystemSingle(source, "No Property With That ID")
			end
		end
	end, {
		help = "Remove Owner of a Property",
		params = {
			{
				name = "Property ID",
				help = "Unique ID of The Property",
			},
		},
	}, 1)

	exports["sandbox-chat"]:RegisterAdminCommand("forecloseproperty", function(source, args, rawCommand)
		local player = exports['sandbox-base']:FetchSource(source)
		if player.Permissions:GetLevel() >= 100 then
			if _properties[args[1]] then
				if args[2] == "1" then
					if Properties.Commerce:Foreclose(args[1], true) then
						exports["sandbox-chat"]:SendSystemSingle(source, "Property Foreclosed")
					else
						exports["sandbox-chat"]:SendSystemSingle(source, "Failed to foreclose property")
					end
				else
					if Properties.Commerce:Foreclose(args[1], false) then
						exports["sandbox-chat"]:SendSystemSingle(source, "Property Unforeclosed")
					else
						exports["sandbox-chat"]:SendSystemSingle(source, "Failed to Unforeclosed property")
					end
				end
			else
				exports["sandbox-chat"]:SendSystemSingle(source, "No Property With That ID")
			end
		end
	end, {
		help = "Remove Owner of a Property",
		params = {
			{
				name = "Property ID",
				help = "Unique ID of The Property",
			},
			{
				name = "Foreclose State",
				help = "1 - Foreclosed, 0 - Not Forceclosed",
			},
		},
	}, 2)

	exports["sandbox-chat"]:RegisterAdminCommand("refreshfurniture", function(source, args, rawCommand)
		local pId = args[1]
		if _properties[pId] then
			if _loadedFurniture[pId] then
				_loadedFurniture[pId] = nil

				exports["sandbox-chat"]:SendSystemSingle(source, "Furniture Refreshed")
			else
				exports["sandbox-chat"]:SendSystemSingle(source, "Furniture Wasn't Loaded Anyway")
			end
		else
			exports["sandbox-chat"]:SendSystemSingle(source, "No Property With That ID")
		end
	end, {
		help = "Force the Furniture to be Loaded from DB Again",
		params = {
			{
				name = "Property ID",
				help = "Unique ID of The Property",
			},
		},
	}, 1)

	exports["sandbox-chat"]:RegisterAdminCommand("resetfurniture", function(source, args, rawCommand)
		local pId = args[1]
		if _properties[pId] then
			if DeletePropertyFurniture(pId) then
				exports["sandbox-chat"]:SendSystemSingle(source, "Furniture Reset")
			else
				exports["sandbox-chat"]:SendSystemSingle(source, "Failed to Reset Furniture")
			end
		else
			exports["sandbox-chat"]:SendSystemSingle(source, "No Property With That ID")
		end
	end, {
		help = "Reset the Property Furniture to Default",
		params = {
			{
				name = "Property ID",
				help = "Unique ID of The Property",
			},
		},
	}, 1)
	local _showAllProps = false
	exports["sandbox-chat"]:RegisterAdminCommand("showallprops", function(source, args, rawCommand)
		TriggerClientEvent("Properties:Client:ShowAllPropertyBlips", source)
	end, {
		help = "Show all property blips",
		params = {},
	}, -1)
end

function ParseCommandData(cmd)
	if cmd:lower() == "true" then
		return true
	elseif cmd:lower() == "false" then
		return false
	elseif tonumber(cmd) then
		return tonumber(cmd)
	else
		return cmd
	end
end
