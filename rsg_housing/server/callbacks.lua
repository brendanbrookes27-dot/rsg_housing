local RSGCore = exports['rsg-core']:GetCoreObject()

-- Get player properties
RSGCore.Functions.CreateCallback('rsg_housing:server:getPlayerProperties', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then 
        cb({})
        return 
    end
    
    local properties = GetPlayerProperties(Player.PlayerData.citizenid)
    cb(properties)
end)

-- Get property details
RSGCore.Functions.CreateCallback('rsg_housing:server:getPropertyDetails', function(source, cb, propertyId)
    local property = Properties[propertyId]
    if not property then
        cb(nil)
        return
    end
    
    -- Get additional details
    local details = {
        property = property,
        keys = {},
        storage = nil,
        earnings = nil
    }
    
    -- Get key holders
    local keys = MySQL.query.await('SELECT player_id, player_name, given_date FROM rsg_housing_keys WHERE property_id = ?', {
        propertyId
    })
    details.keys = keys or {}
    
    -- Get storage info
    local storage = MySQL.query.await('SELECT items FROM rsg_housing_storage WHERE property_id = ?', {
        propertyId
    })
    if storage and storage[1] then
        details.storage = json.decode(storage[1].items) or {}
    end
    
    -- Get earnings for saloons
    if property.type == 'saloon' then
        local earnings = MySQL.query.await('SELECT * FROM rsg_housing_saloon_earnings WHERE property_id = ? ORDER BY date DESC LIMIT 7', {
            propertyId
        })
        details.earnings = earnings or {}
    end
    
    cb(details)
end)

-- Check property access
RSGCore.Functions.CreateCallback('rsg_housing:server:hasPropertyAccess', function(source, cb, propertyId)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then 
        cb(false)
        return 
    end
    
    local hasAccess = HasPropertyAccess(Player.PlayerData.citizenid, propertyId)
    cb(hasAccess)
end)

-- Get nearby properties
RSGCore.Functions.CreateCallback('rsg_housing:server:getNearbyProperties', function(source, cb, coords, radius)
    local nearbyProperties = {}
    radius = radius or 100.0
    
    for _, property in pairs(Properties) do
        local distance = #(coords - property.coords)
        if distance <= radius then
            table.insert(nearbyProperties, property)
        end
    end
    
    cb(nearbyProperties)
end)

-- Get property statistics
RSGCore.Functions.CreateCallback('rsg_housing:server:getPropertyStats', function(source, cb)
    local stats = {
        total_properties = 0,
        owned_properties = 0,
        rented_properties = 0,
        available_properties = 0,
        saloons = 0,
        houses = 0,
        apartments = 0,
        cabins = 0,
        mansions = 0
    }
    
    for _, property in pairs(Properties) do
        stats.total_properties = stats.total_properties + 1
        
        if property.owner then
            if property.ownership_type == 'rented' then
                stats.rented_properties = stats.rented_properties + 1
            else
                stats.owned_properties = stats.owned_properties + 1
            end
        else
            stats.available_properties = stats.available_properties + 1
        end
        
        -- Count by type
        if property.type == 'saloon' then
            stats.saloons = stats.saloons + 1
        elseif property.type == 'house' then
            stats.houses = stats.houses + 1
        elseif property.type == 'apartment' then
            stats.apartments = stats.apartments + 1
        elseif property.type == 'cabin' then
            stats.cabins = stats.cabins + 1
        elseif property.type == 'mansion' then
            stats.mansions = stats.mansions + 1
        end
    end
    
    cb(stats)
end)

-- Get property logs
RSGCore.Functions.CreateCallback('rsg_housing:server:getPropertyLogs', function(source, cb, propertyId, limit)
    limit = limit or 50
    
    local logs = MySQL.query.await('SELECT * FROM rsg_housing_logs WHERE property_id = ? ORDER BY created_at DESC LIMIT ?', {
        propertyId,
        limit
    })
    
    cb(logs or {})
end)

-- Get player property history
RSGCore.Functions.CreateCallback('rsg_housing:server:getPlayerPropertyHistory', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then 
        cb({})
        return 
    end
    
    local history = MySQL.query.await('SELECT * FROM rsg_housing_logs WHERE player_id = ? ORDER BY created_at DESC LIMIT 100', {
        Player.PlayerData.citizenid
    })
    
    cb(history or {})
end)

-- Check if property name exists
RSGCore.Functions.CreateCallback('rsg_housing:server:propertyNameExists', function(source, cb, propertyName)
    for _, property in pairs(Properties) do
        if property.label:lower() == propertyName:lower() then
            cb(true)
            return
        end
    end
    cb(false)
end)

-- Get properties by type
RSGCore.Functions.CreateCallback('rsg_housing:server:getPropertiesByType', function(source, cb, propertyType)
    local propertiesByType = {}
    
    for _, property in pairs(Properties) do
        if property.type == propertyType then
            table.insert(propertiesByType, property)
        end
    end
    
    cb(propertiesByType)
end)

-- Get available properties
RSGCore.Functions.CreateCallback('rsg_housing:server:getAvailableProperties', function(source, cb)
    local availableProperties = {}
    
    for _, property in pairs(Properties) do
        if not property.owner then
            table.insert(availableProperties, property)
        end
    end
    
    cb(availableProperties)
end)

-- Get owned properties by player
RSGCore.Functions.CreateCallback('rsg_housing:server:getOwnedProperties', function(source, cb, citizenid)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then 
        cb({})
        return 
    end
    
    -- Use provided citizenid or player's own
    local targetCitizenid = citizenid or Player.PlayerData.citizenid
    
    local ownedProperties = GetPlayerProperties(targetCitizenid)
    cb(ownedProperties)
end)

-- Get rent due properties
RSGCore.Functions.CreateCallback('rsg_housing:server:getRentDueProperties', function(source, cb)
    local rentDueProperties = {}
    local currentTime = os.time()
    
    for _, property in pairs(Properties) do
        if property.ownership_type == 'rented' and property.rent_due then
            local rentDueTime = os.time(os.date("*t", property.rent_due))
            if rentDueTime <= currentTime and not property.rent_paid then
                table.insert(rentDueProperties, property)
            end
        end
    end
    
    cb(rentDueProperties)
end)

-- Get saloon earnings summary
RSGCore.Functions.CreateCallback('rsg_housing:server:getSaloonEarningsSummary', function(source, cb, propertyId)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then 
        cb(nil)
        return 
    end
    
    local property = Properties[propertyId]
    if not property or property.owner ~= Player.PlayerData.citizenid then
        cb(nil)
        return
    end
    
    -- Get earnings summary
    local summary = MySQL.query.await([[
        SELECT 
            SUM(amount) as total_earnings,
            SUM(CASE WHEN collected = 0 THEN amount ELSE 0 END) as uncollected_earnings,
            COUNT(*) as total_days,
            AVG(amount) as avg_daily_earnings
        FROM rsg_housing_saloon_earnings 
        WHERE property_id = ?
    ]], { propertyId })
    
    local result = summary and summary[1] or {
        total_earnings = 0,
        uncollected_earnings = 0,
        total_days = 0,
        avg_daily_earnings = 0
    }
    
    cb(result)
end)