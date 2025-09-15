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
                description = Lang:t('info.enter_property', {property.label}),
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
            description = Lang:t('info.for_sale', {property.price}),
            icon = 'fas fa-dollar-sign',
            event = 'rsg_housing:client:purchaseProperty',
            args = property
        })
        
        if property.rent > 0 and Config.PropertyTypes[property.type].canRent then
            table.insert(menuOptions, {
                title = Lang:t('menu.rent_property'),
                description = Lang:t('info.for_rent', {property.rent}),
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
    
    -- Check if property uses MLO or shell
    if property.mlo and property.mlo ~= '' then
        -- MLO Interior
        local mloConfig = Config.MLOs[property.mlo]
        if mloConfig then
            local interiorCoords = vector3(
                property.coords.x + mloConfig.coords.x,
                property.coords.y + mloConfig.coords.y,
                property.coords.z + mloConfig.coords.z
            )
            
            SetEntityCoords(PlayerPedId(), interiorCoords.x, interiorCoords.y, interiorCoords.z)
            SetEntityHeading(PlayerPedId(), mloConfig.heading)
        else
            -- MLO not configured, use property coordinates
            SetEntityCoords(PlayerPedId(), property.coords.x, property.coords.y, property.coords.z)
            SetEntityHeading(PlayerPedId(), property.heading)
        end
    else
        -- Shell Interior (fallback)
        local shell = Config.Shells[property.shell or 'basic_house']
        if shell then
            local interiorCoords = vector3(
                property.coords.x + shell.coords.x,
                property.coords.y + shell.coords.y,
                property.coords.z + shell.coords.z
            )
            
            SetEntityCoords(PlayerPedId(), interiorCoords.x, interiorCoords.y, interiorCoords.z)
            SetEntityHeading(PlayerPedId(), shell.heading)
        end
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

-- House Creation System
local creatingHouse = false
local houseCreationData = {}

-- Start house creation process
RegisterNetEvent('rsg_housing:client:startHouseCreation', function()
    creatingHouse = true
    houseCreationData = {}
    
    RSGCore.Functions.Notify(Lang:t('info.house_creation_started'), 'primary')
    RSGCore.Functions.Notify(Lang:t('info.house_creation_instructions'), 'primary')
    
    -- Start creation thread
    CreateThread(function()
        while creatingHouse do
            Wait(0)
            
            -- Draw instructions
            local str = CreateVarString(10, "LITERAL_STRING", Lang:t('info.house_creation_controls'))
            SetTextScale(0.35, 0.35)
            SetTextColor(255, 255, 255, 255)
            SetTextCentre(true)
            DisplayText(str, 0.5, 0.05)
            
            -- Handle input
            if IsControlJustPressed(0, 0xC7B5340A) then -- Enter key
                SetHouseLocation()
            elseif IsControlJustPressed(0, 0x156F7119) then -- Escape key
                CancelHouseCreation()
            end
        end
    end)
end)

-- Set house location
function SetHouseLocation()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    houseCreationData.coords = coords
    houseCreationData.heading = heading
    
    RSGCore.Functions.Notify(Lang:t('success.location_set'), 'success')
    
    -- Open house configuration menu
    OpenHouseConfigMenu()
end

-- Open house configuration menu
function OpenHouseConfigMenu()
    local menu = {
        {
            header = Lang:t('menu.house_config_title'),
            isMenuHeader = true
        },
        {
            header = Lang:t('menu.set_label'),
            txt = Lang:t('menu.set_label_desc'),
            params = {
                event = 'rsg_housing:client:setHouseLabel',
                args = {}
            }
        },
        {
            header = Lang:t('menu.set_type'),
            txt = Lang:t('menu.set_type_desc'),
            params = {
                event = 'rsg_housing:client:setHouseType',
                args = {}
            }
        },
        {
            header = Lang:t('menu.set_price'),
            txt = Lang:t('menu.set_price_desc'),
            params = {
                event = 'rsg_housing:client:setHousePrice',
                args = {}
            }
        },
        {
            header = Lang:t('menu.set_rent'),
            txt = Lang:t('menu.set_rent_desc'),
            params = {
                event = 'rsg_housing:client:setHouseRent',
                args = {}
            }
        },
        {
            header = Lang:t('menu.set_mlo'),
            txt = Lang:t('menu.set_mlo_desc'),
            params = {
                event = 'rsg_housing:client:setHouseMLO',
                args = {}
            }
        },
        {
            header = Lang:t('menu.create_house'),
            txt = Lang:t('menu.create_house_desc'),
            params = {
                event = 'rsg_housing:client:confirmHouseCreation',
                args = {}
            }
        },
        {
            header = Lang:t('menu.cancel'),
            txt = Lang:t('menu.cancel_desc'),
            params = {
                event = 'rsg_housing:client:cancelHouseCreation',
                args = {}
            }
        }
    }
    
    exports['rsg-menu']:openMenu(menu)
end

-- Set house label
RegisterNetEvent('rsg_housing:client:setHouseLabel', function()
    local input = exports['rsg-input']:ShowInput({
        header = Lang:t('input.house_label'),
        submitText = Lang:t('input.submit'),
        inputs = {
            {
                type = 'text',
                isRequired = true,
                name = 'label',
                text = Lang:t('input.house_label_placeholder')
            }
        }
    })
    
    if input and input.label then
        houseCreationData.label = input.label
        RSGCore.Functions.Notify(Lang:t('success.label_set', {input.label}), 'success')
        OpenHouseConfigMenu()
    end
end)

-- Set house type
RegisterNetEvent('rsg_housing:client:setHouseType', function()
    local typeMenu = {
        {
            header = Lang:t('menu.select_house_type'),
            isMenuHeader = true
        }
    }
    
    for typeKey, typeData in pairs(Config.PropertyTypes) do
        table.insert(typeMenu, {
            header = typeData.label,
            txt = typeData.description,
            params = {
                event = 'rsg_housing:client:confirmHouseType',
                args = {type = typeKey}
            }
        })
    end
    
    table.insert(typeMenu, {
        header = Lang:t('menu.back'),
        params = {
            event = 'rsg_housing:client:openHouseConfigMenu',
            args = {}
        }
    })
    
    exports['rsg-menu']:openMenu(typeMenu)
end)

-- Confirm house type
RegisterNetEvent('rsg_housing:client:confirmHouseType', function(data)
    houseCreationData.type = data.type
    RSGCore.Functions.Notify(Lang:t('success.type_set', {Config.PropertyTypes[data.type].label}), 'success')
    OpenHouseConfigMenu()
end)

-- Set house price
RegisterNetEvent('rsg_housing:client:setHousePrice', function()
    local input = exports['rsg-input']:ShowInput({
        header = Lang:t('input.house_price'),
        submitText = Lang:t('input.submit'),
        inputs = {
            {
                type = 'number',
                isRequired = true,
                name = 'price',
                text = Lang:t('input.house_price_placeholder')
            }
        }
    })
    
    if input and input.price then
        houseCreationData.price = tonumber(input.price)
        RSGCore.Functions.Notify(Lang:t('success.price_set', {input.price}), 'success')
        OpenHouseConfigMenu()
    end
end)

-- Set house rent
RegisterNetEvent('rsg_housing:client:setHouseRent', function()
    local input = exports['rsg-input']:ShowInput({
        header = Lang:t('input.house_rent'),
        submitText = Lang:t('input.submit'),
        inputs = {
            {
                type = 'number',
                isRequired = false,
                name = 'rent',
                text = Lang:t('input.house_rent_placeholder')
            }
        }
    })
    
    if input then
        houseCreationData.rent = tonumber(input.rent) or 0
        RSGCore.Functions.Notify(Lang:t('success.rent_set', {input.rent or '0'}), 'success')
        OpenHouseConfigMenu()
    end
end)

-- Set house MLO
RegisterNetEvent('rsg_housing:client:setHouseMLO', function()
    local input = exports['rsg-input']:ShowInput({
        header = Lang:t('input.house_mlo'),
        submitText = Lang:t('input.submit'),
        inputs = {
            {
                type = 'text',
                isRequired = false,
                name = 'mlo',
                text = Lang:t('input.house_mlo_placeholder')
            }
        }
    })
    
    if input then
        houseCreationData.mlo = input.mlo
        if input.mlo and input.mlo ~= '' then
            RSGCore.Functions.Notify(Lang:t('success.mlo_set', {input.mlo}), 'success')
        else
            RSGCore.Functions.Notify(Lang:t('success.mlo_cleared'), 'success')
        end
        OpenHouseConfigMenu()
    end
end)

-- Confirm house creation
RegisterNetEvent('rsg_housing:client:confirmHouseCreation', function()
    if not houseCreationData.coords then
        RSGCore.Functions.Notify(Lang:t('error.no_location_set'), 'error')
        return
    end
    
    -- Set defaults if not specified
    houseCreationData.label = houseCreationData.label or 'Custom Property'
    houseCreationData.type = houseCreationData.type or 'house'
    houseCreationData.price = houseCreationData.price or 2500
    houseCreationData.rent = houseCreationData.rent or 150
    
    -- Send to server
    TriggerServerEvent('rsg_housing:server:createHouse', houseCreationData)
    
    -- Reset creation state
    creatingHouse = false
    houseCreationData = {}
end)

-- Cancel house creation
RegisterNetEvent('rsg_housing:client:cancelHouseCreation', function()
    CancelHouseCreation()
end)

-- Open house config menu event
RegisterNetEvent('rsg_housing:client:openHouseConfigMenu', function()
    OpenHouseConfigMenu()
end)

-- Cancel house creation function
function CancelHouseCreation()
    creatingHouse = false
    houseCreationData = {}
    RSGCore.Functions.Notify(Lang:t('info.house_creation_cancelled'), 'primary')
end

-- Update properties from server
RegisterNetEvent('rsg_housing:client:updateProperties', function(properties)
    Properties = properties
    -- Refresh markers and blips
    RefreshPropertyMarkers()
    RefreshPropertyBlips()
end)

-- Refresh property markers
function RefreshPropertyMarkers()
    -- This function should trigger marker refresh
    -- The actual marker handling is in markers.lua
    TriggerEvent('rsg_housing:client:refreshMarkers')
end

-- Refresh property blips
function RefreshPropertyBlips()
    -- This function should trigger blip refresh
    -- The actual blip handling is in blips.lua
    TriggerEvent('rsg_housing:client:refreshBlips')
end