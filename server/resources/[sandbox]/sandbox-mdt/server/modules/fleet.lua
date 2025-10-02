AddEventHandler("MDT:Server:RegisterCallbacks", function()
  exports["sandbox-base"]:RegisterServerCallback("MDT:ViewVehicleFleet", function(source, data, cb)
    local hasPerms, loggedInJob = CheckMDTPermissions(source, {
      'FLEET_MANAGEMENT',
    })

    if hasPerms and loggedInJob then
      local results = MySQL.query.await(
        "SELECT VIN, Make, Model, Type, OwnerType, OwnerId, OwnerWorkplace, StorageType, StorageId, Properties, RegistrationDate, RegisteredPlate FROM vehicles WHERE OwnerType = ? AND OwnerId = ?",
        { 1, loggedInJob }
      )

      if results then
        for k, v in ipairs(results) do
          if v.Properties then
            local properties = json.decode(v.Properties)
            v.GovAssigned = properties and properties.GovAssigned or nil
          end

          v.Owner = {
            Type = v.OwnerType,
            Id = v.OwnerId,
            Workplace = v.OwnerWorkplace
          }

          if v.StorageType ~= nil then
            local storageName = nil
            if v.StorageType == 0 then
              storageName = exports['sandbox-vehicles']:GaragesImpound().name
            elseif v.StorageType == 1 then
              local garage = exports['sandbox-vehicles']:GaragesGet(v.StorageId)
              storageName = garage and garage.name or nil
            elseif v.StorageType == 2 then
              local prop = exports['sandbox-properties']:Get(v.StorageId)
              storageName = prop and prop.label or nil
            end

            if storageName then
              v.Storage = {
                Type = v.StorageType,
                Id = v.StorageId,
                Name = storageName
              }
            end
          end

          v.OwnerType = nil
          v.OwnerId = nil
          v.OwnerWorkplace = nil
          v.StorageType = nil
          v.StorageId = nil
          v.Properties = nil
        end

        cb(results)
      else
        cb(false)
      end
    else
      cb(false)
    end
  end)

  exports["sandbox-base"]:RegisterServerCallback("MDT:SetAssignedDrivers", function(source, data, cb)
    local hasPerms, loggedInJob = CheckMDTPermissions(source, {
      'FLEET_MANAGEMENT',
    })

    if hasPerms and loggedInJob and data.vehicle and data.assigned then
      local ass = {}
      for k, v in ipairs(data.assigned) do
        table.insert(ass, {
          SID = v.SID,
          First = v.First,
          Last = v.Last,
          Callsign = v.Callsign
        })
      end

      local success = MySQL.update.await(
        "UPDATE vehicles SET Properties = JSON_SET(COALESCE(Properties, '{}'), '$.GovAssigned', ?) WHERE VIN = ?",
        { json.encode(ass), data.vehicle }
      )

      cb(success)
    else
      cb(false)
    end
  end)

  exports["sandbox-base"]:RegisterServerCallback("MDT:TrackFleetVehicle", function(source, data, cb)
    local hasPerms, loggedInJob = CheckMDTPermissions(source, {
      'FLEET_MANAGEMENT',
    })

    if hasPerms and loggedInJob and data.vehicle then
      cb(exports['sandbox-vehicles']:OwnedTrack(data.vehicle))
    else
      cb(false)
    end
  end)
end)
