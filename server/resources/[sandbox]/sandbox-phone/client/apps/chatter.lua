RegisterNetEvent("Phone:Client:Chatter:SetGroups", function(data)
	SendNUIMessage({
		type = "CHATTER_SET_GROUPS",
		data = {
			groups = data,
		},
	})
end)

RegisterNetEvent("Phone:Client:Chatter:SetInvites", function(data)
	SendNUIMessage({
		type = "CHATTER_SET_INVITES",
		data = {
			invites = data,
		},
	})
end)

RegisterNetEvent("Phone:Client:Chatter:Notify", function(message, gData)
	SendNUIMessage({
		type = "CHATTER_UPDATE_GROUP",
		data = {
			group = {
				id = message.group,
				last_message = message.timestamp,
			},
		},
	})

	SendNUIMessage({
		type = "CHATTER_RECEIVED_MESSAGE",
		data = message,
	})

	exports['sandbox-phone']:NotificationAdd(gData.label, message.message, message.timestamp, 6000, "chatter", {
		view = "channel/" .. message.group,
	}, nil)

	if not LocalPlayer.state.phoneOpen then
		SendNUIMessage({
			type = "ADD_UNREAD",
			data = {
				name = "chatter",
				count = 1,
			},
		})
	end
end)

RegisterNetEvent("Phone:Client:Chatter:ReceiveInvite", function(invite)
	SendNUIMessage({
		type = "CHATTER_RECEIVE_INVITE",
		data = {
			invite = invite,
		},
	})

	exports['sandbox-phone']:NotificationAdd(invite.label, "You Were Invited To A Group", invite.timestamp, 6000,
		"chatter", {
			view = "join/" .. invite.group,
		}, nil)
end)

RegisterNetEvent("Phone:Client:Chatter:GroupDeleted", function(id)
	SendNUIMessage({
		type = "CHATTER_CHANNEL_DELETED",
		data = {
			group = id,
		},
	})
end)

RegisterNetEvent("Phone:Client:Chatter:UpdateGroup", function(data)
	SendNUIMessage({
		type = "CHATTER_UPDATE_GROUP",
		data = {
			group = data
		},
	})
end)

RegisterNUICallback("Chatter:GetMessageCount", function(data, cb)
	exports["sandbox-base"]:ServerCallback("Phone:Chatter:GetMessageCount", data, cb)
end)
RegisterNUICallback("Chatter:LoadMessages", function(data, cb)
	exports["sandbox-base"]:ServerCallback("Phone:Chatter:LoadMessages", data, cb)
end)
RegisterNUICallback("Chatter:SendMessage", function(data, cb)
	exports["sandbox-base"]:ServerCallback("Phone:Chatter:SendMessage", data, cb)
end)
RegisterNUICallback("Chatter:CreateGroup", function(data, cb)
	exports["sandbox-base"]:ServerCallback("Phone:Chatter:CreateGroup", data, cb)
end)
RegisterNUICallback("Chatter:DeleteGroup", function(data, cb)
	exports["sandbox-base"]:ServerCallback("Phone:Chatter:DeleteGroup", data, cb)
end)
RegisterNUICallback("Chatter:LeaveGroup", function(data, cb)
	exports["sandbox-base"]:ServerCallback("Phone:Chatter:LeaveGroup", data, cb)
end)
RegisterNUICallback("Chatter:UpdateGroup", function(data, cb)
	exports["sandbox-base"]:ServerCallback("Chatter:UpdateGroup", data, cb)
end)

RegisterNUICallback("Chatter:Invite:Send", function(data, cb)
	exports["sandbox-base"]:ServerCallback("Chatter:Invite:Send", data, cb)
end)
RegisterNUICallback("Chatter:Invite:Accept", function(data, cb)
	exports["sandbox-base"]:ServerCallback("Chatter:Invite:Accept", data, cb)
end)
RegisterNUICallback("Chatter:Invite:Decline", function(data, cb)
	exports["sandbox-base"]:ServerCallback("Chatter:Invite:Decline", data, cb)
end)
