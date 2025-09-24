local catAnims = {
	sleep = {
		animDict = "creatures@cat@amb@world_cat_sleeping_ground@enter",
		anim = "enter",
		blendIn = 1.0,
		blendOut = -1,
		duration = -1,
		flag = 2,
	},
	sit = {
		animDict = "creatures@cat@amb@world_cat_sleeping_ledge@idle_a",
		anim = "idle_a",
		blendIn = 1.0,
		blendOut = -1,
		duration = -1,
		flag = 2,
	},
}

local cats = {
	{
		name = "Colin",
		coords = vector3(-582.193, -1054.765, 21.2),
		heading = 271.607,
		anim = catAnims.sit,
		texture = 1,
	},
	{
		name = "Dave",
		coords = vector3(-575.49, -1049.231, 22.5),
		heading = 178.0,
		--anim = catAnims.sit,
		texture = 2,
	},
	{
		name = "Cat Helman",
		coords = vector3(-575.418, -1068.439, 25.667),
		heading = 1.0,
		anim = catAnims.sit,
		texture = 0,
	},
	{
		name = "Velma",
		coords = vector3(-574.051, -1056.300, 21.2),
		heading = 64.0,
		anim = catAnims.sit,
		texture = 0,
	},
	{
		name = "Judy",
		coords = vector3(-576.401, -1054.913, 21.2),
		heading = 64.0,
		anim = catAnims.sit,
		texture = 1,
	},
}

AddEventHandler("Businesses:Client:Startup", function()
	for k, v in ipairs(cats) do
		exports['sandbox-pedinteraction']:Add(
			"uwu-cat-" .. k,
			`a_c_cat_01`,
			v.coords,
			v.heading,
			25.0,
			{
				{
					icon = "cat",
					text = "Pet " .. v.name,
					event = "Businesses:Client:PetCat",
					data = { cat = v },
					minDist = 2.0,
					jobs = false,
				},
			},
			"cat",
			false,
			true,
			v.anim,
			{
				texture = v.texture,
			}
		)
	end

	exports['sandbox-polyzone']:CreateBox("uwu_cafe_door", vector3(-581.05, -1068.09, 22.34), 3.0, 1.6, {
		heading = 0,
		--debugPoly=true,
		minZ = 21.34,
		maxZ = 24.54,
	}, {})
end)

AddEventHandler("Polyzone:Enter", function(id, testedPoint, insideZones, data)
	if id == "uwu_cafe_door" then
		local h = GetEntityHeading(LocalPlayer.state.ped)
		if h > 310 or h < 50 then
			exports["sandbox-sounds"]:PlayDistance(15, "bell.ogg", 0.3)
		end
	end
end)

AddEventHandler("Businesses:Client:PetCat", function(data)
	if data.entity == nil then
		exports["sandbox-hud"]:NotifError("This is not a cat!")
		return
	end
	TaskTurnPedToFaceEntity(LocalPlayer.state.ped, data.entity, 1000)
	Wait(1000)
	exports["sandbox-base"]:ServerCallback("Businesses:Server:PetCat", data, function(success, newState)
		if success then
			exports['sandbox-animations']:EmotesPlay("petting", false, 3000, true)
			Wait(3000)
			exports["sandbox-hud"]:NotifSuccess("Feeling less stressful.")
		end
	end)
end)

RegisterNetEvent("Inventory:Client:Collectables:UseItem", function(itemName)
	if itemName == "uwu_prize_b1" then -- brown
		exports['sandbox-animations']:EmotesPlay("uwubrownplush", false, false, false)
	end

	if itemName == "uwu_prize_b2" then -- orange
		exports['sandbox-animations']:EmotesPlay("uwuorangeplush", false, false, false)
	end

	if itemName == "uwu_prize_b3" then -- red
		exports['sandbox-animations']:EmotesPlay("uwuorangeplush", false, false, false)
	end

	if itemName == "uwu_prize_b4" then -- green
		exports['sandbox-animations']:EmotesPlay("uwugreenplush", false, false, false)
	end

	if itemName == "uwu_prize_b5" or itemName == "uwu_prize_b7" then -- pink
		exports['sandbox-animations']:EmotesPlay("uwupurpleplush", false, false, false)
	end

	if itemName == "uwu_prize_b6" then -- yellow
		exports['sandbox-animations']:EmotesPlay("uwuyellowplush", false, false, false)
	end

	if itemName == "uwu_prize_b8" then -- blue
		exports['sandbox-animations']:EmotesPlay("uwublueplush", false, false, false)
	end

	if itemName == "uwu_prize_b9" then -- grey
		exports['sandbox-animations']:EmotesPlay("uwuwasabiplush", false, false, false)
	end

	if itemName == "uwu_prize_b10" then -- sky blue
		exports['sandbox-animations']:EmotesPlay("uwuprincessplush", false, false, false)
	end
end)
