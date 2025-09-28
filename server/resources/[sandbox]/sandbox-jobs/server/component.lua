_characterDuty = {}
_dutyData = {}

exports("GetAll", function()
	return JOB_CACHE
end)

exports("Get", function(jobId)
	return JOB_CACHE[jobId]
end)

exports("DoesExist", function(jobId, workplaceId, gradeId)
	local job = exports['sandbox-jobs']:Get(jobId)
	if job then
		if workplaceId and job.Workplaces then
			for _, workplace in ipairs(job.Workplaces) do
				if workplace.Id == workplaceId then
					if not gradeId then
						return {
							Id = job.Id,
							Name = job.Name,
							Workplace = false,
							Hidden = job.Hidden,
						}
					end

					for _, grade in ipairs(workplace.Grades) do
						if grade.Id == gradeId then
							return {
								Id = job.Id,
								Name = job.Name,
								Workplace = {
									Id = workplace.Id,
									Name = workplace.Name,
								},
								Grade = {
									Id = grade.Id,
									Name = grade.Name,
									Level = grade.Level,
								},
								Hidden = job.Hidden,
							}
						end
					end
				end
			end
		elseif not workplaceId then
			if not gradeId then
				return {
					Id = job.Id,
					Name = job.Name,
					Workplace = false,
					Hidden = job.Hidden,
				}
			elseif gradeId and job.Grades then
				for _, grade in ipairs(job.Grades) do
					if grade.Id == gradeId then
						return {
							Id = job.Id,
							Name = job.Name,
							Workplace = false,
							Grade = {
								Id = grade.Id,
								Name = grade.Name,
								Level = grade.Level,
							},
							Hidden = job.Hidden,
						}
					end
				end
			end
		end
	end
	return false
end)

exports("GiveJob", function(stateId, jobId, workplaceId, gradeId, noOverride)
	local newJob = exports['sandbox-jobs']:DoesExist(jobId, workplaceId, gradeId)
	if not newJob or not newJob.Grade then
		return false
	end

	local char = exports['sandbox-characters']:FetchBySID(stateId)

	if char then
		local charJobData = char:GetData("Jobs")
		if not charJobData then
			charJobData = {}
		end

		for k, v in ipairs(charJobData) do
			if v.Id == newJob.Id then
				if noOverride then
					return false
				else
					table.remove(charJobData, k)
				end
			end
		end

		table.insert(charJobData, newJob)

		local source = char:GetData("Source")
		char:SetData("Jobs", charJobData)

		exports['sandbox-base']:MiddlewareTriggerEvent("Characters:ForceStore", source)

		exports['sandbox-phone']:UpdateJobData(source)

		TriggerEvent("Jobs:Server:JobUpdate", source)

		return true
	else
		local p = promise.new()
		exports.oxmysql:execute('SELECT * FROM characters WHERE SID = ?', { stateId }, function(results)
			if results and #results > 0 then
				local charData = results[1]
				local charJobData = json.decode(charData.Jobs)
				if not charJobData then
					charJobData = {}
				end

				for k, v in ipairs(charJobData) do
					if v.Id == newJob.Id then
						if noOverride then
							p:resolve(false)
							return
						else
							table.remove(charJobData, k)
						end
					end
				end

				table.insert(charJobData, newJob)

				exports.oxmysql:execute('UPDATE characters SET Jobs = ? WHERE SID = ?',
					{ json.encode(charJobData), stateId }, function(updated)
						if updated and updated.affectedRows > 0 then
							p:resolve(true)
						else
							p:resolve(false)
						end
					end)
			else
				p:resolve(false)
			end
		end)

		local res = Citizen.Await(p)
		return res
	end
end)

exports("RemoveJob", function(stateId, jobId)
	local char = exports['sandbox-characters']:FetchBySID(stateId)

	if char then
		local found = false
		local charJobData = char:GetData("Jobs")
		if not charJobData then
			charJobData = {}
		end
		local removedJobData

		for k, v in ipairs(charJobData) do
			if v.Id == jobId then
				removedJobData = v
				found = true
				table.remove(charJobData, k)
			end
		end

		if found then
			local source = char:GetData("Source")
			char:SetData("Jobs", charJobData)
			exports['sandbox-jobs']:DutyOff(source, jobId, true)

			exports['sandbox-base']:MiddlewareTriggerEvent("Characters:ForceStore", source)
			exports['sandbox-phone']:UpdateJobData(source)
			TriggerEvent("Jobs:Server:JobUpdate", source)

			if removedJobData.Workplace and removedJobData.Workplace.Name then
				exports['sandbox-hud']:NotifInfo(source,
					"No Longer Employed at " .. removedJobData.Workplace.Name
				)
			else
				exports['sandbox-hud']:NotifInfo(source,
					"No Longer Employed at " .. removedJobData.Name)
			end

			return true
		end
	else
		local p = promise.new()
		exports.oxmysql:execute('SELECT * FROM characters WHERE SID = ?', { stateId }, function(results)
			if results and #results > 0 then
				local charData = results[1]
				local charJobData = json.decode(charData.Jobs)
				if charJobData then
					local found = false
					for k, v in ipairs(charJobData) do
						if v.Id == jobId then
							found = true
							table.remove(charJobData, k)
						end
					end

					if found then
						exports.oxmysql:execute('UPDATE characters SET Jobs = ? WHERE SID = ?',
							{ json.encode(charJobData), stateId }, function(updated)
								if updated and updated.affectedRows > 0 then
									p:resolve(true)
								else
									p:resolve(false)
								end
							end)
					else
						p:resolve(false)
					end
				else
					p:resolve(false)
				end
			else
				p:resolve(false)
			end
		end)

		local res = Citizen.Await(p)
		return res
	end
end)

exports("DutyOn", function(source, jobId, hideNotify)
	local char = exports['sandbox-characters']:FetchCharacterSource(source)
	if char then
		local stateId = char:GetData("SID")
		local charJobs = char:GetData("Jobs")
		local hasJob = false

		for k, v in ipairs(charJobs) do
			if v.Id == jobId then
				hasJob = v
				break
			end
		end

		if hasJob then
			local dutyData = _characterDuty[stateId]
			if dutyData then
				if dutyData.Id == hasJob.Id then
					return true -- Already on duty as that job
				else
					local success = exports['sandbox-jobs']:DutyOff(source, false, true)
					if not success then
						return false
					end
				end
			end

			_characterDuty[stateId] = {
				Source = source,
				Id = hasJob.Id,
				StartTime = os.time(),
				Time = os.time(),
				WorkplaceId = (hasJob.Workplace and hasJob.Workplace.Id or false),
				GradeId = hasJob.Grade.Id,
				GradeLevel = hasJob.Grade.Level,
				First = char:GetData("First"),
				Last = char:GetData("Last"),
				Callsign = char:GetData("Callsign"),
			}

			local ply = Player(source)
			if ply and ply.state then
				ply.state.onDuty = _characterDuty[stateId].Id
			end

			local callsign = char:GetData("Callsign")
			TriggerEvent("Job:Server:DutyAdd", _characterDuty[stateId], source, stateId, callsign)
			TriggerClientEvent("Job:Client:DutyChanged", source, _characterDuty[stateId].Id)
			exports['sandbox-jobs']:DutyRefreshDutyData(hasJob.Id)

			local lastOnDutyData = char:GetData("LastClockOn") or {}
			lastOnDutyData[hasJob.Id] = os.time()
			char:SetData("LastClockOn", lastOnDutyData)

			if not hideNotify then
				if hasJob.Workplace then
					exports['sandbox-hud']:NotifSuccess(source,
						string.format(
							"You're Now On Duty as %s - %s",
							hasJob.Workplace.Name,
							hasJob.Grade.Name
						)
					)
				else
					exports['sandbox-hud']:NotifSuccess(source,
						string.format("You're Now On Duty as %s - %s", hasJob.Name, hasJob.Grade.Name)
					)
				end
			end

			return hasJob
		end
	end

	if not hideNotify then
		exports['sandbox-hud']:NotifError(source, "Failed to Go On Duty")
	end

	return false
end)

exports("DutyOff", function(source, jobId, hideNotify)
	local char = exports['sandbox-characters']:FetchCharacterSource(source)
	if char then
		local stateId = char:GetData("SID")
		local dutyData = _characterDuty[stateId]
		if dutyData and (not jobId or (dutyData.Id == jobId)) then
			local dutyId = dutyData.Id
			local ply = Player(source)
			if ply and ply.state then
				ply.state.onDuty = false
			end

			local existing = char:GetData("Salary") or {}
			local workedMinutes = math.floor((os.time() - dutyData.Time) / 60)
			local j = exports['sandbox-jobs']:Get(dutyData.Id)
			local salary = math.ceil((j.Salary * j.SalaryTier) * (workedMinutes / _payPeriod))

			exports['sandbox-base']:LoggerInfo(
				"Jobs",
				string.format(
					"Adding Salary Data For ^3%s^7 Going Off-Duty (^2%s Minutes^7 - ^3$%s^7)",
					char:GetData("SID"),
					workedMinutes,
					salary
				)
			)

			if existing[dutyData.Id] then
				existing[dutyData.Id] = {
					date = os.time(),
					job = dutyData.Id,
					minutes = (existing[dutyData.Id].minutes or 0) + workedMinutes,
					total = (existing[dutyData.Id].total or 0) + salary,
				}
			else
				existing[dutyData.Id] = {
					date = os.time(),
					job = dutyData.Id,
					minutes = workedMinutes,
					total = salary,
				}
			end

			char:SetData("Salary", existing)

			TriggerEvent("Job:Server:DutyRemove", dutyData, source, stateId)
			TriggerClientEvent("Job:Client:DutyChanged", source, false, dutyData.Id)
			_characterDuty[stateId] = nil
			exports['sandbox-jobs']:DutyRefreshDutyData(dutyId)

			local totalWorkedMinutes = math.floor((os.time() - dutyData.StartTime) / 60)
			local allTimeWorked = char:GetData("TimeClockedOn") or {}
			local jobTimeWorked = allTimeWorked[dutyData.Id] or {}

			if totalWorkedMinutes and totalWorkedMinutes >= 5 then
				table.insert(jobTimeWorked, {
					time = os.time(),
					minutes = totalWorkedMinutes,
				})

				local deleteBefore = os.time() - (60 * 60 * 24 * 14) -- Only Keep Last 14 Days
				for k, v in ipairs(jobTimeWorked) do
					if tonumber(v.time) < deleteBefore then
						table.remove(jobTimeWorked, k)
					end
				end

				allTimeWorked[dutyData.Id] = jobTimeWorked
			end
			char:SetData("TimeClockedOn", allTimeWorked)

			if not hideNotify then
				exports['sandbox-hud']:NotifInfo(source, "You're Now Off Duty")
			end

			return true
		end
	end

	if not hideNotify then
		exports['sandbox-hud']:NotifError(source, "Failed to Go Off Duty")
	end

	return false
end)

exports("DutyGet", function(source, jobId)
	local char = exports['sandbox-characters']:FetchCharacterSource(source)
	if char then
		local dutyData = _characterDuty[char:GetData("SID")]
		if dutyData and (not jobId or (jobId == dutyData.Id)) then
			return dutyData
		end
	end
	return false
end)

exports("DutyGetDutyData", function(jobId)
	return _dutyData[jobId]
end)

exports("DutyRefreshDutyData", function(jobId)
	if not _dutyData[jobId] then
		_dutyData[jobId] = {}
	end

	local onDutyPlayers = {}
	local totalCount = 0
	local workplaceCounts = false

	for k, v in pairs(_characterDuty) do
		if v ~= nil and v.Id == jobId then
			totalCount = totalCount + 1
			table.insert(onDutyPlayers, v.Source)
			if v.WorkplaceId then
				if not workplaceCounts then
					workplaceCounts = {}
				end

				if not workplaceCounts[v.WorkplaceId] then
					workplaceCounts[v.WorkplaceId] = 1
				else
					workplaceCounts[v.WorkplaceId] = workplaceCounts[v.WorkplaceId] + 1
				end
			end
		end
	end

	_dutyData[jobId] = {
		Active = totalCount > 0,
		Count = totalCount,
		WorkplaceCounts = workplaceCounts,
		DutyPlayers = onDutyPlayers,
	}

	if _globalStateDutyCounts and _globalStateDutyCounts[jobId] then
		GlobalState[string.format("Duty:%s", jobId)] = totalCount
	end
end)

exports("IsOwner", function(source, jobId)
	local char = exports['sandbox-characters']:FetchCharacterSource(source)
	if char then
		local jobData = exports['sandbox-jobs']:Get(jobId)
		if jobData.Owner and jobData.Owner == char:GetData("SID") then
			return true
		end
	end
	return false
end)

exports("IsOwnerOfCompany", function(source)
	local char = exports['sandbox-characters']:FetchCharacterSource(source)
	if char then
		local stateId = char:GetData("SID")
		local jobs = char:GetData("Jobs") or {}
		for k, v in ipairs(jobs) do
			local jobData = exports['sandbox-jobs']:Get(v.Id)
			if jobData.Owner and jobData.Owner == stateId then
				return true
			end
		end
	end
	return false
end)

exports("GetJobs", function(source)
	local char = exports['sandbox-characters']:FetchCharacterSource(source)
	if char then
		local jobs = char:GetData("Jobs") or {}
		return jobs
	end
	return false
end)

exports("HasJob", function(source, jobId, workplaceId, gradeId, gradeLevel, checkDuty, permissionKey)
	local jobs = exports['sandbox-jobs']:GetJobs(source)
	if not jobs then
		return false
	end
	if jobId then
		for k, v in ipairs(jobs) do
			if v.Id == jobId then
				if not workplaceId or (v.Workplace and v.Workplace.Id == workplaceId) then
					if not gradeId or (v.Grade.Id == gradeId) then
						if not gradeLevel or (v.Grade.Level and v.Grade.Level >= gradeLevel) then
							if not checkDuty or (checkDuty and exports['sandbox-jobs']:DutyGet(source, jobId)) then
								if
									not permissionKey
									or (
										permissionKey
										and exports['sandbox-jobs']:HasPermissionInJob(source, jobId, permissionKey)
									)
								then
									return v
								end
							end
						end
					end
				end
				break
			end
		end
	elseif permissionKey then
		return exports['sandbox-jobs']:HasPermission(source, permissionKey)
	end
	return false
end)

exports("GetPermissionsFromJob", function(source, jobId, workplaceId)
	local jobData = exports['sandbox-jobs']:HasJob(source, jobId, workplaceId)
	if jobData then
		local perms = GlobalState[string.format(
			"JobPerms:%s:%s:%s",
			jobData.Id,
			(jobData.Workplace and jobData.Workplace.Id or false),
			jobData.Grade.Id
		)]
		if perms then
			return perms
		end
	end
	return false
end)

exports("HasPermissionInJob", function(source, jobId, permissionKey)
	local permissionsInJob = exports['sandbox-jobs']:GetPermissionsFromJob(source, jobId)
	if permissionsInJob then
		if permissionsInJob[permissionKey] then
			return true
		end
	end
	return false
end)

exports("GetAllPermissions", function(source)
	local allPermissions = {}
	local jobs = exports['sandbox-jobs']:GetJobs(source)
	if jobs and #jobs > 0 then
		for k, v in ipairs(jobs) do
			local perms = GlobalState[string.format(
				"JobPerms:%s:%s:%s",
				v.Id,
				(v.Workplace and v.Workplace.Id or false),
				v.Grade.Id
			)]
			if perms ~= nil then
				for k, v in pairs(perms) do
					if not allPermissions[k] then
						allPermissions[k] = v
					end
				end
			end
		end
	end
	return allPermissions
end)

-- Checks if character has a permission in any of their jobs
exports("HasPermission", function(source, permissionKey)
	local allPermissions = exports['sandbox-jobs']:GetAllPermissions(source)
	return allPermissions[permissionKey]
end)

-- For player business creations
exports("ManagementCreate", function(name, ownerSID)
	if not name then
		name = exports['sandbox-base']:GeneratorCompany()
	end
	local jobId = string.format("Company_%s", exports['sandbox-base']:SequenceGet("Company"))
	if jobId and name then
		local existing = exports['sandbox-jobs']:Get(jobId)
		if not existing then
			local p = promise.new()
			local document = {
				Type = "Company",
				Custom = true,
				Id = jobId,
				Name = name,
				Owner = ownerSID,
				Salary = 100,
				SalaryTier = 1,
				Grades = {
					{
						Id = "owner",
						Name = "Owner",
						Level = 100,
						Permissions = {
							JOB_MANAGEMENT = true,
							JOB_FIRE = true,
							JOB_HIRE = true,
							JOB_MANAGE_EMPLOYEES = true,
						},
					},
				},
			}

			exports['sandbox-base']:DatabaseGameInsertOne({
				collection = "jobs",
				document = document,
			}, function(success, inserted)
				if success and inserted > 0 then
					RefreshAllJobData(document.Id)

					exports['sandbox-jobs']:GiveJob(ownerSID, document.Id, false, "owner")

					p:resolve(document)
				else
					p:resolve(false)
				end
			end)

			local res = Citizen.Await(p)
			return res
		end
	end
	return false
end)

exports("ManagementTransfer", function(jobId, newOwner)
	-- TODO
	--exports['sandbox-base']:MiddlewareTriggerEvent("Business:Transfer", jobId, source:GetData("SID"), target:GetData("SID"))
end)

exports("ManagementUpgradesHas", function(jobId, upgradeKey)
	-- TODO
end)

exports("ManagementUpgradesUnlock", function(jobId, upgradeKey)
	-- TODO
end)

exports("ManagementUpgradesLock", function(jobId, upgradeKey)
	-- TODO
end)

exports("ManagementUpgradesReset", function(jobId)
	-- TODO
end)

exports("ManagementDelete", function(jobId)
	-- TODO
end)

exports("ManagementEdit", function(jobId, settingData)
	if exports['sandbox-jobs']:DoesExist(jobId) then
		local actualSettingData = {}

		for k, v in pairs(settingData) do
			if k ~= "Grades" and k ~= "Workplaces" and k ~= "Id" and v ~= nil then
				actualSettingData[k] = v
			end
		end

		local p = promise.new()
		exports['sandbox-base']:DatabaseGameUpdateOne({
			collection = "jobs",
			query = {
				Id = jobId,
			},
			update = {
				["$set"] = actualSettingData,
			},
		}, function(success, res)
			if success then
				RefreshAllJobData(jobId)

				if actualSettingData.Name then
					exports['sandbox-jobs']:ManagementEmployeesUpdateAllJob(jobId, actualSettingData.Name)
				end

				p:resolve(true)
			else
				p:resolve(false)
			end
		end)

		local res = Citizen.Await(p)
		return {
			success = res,
			code = "ERROR",
		}
	else
		return {
			success = false,
			code = "MISSING_JOB",
		}
	end
end)

exports("ManagementWorkplaceEdit", function(jobId, workplaceId, newWorkplaceName)
	if exports['sandbox-jobs']:DoesExist(jobId, workplaceId) then
		local p = promise.new()
		exports['sandbox-base']:DatabaseGameUpdateOne({
			collection = "jobs",
			query = {
				Type = "Government",
				Id = jobId,
				["Workplaces.Id"] = workplaceId,
			},
			update = {
				["$set"] = {
					["Workplaces.$[workplace].Name"] = newWorkplaceName,
				},
			},
			options = {
				arrayFilters = {
					{ ["workplace.Id"] = workplaceId },
				},
			},
		}, function(success, res)
			if success then
				RefreshAllJobData(jobId)
				exports['sandbox-jobs']:ManagementEmployeesUpdateAllWorkplace(jobId, workplaceId, newWorkplaceName)

				p:resolve(true)
			else
				p:resolve(false)
			end
		end)

		local res = Citizen.Await(p)
		return {
			success = res,
			code = "ERROR",
		}
	else
		return {
			success = false,
			code = "ERROR",
		}
	end
end)

exports("ManagementGradesCreate", function(jobId, workplaceId, gradeName, gradeLevel, gradePermissions)
	if exports['sandbox-jobs']:DoesExist(jobId, workplaceId) then
		local p = promise.new()
		local gradeId
		if workplaceId then
			gradeId = string.format(
				"Grade_%s",
				exports['sandbox-base']:SequenceGet(string.format("Company:%s:%s:Grades", jobId, workplaceId))
			)
		else
			gradeId = string.format("Grade_%s",
				exports['sandbox-base']:SequenceGet(string.format("Company:%s:Grades", jobId)))
		end

		if not exports['sandbox-jobs']:DoesExist(jobId, workplaceId, gradeId) then
			local query = {}
			local update = {}
			local options = {}

			local gradeData = {
				Id = gradeId,
				Name = gradeName,
				Level = gradeLevel,
				Permissions = gradePermissions or {},
			}

			if workplaceId then
				query = {
					Type = "Government",
					Id = jobId,
					["Workplaces.Id"] = workplaceId,
				}

				update = {
					["$push"] = {
						["Workplaces.$[workplace].Grades"] = gradeData,
					},
				}

				options = {
					arrayFilters = {
						{
							["workplace.Id"] = workplaceId,
						},
					},
					multi = true,
				}
			else
				query = {
					Type = "Company",
					Id = jobId,
				}

				update = {
					["$push"] = {
						Grades = gradeData,
					},
				}

				options = {
					multi = true,
				}
			end

			exports['sandbox-base']:DatabaseGameUpdateOne({
				collection = "jobs",
				query = query,
				update = update,
				options = options,
			}, function(success, updated)
				if success then
					RefreshAllJobData(jobId)

					p:resolve(true)
				else
					p:resolve(false)
				end
			end)

			local res = Citizen.Await(p)
			return {
				success = res,
				code = "ERROR",
			}
		else
			return {
				success = false,
				code = "ERROR",
			}
		end
	else
		return {
			success = false,
			code = "MISSING_JOB",
		}
	end
end)

exports("ManagementGradesEdit", function(jobId, workplaceId, gradeId, settingData)
	if exports['sandbox-jobs']:DoesExist(jobId, workplaceId, gradeId) then
		local p = promise.new()
		local query = {}
		local update = {}
		local options = {}

		if workplaceId then
			query = {
				Type = "Government",
				Id = jobId,
				["Workplaces.Id"] = workplaceId,
				["Workplaces.Grades.Id"] = gradeId,
			}

			update = {
				["$set"] = {},
			}

			for k, v in pairs(settingData) do
				if k ~= "Id" then
					local updateKey = string.format("Workplaces.$[workplace].Grades.$[grade].%s", k)
					update["$set"][updateKey] = v
				end
			end

			options = {
				arrayFilters = {
					{
						["workplace.Id"] = workplaceId,
					},
					{
						["grade.Id"] = gradeId,
					},
				},
			}
		else
			query = {
				Type = "Company",
				Id = jobId,
				["Grades.Id"] = gradeId,
			}

			update = {
				["$set"] = {},
			}

			for k, v in pairs(settingData) do
				if k ~= "Id" then
					local updateKey = string.format("Grades.$[grade].%s", k)
					update["$set"][updateKey] = v
				end
			end

			options = {
				arrayFilters = { { ["grade.Id"] = gradeId } },
			}
		end

		exports['sandbox-base']:DatabaseGameUpdateOne({
			collection = "jobs",
			query = query,
			update = update,
			options = options,
		}, function(success, updated)
			if success then
				RefreshAllJobData(jobId)
				exports['sandbox-jobs']:ManagementEmployeesUpdateAllGrade(jobId, workplaceId, gradeId, settingData)

				p:resolve(true)
			else
				p:resolve(false)
			end
		end)

		local res = Citizen.Await(p)
		return {
			success = res,
			code = "ERROR",
		}
	else
		return {
			success = false,
			code = "MISSING_JOB",
		}
	end
end)

exports("ManagementGradesDelete", function(jobId, workplaceId, gradeId)
	local peopleWithJobGrade = exports['sandbox-jobs']:ManagementEmployeesGetAll(jobId, workplaceId, gradeId)
	if #peopleWithJobGrade <= 0 then
		if exports['sandbox-jobs']:DoesExist(jobId, workplaceId, gradeId) then
			local p = promise.new()
			local query = {}
			local update = {}
			local options = {}

			if workplaceId then
				query = {
					Type = "Government",
					Id = jobId,
					["Workplaces.Id"] = workplaceId,
				}

				update = {
					["$pull"] = {
						["Workplaces.$[workplace].Grades"] = {
							Id = gradeId,
						},
					},
				}

				options = {
					arrayFilters = {
						{
							["workplace.Id"] = workplaceId,
						},
					},
					multi = true,
				}
			else
				query = {
					Type = "Company",
					Id = jobId,
				}

				update = {
					["$pull"] = {
						Grades = {
							Id = gradeId,
						},
					},
				}

				options = {
					multi = true,
				}
			end

			exports['sandbox-base']:DatabaseGameUpdateOne({
				collection = "jobs",
				query = query,
				update = update,
				options = options,
			}, function(success, updated)
				if success then
					RefreshAllJobData(jobId)

					p:resolve(true)
				else
					p:resolve(false)
				end
			end)

			local res = Citizen.Await(p)
			return {
				success = res,
				code = "ERROR",
			}
		else
			return {
				success = false,
				code = "MISSING_JOB",
			}
		end
	else
		return {
			success = false,
			code = "JOB_OCCUPIED",
		}
	end
end)

exports("ManagementEmployeesGetAll", function(jobId, workplaceId, gradeId)
	local jobCharacters = {}
	local onlineCharacters = {}
	for k, v in pairs(exports['sandbox-characters']:FetchAllCharacters()) do
		if v ~= nil then
			table.insert(onlineCharacters, v:GetData("SID"))
			local jobs = v:GetData("Jobs")
			if jobs and #jobs > 0 then
				for k, v in ipairs(jobs) do
					if
						v.Id == jobId
						and (not workplaceId or (workplaceId and (v.Workplace and v.Workplace.Id == workplaceId)))
						and (not gradeId or (v.Grade.Id == gradeId))
					then
						table.insert(jobCharacters, {
							Source = v:GetData("Source"),
							SID = v:GetData("SID"),
							First = v:GetData("First"),
							Last = v:GetData("Last"),
							Phone = v:GetData("Phone"),
							JobData = v,
						})
					end
				end
			end
		end
	end

	local p = promise.new()

	MySQL.Async.fetchAll("SELECT * FROM characters WHERE SID NOT IN (?)", { table.concat(onlineCharacters, ",") },
		function(results)
			if results then
				for _, c in ipairs(results) do
					local jobs = json.decode(c.Jobs)
					if jobs and #jobs > 0 then
						for _, v in ipairs(jobs) do
							if
								v.Id == jobId
								and (not workplaceId or (workplaceId and (v.Workplace and v.Workplace.Id == workplaceId)))
								and (not gradeId or (v.Grade.Id == gradeId))
							then
								table.insert(jobCharacters, {
									Source = false,
									SID = c.SID,
									First = c.First,
									Last = c.Last,
									Phone = c.Phone,
									JobData = v,
								})
							end
						end
					end
				end
				p:resolve(true)
			else
				p:resolve(false)
			end
		end)

	local res = Citizen.Await(p)
	if res then
		return jobCharacters
	else
		return false
	end
end)

exports("ManagementEmployeesUpdateAllJob", function(jobId, newJobName)
	local onlineCharacters = {}
	for k, v in pairs(exports['sandbox-characters']:FetchAllCharacters()) do
		if v ~= nil then
			table.insert(onlineCharacters, v:GetData("SID"))
			local jobs = v:GetData("Jobs")
			if jobs and #jobs > 0 then
				for k, v in ipairs(jobs) do
					if v.Id == jobId then
						v.Name = newJobName
						v:SetData("Jobs", jobs)
						exports['sandbox-phone']:UpdateJobData(v:GetData("Source"))
					end
				end
			end
		end
	end

	local p = promise.new()

	MySQL.Async.fetchAll("SELECT * FROM characters WHERE SID NOT IN (?)", { table.concat(onlineCharacters, ",") },
		function(results)
			if results then
				for _, c in ipairs(results) do
					local jobs = json.decode(c.Jobs)
					if jobs and #jobs > 0 then
						for _, v in ipairs(jobs) do
							if v.Id == jobId then
								v.Name = newJobName
							end
						end
						local updatedJobsJson = json.encode(jobs)
						MySQL.Async.execute("UPDATE characters SET Jobs = @jobs WHERE SID = @sid", {
							["@jobs"] = updatedJobsJson,
							["@sid"] = c.SID
						}, function(affectedRows)
							if affectedRows > 0 then
								p:resolve(true)
							else
								p:resolve(false)
							end
						end)
					end
				end
			else
				p:resolve(false)
			end
		end)

	local res = Citizen.Await(p)
	return res
end)

exports("ManagementEmployeesUpdateAllWorkplace", function(jobId, workplaceId, newWorkplaceName)
	local p = promise.new()

	local jobCharacters = {}
	local onlineCharacters = {}
	for k, v in pairs(exports['sandbox-characters']:FetchAllCharacters()) do
		if v ~= nil then
			table.insert(onlineCharacters, v:GetData("SID"))
			local jobs = v:GetData("Jobs")
			if jobs and #jobs > 0 then
				for k, v in ipairs(jobs) do
					if v.Id == jobId and (v.Workplace and (v.Workplace.Id == workplaceId)) then
						v.Workplace.Name = newWorkplaceName
						v:SetData("Jobs", jobs)
						exports['sandbox-phone']:UpdateJobData(v:GetData("Source"))
					end
				end
			end
		end
	end

	MySQL.Async.fetchAll("SELECT * FROM characters WHERE SID NOT IN (?)", { table.concat(onlineCharacters, ",") },
		function(results)
			if results then
				for _, c in ipairs(results) do
					local jobs = json.decode(c.Jobs)
					if jobs and #jobs > 0 then
						for _, v in ipairs(jobs) do
							if v.Id == jobId and (v.Workplace and v.Workplace.Id == workplaceId) then
								v.Workplace.Name = newWorkplaceName
							end
						end
						local updatedJobsJson = json.encode(jobs)
						MySQL.Async.execute("UPDATE characters SET Jobs = @jobs WHERE SID = @sid", {
							["@jobs"] = updatedJobsJson,
							["@sid"] = c.SID
						}, function(affectedRows)
							if affectedRows > 0 then
								p:resolve(true)
							else
								p:resolve(false)
							end
						end)
					end
				end
			else
				p:resolve(false)
			end
		end)

	local res = Citizen.Await(p)
	return res
end)

exports("ManagementEmployeesUpdateAllGrade", function(jobId, workplaceId, gradeId, settingData)
	local jobCharacters = {}
	local onlineCharacters = {}

	if settingData.Name or settingData.Level then
		local p = promise.new()
		for k, v in pairs(exports['sandbox-characters']:FetchAllCharacters()) do
			if v ~= nil then
				table.insert(onlineCharacters, v:GetData("SID"))
				local jobs = v:GetData("Jobs")
				if jobs and #jobs > 0 then
					for k2, v2 in ipairs(jobs) do
						if
							v2.Id == jobId
							and (not workplaceId or (workplaceId and v2.Workplace and (v2.Workplace.Id == workplaceId)))
							and v2.Grade.Id == gradeId
						then
							if settingData.Name then
								v2.Grade.Name = settingData.Name
							end

							if settingData.Level then
								v2.Grade.Level = settingData.Level
							end

							v:SetData("Jobs", jobs)
							exports['sandbox-phone']:UpdateJobData(v:GetData("Source"))
						end
					end
				end
			end
		end

		MySQL.Async.fetchAll("SELECT * FROM characters WHERE SID NOT IN (?)", { table.concat(onlineCharacters, ",") },
			function(results)
				if results then
					for _, c in ipairs(results) do
						local jobs = json.decode(c.Jobs)
						if jobs and #jobs > 0 then
							for _, v in ipairs(jobs) do
								if
									v.Id == jobId
									and (not workplaceId or (workplaceId and v.Workplace and (v.Workplace.Id == workplaceId)))
									and v.Grade.Id == gradeId
								then
									if settingData.Name then
										v.Grade.Name = settingData.Name
									end

									if settingData.Level then
										v.Grade.Level = settingData.Level
									end
								end
							end
							local updatedJobsJson = json.encode(jobs)
							MySQL.Async.execute("UPDATE characters SET Jobs = @jobs WHERE SID = @sid", {
								["@jobs"] = updatedJobsJson,
								["@sid"] = c.SID
							}, function(affectedRows)
								if affectedRows > 0 then
									p:resolve(true)
								else
									p:resolve(false)
								end
							end)
						end
					end
				else
					p:resolve(false)
				end
			end)

		local res = Citizen.Await(p)
		return res
	end
end)

exports("DataSet", function(jobId, key, val)
	if exports['sandbox-jobs']:DoesExist(jobId) and key then
		local p = promise.new()
		exports['sandbox-base']:DatabaseGameUpdateOne({
			collection = "jobs",
			query = {
				Id = jobId,
			},
			update = {
				["$set"] = {
					[string.format("Data.%s", key)] = val,
				},
			},
		}, function(success, res)
			if success then
				RefreshAllJobData(jobId)

				p:resolve(true)
			else
				p:resolve(false)
			end
		end)

		local res = Citizen.Await(p)
		return {
			success = res,
			code = "ERROR",
		}
	else
		return {
			success = false,
			code = "MISSING_JOB",
		}
	end
end)

exports("DataGet", function(jobId, key)
	if key and JOB_CACHE[jobId] and JOB_CACHE[jobId].Data then
		return JOB_CACHE[jobId].Data[key]
	end
end)

exports("GetJobSpawns", function()
	return _jobSpawns or {}
end)
