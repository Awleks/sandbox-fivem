local _joiner = nil
local _working = false
local _state = nil
local _nodes = nil
local eventHandlers = {}

AddEventHandler("Labor:Client:Setup", function() end)

RegisterNetEvent("Prison:Client:OnDuty", function(joiner, time)
	_working = true
	_joiner = joiner
	_state = 0

	eventHandlers["receive"] = RegisterNetEvent(string.format("Prison:Client:%s:Receive", joiner), function(data)
		_nodes = data
		_state = 1

		for k, v in ipairs(_nodes.locations) do
			local id = string.format("PrisonNode%s", v.data.id)

			exports["sandbox-blips"]:Add(id, data.blip.name, v.coords, data.blip.sprite or 188, data.blip.color or 56,
				0.8)
			if v.type == "box" then
				exports.ox_target:addBoxZone({
					id = id,
					coords = v.coords,
					size = vector3(v.length, v.width, 2.0),
					rotation = v.options.heading or 0,
					debug = false,
					minZ = v.options.minZ,
					maxZ = v.options.maxZ,
					options = {
						{
							icon = "hand-middle-finger",
							label = data.action,
							event = string.format("Labor:Client:%s:Action", joiner),
							canInteract = function(data)
								return _working and _state == 1
							end,
						},
					}
				})
			elseif v.type == "circle" then
				exports.ox_target:addSphereZone({
					id = id,
					coords = v.coords,
					radius = v.radius,
					debug = false,
					options = {
						{
							icon = "hand-middle-finger",
							label = data.action,
							event = string.format("Labor:Client:%s:Action", joiner),
							canInteract = function(data)
								return _working and _state == 1
							end,
						},
					}
				})
			elseif v.type == "poly" then
				exports.ox_target:addPolyZone({
					id = id,
					points = v.points,
					debug = false,
					options = {
						{
							icon = "hand-middle-finger",
							label = data.action,
							event = string.format("Labor:Client:%s:Action", joiner),
							canInteract = function(data)
								return _working and _state == 1
							end,
						},
					}
				})
			end
		end
	end)

	eventHandlers["action"] = AddEventHandler(string.format("Labor:Client:%s:Action", joiner), function(ent, data)
		exports['sandbox-hud']:Progress({
			name = "prison_action",
			duration = data.duration,
			label = data.label,
			useWhileDead = false,
			canCancel = true,
			controlDisables = {
				disableMovement = true,
				disableCarMovement = true,
				disableMouse = false,
				disableCombat = true,
			},
			animation = data.animation,
		}, function(status)
			if not status then
				exports["sandbox-base"]:ServerCallback("Prison:Action", data.id, function(s)
					local id = string.format("PrisonNode%s", data.id)
					exports.ox_target:removeZone(id)
					exports["sandbox-blips"]:Remove(id)
				end)
			end
		end)
	end)

	eventHandlers["cleanup"] = AddEventHandler(string.format("Labor:Client:%s:Cleanup", joiner), function()
		if _nodes ~= nil then
			for k, v in ipairs(_nodes.locations) do
				local id = string.format("PrisonNode%s", v.id)
				exports.ox_target:removeZone(id)
				exports["sandbox-blips"]:Remove(id)
			end
		end

		_nodes = nil
		_state = 0
	end)
end)

AddEventHandler("Prison:Client:StartJob", function()
	exports["sandbox-base"]:ServerCallback("Prison:StartJob", _joiner, function(state)
		if not state then
			exports["sandbox-hud"]:NotifError("Unable To Start Job")
		end
	end)
end)

RegisterNetEvent("Prison:Client:OffDuty", function(time)
	for k, v in pairs(eventHandlers) do
		RemoveEventHandler(v)
	end

	if _nodes ~= nil then
		for k, v in ipairs(_nodes.locations) do
			local id = string.format("PrisonNode%s", v.id)
			exports.ox_target:removeZone(id)
			exports["sandbox-blips"]:Remove(id)
		end
	end

	_joiner = nil
	_working = false
	_nodes = nil
	_state = nil
	eventHandlers = {}
end)
