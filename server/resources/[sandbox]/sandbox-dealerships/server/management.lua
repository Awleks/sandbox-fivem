_managementData = {}

exports('ManagementLoadData', function()
    local p = promise.new()
    exports.oxmysql:execute('SELECT * FROM dealer_data', {}, function(results)
        if results then
            local cardealers = {}
            for k, v in ipairs(results) do
                if v.dealership then
                    cardealers[v.dealership] = v
                end
            end

            for k, v in pairs(_dealerships) do
                if cardealers[k] then
                    _managementData[k] = cardealers[k]
                else
                    _managementData[k] = _defaultDealershipSalesData
                end
            end
            p:resolve(true)
        else
            p:resolve(false)
        end
    end)
    return Citizen.Await(p)
end)

exports('ManagementSetData', function(dealerId, key, val)
    local data = _managementData[dealerId]
    if data then
        local dealerData = table.copy(data)
        dealerData.dealership = nil
        dealerData._id = nil
        dealerData[key] = val

        local p = promise.new()
        exports.oxmysql:execute(
            'INSERT INTO dealer_data (dealership, ' .. key .. ') VALUES (?, ?) ON DUPLICATE KEY UPDATE ' .. key .. ' = ?',
            { dealerId, val, val },
            function(affectedRows)
                if affectedRows and affectedRows > 0 then
                    _managementData[dealerId] = dealerData
                    p:resolve(_managementData[dealerId])
                else
                    p:resolve(false)
                end
            end)
        return Citizen.Await(p)
    end
    return false
end)

exports('ManagementSetMultipleData', function(dealerId, updatingData)
    local data = _managementData[dealerId]
    if data then
        local dealerData = table.copy(data)
        dealerData.dealership = nil
        dealerData._id = nil

        for k, v in pairs(updatingData) do
            dealerData[k] = v
        end

        local p = promise.new()

        local setParts = {}
        local values = {}
        for k, v in pairs(updatingData) do
            table.insert(setParts, k .. ' = ?')
            table.insert(values, v)
        end

        local query = 'INSERT INTO dealer_data (dealership, ' ..
            table.concat(setParts, ', ') ..
            ') VALUES (?, ' ..
            string.rep('?, ', #values - 1) .. '?) ON DUPLICATE KEY UPDATE ' .. table.concat(setParts, ', ')
        table.insert(values, 1, dealerId)
        table.insert(values, dealerId)

        exports.oxmysql:execute(query, values, function(affectedRows)
            if affectedRows and affectedRows > 0 then
                _managementData[dealerId] = dealerData
                p:resolve(_managementData[dealerId])
            else
                p:resolve(false)
            end
        end)
        return Citizen.Await(p)
    end
    return false
end)

exports('ManagementGetAllData', function(dealerId)
    return _managementData[dealerId]
end)

exports('ManagementGetData', function(dealerId, key)
    local data = _managementData[dealerId]
    if data then
        return data[key]
    end
    return false
end)
