local RSGCore = exports['rsg-core']:GetCoreObject()

-- Global variables
local Properties = {}
local PlayerProperties = {}
local PropertyBlips = {}

-- Initialize the housing system
CreateThread(function()
    Wait(1000)
    LoadProperties()
    StartRentPaymentThread()
    if Config.Debug then
        print('^2[RSG Housing]^7 Housing system initialized successfully')
    end
end)

-- Load all properties from database
function LoadProperties()
    local result = MySQL.query.await('SELECT * FROM rsg_housing_properties')
    if result then
        for i = 1, #result do
            local property = result[i]
            property.coords = json.decode(property.coords)
            if property.garage_coords then
                property.garage_coords = json.decode(property.garage_coords)
            end
            if property.images then
                property.images = json.decode(property.images)
            end
            Properties[property.id] = property
        end
        if Config.Debug then
            print('^2[RSG Housing]^7 Loaded ' .. #result .. ' properties')
        end
    end
end

-- Load player properties
function LoadPlayerProperties(citizenid)
    local result = MySQL.query.await('SELECT * FROM rsg_housing_ownership WHERE citizenid = ?', {citizenid})
    if result then
        PlayerProperties[citizenid] = {}
        for i = 1, #result do
            PlayerProperties[citizenid][result[i].property_id] = result[i]
        end
    end
end

-- Get property by ID
function GetProperty(propertyId)
    return Properties[propertyId]
end

-- Get property ownership
function GetPropertyOwnership(propertyId)
    local result = MySQL.query.await('SELECT * FROM rsg_housing_ownership WHERE property_id = ?', {propertyId})
    return result and result[1] or nil
end

-- Check if player owns property
function PlayerOwnsProperty(citizenid, propertyId)
    local result = MySQL.query.await('SELECT * FROM rsg_housing_ownership WHERE citizenid = ? AND property_id = ?', {citizenid, propertyId})
    return result and #result > 0
end

-- Check if player has keys to property
function PlayerHasKeys(citizenid, propertyId)
    local result = MySQL.query.await('SELECT * FROM rsg_housing_keys WHERE citizenid = ? AND property_id = ? AND is_active = 1', {citizenid, propertyId})
    return result and #result > 0
end

-- Get player property count
function GetPlayerPropertyCount(citizenid)
    local result = MySQL.query.await('SELECT COUNT(*) as count FROM rsg_housing_ownership WHERE citizenid = ?', {citizenid})
    return result and result[1].count or 0
end

-- Purchase property
function PurchaseProperty(src, propertyId, purchaseType)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local property = GetProperty(propertyId)
    if not property then return false end
    
    local ownership = GetPropertyOwnership(propertyId)
    if ownership then return false end -- Already owned
    
    local playerCount = GetPlayerPropertyCount(Player.PlayerData.citizenid)
    if playerCount >= Config.MaxHousesPerPlayer then return false end
    
    local price = purchaseType == 'buy' and property.buy_price or property.rent_price
    if Player.PlayerData.money.cash < price then return false end
    
    -- Remove money
    Player.Functions.RemoveMoney('cash', price)
    
    -- Create ownership record
    local rentDueDate = purchaseType == 'rent' and os.date('%Y-%m-%d %H:%M:%S', os.time() + (Config.RentPaymentInterval * 24 * 60 * 60)) or nil
    
    MySQL.insert.await('INSERT INTO rsg_housing_ownership (property_id, citizenid, ownership_type, rent_due_date) VALUES (?, ?, ?, ?)', {
        propertyId,
        Player.PlayerData.citizenid,
        purchaseType == 'buy' and 'owned' or 'rented',
        rentDueDate
    })
    
    -- Give keys to owner
    MySQL.insert.await('INSERT INTO rsg_housing_keys (property_id, citizenid, key_type, granted_by) VALUES (?, ?, ?, ?)', {
        propertyId,
        Player.PlayerData.citizenid,
        'owner',
        Player.PlayerData.citizenid
    })
    
    -- Create storage for property
    CreatePropertyStorage(propertyId)
    
    -- Log the purchase
    LogPropertyAction(propertyId, Player.PlayerData.citizenid, purchaseType == 'buy' and 'property_purchased' or 'property_rented', {
        price = price,
        type = purchaseType
    })
    
    -- Update player properties
    LoadPlayerProperties(Player.PlayerData.citizenid)
    
    -- Notify all clients to update this property's blip
    TriggerClientEvent('rsg_housing:client:propertyOwnershipChanged', -1, propertyId)
    
    return true
end

-- Sell property
function SellProperty(src, propertyId)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local property = GetProperty(propertyId)
    if not property then return false end
    
    local ownership = GetPropertyOwnership(propertyId)
    if not ownership or ownership.citizenid ~= Player.PlayerData.citizenid then return false end
    
    -- Calculate sell price (80% of buy price)
    local sellPrice = math.floor(property.buy_price * 0.8)
    
    -- Give money back
    Player.Functions.AddMoney('cash', sellPrice)
    
    -- Remove ownership
    MySQL.query.await('DELETE FROM rsg_housing_ownership WHERE property_id = ?', {propertyId})
    
    -- Remove all keys
    MySQL.query.await('DELETE FROM rsg_housing_keys WHERE property_id = ?', {propertyId})
    
    -- Remove furniture
    MySQL.query.await('DELETE FROM rsg_housing_furniture WHERE property_id = ?', {propertyId})
    
    -- Log the sale
    LogPropertyAction(propertyId, Player.PlayerData.citizenid, 'property_sold', {
        price = sellPrice
    })
    
    -- Update player properties
    LoadPlayerProperties(Player.PlayerData.citizenid)
    
    -- Notify all clients to update this property's blip
    TriggerClientEvent('rsg_housing:client:propertyOwnershipChanged', -1, propertyId)
    
    return true, sellPrice
end

-- Pay rent
function PayRent(src, propertyId)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local property = GetProperty(propertyId)
    if not property then return false end
    
    local ownership = GetPropertyOwnership(propertyId)
    if not ownership or ownership.citizenid ~= Player.PlayerData.citizenid or ownership.ownership_type ~= 'rented' then return false end
    
    if Player.PlayerData.money.cash < property.rent_price then return false end
    
    -- Remove money
    Player.Functions.RemoveMoney('cash', property.rent_price)
    
    -- Update rent due date
    local newRentDue = os.date('%Y-%m-%d %H:%M:%S', os.time() + (Config.RentPaymentInterval * 24 * 60 * 60))
    MySQL.query.await('UPDATE rsg_housing_ownership SET rent_due_date = ?, rent_paid = 1 WHERE property_id = ?', {newRentDue, propertyId})
    
    -- Log the payment
    LogPropertyAction(propertyId, Player.PlayerData.citizenid, 'rent_paid', {
        amount = property.rent_price
    })
    
    return true
end

-- Give keys to player
function GiveKeys(src, propertyId, targetId, keyType)
    local Player = RSGCore.Functions.GetPlayer(src)
    local Target = RSGCore.Functions.GetPlayer(targetId)
    if not Player or not Target then return false end
    
    local ownership = GetPropertyOwnership(propertyId)
    if not ownership or ownership.citizenid ~= Player.PlayerData.citizenid then return false end
    
    -- Check if target already has keys
    if PlayerHasKeys(Target.PlayerData.citizenid, propertyId) then return false end
    
    -- Insert keys
    MySQL.insert.await('INSERT INTO rsg_housing_keys (property_id, citizenid, key_type, granted_by) VALUES (?, ?, ?, ?)', {
        propertyId,
        Target.PlayerData.citizenid,
        keyType or 'temporary',
        Player.PlayerData.citizenid
    })
    
    -- Log the action
    LogPropertyAction(propertyId, Player.PlayerData.citizenid, 'keys_given', {
        target = Target.PlayerData.citizenid,
        key_type = keyType or 'temporary'
    })
    
    return true
end

-- Remove keys from player
function RemoveKeys(src, propertyId, targetId)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    local ownership = GetPropertyOwnership(propertyId)
    if not ownership or ownership.citizenid ~= Player.PlayerData.citizenid then return false end
    
    -- Remove keys
    MySQL.query.await('DELETE FROM rsg_housing_keys WHERE property_id = ? AND citizenid = ? AND key_type != ?', {propertyId, targetId, 'owner'})
    
    -- Log the action
    LogPropertyAction(propertyId, Player.PlayerData.citizenid, 'keys_removed', {
        target = targetId
    })
    
    return true
end

-- Toggle property lock
function TogglePropertyLock(src, propertyId)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    if not PlayerHasKeys(Player.PlayerData.citizenid, propertyId) then return false end
    
    local ownership = GetPropertyOwnership(propertyId)
    if not ownership then return false end
    
    local newLockState = not ownership.is_locked
    MySQL.query.await('UPDATE rsg_housing_ownership SET is_locked = ? WHERE property_id = ?', {newLockState, propertyId})
    
    -- Log the action
    LogPropertyAction(propertyId, Player.PlayerData.citizenid, newLockState and 'property_locked' or 'property_unlocked')
    
    return true, newLockState
end

-- Create property storage
function CreatePropertyStorage(propertyId)
    local property = GetProperty(propertyId)
    if not property then return end
    
    local storageId = 'property_' .. propertyId
    local maxSlots = Config.Storage.MaxSlots
    local maxWeight = Config.Storage.MaxWeight
    
    MySQL.insert.await('INSERT INTO rsg_housing_storage (property_id, storage_id, max_slots, max_weight) VALUES (?, ?, ?, ?)', {
        propertyId,
        storageId,
        maxSlots,
        maxWeight
    })
    
    -- Register stash with rsg-inventory if available
    if GetResourceState('rsg-inventory') == 'started' then
        exports['rsg-inventory']:CreateStash(storageId, 'Property Storage', maxSlots, maxWeight)
    end
end

-- Log property actions
function LogPropertyAction(propertyId, citizenid, action, details)
    MySQL.insert.await('INSERT INTO rsg_housing_logs (property_id, citizenid, action, details) VALUES (?, ?, ?, ?)', {
        propertyId,
        citizenid,
        action,
        json.encode(details or {})
    })
end

-- Rent payment thread
function StartRentPaymentThread()
    CreateThread(function()
        while true do
            Wait(60000 * 60) -- Check every hour
            
            local overdueRentals = MySQL.query.await('SELECT * FROM rsg_housing_ownership WHERE ownership_type = ? AND rent_due_date < NOW() AND rent_paid = 0', {'rented'})
            
            if overdueRentals then
                for i = 1, #overdueRentals do
                    local rental = overdueRentals[i]
                    local Player = RSGCore.Functions.GetPlayerByCitizenId(rental.citizenid)
                    
                    if Player then
                        local property = GetProperty(rental.property_id)
                        if property then
                            TriggerClientEvent('rsg_housing:client:rentDue', Player.PlayerData.source, property.label, property.rent_price)
                        end
                    end
                    
                    -- Check if eviction is needed (7 days overdue)
                    local evictionDate = os.time() - (7 * 24 * 60 * 60)
                    local rentDueTime = os.time(os.date("*t", rental.rent_due_date))
                    
                    if rentDueTime < evictionDate then
                        -- Evict player
                        MySQL.query.await('DELETE FROM rsg_housing_ownership WHERE id = ?', {rental.id})
                        MySQL.query.await('DELETE FROM rsg_housing_keys WHERE property_id = ?', {rental.property_id})
                        
                        LogPropertyAction(rental.property_id, rental.citizenid, 'evicted', {
                            reason = 'rent_overdue'
                        })
                        
                        if Player then
                            TriggerClientEvent('rsg_housing:client:evicted', Player.PlayerData.source, property.label)
                        end
                    end
                end
            end
        end
    end)
end

-- Events
RegisterNetEvent('rsg_housing:server:purchaseProperty', function(propertyId, purchaseType)
    local src = source
    local success = PurchaseProperty(src, propertyId, purchaseType)
    TriggerClientEvent('rsg_housing:client:purchaseResult', src, success, propertyId, purchaseType)
end)

RegisterNetEvent('rsg_housing:server:sellProperty', function(propertyId)
    local src = source
    local success, sellPrice = SellProperty(src, propertyId)
    TriggerClientEvent('rsg_housing:client:sellResult', src, success, sellPrice)
end)

RegisterNetEvent('rsg_housing:server:payRent', function(propertyId)
    local src = source
    local success = PayRent(src, propertyId)
    TriggerClientEvent('rsg_housing:client:payRentResult', src, success)
end)

RegisterNetEvent('rsg_housing:server:giveKeys', function(propertyId, targetId, keyType)
    local src = source
    local success = GiveKeys(src, propertyId, targetId, keyType)
    TriggerClientEvent('rsg_housing:client:giveKeysResult', src, success)
end)

RegisterNetEvent('rsg_housing:server:removeKeys', function(propertyId, targetId)
    local src = source
    local success = RemoveKeys(src, propertyId, targetId)
    TriggerClientEvent('rsg_housing:client:removeKeysResult', src, success)
end)

RegisterNetEvent('rsg_housing:server:toggleLock', function(propertyId)
    local src = source
    local success, lockState = TogglePropertyLock(src, propertyId)
    TriggerClientEvent('rsg_housing:client:toggleLockResult', src, success, lockState)
end)

RegisterNetEvent('rsg_housing:server:enterProperty', function(propertyId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local property = GetProperty(propertyId)
    if not property then return end
    
    local ownership = GetPropertyOwnership(propertyId)
    if ownership and ownership.is_locked and not PlayerHasKeys(Player.PlayerData.citizenid, propertyId) then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.property_locked'), 'error')
        return
    end
    
    -- Teleport player to interior
    TriggerClientEvent('rsg_housing:client:enterProperty', src, property)
end)

RegisterNetEvent('rsg_housing:server:exitProperty', function(propertyId)
    local src = source
    local property = GetProperty(propertyId)
    if not property then return end
    
    -- Teleport player back outside
    TriggerClientEvent('rsg_housing:client:exitProperty', src, property)
end)

-- Callbacks
RSGCore.Functions.CreateCallback('rsg_housing:server:getProperties', function(source, cb)
    cb(Properties)
end)

RSGCore.Functions.CreateCallback('rsg_housing:server:getProperty', function(source, cb, propertyId)
    cb(GetProperty(propertyId))
end)

RSGCore.Functions.CreateCallback('rsg_housing:server:getPropertyOwnership', function(source, cb, propertyId)
    cb(GetPropertyOwnership(propertyId))
end)

RSGCore.Functions.CreateCallback('rsg_housing:server:getPlayerProperties', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then cb({}) return end
    
    local result = MySQL.query.await('SELECT * FROM rsg_housing_ownership WHERE citizenid = ?', {Player.PlayerData.citizenid})
    cb(result or {})
end)

RSGCore.Functions.CreateCallback('rsg_housing:server:hasKeys', function(source, cb, propertyId)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then cb(false) return end
    
    cb(PlayerHasKeys(Player.PlayerData.citizenid, propertyId))
end)

-- Admin commands
RSGCore.Commands.Add('createhouse', 'Create a new house (Admin Only)', {
    {name = 'type', help = 'Property type (house/apartment/mansion/cabin)'},
    {name = 'price', help = 'Property price'}
}, true, function(source, args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    if not RSGCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('RSGCore:Notify', src, 'You do not have permission to use this command', 'error')
        return
    end
    
    TriggerClientEvent('rsg_housing:client:createHouse', src, args[1], tonumber(args[2]))
end)

RSGCore.Commands.Add('deletehouse', 'Delete a house (Admin Only)', {
    {name = 'id', help = 'Property ID'}
}, true, function(source, args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    if not RSGCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('RSGCore:Notify', src, 'You do not have permission to use this command', 'error')
        return
    end
    
    local propertyId = tonumber(args[1])
    if not propertyId then return end
    
    MySQL.query.await('DELETE FROM rsg_housing_properties WHERE id = ?', {propertyId})
    Properties[propertyId] = nil
    
    TriggerClientEvent('RSGCore:Notify', src, 'Property deleted successfully', 'success')
end)

-- Player loaded event
RegisterNetEvent('RSGCore:Server:PlayerLoaded', function(Player)
    LoadPlayerProperties(Player.PlayerData.citizenid)
end)

-- Export functions
exports('GetProperty', GetProperty)
exports('GetPropertyOwnership', GetPropertyOwnership)
exports('PlayerOwnsProperty', PlayerOwnsProperty)
exports('PlayerHasKeys', PlayerHasKeys)