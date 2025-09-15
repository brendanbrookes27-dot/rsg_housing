local RSGCore = exports['rsg-core']:GetCoreObject()

-- Furniture management system
local PlacedFurniture = {}
local FurniturePlacementMode = {}

-- Load placed furniture for property
function LoadPropertyFurniture(propertyId)
    local result = MySQL.query.await('SELECT * FROM rsg_housing_furniture WHERE property_id = ?', {propertyId})
    if result then
        PlacedFurniture[propertyId] = {}
        for i = 1, #result do
            local furniture = result[i]
            furniture.coords = json.decode(furniture.coords)
            furniture.metadata = furniture.metadata and json.decode(furniture.metadata) or {}
            PlacedFurniture[propertyId][furniture.id] = furniture
        end
    end
end

-- Get furniture config by ID
function GetFurnitureConfig(furnitureId)
    for category, data in pairs(Config.Furniture.Categories) do
        if data.items[furnitureId] then
            return data.items[furnitureId]
        end
    end
    return nil
end

-- Purchase furniture
function PurchaseFurniture(src, propertyId, furnitureId)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    -- Check if player has access to property
    if not exports['rsg_housing']:PlayerHasKeys(Player.PlayerData.citizenid, propertyId) then
        return false
    end
    
    local furnitureConfig = GetFurnitureConfig(furnitureId)
    if not furnitureConfig then return false end
    
    -- Check if player has enough money
    if Player.PlayerData.money.cash < furnitureConfig.price then
        return false
    end
    
    -- Check furniture limit
    local furnitureCount = GetPropertyFurnitureCount(propertyId)
    if furnitureCount >= Config.Furniture.MaxItems then
        return false
    end
    
    -- Remove money
    Player.Functions.RemoveMoney('cash', furnitureConfig.price)
    
    -- Add to player's furniture inventory (temporary storage until placed)
    local furnitureData = {
        id = furnitureId,
        label = furnitureConfig.label,
        model = furnitureConfig.model,
        price = furnitureConfig.price,
        purchased_by = Player.PlayerData.citizenid,
        purchased_at = os.time()
    }
    
    -- Store in temporary furniture storage
    if not PlacedFurniture[propertyId] then
        PlacedFurniture[propertyId] = {}
    end
    
    -- Generate unique furniture instance ID
    local instanceId = 'furniture_' .. propertyId .. '_' .. furnitureId .. '_' .. os.time()
    PlacedFurniture[propertyId][instanceId] = furnitureData
    
    -- Log the purchase
    exports['rsg_housing']:LogPropertyAction(propertyId, Player.PlayerData.citizenid, 'furniture_purchased', {
        furniture_id = furnitureId,
        price = furnitureConfig.price
    })
    
    return true, instanceId
end

-- Place furniture
function PlaceFurniture(src, propertyId, instanceId, coords, heading)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    -- Check if player has access to property
    if not exports['rsg_housing']:PlayerHasKeys(Player.PlayerData.citizenid, propertyId) then
        return false
    end
    
    -- Check if furniture instance exists
    if not PlacedFurniture[propertyId] or not PlacedFurniture[propertyId][instanceId] then
        return false
    end
    
    local furniture = PlacedFurniture[propertyId][instanceId]
    
    -- Insert into database
    local furnitureDbId = MySQL.insert.await('INSERT INTO rsg_housing_furniture (property_id, citizenid, furniture_type, furniture_id, model, coords, heading, metadata) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        propertyId,
        Player.PlayerData.citizenid,
        'furniture',
        furniture.id,
        furniture.model,
        json.encode(coords),
        heading,
        json.encode(furniture)
    })
    
    if furnitureDbId then
        -- Update furniture data with placement info
        furniture.coords = coords
        furniture.heading = heading
        furniture.placed = true
        furniture.db_id = furnitureDbId
        
        -- Spawn furniture object for all players in property
        SpawnFurnitureForProperty(propertyId, instanceId, furniture)
        
        -- Log the placement
        exports['rsg_housing']:LogPropertyAction(propertyId, Player.PlayerData.citizenid, 'furniture_placed', {
            furniture_id = furniture.id,
            coords = coords,
            heading = heading
        })
        
        return true
    end
    
    return false
end

-- Remove furniture
function RemoveFurniture(src, propertyId, instanceId)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    -- Check if player has access to property
    if not exports['rsg_housing']:PlayerHasKeys(Player.PlayerData.citizenid, propertyId) then
        return false
    end
    
    -- Check if furniture exists
    if not PlacedFurniture[propertyId] or not PlacedFurniture[propertyId][instanceId] then
        return false
    end
    
    local furniture = PlacedFurniture[propertyId][instanceId]
    
    -- Remove from database
    if furniture.db_id then
        MySQL.query.await('DELETE FROM rsg_housing_furniture WHERE id = ?', {furniture.db_id})
    end
    
    -- Remove furniture object for all players
    RemoveFurnitureForProperty(propertyId, instanceId)
    
    -- Remove from memory
    PlacedFurniture[propertyId][instanceId] = nil
    
    -- Log the removal
    exports['rsg_housing']:LogPropertyAction(propertyId, Player.PlayerData.citizenid, 'furniture_removed', {
        furniture_id = furniture.id
    })
    
    return true
end

-- Get property furniture count
function GetPropertyFurnitureCount(propertyId)
    local result = MySQL.query.await('SELECT COUNT(*) as count FROM rsg_housing_furniture WHERE property_id = ?', {propertyId})
    return result and result[1].count or 0
end

-- Spawn furniture object for property
function SpawnFurnitureForProperty(propertyId, instanceId, furniture)
    -- Get all players in the property
    local playersInProperty = GetPlayersInProperty(propertyId)
    
    for _, playerId in ipairs(playersInProperty) do
        TriggerClientEvent('rsg_housing:client:spawnFurniture', playerId, propertyId, instanceId, furniture)
    end
end

-- Remove furniture object for property
function RemoveFurnitureForProperty(propertyId, instanceId)
    -- Get all players in the property
    local playersInProperty = GetPlayersInProperty(propertyId)
    
    for _, playerId in ipairs(playersInProperty) do
        TriggerClientEvent('rsg_housing:client:removeFurniture', playerId, propertyId, instanceId)
    end
end

-- Get players currently in property
function GetPlayersInProperty(propertyId)
    local players = {}
    local allPlayers = RSGCore.Functions.GetPlayers()
    
    for _, playerId in ipairs(allPlayers) do
        local Player = RSGCore.Functions.GetPlayer(playerId)
        if Player and Player.PlayerData.metadata.currentProperty == propertyId then
            table.insert(players, playerId)
        end
    end
    
    return players
end

-- Toggle furniture placement mode
function ToggleFurniturePlacementMode(src, propertyId, enabled)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return false end
    
    -- Check if player has access to property
    if not exports['rsg_housing']:PlayerHasKeys(Player.PlayerData.citizenid, propertyId) then
        return false
    end
    
    FurniturePlacementMode[src] = enabled and propertyId or nil
    
    TriggerClientEvent('rsg_housing:client:toggleFurniturePlacementMode', src, enabled, propertyId)
    
    return true
end

-- Get available furniture for placement
function GetAvailableFurniture(src, propertyId)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return {} end
    
    if not PlacedFurniture[propertyId] then
        return {}
    end
    
    local availableFurniture = {}
    for instanceId, furniture in pairs(PlacedFurniture[propertyId]) do
        if not furniture.placed and furniture.purchased_by == Player.PlayerData.citizenid then
            table.insert(availableFurniture, {
                instanceId = instanceId,
                furniture = furniture
            })
        end
    end
    
    return availableFurniture
end

-- Events
RegisterNetEvent('rsg_housing:server:purchaseFurniture', function(propertyId, furnitureId)
    local src = source
    local success, instanceId = PurchaseFurniture(src, propertyId, furnitureId)
    TriggerClientEvent('rsg_housing:client:purchaseFurnitureResult', src, success, instanceId)
end)

RegisterNetEvent('rsg_housing:server:placeFurniture', function(propertyId, instanceId, coords, heading)
    local src = source
    local success = PlaceFurniture(src, propertyId, instanceId, coords, heading)
    TriggerClientEvent('rsg_housing:client:placeFurnitureResult', src, success)
end)

RegisterNetEvent('rsg_housing:server:removeFurniture', function(propertyId, instanceId)
    local src = source
    local success = RemoveFurniture(src, propertyId, instanceId)
    TriggerClientEvent('rsg_housing:client:removeFurnitureResult', src, success)
end)

RegisterNetEvent('rsg_housing:server:toggleFurniturePlacementMode', function(propertyId, enabled)
    local src = source
    ToggleFurniturePlacementMode(src, propertyId, enabled)
end)

-- Callbacks
RSGCore.Functions.CreateCallback('rsg_housing:server:getPropertyFurniture', function(source, cb, propertyId)
    LoadPropertyFurniture(propertyId)
    cb(PlacedFurniture[propertyId] or {})
end)

RSGCore.Functions.CreateCallback('rsg_housing:server:getAvailableFurniture', function(source, cb, propertyId)
    cb(GetAvailableFurniture(source, propertyId))
end)

RSGCore.Functions.CreateCallback('rsg_housing:server:getFurnitureConfig', function(source, cb)
    cb(Config.Furniture.Categories)
end)

-- Initialize furniture system
CreateThread(function()
    -- Load all property furniture on startup
    local properties = exports['rsg_housing']:GetProperty()
    if properties then
        for propertyId, _ in pairs(properties) do
            LoadPropertyFurniture(propertyId)
        end
    end
end)

-- Export functions
exports('PurchaseFurniture', PurchaseFurniture)
exports('PlaceFurniture', PlaceFurniture)
exports('RemoveFurniture', RemoveFurniture)
exports('GetPropertyFurnitureCount', GetPropertyFurnitureCount)