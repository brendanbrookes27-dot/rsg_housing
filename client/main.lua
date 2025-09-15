local RSGCore = exports['rsg-core']:GetCoreObject()

-- Global variables
local Properties = {}
local PlayerProperties = {}
local CurrentProperty = nil
local InsideProperty = false
local PropertyBlips = {}
local PropertyZones = {}

-- Initialize client
CreateThread(function()
    Wait(1000)
    LoadProperties()
    if Config.Debug then
        print('^2[RSG Housing]^7 Client initialized successfully')
    end
end)

-- Load properties from server
function LoadProperties()
    RSGCore.Functions.TriggerCallback('rsg_housing:server:getProperties', function(properties)
        if properties then
            Properties = properties
            if Config.Debug then
                print('^2[RSG Housing]^7 Loaded ' .. table.count(Properties) .. ' properties on client')
            end
            -- Create blips and zones after properties are loaded
            CreatePropertyBlips()
            CreatePropertyZones()
        else
            if Config.Debug then
                print('^1[RSG Housing]^7 Failed to load properties from server')
            end
        end
    end)
end

-- Create blips for all properties
function CreatePropertyBlips()
    if not Properties or table.count(Properties) == 0 then
        if Config.Debug then
            print('^3[RSG Housing]^7 No properties to create blips for')
        end
        return
    end
    
    for propertyId, property in pairs(Properties) do
        CreatePropertyBlip(property)
    end
    
    if Config.Debug then
        print('^2[RSG Housing]^7 Created blips for ' .. table.count(PropertyBlips) .. ' properties')
    end
end

-- Create individual property blip
function CreatePropertyBlip(property)
    if not property or not property.coords then
        if Config.Debug then
            print('^1[RSG Housing]^7 Invalid property data for blip creation')
        end
        return
    end
    
    -- Remove existing blip if it exists
    if PropertyBlips[property.id] then
        RemoveBlip(PropertyBlips[property.id])
        PropertyBlips[property.id] = nil
    end
    
    -- Create the blip
    local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, property.coords.x, property.coords.y, property.coords.z)
    
    if not blip or blip == 0 then
        if Config.Debug then
            print('^1[RSG Housing]^7 Failed to create blip for property ' .. property.id)
        end
        return
    end
    
    -- Store blip immediately
    PropertyBlips[property.id] = blip
    
    -- Get ownership to determine blip appearance
    RSGCore.Functions.TriggerCallback('rsg_housing:server:getPropertyOwnership', function(ownership)
        if not DoesBlipExist(blip) then
            if Config.Debug then
                print('^1[RSG Housing]^7 Blip no longer exists for property ' .. property.id)
            end
            return
        end
        
        local blipConfig = Config.HouseBlip -- Default for available properties
        
        if ownership then
            if ownership.ownership_type == 'owned' then
                blipConfig = Config.OwnedBlip
            elseif ownership.ownership_type == 'rented' then
                blipConfig = Config.RentedBlip
            end
        end
        
        -- Set blip sprite
        SetBlipSprite(blip, blipConfig.Sprite, true)
        
        -- Set blip scale
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, blipConfig.Scale)
        
        -- Set blip color
        Citizen.InvokeNative(0x662D364ABF16DE2F, blip, GetHashKey(blipConfig.Color))
        
        -- Set blip name
        local blipName = property.label or ('Property ' .. property.id)
        if ownership then
            if ownership.ownership_type == 'owned' then
                blipName = blipName .. ' (Owned)'
            elseif ownership.ownership_type == 'rented' then
                blipName = blipName .. ' (Rented)'
            end
        else
            blipName = blipName .. ' (Available)'
        end
        
        -- Set the blip name
        Citizen.InvokeNative(0x9CB1A1623062F402, blip, blipName)
        
        if Config.Debug then
            print('^2[RSG Housing]^7 Created blip for property: ' .. blipName .. ' at ' .. property.coords.x .. ', ' .. property.coords.y .. ', ' .. property.coords.z)
        end
    end, property.id)
end

-- Refresh all property blips
function RefreshPropertyBlips()
    if Config.Debug then
        print('^2[RSG Housing]^7 Refreshing property blips')
    end
    
    -- Remove all existing blips
    for propertyId, blip in pairs(PropertyBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    PropertyBlips = {}
    
    -- Recreate all blips
    CreatePropertyBlips()
end

-- Update specific property blip
function UpdatePropertyBlip(propertyId)
    local property = Properties[propertyId]
    if property then
        CreatePropertyBlip(property)
    end
end

-- Remove all property blips
function RemoveAllPropertyBlips()
    for propertyId, blip in pairs(PropertyBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    PropertyBlips = {}
end

-- Utility function to count table entries
function table.count(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

-- Create property interaction zones
function CreatePropertyZones()
    if not Properties or table.count(Properties) == 0 then
        if Config.Debug then
            print('^3[RSG Housing]^7 No properties to create zones for')
        end
        return
    end
    
    if Config.UseTarget then
        CreateTargetZones()
    else
        CreateDrawTextZones()
    end
end

-- Create target zones for properties
function CreateTargetZones()
    for propertyId, property in pairs(Properties) do
        local options = {
            {
                type = "client",
                event = "rsg_housing:client:propertyMenu",
                icon = "fas fa-home",
                label = Lang:t('target.manage_property'),
                propertyId = propertyId,
                canInteract = function()
                    return RSGCore.Functions.TriggerCallback('rsg_housing:server:hasKeys', function(hasKeys)
                        return hasKeys
                    end, propertyId)
                end
            },
            {
                type = "client",
                event = "rsg_housing:client:enterProperty",
                icon = "fas fa-door-open",
                label = Lang:t('target.enter_property'),
                propertyId = propertyId,
                canInteract = function()
                    return not InsideProperty
                end
            },
            {
                type = "client",
                event = "rsg_housing:client:buyRentMenu",
                icon = "fas fa-dollar-sign",
                label = Lang:t('target.buy_property'),
                propertyId = propertyId,
                canInteract = function()
                    return RSGCore.Functions.TriggerCallback('rsg_housing:server:getPropertyOwnership', function(ownership)
                        return not ownership
                    end, propertyId)
                end
            }
        }
        
        exports['rsg-target']:AddBoxZone('property_' .. propertyId, property.coords, 2.0, 2.0, {
            name = 'property_' .. propertyId,
            heading = property.heading,
            debugPoly = Config.Debug,
            minZ = property.coords.z - 1,
            maxZ = property.coords.z + 3,
        }, {
            options = options,
            distance = Config.InteractionDistance
        })
    end
end

-- Create draw text zones for properties
function CreateDrawTextZones()
    CreateThread(function()
        while true do
            local sleep = 1000
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            for propertyId, property in pairs(Properties) do
                local distance = #(playerCoords - vector3(property.coords.x, property.coords.y, property.coords.z))
                
                if distance < Config.DrawTextDistance then
                    sleep = 0
                    
                    if distance < Config.InteractionDistance then
                        local text = Lang:t('info.manage_property')
                        
                        RSGCore.Functions.TriggerCallback('rsg_housing:server:getPropertyOwnership', function(ownership)
                            if not ownership then
                                text = Lang:t('info.for_sale', property.buy_price) .. ' | ' .. Lang:t('info.for_rent', property.rent_price)
                            elseif RSGCore.Functions.TriggerCallback('rsg_housing:server:hasKeys', function(hasKeys) return hasKeys end, propertyId) then
                                text = Lang:t('info.enter_property', property.label)
                            else
                                text = Lang:t('info.ring_doorbell')
                            end
                        end, propertyId)
                        
                        RSGCore.Functions.DrawText3D(property.coords.x, property.coords.y, property.coords.z + 1, text)
                        
                        if IsControlJustPressed(0, 0x760A9C6F) then -- G key
                            HandlePropertyInteraction(propertyId)
                        end
                    end
                end
            end
            
            Wait(sleep)
        end
    end)
end

-- Handle property interaction
function HandlePropertyInteraction(propertyId)
    RSGCore.Functions.TriggerCallback('rsg_housing:server:getPropertyOwnership', function(ownership)
        if not ownership then
            OpenBuyRentMenu(propertyId)
        else
            RSGCore.Functions.TriggerCallback('rsg_housing:server:hasKeys', function(hasKeys)
                if hasKeys then
                    if InsideProperty then
                        TriggerServerEvent('rsg_housing:server:exitProperty', propertyId)
                    else
                        TriggerServerEvent('rsg_housing:server:enterProperty', propertyId)
                    end
                else
                    OpenPropertyMenu(propertyId)
                end
            end, propertyId)
        end
    end, propertyId)
end

-- Open buy/rent menu
function OpenBuyRentMenu(propertyId)
    RSGCore.Functions.TriggerCallback('rsg_housing:server:getProperty', function(property)
        if not property then return end
        
        local menuOptions = {
            {
                header = property.label,
                txt = Lang:t('menu.property_type', Config.PropertyTypes[property.type].label),
                isMenuHeader = true
            },
            {
                header = Lang:t('menu.buy_property'),
                txt = Lang:t('menu.buy_price', property.buy_price),
                params = {
                    event = 'rsg_housing:client:confirmPurchase',
                    args = {
                        propertyId = propertyId,
                        type = 'buy',
                        price = property.buy_price
                    }
                }
            },
            {
                header = Lang:t('menu.rent_property'),
                txt = Lang:t('menu.rent_price', property.rent_price),
                params = {
                    event = 'rsg_housing:client:confirmPurchase',
                    args = {
                        propertyId = propertyId,
                        type = 'rent',
                        price = property.rent_price
                    }
                }
            },
            {
                header = Lang:t('menu.close'),
                params = {
                    event = 'rsg-menu:closeMenu'
                }
            }
        }
        
        exports['rsg-menu']:openMenu(menuOptions)
    end, propertyId)
end

-- Open property management menu
function OpenPropertyMenu(propertyId)
    RSGCore.Functions.TriggerCallback('rsg_housing:server:getProperty', function(property)
        RSGCore.Functions.TriggerCallback('rsg_housing:server:getPropertyOwnership', function(ownership)
            if not property or not ownership then return end
            
            local menuOptions = {
                {
                    header = property.label,
                    txt = Lang:t('menu.owner', ownership.citizenid),
                    isMenuHeader = true
                }
            }
            
            -- Check if player is owner
            local Player = RSGCore.Functions.GetPlayerData()
            local isOwner = ownership.citizenid == Player.citizenid
            
            if isOwner then
                if ownership.ownership_type == 'rented' then
                    table.insert(menuOptions, {
                        header = Lang:t('menu.pay_rent'),
                        txt = Lang:t('menu.rent_price', property.rent_price),
                        params = {
                            event = 'rsg_housing:client:payRent',
                            args = { propertyId = propertyId }
                        }
                    })
                end
                
                if ownership.ownership_type == 'owned' then
                    table.insert(menuOptions, {
                        header = Lang:t('menu.sell_property'),
                        txt = Lang:t('menu.confirm_sale'),
                        params = {
                            event = 'rsg_housing:client:sellProperty',
                            args = { propertyId = propertyId }
                        }
                    })
                end
                
                table.insert(menuOptions, {
                    header = Lang:t('menu.manage_keys'),
                    txt = 'Give or remove keys',
                    params = {
                        event = 'rsg_housing:client:manageKeys',
                        args = { propertyId = propertyId }
                    }
                })
                
                table.insert(menuOptions, {
                    header = ownership.is_locked and Lang:t('menu.unlock_property') or Lang:t('menu.lock_property'),
                    txt = 'Toggle property lock',
                    params = {
                        event = 'rsg_housing:client:toggleLock',
                        args = { propertyId = propertyId }
                    }
                })
            end
            
            table.insert(menuOptions, {
                header = Lang:t('menu.close'),
                params = {
                    event = 'rsg-menu:closeMenu'
                }
            })
            
            exports['rsg-menu']:openMenu(menuOptions)
        end, propertyId)
    end, propertyId)
end

-- Enter property
function EnterProperty(property)
    if not property then 
        if Config.Debug then
            print('[RSG Housing] EnterProperty: No property data provided')
        end
        return 
    end
    
    if not property.shell then 
        if Config.Debug then
            print('[RSG Housing] EnterProperty: Property has no shell defined')
        end
        -- Use default shell if none specified
        property.shell = 'rsg_housing_shell_01'
    end
    
    local shell = Config.Shells[property.shell]
    if not shell then 
        if Config.Debug then
            print('[RSG Housing] EnterProperty: Shell not found: ' .. tostring(property.shell))
        end
        return 
    end
    
    if not property.coords then
        if Config.Debug then
            print('[RSG Housing] EnterProperty: Property has no coordinates')
        end
        return
    end
    
    -- For RedM/RSG, we use interior coordinates instead of CreateInterior
    local interiorCoords = vector3(
        property.coords.x + shell.doorCoords.x,
        property.coords.y + shell.doorCoords.y,
        property.coords.z + shell.doorCoords.z
    )
    
    if Config.Debug then
        print('[RSG Housing] Entering property: ' .. tostring(property.label or property.id))
        print('[RSG Housing] Interior coords: ' .. tostring(interiorCoords))
    end
    
    -- Teleport player to interior
    DoScreenFadeOut(500)
    Wait(500)
    
    SetEntityCoords(PlayerPedId(), interiorCoords.x, interiorCoords.y, interiorCoords.z)
    SetEntityHeading(PlayerPedId(), property.heading or 0.0)
    
    Wait(500)
    DoScreenFadeIn(500)
    
    CurrentProperty = property
    InsideProperty = true
    
    -- Create interior zones
    CreateInteriorZones(property)
    
    RSGCore.Functions.Notify(Lang:t('success.property_entered'), 'success')
end

-- Exit property
function ExitProperty(property)
    if not InsideProperty then return end
    
    if not property then
        if Config.Debug then
            print('[RSG Housing] ExitProperty: No property data provided')
        end
        property = CurrentProperty -- Use current property as fallback
    end
    
    if not property or not property.coords then
        if Config.Debug then
            print('[RSG Housing] ExitProperty: No valid property coordinates')
        end
        return
    end
    
    if Config.Debug then
        print('[RSG Housing] Exiting property: ' .. tostring(property.label or property.id))
    end
    
    -- Teleport player outside with fade effect
    DoScreenFadeOut(500)
    Wait(500)
    
    SetEntityCoords(PlayerPedId(), property.coords.x, property.coords.y, property.coords.z)
    SetEntityHeading(PlayerPedId(), property.heading or 0.0)
    
    Wait(500)
    DoScreenFadeIn(500)
    
    CurrentProperty = nil
    InsideProperty = false
    
    -- Remove interior zones
    RemoveInteriorZones()
    
    RSGCore.Functions.Notify(Lang:t('success.property_exited'), 'success')
end

-- Create interior interaction zones
function CreateInteriorZones(property)
    if not property.shell then return end
    
    local shell = Config.Shells[property.shell]
    if not shell then return end
    
    -- Storage zone
    if shell.stashCoords then
        local stashCoords = vector3(property.coords.x + shell.stashCoords.x, property.coords.y + shell.stashCoords.y, property.coords.z + shell.stashCoords.z)
        
        if Config.UseTarget then
            exports['rsg-target']:AddBoxZone('property_storage_' .. property.id, stashCoords, 1.0, 1.0, {
                name = 'property_storage_' .. property.id,
                heading = property.heading,
                debugPoly = Config.Debug,
                minZ = stashCoords.z - 1,
                maxZ = stashCoords.z + 2,
            }, {
                options = {
                    {
                        type = "client",
                        event = "rsg_housing:client:openStorage",
                        icon = "fas fa-box",
                        label = Lang:t('target.access_storage'),
                        propertyId = property.id
                    }
                },
                distance = 2.0
            })
        end
    end
    
    -- Wardrobe zone
    if shell.clothingCoords then
        local clothingCoords = vector3(property.coords.x + shell.clothingCoords.x, property.coords.y + shell.clothingCoords.y, property.coords.z + shell.clothingCoords.z)
        
        if Config.UseTarget then
            exports['rsg-target']:AddBoxZone('property_wardrobe_' .. property.id, clothingCoords, 1.0, 1.0, {
                name = 'property_wardrobe_' .. property.id,
                heading = property.heading,
                debugPoly = Config.Debug,
                minZ = clothingCoords.z - 1,
                maxZ = clothingCoords.z + 2,
            }, {
                options = {
                    {
                        type = "client",
                        event = "rsg_housing:client:openWardrobe",
                        icon = "fas fa-tshirt",
                        label = Lang:t('target.access_wardrobe'),
                        propertyId = property.id
                    }
                },
                distance = 2.0
            })
        end
    end
    
    -- Exit zone
    local exitCoords = vector3(property.coords.x + shell.doorCoords.x, property.coords.y + shell.doorCoords.y, property.coords.z + shell.doorCoords.z)
    
    if Config.UseTarget then
        exports['rsg-target']:AddBoxZone('property_exit_' .. property.id, exitCoords, 1.0, 1.0, {
            name = 'property_exit_' .. property.id,
            heading = property.heading,
            debugPoly = Config.Debug,
            minZ = exitCoords.z - 1,
            maxZ = exitCoords.z + 2,
        }, {
            options = {
                {
                    type = "client",
                    event = "rsg_housing:client:exitProperty",
                    icon = "fas fa-door-open",
                    label = Lang:t('target.exit_property'),
                    propertyId = property.id
                }
            },
            distance = 2.0
        })
    end
end

-- Remove interior zones
function RemoveInteriorZones()
    if not CurrentProperty then return end
    
    if Config.UseTarget then
        exports['rsg-target']:RemoveZone('property_storage_' .. CurrentProperty.id)
        exports['rsg-target']:RemoveZone('property_wardrobe_' .. CurrentProperty.id)
        exports['rsg-target']:RemoveZone('property_exit_' .. CurrentProperty.id)
    end
end

-- Events
RegisterNetEvent('rsg_housing:client:propertyMenu', function(data)
    OpenPropertyMenu(data.propertyId)
end)

RegisterNetEvent('rsg_housing:client:buyRentMenu', function(data)
    OpenBuyRentMenu(data.propertyId)
end)

RegisterNetEvent('rsg_housing:client:confirmPurchase', function(data)
    local input = exports['rsg-input']:ShowInput({
        header = Lang:t('menu.confirm_purchase'),
        submitText = "Confirm",
        inputs = {
            {
                text = data.type == 'buy' and Lang:t('menu.buy_price', data.price) or Lang:t('menu.rent_price', data.price),
                name = "confirm",
                type = "text",
                isRequired = true
            }
        }
    })
    
    if input and input.confirm and string.lower(input.confirm) == 'yes' then
        TriggerServerEvent('rsg_housing:server:purchaseProperty', data.propertyId, data.type)
    end
end)

RegisterNetEvent('rsg_housing:client:enterProperty', function(data)
    if data and data.propertyId then
        TriggerServerEvent('rsg_housing:server:enterProperty', data.propertyId)
    else
        TriggerServerEvent('rsg_housing:server:enterProperty', data)
    end
end)

RegisterNetEvent('rsg_housing:client:exitProperty', function(data)
    if data and data.propertyId then
        TriggerServerEvent('rsg_housing:server:exitProperty', data.propertyId)
    else
        TriggerServerEvent('rsg_housing:server:exitProperty', CurrentProperty.id)
    end
end)

RegisterNetEvent('rsg_housing:client:payRent', function(data)
    TriggerServerEvent('rsg_housing:server:payRent', data.propertyId)
end)

RegisterNetEvent('rsg_housing:client:sellProperty', function(data)
    local input = exports['rsg-input']:ShowInput({
        header = Lang:t('menu.confirm_sale'),
        submitText = "Confirm",
        inputs = {
            {
                text = "Type 'yes' to confirm sale",
                name = "confirm",
                type = "text",
                isRequired = true
            }
        }
    })
    
    if input and input.confirm and string.lower(input.confirm) == 'yes' then
        TriggerServerEvent('rsg_housing:server:sellProperty', data.propertyId)
    end
end)

RegisterNetEvent('rsg_housing:client:toggleLock', function(data)
    TriggerServerEvent('rsg_housing:server:toggleLock', data.propertyId)
end)

RegisterNetEvent('rsg_housing:client:manageKeys', function(data)
    local input = exports['rsg-input']:ShowInput({
        header = Lang:t('menu.manage_keys'),
        submitText = "Give Keys",
        inputs = {
            {
                text = Lang:t('menu.enter_player_id'),
                name = "playerId",
                type = "number",
                isRequired = true
            }
        }
    })
    
    if input and input.playerId then
        TriggerServerEvent('rsg_housing:server:giveKeys', data.propertyId, tonumber(input.playerId), 'roommate')
    end
end)

RegisterNetEvent('rsg_housing:client:openStorage', function(data)
    if not InsideProperty or not CurrentProperty then return end
    
    local storageId = 'property_' .. CurrentProperty.id
    
    if GetResourceState('rsg-inventory') == 'started' then
        exports['rsg-inventory']:OpenInventory('stash', storageId)
    else
        RSGCore.Functions.Notify('Storage system not available', 'error')
    end
end)

RegisterNetEvent('rsg_housing:client:openWardrobe', function(data)
    if not InsideProperty or not CurrentProperty then return end
    
    if GetResourceState('rsg-clothing') == 'started' then
        TriggerEvent('rsg-clothing:client:openOutfitMenu')
    else
        RSGCore.Functions.Notify('Clothing system not available', 'error')
    end
end)

-- Server response events
RegisterNetEvent('rsg_housing:client:purchaseResult', function(success, propertyId, purchaseType)
    if success then
        RSGCore.Functions.Notify(Lang:t('success.property_' .. (purchaseType == 'buy' and 'purchased' or 'rented')), 'success')
        LoadProperties()
        CreatePropertyBlips()
    else
        RSGCore.Functions.Notify(Lang:t('error.insufficient_funds'), 'error')
    end
end)

RegisterNetEvent('rsg_housing:client:sellResult', function(success, sellPrice)
    if success then
        RSGCore.Functions.Notify(Lang:t('success.property_sold', sellPrice), 'success')
        LoadProperties()
        CreatePropertyBlips()
    else
        RSGCore.Functions.Notify(Lang:t('error.not_owner'), 'error')
    end
end)

RegisterNetEvent('rsg_housing:client:payRentResult', function(success)
    if success then
        RSGCore.Functions.Notify(Lang:t('success.rent_paid'), 'success')
    else
        RSGCore.Functions.Notify(Lang:t('error.insufficient_funds'), 'error')
    end
end)

RegisterNetEvent('rsg_housing:client:toggleLockResult', function(success, lockState)
    if success then
        RSGCore.Functions.Notify(Lang:t('success.property_' .. (lockState and 'locked' or 'unlocked')), 'success')
    else
        RSGCore.Functions.Notify(Lang:t('error.no_access'), 'error')
    end
end)

RegisterNetEvent('rsg_housing:client:rentDue', function(propertyLabel, amount)
    RSGCore.Functions.Notify(Lang:t('info.rent_due', propertyLabel) .. ' - ' .. Lang:t('info.rent_due_amount', amount), 'primary', 10000)
end)

RegisterNetEvent('rsg_housing:client:evicted', function(propertyLabel)
    RSGCore.Functions.Notify(Lang:t('info.evicted', propertyLabel), 'error', 10000)
end)

-- Server events for property entry/exit
RegisterNetEvent('rsg_housing:client:enterProperty', function(property)
    EnterProperty(property)
end)

RegisterNetEvent('rsg_housing:client:exitProperty', function(property)
    ExitProperty(property)
end)

-- Commands
RegisterCommand('refreshblips', function()
    if Config.Debug then
        RefreshPropertyBlips()
        RSGCore.Functions.Notify('Property blips refreshed', 'success')
    end
end)

RegisterCommand('housing', function()
    RSGCore.Functions.TriggerCallback('rsg_housing:server:getPlayerProperties', function(properties)
        if #properties == 0 then
            RSGCore.Functions.Notify('You do not own any properties', 'error')
            return
        end
        
        local menuOptions = {
            {
                header = 'My Properties',
                txt = 'Total properties: ' .. #properties,
                isMenuHeader = true
            }
        }
        
        for i = 1, #properties do
            local property = Properties[properties[i].property_id]
            if property then
                table.insert(menuOptions, {
                    header = property.label,
                    txt = properties[i].ownership_type == 'owned' and 'Owned' or 'Rented',
                    params = {
                        event = 'rsg_housing:client:propertyMenu',
                        args = { propertyId = property.id }
                    }
                })
            end
        end
        
        table.insert(menuOptions, {
            header = Lang:t('menu.close'),
            params = {
                event = 'rsg-menu:closeMenu'
            }
        })
        
        exports['rsg-menu']:openMenu(menuOptions)
    end)
end)

-- Admin command for creating houses
RegisterNetEvent('rsg_housing:client:createHouse', function(propertyType, price)
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    
    local input = exports['rsg-input']:ShowInput({
        header = "Create New Property",
        submitText = "Create",
        inputs = {
            {
                text = "Property Label",
                name = "label",
                type = "text",
                isRequired = true
            },
            {
                text = "Property Type",
                name = "type",
                type = "text",
                isRequired = true,
                default = propertyType or 'house'
            },
            {
                text = "Buy Price",
                name = "buyPrice",
                type = "number",
                isRequired = true,
                default = price or 1000
            },
            {
                text = "Rent Price",
                name = "rentPrice",
                type = "number",
                isRequired = true,
                default = math.floor((price or 1000) * 0.1)
            }
        }
    })
    
    if input then
        -- This would need to be implemented on server side
        TriggerServerEvent('rsg_housing:server:createProperty', {
            label = input.label,
            type = input.type,
            coords = coords,
            heading = heading,
            buyPrice = tonumber(input.buyPrice),
            rentPrice = tonumber(input.rentPrice)
        })
    end
end)

-- Property update events
RegisterNetEvent('rsg_housing:client:propertyCreated', function(property)
    if property then
        Properties[property.id] = property
        CreatePropertyBlip(property)
        if Config.Debug then
            print('^2[RSG Housing]^7 New property created: ' .. property.label)
        end
    end
end)

RegisterNetEvent('rsg_housing:client:propertyDeleted', function(propertyId)
    if Properties[propertyId] then
        -- Remove blip
        if PropertyBlips[propertyId] then
            RemoveBlip(PropertyBlips[propertyId])
            PropertyBlips[propertyId] = nil
        end
        
        -- Remove from properties
        Properties[propertyId] = nil
        
        if Config.Debug then
            print('^2[RSG Housing]^7 Property deleted: ' .. propertyId)
        end
    end
end)

RegisterNetEvent('rsg_housing:client:propertyOwnershipChanged', function(propertyId)
    -- Update the blip for this property
    UpdatePropertyBlip(propertyId)
    if Config.Debug then
        print('^2[RSG Housing]^7 Property ownership changed: ' .. propertyId)
    end
end)

RegisterNetEvent('rsg_housing:client:refreshBlips', function()
    RefreshPropertyBlips()
end)

-- Player events
RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    Wait(2000) -- Wait for everything to load
    LoadProperties()
end)

RegisterNetEvent('RSGCore:Client:OnPlayerUnload', function()
    RemoveAllPropertyBlips()
    Properties = {}
    CurrentProperty = nil
    InsideProperty = false
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        RemoveAllPropertyBlips()
        if Config.UseTarget then
            -- Remove all target zones
            for propertyId, _ in pairs(Properties) do
                exports['rsg-target']:RemoveZone('property_' .. propertyId)
                exports['rsg-target']:RemoveZone('property_storage_' .. propertyId)
                exports['rsg-target']:RemoveZone('property_wardrobe_' .. propertyId)
                exports['rsg-target']:RemoveZone('property_logout_' .. propertyId)
            end
        end
    end
end)