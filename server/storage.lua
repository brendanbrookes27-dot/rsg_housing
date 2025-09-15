local RSGCore = exports['rsg-core']:GetCoreObject()

-- Storage system for properties
local PropertyStorages = {}

-- Initialize storage system
CreateThread(function()
    Wait(1000)
    LoadAllPropertyStorages()
    if Config.Debug then
        print('^2[RSG Housing]^7 Storage system initialized')
    end
end)

-- Load all property storages
function LoadAllPropertyStorages()
    local result = MySQL.query.await('SELECT * FROM rsg_housing_storage')
    if result then
        for i = 1, #result do
            local storage = result[i]
            PropertyStorages[storage.property_id] = storage
            
            -- Register with inventory system if available
            if GetResourceState('rsg-inventory') == 'started' then
                exports['rsg-inventory']:CreateStash(storage.storage_id, 'Property Storage', storage.max_slots, storage.max_weight)
            end
        end
        if Config.Debug then
            print('^2[RSG Housing]^7 Loaded ' .. #result .. ' property storages')
        end
    end
end

-- Create storage for property
function CreatePropertyStorage(propertyId)
    if PropertyStorages[propertyId] then return end
    
    local storageId = 'property_' .. propertyId
    local maxSlots = Config.Storage.MaxSlots
    local maxWeight = Config.Storage.MaxWeight
    
    -- Insert into database
    local storageDbId = MySQL.insert.await('INSERT INTO rsg_housing_storage (property_id, storage_id, max_slots, max_weight) VALUES (?, ?, ?, ?)', {
        propertyId,
        storageId,
        maxSlots,
        maxWeight
    })
    
    if storageDbId then
        PropertyStorages[propertyId] = {
            id = storageDbId,
            property_id = propertyId,
            storage_id = storageId,
            max_slots = maxSlots,
            max_weight = maxWeight
        }
        
        -- Register with inventory system
        if GetResourceState('rsg-inventory') == 'started' then
            exports['rsg-inventory']:CreateStash(storageId, 'Property Storage', maxSlots, maxWeight)
        end
        
        return true
    end
    
    return false
end

-- Get property storage
function GetPropertyStorage(propertyId)
    return PropertyStorages[propertyId]
end

-- Open storage for player
function OpenPropertyStorage(src, propertyId)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    -- Check if player has access to property
    if not exports['rsg_housing']:PlayerHasKeys(Player.PlayerData.citizenid, propertyId) then
        return false
    end
    
    local storage = GetPropertyStorage(propertyId)
    if not storage then
        -- Create storage if it doesn't exist
        if CreatePropertyStorage(propertyId) then
            storage = GetPropertyStorage(propertyId)
        else
            return false
        end
    end
    
    -- Open storage with inventory system
    if GetResourceState('rsg-inventory') == 'started' then
        exports['rsg-inventory']:OpenInventory('stash', storage.storage_id, {
            maxweight = storage.max_weight,
            slots = storage.max_slots
        })
        return true
    elseif GetResourceState('qb-inventory') == 'started' then
        exports['qb-inventory']:OpenInventory('stash', storage.storage_id, {
            maxweight = storage.max_weight,
            slots = storage.max_slots
        })
        return true
    end
    
    return false
end

-- Get storage contents
function GetStorageContents(propertyId)
    local storage = GetPropertyStorage(propertyId)
    if not storage then return {} end
    
    if GetResourceState('rsg-inventory') == 'started' then
        return exports['rsg-inventory']:GetStashItems(storage.storage_id) or {}
    elseif GetResourceState('qb-inventory') == 'started' then
        return exports['qb-inventory']:GetStashItems(storage.storage_id) or {}
    end
    
    return {}
end

-- Clear storage contents
function ClearStorageContents(propertyId)
    local storage = GetPropertyStorage(propertyId)
    if not storage then return false end
    
    if GetResourceState('rsg-inventory') == 'started' then
        exports['rsg-inventory']:ClearStash(storage.storage_id)
        return true
    elseif GetResourceState('qb-inventory') == 'started' then
        exports['qb-inventory']:ClearStash(storage.storage_id)
        return true
    end
    
    return false
end

-- Transfer storage contents to another property
function TransferStorageContents(fromPropertyId, toPropertyId)
    local fromStorage = GetPropertyStorage(fromPropertyId)
    local toStorage = GetPropertyStorage(toPropertyId)
    
    if not fromStorage or not toStorage then return false end
    
    local contents = GetStorageContents(fromPropertyId)
    if not contents or #contents == 0 then return true end
    
    -- This would need to be implemented based on the inventory system being used
    -- For now, we'll just log the transfer
    if Config.Debug then
        print('^2[RSG Housing]^7 Storage transfer from property ' .. fromPropertyId .. ' to ' .. toPropertyId)
    end
    
    return true
end

-- Upgrade storage capacity
function UpgradeStorageCapacity(propertyId, newSlots, newWeight)
    local storage = GetPropertyStorage(propertyId)
    if not storage then return false end
    
    -- Update database
    MySQL.query.await('UPDATE rsg_housing_storage SET max_slots = ?, max_weight = ? WHERE property_id = ?', {
        newSlots,
        newWeight,
        propertyId
    })
    
    -- Update memory
    storage.max_slots = newSlots
    storage.max_weight = newWeight
    
    -- Update inventory system
    if GetResourceState('rsg-inventory') == 'started' then
        exports['rsg-inventory']:SetStashMaxWeight(storage.storage_id, newWeight)
        exports['rsg-inventory']:SetStashSlots(storage.storage_id, newSlots)
    end
    
    return true
end

-- Check if item is restricted
function IsItemRestricted(itemName)
    for i = 1, #Config.Storage.RestrictedItems do
        if Config.Storage.RestrictedItems[i] == itemName then
            return true
        end
    end
    return false
end

-- Add item to storage (with restrictions)
function AddItemToStorage(propertyId, itemName, amount, metadata)
    if IsItemRestricted(itemName) then
        return false, 'Item is restricted from storage'
    end
    
    local storage = GetPropertyStorage(propertyId)
    if not storage then return false, 'Storage not found' end
    
    if GetResourceState('rsg-inventory') == 'started' then
        return exports['rsg-inventory']:AddItem(storage.storage_id, itemName, amount, nil, metadata)
    elseif GetResourceState('qb-inventory') == 'started' then
        return exports['qb-inventory']:AddItem(storage.storage_id, itemName, amount, nil, metadata)
    end
    
    return false, 'No inventory system available'
end

-- Remove item from storage
function RemoveItemFromStorage(propertyId, itemName, amount)
    local storage = GetPropertyStorage(propertyId)
    if not storage then return false end
    
    if GetResourceState('rsg-inventory') == 'started' then
        return exports['rsg-inventory']:RemoveItem(storage.storage_id, itemName, amount)
    elseif GetResourceState('qb-inventory') == 'started' then
        return exports['qb-inventory']:RemoveItem(storage.storage_id, itemName, amount)
    end
    
    return false
end

-- Get storage statistics
function GetStorageStats(propertyId)
    local storage = GetPropertyStorage(propertyId)
    if not storage then return nil end
    
    local contents = GetStorageContents(propertyId)
    local totalWeight = 0
    local usedSlots = 0
    
    if contents then
        for _, item in pairs(contents) do
            if item.amount and item.amount > 0 then
                usedSlots = usedSlots + 1
                if item.weight then
                    totalWeight = totalWeight + (item.weight * item.amount)
                end
            end
        end
    end
    
    return {
        maxSlots = storage.max_slots,
        usedSlots = usedSlots,
        maxWeight = storage.max_weight,
        usedWeight = totalWeight,
        items = contents
    }
end

-- Events
RegisterNetEvent('rsg_housing:server:openStorage', function(propertyId)
    local src = source
    local success = OpenPropertyStorage(src, propertyId)
    if not success then
        TriggerClientEvent('RSGCore:Notify', src, 'Unable to access storage', 'error')
    end
end)

RegisterNetEvent('rsg_housing:server:upgradeStorage', function(propertyId, upgradeType)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Check if player owns the property
    if not exports['rsg_housing']:PlayerOwnsProperty(Player.PlayerData.citizenid, propertyId) then
        TriggerClientEvent('RSGCore:Notify', src, 'You do not own this property', 'error')
        return
    end
    
    local upgradeCosts = {
        slots = { price = 500, slots = 75, weight = 0 },
        weight = { price = 750, slots = 0, weight = 600000 },
        premium = { price = 1200, slots = 100, weight = 800000 }
    }
    
    local upgrade = upgradeCosts[upgradeType]
    if not upgrade then return end
    
    if Player.PlayerData.money.cash < upgrade.price then
        TriggerClientEvent('RSGCore:Notify', src, 'Insufficient funds', 'error')
        return
    end
    
    local storage = GetPropertyStorage(propertyId)
    if not storage then return end
    
    local newSlots = upgrade.slots > 0 and upgrade.slots or storage.max_slots
    local newWeight = upgrade.weight > 0 and upgrade.weight or storage.max_weight
    
    Player.Functions.RemoveMoney('cash', upgrade.price)
    UpgradeStorageCapacity(propertyId, newSlots, newWeight)
    
    TriggerClientEvent('RSGCore:Notify', src, 'Storage upgraded successfully', 'success')
    
    -- Log the upgrade
    exports['rsg_housing']:LogPropertyAction(propertyId, Player.PlayerData.citizenid, 'storage_upgraded', {
        upgrade_type = upgradeType,
        price = upgrade.price,
        new_slots = newSlots,
        new_weight = newWeight
    })
end)

-- Callbacks
RSGCore.Functions.CreateCallback('rsg_housing:server:getStorageStats', function(source, cb, propertyId)
    cb(GetStorageStats(propertyId))
end)

RSGCore.Functions.CreateCallback('rsg_housing:server:getStorageContents', function(source, cb, propertyId)
    cb(GetStorageContents(propertyId))
end)

-- Property ownership change handler
RegisterNetEvent('rsg_housing:server:propertyOwnershipChanged', function(propertyId, oldOwner, newOwner)
    -- Handle storage ownership change if needed
    if Config.Debug then
        print('^2[RSG Housing]^7 Storage ownership changed for property ' .. propertyId)
    end
end)

-- Property deletion handler
RegisterNetEvent('rsg_housing:server:propertyDeleted', function(propertyId)
    -- Clear storage when property is deleted
    ClearStorageContents(propertyId)
    
    -- Remove from database
    MySQL.query.await('DELETE FROM rsg_housing_storage WHERE property_id = ?', {propertyId})
    
    -- Remove from memory
    PropertyStorages[propertyId] = nil
    
    if Config.Debug then
        print('^2[RSG Housing]^7 Storage cleared for deleted property ' .. propertyId)
    end
end)

-- Export functions
exports('CreatePropertyStorage', CreatePropertyStorage)
exports('GetPropertyStorage', GetPropertyStorage)
exports('OpenPropertyStorage', OpenPropertyStorage)
exports('GetStorageContents', GetStorageContents)
exports('ClearStorageContents', ClearStorageContents)
exports('GetStorageStats', GetStorageStats)
exports('AddItemToStorage', AddItemToStorage)
exports('RemoveItemFromStorage', RemoveItemFromStorage)
exports('UpgradeStorageCapacity', UpgradeStorageCapacity)