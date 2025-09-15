local RSGCore = exports['rsg-core']:GetCoreObject()

-- Variables
local Properties = {}
local PropertyOwnership = {}

-- Initialize
CreateThread(function()
    LoadPropertiesFromDatabase()
    LoadOwnershipFromDatabase()
    
    -- Start daily earnings for saloons
    CreateThread(function()
        while true do
            Wait(24 * 60 * 60 * 1000) -- 24 hours
            ProcessSaloonEarnings()
        end
    end)
end)

-- Load properties from database
function LoadPropertiesFromDatabase()
    local result = MySQL.query.await('SELECT * FROM rsg_housing_properties')
    
    if result then
        for _, property in pairs(result) do
            -- Parse coordinates
            local coords = json.decode(property.coords)
            property.coords = vector3(coords.x, coords.y, coords.z)
            
            Properties[property.id] = property
        end
        
        if Config.Debug then
            print('[RSG Housing] Loaded ' .. #result .. ' properties from database')
        end
    end
end

-- Load ownership from database
function LoadOwnershipFromDatabase()
    local result = MySQL.query.await('SELECT * FROM rsg_housing_ownership')
    
    if result then
        for _, ownership in pairs(result) do
            PropertyOwnership[ownership.property_id] = ownership
            
            -- Add owner info to property
            if Properties[ownership.property_id] then
                Properties[ownership.property_id].owner = ownership.player_id
                Properties[ownership.property_id].owner_name = ownership.player_name
                Properties[ownership.property_id].ownership_type = ownership.ownership_type
                Properties[ownership.property_id].rent_due = ownership.rent_due
                Properties[ownership.property_id].rent_paid = ownership.rent_paid
            end
        end
        
        if Config.Debug then
            print('[RSG Housing] Loaded ' .. #result .. ' property ownerships from database')
        end
    end
end

-- Get properties for client
RegisterNetEvent('rsg_housing:server:loadProperties', function()
    local src = source
    local propertiesList = {}
    
    for _, property in pairs(Properties) do
        table.insert(propertiesList, property)
    end
    
    TriggerClientEvent('rsg_housing:client:loadProperties', src, propertiesList)
end)

-- Purchase property
RegisterNetEvent('rsg_housing:server:purchaseProperty', function(propertyId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local property = Properties[propertyId]
    if not property then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.property_not_exist'), 'error')
        return
    end
    
    -- Check if property is already owned
    if property.owner then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.already_owned'), 'error')
        return
    end
    
    -- Check if player has enough money
    if Player.PlayerData.money.cash < property.price then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.insufficient_funds'), 'error')
        return
    end
    
    -- Check max properties limit
    local playerProperties = GetPlayerProperties(Player.PlayerData.citizenid)
    if #playerProperties >= Config.MaxPropertiesPerPlayer then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.max_properties'), 'error')
        return
    end
    
    -- Remove money
    Player.Functions.RemoveMoney('cash', property.price, 'property-purchase')
    
    -- Add ownership to database
    MySQL.insert('INSERT INTO rsg_housing_ownership (property_id, player_id, player_name, ownership_type) VALUES (?, ?, ?, ?)', {
        propertyId,
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        'owned'
    })
    
    -- Update property data
    property.owner = Player.PlayerData.citizenid
    property.owner_name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    property.ownership_type = 'owned'
    
    PropertyOwnership[propertyId] = {
        property_id = propertyId,
        player_id = Player.PlayerData.citizenid,
        player_name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        ownership_type = 'owned'
    }
    
    -- Log the purchase
    LogPropertyAction(propertyId, Player.PlayerData.citizenid, 'purchase', 'Purchased property for $' .. property.price)
    
    -- Notify client
    TriggerClientEvent('rsg_housing:client:propertyPurchased', src, property)
    
    -- Update all clients
    local propertiesList = {}
    for _, prop in pairs(Properties) do
        table.insert(propertiesList, prop)
    end
    TriggerClientEvent('rsg_housing:client:updateBlips', -1, propertiesList)
    
    if Config.Debug then
        print('[RSG Housing] Property ' .. propertyId .. ' purchased by ' .. Player.PlayerData.citizenid)
    end
end)

-- Rent property
RegisterNetEvent('rsg_housing:server:rentProperty', function(propertyId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local property = Properties[propertyId]
    if not property then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.property_not_exist'), 'error')
        return
    end
    
    -- Check if property is already owned/rented
    if property.owner then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.already_owned'), 'error')
        return
    end
    
    -- Check if property can be rented
    if property.rent <= 0 or not Config.PropertyTypes[property.type].canRent then
        TriggerClientEvent('RSGCore:Notify', src, 'This property cannot be rented', 'error')
        return
    end
    
    -- Check if player has enough money
    if Player.PlayerData.money.cash < property.rent then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.insufficient_funds'), 'error')
        return
    end
    
    -- Remove money
    Player.Functions.RemoveMoney('cash', property.rent, 'property-rent')
    
    -- Calculate rent due date
    local rentDue = os.date('%Y-%m-%d %H:%M:%S', os.time() + (Config.RentPaymentInterval * 24 * 60 * 60))
    
    -- Add ownership to database
    MySQL.insert('INSERT INTO rsg_housing_ownership (property_id, player_id, player_name, ownership_type, rent_due) VALUES (?, ?, ?, ?, ?)', {
        propertyId,
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        'rented',
        rentDue
    })
    
    -- Update property data
    property.owner = Player.PlayerData.citizenid
    property.owner_name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname
    property.ownership_type = 'rented'
    property.rent_due = rentDue
    property.rent_paid = true
    
    PropertyOwnership[propertyId] = {
        property_id = propertyId,
        player_id = Player.PlayerData.citizenid,
        player_name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        ownership_type = 'rented',
        rent_due = rentDue,
        rent_paid = true
    }
    
    -- Log the rental
    LogPropertyAction(propertyId, Player.PlayerData.citizenid, 'rent', 'Rented property for $' .. property.rent)
    
    -- Notify client
    TriggerClientEvent('rsg_housing:client:propertyRented', src, property)
    
    -- Update all clients
    local propertiesList = {}
    for _, prop in pairs(Properties) do
        table.insert(propertiesList, prop)
    end
    TriggerClientEvent('rsg_housing:client:updateBlips', -1, propertiesList)
    
    if Config.Debug then
        print('[RSG Housing] Property ' .. propertyId .. ' rented by ' .. Player.PlayerData.citizenid)
    end
end)

-- Sell property
RegisterNetEvent('rsg_housing:server:sellProperty', function(propertyId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local property = Properties[propertyId]
    if not property then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.property_not_exist'), 'error')
        return
    end
    
    -- Check if player owns the property
    if not property.owner or property.owner ~= Player.PlayerData.citizenid then
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.not_owner'), 'error')
        return
    end
    
    -- Calculate sale price (80% of original price)
    local salePrice = math.floor(property.price * 0.8)
    
    -- Add money to player
    Player.Functions.AddMoney('cash', salePrice, 'property-sale')
    
    -- Remove ownership from database
    MySQL.execute('DELETE FROM rsg_housing_ownership WHERE property_id = ?', { propertyId })
    MySQL.execute('DELETE FROM rsg_housing_keys WHERE property_id = ?', { propertyId })
    MySQL.execute('DELETE FROM rsg_housing_storage WHERE property_id = ?', { propertyId })
    
    -- Update property data
    property.owner = nil
    property.owner_name = nil
    property.ownership_type = nil
    property.rent_due = nil
    property.rent_paid = nil
    
    PropertyOwnership[propertyId] = nil
    
    -- Log the sale
    LogPropertyAction(propertyId, Player.PlayerData.citizenid, 'sell', 'Sold property for $' .. salePrice)
    
    -- Notify client
    TriggerClientEvent('rsg_housing:client:propertySold', src, salePrice)
    
    -- Update all clients
    local propertiesList = {}
    for _, prop in pairs(Properties) do
        table.insert(propertiesList, prop)
    end
    TriggerClientEvent('rsg_housing:client:updateBlips', -1, propertiesList)
    
    if Config.Debug then
        print('[RSG Housing] Property ' .. propertyId .. ' sold by ' .. Player.PlayerData.citizenid)
    end
end)

-- Get player properties
function GetPlayerProperties(citizenid)
    local playerProperties = {}
    
    for _, property in pairs(Properties) do
        if property.owner == citizenid then
            table.insert(playerProperties, property)
        end
    end
    
    return playerProperties
end

-- Log property action
function LogPropertyAction(propertyId, playerId, action, details)
    MySQL.insert('INSERT INTO rsg_housing_logs (property_id, player_id, action, details) VALUES (?, ?, ?, ?)', {
        propertyId,
        playerId,
        action,
        details
    })
end

-- Process saloon earnings (daily)
function ProcessSaloonEarnings()
    for _, property in pairs(Properties) do
        if property.type == 'saloon' and property.owner then
            local baseEarnings = math.random(100, 500) -- Base daily earnings
            local earnings = math.floor(baseEarnings * Config.Economy.saloon_income_multiplier)
            
            -- Add earnings to database
            MySQL.insert('INSERT INTO rsg_housing_saloon_earnings (property_id, amount, date) VALUES (?, ?, ?)', {
                property.id,
                earnings,
                os.date('%Y-%m-%d')
            })
            
            if Config.Debug then
                print('[RSG Housing] Generated $' .. earnings .. ' for saloon ' .. property.id)
            end
        end
    end
end

-- Player disconnect cleanup
RegisterNetEvent('RSGCore:Server:OnPlayerUnload', function(src)
    -- Any cleanup needed when player disconnects
end)