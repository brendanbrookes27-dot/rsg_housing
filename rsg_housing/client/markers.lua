local RSGCore = exports['rsg-core']:GetCoreObject()

-- Variables
local NearbyProperties = {}
local CurrentMarkers = {}

-- Main marker thread
CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local sleep = 1000
        
        -- Clear nearby properties
        NearbyProperties = {}
        
        -- Check all properties for proximity
        if PropertyMarkers and next(PropertyMarkers) then
            for _, property in pairs(PropertyMarkers) do
                local distance = #(playerCoords - vector3(property.coords.x, property.coords.y, property.coords.z))
                
                if distance <= Config.MarkerDistance then
                    sleep = 0
                    table.insert(NearbyProperties, property)
                    
                    -- Draw marker
                    DrawPropertyMarker(property, distance)
                    
                    -- Show interaction text
                    if distance <= Config.InteractionDistance then
                        ShowPropertyInteraction(property)
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- Draw property marker
function DrawPropertyMarker(property, distance)
    local markerConfig
    local markerColor
    
    -- Determine marker type and color based on property status
    if property.type == 'saloon' then
        markerConfig = Config.Markers.Saloon
        markerColor = markerConfig.color
    elseif property.owner then
        markerConfig = Config.Markers.Owned
        markerColor = markerConfig.color
    else
        markerConfig = Config.Markers.ForSale
        markerColor = markerConfig.color
    end
    
    -- Draw the marker
    Citizen.InvokeNative(
        0x2A32FAA57B937173, -- DrawMarker
        markerConfig.type,
        property.coords.x, property.coords.y, property.coords.z - 1.0,
        0.0, 0.0, 0.0, -- direction
        0.0, 0.0, 0.0, -- rotation
        markerConfig.scale.x, markerConfig.scale.y, markerConfig.scale.z,
        markerColor.r, markerColor.g, markerColor.b, markerColor.a,
        markerConfig.bobUpAndDown,
        markerConfig.faceCamera,
        2, -- p19
        markerConfig.rotate,
        0, 0 -- texture dict and name
    )
    
    -- Draw property label above marker
    if distance <= 10.0 then
        DrawPropertyLabel(property)
    end
end

-- Draw property label
function DrawPropertyLabel(property)
    local coords = vector3(property.coords.x, property.coords.y, property.coords.z + 1.5)
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    
    if onScreen then
        local scale = 0.35
        local font = 1
        
        -- Property name
        SetTextScale(scale, scale)
        SetTextFont(font)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        AddTextComponentString(property.label)
        DrawText(screenX, screenY - 0.05)
        
        -- Property status/price
        local statusText = ""
        if property.owner then
            if property.type == 'saloon' then
                statusText = Lang:t('info.saloon_property')
            else
                statusText = Lang:t('info.owned_property')
            end
        else
            statusText = Lang:t('info.for_sale', property.price)
            if property.rent > 0 and Config.PropertyTypes[property.type].canRent then
                statusText = statusText .. " | " .. Lang:t('info.for_rent', property.rent)
            end
        end
        
        SetTextScale(0.25, 0.25)
        SetTextColour(200, 200, 200, 255)
        SetTextEntry("STRING")
        AddTextComponentString(statusText)
        DrawText(screenX, screenY - 0.02)
    end
end

-- Show property interaction
function ShowPropertyInteraction(property)
    local interactionText = ""
    
    if property.owner then
        if property.owner == RSGCore.Functions.GetPlayerData().citizenid then
            -- Player owns this property
            if InsideProperty and CurrentProperty and CurrentProperty.id == property.id then
                interactionText = Lang:t('info.exit_property')
            else
                interactionText = Lang:t('info.enter_property', property.label)
            end
        else
            -- Someone else owns this property
            interactionText = Lang:t('info.ring_doorbell')
        end
    else
        -- Property is available
        interactionText = Lang:t('info.purchase_property')
    end
    
    -- Draw interaction prompt
    DrawInteractionPrompt(interactionText)
    
    -- Handle input
    if Citizen.InvokeNative(0x91AEF906BCA88877, 0, Config.Keys['G']) then -- IsControlJustPressed
        HandlePropertyInteraction(property)
    end
end

-- Draw interaction prompt
function DrawInteractionPrompt(text)
    local str = CreateVarString(10, "LITERAL_STRING", text)
    PromptSetActiveGroupThisFrame(GetHashKey("PropertyPrompts"), str)
end

-- Handle property interaction
function HandlePropertyInteraction(property)
    if InsideProperty and CurrentProperty and CurrentProperty.id == property.id then
        -- Exit property
        TriggerEvent('rsg_housing:client:exitProperty')
    else
        -- Show property menu
        ShowPropertyMenu(property)
    end
end

-- Create interaction prompts
CreateThread(function()
    -- Create prompt group
    local promptGroup = GetHashKey("PropertyPrompts")
    
    -- Create individual prompts
    local interactPrompt = PromptRegisterBegin()
    PromptSetControlAction(interactPrompt, Config.Keys['G'])
    PromptSetText(interactPrompt, CreateVarString(10, "LITERAL_STRING", "Interact"))
    PromptSetEnabled(interactPrompt, true)
    PromptSetVisible(interactPrompt, true)
    PromptSetHoldMode(interactPrompt, false)
    PromptSetGroup(interactPrompt, promptGroup)
    PromptRegisterEnd(interactPrompt)
end)

-- Utility function to create variable string
function CreateVarString(p0, p1, variadic)
    return Citizen.InvokeNative(0xFA925AC00EB830B9, p0, p1, variadic, Citizen.ResultAsLong())
end