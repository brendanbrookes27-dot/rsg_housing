local RSGCore = exports['rsg-core']:GetCoreObject()

-- Create property blip
function CreatePropertyBlip(property)
    local blipConfig
    local blipLabel = property.label
    
    -- Determine blip configuration based on property status and type
    if property.type == 'saloon' then
        blipConfig = Config.Blips.Saloon
        blipLabel = Lang:t('info.saloon_marker', property.label)
    elseif property.owner then
        blipConfig = Config.Blips.Owned
        if property.owner == RSGCore.Functions.GetPlayerData().citizenid then
            blipLabel = Lang:t('info.owned_property') .. ': ' .. property.label
        else
            blipLabel = property.label .. ' (Owned)'
        end
    else
        blipConfig = Config.Blips.ForSale
        blipLabel = Lang:t('info.available_property') .. ': ' .. property.label
    end
    
    -- Create the blip
    local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, property.coords.x, property.coords.y, property.coords.z)
    
    -- Set blip properties
    SetBlipSprite(blip, blipConfig.sprite, true)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, blipLabel) -- SetBlipName
    
    -- Set blip color
    local colorHash = GetHashKey(blipConfig.color)
    Citizen.InvokeNative(0x662D364ABF16DE2F, blip, colorHash) -- SetBlipColor
    
    -- Set blip scale
    Citizen.InvokeNative(0xD38744167B2FA257, blip, blipConfig.scale) -- SetBlipScale
    
    -- Store blip reference
    PropertyBlips[property.id] = blip
    
    if Config.Debug then
        print('[RSG Housing] Created blip for property: ' .. property.id)
    end
end

-- Update property blip
function UpdatePropertyBlip(property)
    local existingBlip = PropertyBlips[property.id]
    
    if existingBlip and DoesBlipExist(existingBlip) then
        RemoveBlip(existingBlip)
    end
    
    CreatePropertyBlip(property)
end

-- Remove property blip
function RemovePropertyBlip(propertyId)
    local blip = PropertyBlips[propertyId]
    
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
        PropertyBlips[propertyId] = nil
        
        if Config.Debug then
            print('[RSG Housing] Removed blip for property: ' .. propertyId)
        end
    end
end

-- Update all blips (called when property ownership changes)
RegisterNetEvent('rsg_housing:client:updateBlips', function(properties)
    if Config.Debug then
        print('[RSG Housing] Updating all property blips')
    end
    
    -- Remove existing blips
    RemoveAllBlips()
    
    -- Create new blips
    for _, property in pairs(properties) do
        CreatePropertyBlip(property)
    end
end)

-- Update specific property blip
RegisterNetEvent('rsg_housing:client:updatePropertyBlip', function(property)
    if Config.Debug then
        print('[RSG Housing] Updating blip for property: ' .. property.id)
    end
    
    UpdatePropertyBlip(property)
end)