local CACHE_TIME = 60000 -- 1 Minute(s)
local cachedData = nil
local lastRefreshed = 0

AddEventHandler("Jail:Shared:DependencyUpdate", RetrieveComponents)
function RetrieveComponents()
	Pwnzor = exports["sandbox-base"]:FetchComponent("Pwnzor")
	Reputation = exports["sandbox-base"]:FetchComponent("Reputation")
end

AddEventHandler("Core:Shared:Ready", function()
	exports["sandbox-base"]:RequestDependencies("Jail", {
		"Pwnzor",
		"Reputation",
	}, function(error)
		if #error > 0 then
			return
		end
		RetrieveComponents()
		RegisterCommands()
		RegisterCallbacks()
		RegisterMiddleware()
		RegisterPrisonSearchStartup()
		RegisterPrisonStashStartup()
		RegisterPrisonCraftingStartup()
	end)
end)

function RegisterCommands()
	exports["sandbox-chat"]:RegisterCommand(
		"jail",
		function(source, args, rawCommand)
			if tonumber(args[1]) and tonumber(args[2]) then
				local char = exports['sandbox-characters']:FetchBySID(tonumber(args[1]))
				if char ~= nil then
					exports['sandbox-jail']:Sentence(source, char:GetData("Source"), tonumber(args[2]))
					exports["sandbox-chat"]:SendSystemSingle(source,
						string.format("%s Has Been Jailed For %s Months", args[1], args[2]))
					exports["sandbox-chat"]:SendDispatchDOC(
						string.format(
							"%s %s (%s) Has Been Jailed For %s Months",
							char:GetData("First"),
							char:GetData("Last"),
							args[1],
							args[2]
						)
					)
				else
					exports["sandbox-chat"]:SendSystemSingle(source, "State ID Not Logged In")
				end
			else
				exports["sandbox-chat"]:SendSystemSingle(source, "Invalid Arguments")
			end
		end,
		{
			help = "Jail Player",
			params = {
				{
					name = "Target",
					help = "State ID of target",
				},
				{
					name = "Length",
					help = "How long, in months (minutes), to jail player",
				},
			},
		},
		2,
		{
			{
				Id = "police",
			},
			{
				Id = "prison",
			},
		}
	)
end

exports('IsJailed', function(source)
	local char = exports['sandbox-characters']:FetchCharacterSource(source)
	if char ~= nil then
		local jailed = char:GetData("Jailed")
		if jailed and not jailed.Released then
			return true
		else
			return false
		end
	else
		return false
	end
end)

exports('IsReleaseEligible', function(source)
	local char = exports['sandbox-characters']:FetchCharacterSource(source)
	if char ~= nil then
		local jailed = char:GetData("Jailed")
		if not jailed or jailed and jailed.Duration < 9999 and os.time() >= (jailed.Release or 0) then
			return true
		else
			return false
		end
	else
		return false
	end
end)

exports('Sentence', function(source, target, duration)
	local jailer = exports['sandbox-characters']:FetchCharacterSource(source)
	local jState = Player(source).state
	local jailerName = "LOS SANTOS POLICE DEPARTMENT"
	for k, v in ipairs(jailer:GetData("Jobs")) do
		if v.Id == jState.onDuty then
			if v.Workplace ~= nil then
				jailerName = v.Workplace.Name
			else
				jailerName = v.Name
			end
			break
		end
	end

	local char = exports['sandbox-characters']:FetchCharacterSource(target)
	if char ~= nil then
		if char:GetData("ICU") ~= nil and not char:GetData("ICU").Released then
			return false
		end

		exports['sandbox-labor']:JailSentenced(target)

		char:SetData("Jailed", {
			Time = os.time(),
			Release = (os.time() + (60 * duration)),
			Duration = duration,
			Released = false,
		})

		CreateThread(function()
			exports['sandbox-jobs']:DutyOff(target, Player(target).state.onDuty)
			exports['sandbox-police']:UncuffTarget(-1, target)
			exports['sandbox-ped']:MaskUnequipNoItem(target)
			exports['sandbox-inventory']:HoldingPut(target)
		end)

		TriggerClientEvent("Jail:Client:Jailed", target)
		Pwnzor.Players:TempPosIgnore(target)
		exports["sandbox-base"]:ClientCallback(target, "Jail:DoMugshot", {
			jailer = jailerName,
			duration = duration,
			date = os.date("%c"),
		}, function()
			TriggerClientEvent("Jail:Client:EnterJail", target)

			exports['sandbox-mdt']:EmergencyAlertsCreate("DOC", "New Inmate Arrival", "doc_alerts", {
				street1 = "Bolingbroke Penitentiary",
				x = 1852.444,
				y = 2585.973,
				z = 45.672,
			}, {
				details = "An inmate has just been sentenced.",
				icon = "info",
			}, false, false, nil, false)
		end)

		if duration >= 100 then
			exports['sandbox-finance']:LoansCreditDecrease(char:GetData("SID"), 10)
		end

		cachedData = nil
	else
		return false
	end
end)

exports('Reduce', function(source, reduction)
	local char = exports['sandbox-characters']:FetchCharacterSource(source)
	if char ~= nil and reduction and type(reduction) == "number" and reduction > 0 and reduction <= 100 then
		local jailData = char:GetData("Jailed")
		if
			jailData
			and not jailData.Released
			and jailData.Release > os.time()
			and math.floor(jailData.Duration - reduction) > 0
		then
			jailData.Duration = math.floor(jailData.Duration - reduction)
			jailData.Release = (jailData.Time + (60 * jailData.Duration))

			if not jailData.Reduced then
				jailData.Reduced = reduction
			else
				jailData.Reduced = jailData.Reduced + reduction
			end

			char:SetData("Jailed", jailData)

			cachedData = nil
			return true
		end
	end
	return false
end)

exports('Release', function(source)
	if exports['sandbox-jail']:IsReleaseEligible(source) then
		local char = exports['sandbox-characters']:FetchCharacterSource(source)
		if char ~= nil then
			exports['sandbox-labor']:JailReleased(source)
			char:SetData("Jailed", false)

			cachedData = nil
			return true
		else
			return false
		end
	else
		exports['sandbox-base']:ExecuteClient(source, "Notification", "Error", "Not Eligible For Release")
		return false
	end
end)

exports('GetPrisoners', function()
	FetchInmates()
	return cachedData
end)

function FetchInmates()
	if cachedData == nil or (GetGameTimer() - lastRefreshed) >= CACHE_TIME then
		local _inmates = {}

		for k, v in pairs(exports['sandbox-characters']:FetchAllCharacters()) do
			local jailed = v:GetData("Jailed")
			if jailed and not jailed.Released then
				table.insert(_inmates, {
					SID = v:GetData("SID"),
					First = v:GetData("First"),
					Last = v:GetData("Last"),
					Jailed = v:GetData("Jailed"),
				})
			end
		end

		cachedData = _inmates
		lastRefreshed = GetGameTimer()
	end
end
