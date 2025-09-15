local RSGCore = exports['rsg-core']:GetCoreObject()

-- Toggle property lock
RegisterNetEvent('rsg_housing:server:toggleLock', function(propertyId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local property = Properties[propertyId]
    if not property then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.property_not_exist'), 'error')
        return
    end
    
    -- Check if player has access
    if not HasPropertyAccess(Player.PlayerData.citizenid, propertyId) then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.no_access'), 'error')
        return
    end
    
    -- Toggle lock status
    property.locked = not property.locked
    
    -- Update database
    MySQL.execute('UPDATE rsg_housing_properties SET locked = ? WHERE id = ?', {
        property.locked and 1 or 0,
        propertyId
    })
    
    -- Log the action
    LogPropertyAction(propertyId, Player.PlayerData.citizenid, 'lock_toggle', 'Toggled lock: ' .. (property.locked and 'locked' or 'unlocked'))
    
    -- Notify client
    TriggerClientEvent('rsg_housing:client:lockToggled', src, property.locked)
    
    if Config.Debug then
        print('[RSG Housing] Property ' .. propertyId .. ' lock toggled by ' .. Player.PlayerData.citizenid)
    end
end)

-- Give keys to player
RegisterNetEvent('rsg_housing:server:giveKeys', function(propertyId, targetPlayerId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local TargetPlayer = RSGCore.Functions.GetPlayer(targetPlayerId)
    
    if not Player or not TargetPlayer then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.player_not_exist'), 'error')
        return
    end
    
    local property = Properties[propertyId]
    if not property then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.property_not_exist'), 'error')
        return
    end
    
    -- Check if player owns the property
    if property.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.not_owner'), 'error')
        return
    end
    
    -- Check if target already has keys
    local existingKeys = MySQL.query.await('SELECT * FROM rsg_housing_keys WHERE property_id = ? AND player_id = ?', {
        propertyId,
        TargetPlayer.PlayerData.citizenid
    })
    
    if existingKeys and #existingKeys > 0 then
        TriggerClientEvent('RSGCore:Notify', src, 'Player already has keys to this property', 'error')
        return
    end
    
    -- Give keys
    MySQL.insert('INSERT INTO rsg_housing_keys (property_id, player_id, player_name, given_by) VALUES (?, ?, ?, ?)', {
        propertyId,
        TargetPlayer.PlayerData.citizenid,
        TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname,
        Player.PlayerData.citizenid
    })
    
    -- Log the action
    LogPropertyAction(propertyId, Player.PlayerData.citizenid, 'give_keys', 'Gave keys to ' .. TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname)
    
    -- Notify both players
    local targetName = TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname
    TriggerClientEvent('rsg_housing:client:keysGiven', src, targetName)
    TriggerClientEvent('RSGCore:Notify', targetPlayerId, 'You have been given keys to ' .. property.label, 'success')
    
    if Config.Debug then
        print('[RSG Housing] Keys given for property ' .. propertyId .. ' to ' .. TargetPlayer.PlayerData.citizenid)
    end
end)

-- Remove keys from player
RegisterNetEvent('rsg_housing:server:removeKeys', function(propertyId, targetPlayerId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local property = Properties[propertyId]
    if not property then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.property_not_exist'), 'error')
        return
    end
    
    -- Check if player owns the property
    if property.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.not_owner'), 'error')
        return
    end
    
    -- Get target player name
    local keyInfo = MySQL.query.await('SELECT player_name FROM rsg_housing_keys WHERE property_id = ? AND player_id = ?', {
        propertyId,
        targetPlayerId
    })
    
    if not keyInfo or #keyInfo == 0 then
        TriggerClientEvent('RSGCore:Notify', src, 'Player does not have keys to this property', 'error')
        return
    end
    
    -- Remove keys
    MySQL.execute('DELETE FROM rsg_housing_keys WHERE property_id = ? AND player_id = ?', {
        propertyId,
        targetPlayerId
    })
    
    -- Log the action
    LogPropertyAction(propertyId, Player.PlayerData.citizenid, 'remove_keys', 'Removed keys from ' .. keyInfo[1].player_name)
    
    -- Notify player
    TriggerClientEvent('rsg_housing:client:keysRemoved', src, keyInfo[1].player_name)
    
    -- Notify target if online
    local TargetPlayer = RSGCore.Functions.GetPlayerByCitizenId(targetPlayerId)
    if TargetPlayer then
        TriggerClientEvent('RSGCore:Notify', TargetPlayer.PlayerData.source, 'Your keys to ' .. property.label .. ' have been removed', 'error')
    end
    
    if Config.Debug then
        print('[RSG Housing] Keys removed for property ' .. propertyId .. ' from ' .. targetPlayerId)
    end
end)

-- Ring doorbell
RegisterNetEvent('rsg_housing:server:ringDoorbell', function(propertyId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local property = Properties[propertyId]
    if not property then return end
    
    if not property.owner then
        TriggerClientEvent('RSGCore:Notify', src, 'No one lives here', 'error')
        return
    end
    
    -- Find owner if online
    local OwnerPlayer = RSGCore.Functions.GetPlayerByCitizenId(property.owner)
    if OwnerPlayer then
        local playerName = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
        TriggerClientEvent('rsg_housing:client:doorbellRang', OwnerPlayer.PlayerData.source, property.label, playerName)
        TriggerClientEvent('RSGCore:Notify', src, 'Doorbell rang', 'success')
    else
        TriggerClientEvent('RSGCore:Notify', src, 'No one is home', 'error')
    end
    
    -- Log the action
    LogPropertyAction(propertyId, Player.PlayerData.citizenid, 'doorbell', 'Rang doorbell')
end)

-- Open property storage
RegisterNetEvent('rsg_housing:server:openStorage', function(propertyId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player has access
    if not HasPropertyAccess(Player.PlayerData.citizenid, propertyId) then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.no_access'), 'error')
        return
    end
    
    local property = Properties[propertyId]
    if not property then return end
    
    local storageSize = Config.PropertyTypes[property.type].storage or 50
    
    -- Open inventory
    exports['rsg-inventory']:OpenInventory(src, 'stash', 'property_' .. propertyId, {
        maxweight = storageSize * 1000,
        slots = storageSize
    })
end)

-- Check if player has access to property
function HasPropertyAccess(citizenid, propertyId)
    local property = Properties[propertyId]
    if not property then return false end
    
    -- Owner has access
    if property.owner == citizenid then
        return true
    end
    
    -- Check if player has keys
    local keys = MySQL.query.await('SELECT * FROM rsg_housing_keys WHERE property_id = ? AND player_id = ?', {
        propertyId,
        citizenid
    })
    
    return keys and #keys > 0
end

-- Get property keys (for management)
RSGCore.Functions.CreateCallback('rsg_housing:server:getPropertyKeys', function(source, cb, propertyId)
    local keys = MySQL.query.await('SELECT player_id, player_name FROM rsg_housing_keys WHERE property_id = ?', {
        propertyId
    })
    
    cb(keys or {})
end)

-- Saloon earnings management
RSGCore.Functions.CreateCallback('rsg_housing:server:getSaloonEarnings', function(source, cb, propertyId)
    local earnings = MySQL.query.await('SELECT * FROM rsg_housing_saloon_earnings WHERE property_id = ? ORDER BY date DESC LIMIT 30', {
        propertyId
    })
    
    cb(earnings or {})
end)

-- Collect saloon earnings
RegisterNetEvent('rsg_housing:server:collectEarnings', function(propertyId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local property = Properties[propertyId]
    if not property then return end
    
    -- Check if player owns the property
    if property.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.not_owner'), 'error')
        return
    end
    
    -- Get uncollected earnings
    local earnings = MySQL.query.await('SELECT SUM(amount) as total FROM rsg_housing_saloon_earnings WHERE property_id = ? AND collected = 0', {
        propertyId
    })
    
    if not earnings or not earnings[1] or earnings[1].total == 0 then
        TriggerClientEvent('RSGCore:Notify', src, 'No earnings to collect', 'error')
        return
    end
    
    local totalEarnings = earnings[1].total
    
    -- Add money to player
    Player.Functions.AddMoney('cash', totalEarnings, 'saloon-earnings')
    
    -- Mark earnings as collected
    MySQL.execute('UPDATE rsg_housing_saloon_earnings SET collected = 1 WHERE property_id = ? AND collected = 0', {
        propertyId
    })
    
    -- Log the action
    LogPropertyAction(propertyId, Player.PlayerData.citizenid, 'collect_earnings', 'Collected $' .. totalEarnings .. ' in earnings')
    
    -- Notify client
    TriggerClientEvent('rsg_housing:client:earningsCollected', src, totalEarnings)
    
    if Config.Debug then
        print('[RSG Housing] Earnings collected for saloon ' .. propertyId .. ': $' .. totalEarnings)
    end
end)

-- Hire staff
RegisterNetEvent('rsg_housing:server:hireStaff', function(propertyId, staffType)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local property = Properties[propertyId]
    if not property then return end
    
    -- Check if player owns the property
    if property.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.not_owner'), 'error')
        return
    end
    
    local cost = staffType == 'bartender' and 500 or 300
    
    -- Check if player has enough money
    if Player.PlayerData.money.cash < cost then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.insufficient_funds'), 'error')
        return
    end
    
    -- Remove money
    Player.Functions.RemoveMoney('cash', cost, 'staff-hire')
    
    -- Add staff to database (you would need to create this table)
    -- For now, just log it
    LogPropertyAction(propertyId, Player.PlayerData.citizenid, 'hire_staff', 'Hired ' .. staffType .. ' for $' .. cost)
    
    -- Notify client
    TriggerClientEvent('rsg_housing:client:staffHired', src, staffType, cost)
    
    if Config.Debug then
        print('[RSG Housing] Staff hired for property ' .. propertyId .. ': ' .. staffType)
    end
end)

-- Get property staff (placeholder)
RSGCore.Functions.CreateCallback('rsg_housing:server:getPropertyStaff', function(source, cb, propertyId)
    -- This would query a staff table if implemented
    cb({})
end)

-- Fire staff
RegisterNetEvent('rsg_housing:server:fireStaff', function(propertyId, staffId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    -- Implementation would remove staff from database
    LogPropertyAction(propertyId, Player.PlayerData.citizenid, 'fire_staff', 'Fired staff member')
    
    TriggerClientEvent('rsg_housing:client:staffFired', src, 'staff member')
end)