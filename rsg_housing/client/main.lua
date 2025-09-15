local RSGCore = exports['rsg-core']:GetCoreObject()

-- Variables
local PlayerData = {}
local CurrentProperty = nil
local InsideProperty = false

-- Global variables for other client files
PropertyBlips = {}
PropertyMarkers = {}
NearbyProperties = {}

-- Initialize
CreateThread(function()
    while RSGCore.Functions.GetPlayerData().citizenid == nil do
        Wait(10)
    end
    PlayerData = RSGCore.Functions.GetPlayerData()
    TriggerServerEvent('rsg_housing:server:loadProperties')
end)

-- Events
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    PlayerData = RSGCore.Functions.GetPlayerData()
    TriggerServerEvent('rsg_housing:server:loadProperties')
end)

RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    RemoveAllBlips()
    RemoveAllMarkers()
end)

-- Property Loading
RegisterNetEvent('rsg_housing:client:loadProperties', function(properties)
    if Config.Debug then
        print('[RSG Housing] Loading ' .. #properties .. ' properties')
    end
    
    RemoveAllBlips()
    RemoveAllMarkers()
    
    for _, property in pairs(properties) do
        CreatePropertyBlip(property)
    end
    
    PropertyMarkers = properties
end)

-- Property Interaction
function ShowPropertyMenu(property)
    local menuOptions = {}
    
    if property.owner then
        -- Property is owned
        if property.owner == PlayerData.citizenid then
            -- Player owns this property
            table.insert(menuOptions, {
                title = Lang:t('menu.enter_property'),
                description = Lang:t('info.enter_property', property.label),
                icon = 'fas fa-door-open',
                event = 'rsg_housing:client:enterProperty',
                args = property
            })
            
            table.insert(menuOptions, {
                title = Lang:t('menu.manage_property'),
                description = 'Manage your property settings',
                icon = 'fas fa-cog',
                event = 'rsg_housing:client:manageProperty',
                args = property
            })
            
            if property.type == 'saloon' then
                table.insert(menuOptions, {
                    title = Lang:t('menu.manage_saloon'),
                    description = 'Manage your saloon business',
                    icon = 'fas fa-glass-whiskey',
                    event = 'rsg_housing:client:manageSaloon',
                    args = property
                })
            end
        else
            -- Someone else owns this property
            table.insert(menuOptions, {
                title = Lang:t('menu.ring_doorbell'),
                description = 'Ring the doorbell',
                icon = 'fas fa-bell',
                event = 'rsg_housing:client:ringDoorbell',
                args = property
            })
        end
    else
        -- Property is available
        table.insert(menuOptions, {
            title = Lang:t('menu.purchase_property'),
            description = Lang:t('info.for_sale', property.price),
            icon = 'fas fa-dollar-sign',
            event = 'rsg_housing:client:purchaseProperty',
            args = property
        })
        
        if property.rent > 0 and Config.PropertyTypes[property.type].canRent then
            table.insert(menuOptions, {
                title = Lang:t('menu.rent_property'),
                description = Lang:t('info.for_rent', property.rent),
                icon = 'fas fa-key',
                event = 'rsg_housing:client:rentProperty',
                args = property
            })
        end
        
        table.insert(menuOptions, {
            title = Lang:t('menu.property_info'),
            description = 'View property details',
            icon = 'fas fa-info-circle',
            event = 'rsg_housing:client:viewPropertyInfo',
            args = property
        })
    end
    
    exports['rsg-menu']:openMenu(menuOptions)
end

-- Property Purchase
RegisterNetEvent('rsg_housing:client:purchaseProperty', function(property)
    local input = exports['rsg-input']:ShowInput({
        header = Lang:t('menu.purchase_property'),
        submitText = 'Purchase',
        inputs = {
            {
                text = 'Confirm Purchase',
                name = 'confirm',
                type = 'select',
                options = {
                    { value = 'yes', text = 'Yes, purchase for $' .. property.price },
                    { value = 'no', text = 'No, cancel' }
                }
            }
        }
    })
    
    if input and input.confirm == 'yes' then
        TriggerServerEvent('rsg_housing:server:purchaseProperty', property.id)
    end
end)

-- Property Rental
RegisterNetEvent('rsg_housing:client:rentProperty', function(property)
    local input = exports['rsg-input']:ShowInput({
        header = Lang:t('menu.rent_property'),
        submitText = 'Rent',
        inputs = {
            {
                text = 'Confirm Rental',
                name = 'confirm',
                type = 'select',
                options = {
                    { value = 'yes', text = 'Yes, rent for $' .. property.rent .. '/week' },
                    { value = 'no', text = 'No, cancel' }
                }
            }
        }
    })
    
    if input and input.confirm == 'yes' then
        TriggerServerEvent('rsg_housing:server:rentProperty', property.id)
    end
end)

-- Property Management
RegisterNetEvent('rsg_housing:client:manageProperty', function(property)
    local menuOptions = {
        {
            title = 'Lock/Unlock Property',
            description = 'Toggle property lock',
            icon = 'fas fa-lock',
            event = 'rsg_housing:client:toggleLock',
            args = property
        },
        {
            title = 'Give Keys',
            description = 'Give keys to another player',
            icon = 'fas fa-key',
            event = 'rsg_housing:client:giveKeys',
            args = property
        },
        {
            title = 'Remove Keys',
            description = 'Remove keys from a player',
            icon = 'fas fa-key',
            event = 'rsg_housing:client:removeKeys',
            args = property
        },
        {
            title = 'Sell Property',
            description = 'Sell this property',
            icon = 'fas fa-dollar-sign',
            event = 'rsg_housing:client:sellProperty',
            args = property
        }
    }
    
    exports['rsg-menu']:openMenu(menuOptions)
end)

-- Saloon Management
RegisterNetEvent('rsg_housing:client:manageSaloon', function(property)
    local menuOptions = {
        {
            title = 'View Earnings',
            description = 'Check saloon earnings',
            icon = 'fas fa-chart-line',
            event = 'rsg_housing:client:viewEarnings',
            args = property
        },
        {
            title = 'Collect Earnings',
            description = 'Collect daily earnings',
            icon = 'fas fa-money-bill',
            event = 'rsg_housing:client:collectEarnings',
            args = property
        },
        {
            title = 'Manage Staff',
            description = 'Hire or fire staff',
            icon = 'fas fa-users',
            event = 'rsg_housing:client:manageStaff',
            args = property
        }
    }
    
    exports['rsg-menu']:openMenu(menuOptions)
end)

-- Property Entry/Exit
RegisterNetEvent('rsg_housing:client:enterProperty', function(property)
    if Config.Debug then
        print('[RSG Housing] Entering property: ' .. property.id)
    end
    
    DoScreenFadeOut(500)
    Wait(500)
    
    local shell = Config.Shells[property.shell]
    if shell then
        local interiorCoords = vector3(
            property.coords.x + shell.coords.x,
            property.coords.y + shell.coords.y,
            property.coords.z + shell.coords.z
        )
        
        SetEntityCoords(PlayerPedId(), interiorCoords.x, interiorCoords.y, interiorCoords.z)
        SetEntityHeading(PlayerPedId(), shell.heading)
    end
    
    Wait(500)
    DoScreenFadeIn(500)
    
    CurrentProperty = property
    InsideProperty = true
    
    RSGCore.Functions.Notify(Lang:t('success.property_entered'), 'success')
end)

RegisterNetEvent('rsg_housing:client:exitProperty', function()
    if not InsideProperty or not CurrentProperty then return end
    
    DoScreenFadeOut(500)
    Wait(500)
    
    SetEntityCoords(PlayerPedId(), CurrentProperty.coords.x, CurrentProperty.coords.y, CurrentProperty.coords.z)
    SetEntityHeading(PlayerPedId(), CurrentProperty.heading)
    
    Wait(500)
    DoScreenFadeIn(500)
    
    CurrentProperty = nil
    InsideProperty = false
    
    RSGCore.Functions.Notify(Lang:t('success.property_exited'), 'success')
end)

-- Property Info
RegisterNetEvent('rsg_housing:client:viewPropertyInfo', function(property)
    local propertyType = Config.PropertyTypes[property.type]
    local info = {
        {
            title = 'Property Information',
            description = property.label,
            icon = 'fas fa-home'
        },
        {
            title = 'Type',
            description = propertyType.label,
            icon = 'fas fa-tag'
        },
        {
            title = 'Price',
            description = '$' .. property.price,
            icon = 'fas fa-dollar-sign'
        }
    }
    
    if property.rent > 0 then
        table.insert(info, {
            title = 'Weekly Rent',
            description = '$' .. property.rent,
            icon = 'fas fa-calendar-week'
        })
    end
    
    table.insert(info, {
        title = 'Storage',
        description = propertyType.storage .. ' slots',
        icon = 'fas fa-box'
    })
    
    if propertyType.wardrobe then
        table.insert(info, {
            title = 'Wardrobe',
            description = 'Available',
            icon = 'fas fa-tshirt'
        })
    end
    
    if property.garage then
        table.insert(info, {
            title = 'Garage',
            description = 'Available',
            icon = 'fas fa-car'
        })
    end
    
    table.insert(info, {
        title = 'Description',
        description = property.description or 'No description available',
        icon = 'fas fa-info'
    })
    
    exports['rsg-menu']:openMenu(info)
end)

-- Utility Functions
function RemoveAllBlips()
    if PropertyBlips and next(PropertyBlips) then
        for _, blip in pairs(PropertyBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
    end
    PropertyBlips = {}
end

function RemoveAllMarkers()
    PropertyMarkers = {}
end

-- Key Bindings
RegisterCommand('exitproperty', function()
    if InsideProperty then
        TriggerEvent('rsg_housing:client:exitProperty')
    end
end, false)

-- Register command for exiting property
RegisterCommand('exitproperty', function()
    if InsideProperty and CurrentProperty then
        ExitProperty()
    end
end, false)

-- Key mapping for F7 (RedM compatible)
CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0, 0x3C0A40F2) then -- F7 key for RedM
            if InsideProperty and CurrentProperty then
                ExitProperty()
            end
        end
    end
end)