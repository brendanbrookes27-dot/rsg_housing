local RSGCore = exports['rsg-core']:GetCoreObject()

-- Storage system client-side
local CurrentProperty = nil
local StorageZones = {}

-- Initialize storage system
CreateThread(function()
    Wait(1000)
    if Config.Debug then
        print('^2[RSG Housing]^7 Storage client initialized')
    end
end)

-- Create storage interaction zones for property
function CreateStorageZones(property)
    if not property or not property.shell then return end
    
    local shell = Config.Shells[property.shell]
    if not shell or not shell.stashCoords then return end
    
    local stashCoords = vector3(
        property.coords.x + shell.stashCoords.x,
        property.coords.y + shell.stashCoords.y,
        property.coords.z + shell.stashCoords.z
    )
    
    if Config.UseTarget then
        -- Create target zone for storage
        exports['rsg-target']:AddBoxZone('property_storage_' .. property.id, stashCoords, 1.5, 1.5, {
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
                },
                {
                    type = "client",
                    event = "rsg_housing:client:storageMenu",
                    icon = "fas fa-cog",
                    label = "Storage Settings",
                    propertyId = property.id,
                    canInteract = function()
                        return RSGCore.Functions.TriggerCallback('rsg_housing:server:getPropertyOwnership', function(ownership)
                            local Player = RSGCore.Functions.GetPlayerData()
                            return ownership and ownership.citizenid == Player.citizenid
                        end, property.id)
                    end
                }
            },
            distance = 2.0
        })
        
        StorageZones[property.id] = 'property_storage_' .. property.id
    else
        -- Create draw text zone
        CreateThread(function()
            while CurrentProperty and CurrentProperty.id == property.id do
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(playerCoords - stashCoords)
                
                if distance < 3.0 then
                    RSGCore.Functions.DrawText3D(stashCoords.x, stashCoords.y, stashCoords.z + 0.5, Lang:t('info.access_storage'))
                    
                    if distance < 1.5 and IsControlJustPressed(0, 0x760A9C6F) then -- G key
                        OpenStorage(property.id)
                    end
                end
                
                Wait(0)
            end
        end)
    end
end

-- Remove storage zones
function RemoveStorageZones(propertyId)
    if Config.UseTarget and StorageZones[propertyId] then
        exports['rsg-target']:RemoveZone(StorageZones[propertyId])
        StorageZones[propertyId] = nil
    end
end

-- Open storage
function OpenStorage(propertyId)
    TriggerServerEvent('rsg_housing:server:openStorage', propertyId)
end

-- Show storage management menu
function ShowStorageMenu(propertyId)
    RSGCore.Functions.TriggerCallback('rsg_housing:server:getStorageStats', function(stats)
        if not stats then
            RSGCore.Functions.Notify('Unable to load storage information', 'error')
            return
        end
        
        local menuOptions = {
            {
                header = 'Storage Management',
                txt = string.format('Slots: %d/%d | Weight: %.1fkg/%.1fkg', 
                    stats.usedSlots, stats.maxSlots, 
                    stats.usedWeight / 1000, stats.maxWeight / 1000),
                isMenuHeader = true
            },
            {
                header = 'Access Storage',
                txt = 'Open storage container',
                params = {
                    event = 'rsg_housing:client:openStorage',
                    args = { propertyId = propertyId }
                }
            }
        }
        
        -- Add upgrade options if not at maximum
        if stats.maxSlots < 100 then
            table.insert(menuOptions, {
                header = 'Upgrade Slots',
                txt = 'Increase storage slots to 75 - $500',
                params = {
                    event = 'rsg_housing:client:upgradeStorage',
                    args = { propertyId = propertyId, upgradeType = 'slots' }
                }
            })
        end
        
        if stats.maxWeight < 600000 then
            table.insert(menuOptions, {
                header = 'Upgrade Weight',
                txt = 'Increase weight capacity to 600kg - $750',
                params = {
                    event = 'rsg_housing:client:upgradeStorage',
                    args = { propertyId = propertyId, upgradeType = 'weight' }
                }
            })
        end
        
        if stats.maxSlots < 100 or stats.maxWeight < 800000 then
            table.insert(menuOptions, {
                header = 'Premium Upgrade',
                txt = 'Maximum slots & weight (100/800kg) - $1,200',
                params = {
                    event = 'rsg_housing:client:upgradeStorage',
                    args = { propertyId = propertyId, upgradeType = 'premium' }
                }
            })
        end
        
        table.insert(menuOptions, {
            header = 'Storage Information',
            txt = 'View detailed storage stats',
            params = {
                event = 'rsg_housing:client:storageInfo',
                args = { propertyId = propertyId, stats = stats }
            }
        })
        
        table.insert(menuOptions, {
            header = 'Close',
            params = {
                event = 'rsg-menu:closeMenu'
            }
        })
        
        exports['rsg-menu']:openMenu(menuOptions)
    end, propertyId)
end

-- Show storage information
function ShowStorageInfo(propertyId, stats)
    local menuOptions = {
        {
            header = 'Storage Information',
            isMenuHeader = true
        },
        {
            header = 'Capacity',
            txt = string.format('Slots: %d/%d (%.1f%% full)', 
                stats.usedSlots, stats.maxSlots, 
                (stats.usedSlots / stats.maxSlots) * 100),
            isMenuHeader = false
        },
        {
            header = 'Weight',
            txt = string.format('Weight: %.1fkg/%.1fkg (%.1f%% full)', 
                stats.usedWeight / 1000, stats.maxWeight / 1000,
                (stats.usedWeight / stats.maxWeight) * 100),
            isMenuHeader = false
        }
    }
    
    -- Show top items if available
    if stats.items and #stats.items > 0 then
        table.insert(menuOptions, {
            header = 'Top Items',
            isMenuHeader = true
        })
        
        -- Sort items by amount and show top 5
        table.sort(stats.items, function(a, b) return (a.amount or 0) > (b.amount or 0) end)
        
        for i = 1, math.min(5, #stats.items) do
            local item = stats.items[i]
            if item.amount and item.amount > 0 then
                table.insert(menuOptions, {
                    header = item.label or item.name,
                    txt = 'Amount: ' .. item.amount,
                    isMenuHeader = false
                })
            end
        end
    end
    
    table.insert(menuOptions, {
        header = 'Back',
        params = {
            event = 'rsg_housing:client:storageMenu',
            args = { propertyId = propertyId }
        }
    })
    
    exports['rsg-menu']:openMenu(menuOptions)
end

-- Upgrade storage
function UpgradeStorage(propertyId, upgradeType)
    local upgradeCosts = {
        slots = { price = 500, description = 'Increase storage slots to 75' },
        weight = { price = 750, description = 'Increase weight capacity to 600kg' },
        premium = { price = 1200, description = 'Maximum slots & weight (100/800kg)' }
    }
    
    local upgrade = upgradeCosts[upgradeType]
    if not upgrade then return end
    
    local input = exports['rsg-input']:ShowInput({
        header = "Confirm Storage Upgrade",
        submitText = "Confirm",
        inputs = {
            {
                text = upgrade.description .. ' - $' .. upgrade.price,
                name = "info",
                type = "text",
                isRequired = false,
                disabled = true
            },
            {
                text = "Type 'yes' to confirm upgrade",
                name = "confirm",
                type = "text",
                isRequired = true
            }
        }
    })
    
    if input and input.confirm and string.lower(input.confirm) == 'yes' then
        TriggerServerEvent('rsg_housing:server:upgradeStorage', propertyId, upgradeType)
    end
end

-- Events
RegisterNetEvent('rsg_housing:client:openStorage', function(data)
    OpenStorage(data.propertyId)
end)

RegisterNetEvent('rsg_housing:client:storageMenu', function(data)
    ShowStorageMenu(data.propertyId)
end)

RegisterNetEvent('rsg_housing:client:storageInfo', function(data)
    ShowStorageInfo(data.propertyId, data.stats)
end)

RegisterNetEvent('rsg_housing:client:upgradeStorage', function(data)
    UpgradeStorage(data.propertyId, data.upgradeType)
end)

-- Property entry/exit events
RegisterNetEvent('rsg_housing:client:enteredProperty', function(property)
    CurrentProperty = property
    CreateStorageZones(property)
end)

RegisterNetEvent('rsg_housing:client:exitedProperty', function()
    if CurrentProperty then
        RemoveStorageZones(CurrentProperty.id)
        CurrentProperty = nil
    end
end)

-- Storage access animation
function PlayStorageAccessAnimation()
    local playerPed = PlayerPedId()
    
    -- Load animation dictionary
    local animDict = "script_common@other@book_newspaper@base"
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(1)
    end
    
    -- Play animation
    TaskPlayAnim(playerPed, animDict, "base", 8.0, -8.0, 2000, 1, 0, false, false, false)
    
    -- Clean up
    Wait(2000)
    RemoveAnimDict(animDict)
end

-- Storage interaction feedback
RegisterNetEvent('rsg_housing:client:storageOpened', function()
    PlayStorageAccessAnimation()
    RSGCore.Functions.Notify('Storage accessed', 'success')
end)

RegisterNetEvent('rsg_housing:client:storageUpgraded', function(upgradeType)
    RSGCore.Functions.Notify('Storage upgraded successfully', 'success')
    
    -- Show upgrade effect
    CreateThread(function()
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        
        -- Simple particle effect (if available)
        if HasNamedPtfxAssetLoaded("core") then
            UseParticleFxAssetNextCall("core")
            StartParticleFxNonLoopedAtCoord("ent_sht_electrical_box", coords.x, coords.y, coords.z + 1.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
        end
    end)
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if CurrentProperty then
            RemoveStorageZones(CurrentProperty.id)
        end
    end
end)