local RSGCore = exports['rsg-core']:GetCoreObject()

-- Furniture system variables
local FurniturePlacementMode = false
local CurrentProperty = nil
local PlacedFurnitureObjects = {}
local PreviewObject = nil
local SelectedFurniture = nil

-- Initialize furniture system
CreateThread(function()
    Wait(1000)
    LoadPropertyFurniture()
end)

-- Load furniture for current property
function LoadPropertyFurniture()
    if not CurrentProperty then return end
    
    RSGCore.Functions.TriggerCallback('rsg_housing:server:getPropertyFurniture', function(furniture)
        -- Clear existing furniture
        ClearPropertyFurniture()
        
        -- Spawn furniture objects
        for instanceId, furnitureData in pairs(furniture) do
            if furnitureData.placed then
                SpawnFurnitureObject(instanceId, furnitureData)
            end
        end
    end, CurrentProperty.id)
end

-- Clear all furniture objects for property
function ClearPropertyFurniture()
    for instanceId, objectHandle in pairs(PlacedFurnitureObjects) do
        if DoesEntityExist(objectHandle) then
            DeleteEntity(objectHandle)
        end
    end
    PlacedFurnitureObjects = {}
end

-- Spawn furniture object
function SpawnFurnitureObject(instanceId, furnitureData)
    if not furnitureData.coords or not furnitureData.model then return end
    
    local modelHash = GetHashKey(furnitureData.model)
    
    -- Request model
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(1)
    end
    
    -- Create object
    local obj = CreateObject(modelHash, furnitureData.coords.x, furnitureData.coords.y, furnitureData.coords.z, false, false, false)
    SetEntityHeading(obj, furnitureData.heading or 0.0)
    FreezeEntityPosition(obj, true)
    
    -- Store object handle
    PlacedFurnitureObjects[instanceId] = obj
    
    -- Set model as no longer needed
    SetModelAsNoLongerNeeded(modelHash)
    
    if Config.Debug then
        print('^2[RSG Housing]^7 Spawned furniture: ' .. furnitureData.model .. ' at ' .. json.encode(furnitureData.coords))
    end
end

-- Remove furniture object
function RemoveFurnitureObject(instanceId)
    if PlacedFurnitureObjects[instanceId] then
        local obj = PlacedFurnitureObjects[instanceId]
        if DoesEntityExist(obj) then
            DeleteEntity(obj)
        end
        PlacedFurnitureObjects[instanceId] = nil
    end
end

-- Enter furniture placement mode
function EnterFurniturePlacementMode(propertyId)
    if FurniturePlacementMode then return end
    
    FurniturePlacementMode = true
    CurrentProperty = { id = propertyId }
    
    -- Get available furniture
    RSGCore.Functions.TriggerCallback('rsg_housing:server:getAvailableFurniture', function(availableFurniture)
        if #availableFurniture == 0 then
            RSGCore.Functions.Notify('No furniture available for placement', 'error')
            ExitFurniturePlacementMode()
            return
        end
        
        -- Show furniture selection menu
        ShowFurnitureSelectionMenu(availableFurniture)
    end, propertyId)
    
    RSGCore.Functions.Notify('Furniture placement mode activated', 'success')
end

-- Exit furniture placement mode
function ExitFurniturePlacementMode()
    if not FurniturePlacementMode then return end
    
    FurniturePlacementMode = false
    SelectedFurniture = nil
    
    -- Remove preview object
    if PreviewObject and DoesEntityExist(PreviewObject) then
        DeleteEntity(PreviewObject)
        PreviewObject = nil
    end
    
    RSGCore.Functions.Notify('Furniture placement mode deactivated', 'info')
end

-- Show furniture selection menu
function ShowFurnitureSelectionMenu(availableFurniture)
    local menuOptions = {
        {
            header = 'Select Furniture to Place',
            isMenuHeader = true
        }
    }
    
    for i = 1, #availableFurniture do
        local item = availableFurniture[i]
        table.insert(menuOptions, {
            header = item.furniture.label,
            txt = 'Price: $' .. item.furniture.price,
            params = {
                event = 'rsg_housing:client:selectFurnitureForPlacement',
                args = {
                    instanceId = item.instanceId,
                    furniture = item.furniture
                }
            }
        })
    end
    
    table.insert(menuOptions, {
        header = 'Cancel',
        params = {
            event = 'rsg_housing:client:exitFurniturePlacementMode'
        }
    })
    
    exports['rsg-menu']:openMenu(menuOptions)
end

-- Select furniture for placement
function SelectFurnitureForPlacement(instanceId, furniture)
    SelectedFurniture = {
        instanceId = instanceId,
        furniture = furniture
    }
    
    -- Create preview object
    CreatePreviewObject(furniture.model)
    
    -- Start placement thread
    StartFurniturePlacementThread()
    
    RSGCore.Functions.Notify('Use WASD to move, Q/E to rotate, ENTER to place, ESC to cancel', 'info', 8000)
end

-- Create preview object
function CreatePreviewObject(model)
    local modelHash = GetHashKey(model)
    
    -- Request model
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(1)
    end
    
    -- Get player position
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)
    
    -- Create preview object
    PreviewObject = CreateObject(modelHash, playerCoords.x, playerCoords.y, playerCoords.z, false, false, false)
    SetEntityHeading(PreviewObject, playerHeading)
    SetEntityAlpha(PreviewObject, 150, false)
    SetEntityCollision(PreviewObject, false, false)
    
    -- Set model as no longer needed
    SetModelAsNoLongerNeeded(modelHash)
end

-- Start furniture placement thread
function StartFurniturePlacementThread()
    CreateThread(function()
        local moveSpeed = 0.1
        local rotateSpeed = 2.0
        
        while FurniturePlacementMode and SelectedFurniture and DoesEntityExist(PreviewObject) do
            local playerPed = PlayerPedId()
            local previewCoords = GetEntityCoords(PreviewObject)
            local previewHeading = GetEntityHeading(PreviewObject)
            
            -- Movement controls
            if IsControlPressed(0, 0x8FD015D8) then -- W
                local newCoords = GetOffsetFromEntityInWorldCoords(PreviewObject, 0.0, moveSpeed, 0.0)
                SetEntityCoords(PreviewObject, newCoords.x, newCoords.y, newCoords.z, false, false, false, false)
            end
            
            if IsControlPressed(0, 0xD27782E3) then -- S
                local newCoords = GetOffsetFromEntityInWorldCoords(PreviewObject, 0.0, -moveSpeed, 0.0)
                SetEntityCoords(PreviewObject, newCoords.x, newCoords.y, newCoords.z, false, false, false, false)
            end
            
            if IsControlPressed(0, 0x7065027D) then -- A
                local newCoords = GetOffsetFromEntityInWorldCoords(PreviewObject, -moveSpeed, 0.0, 0.0)
                SetEntityCoords(PreviewObject, newCoords.x, newCoords.y, newCoords.z, false, false, false, false)
            end
            
            if IsControlPressed(0, 0xB4E465B4) then -- D
                local newCoords = GetOffsetFromEntityInWorldCoords(PreviewObject, moveSpeed, 0.0, 0.0)
                SetEntityCoords(PreviewObject, newCoords.x, newCoords.y, newCoords.z, false, false, false, false)
            end
            
            -- Rotation controls
            if IsControlPressed(0, 0xDE794E3E) then -- Q
                SetEntityHeading(PreviewObject, previewHeading - rotateSpeed)
            end
            
            if IsControlPressed(0, 0x8FFC75D6) then -- E
                SetEntityHeading(PreviewObject, previewHeading + rotateSpeed)
            end
            
            -- Vertical movement
            if IsControlPressed(0, 0xD9D0E1C0) then -- SPACE
                SetEntityCoords(PreviewObject, previewCoords.x, previewCoords.y, previewCoords.z + 0.05, false, false, false, false)
            end
            
            if IsControlPressed(0, 0x8FD015D8) and IsControlPressed(0, 0x21D5A956) then -- CTRL
                SetEntityCoords(PreviewObject, previewCoords.x, previewCoords.y, previewCoords.z - 0.05, false, false, false, false)
            end
            
            -- Place furniture
            if IsControlJustPressed(0, 0xC7B5340A) then -- ENTER
                PlaceFurniture()
                break
            end
            
            -- Cancel placement
            if IsControlJustPressed(0, 0x156F7119) then -- ESC
                ExitFurniturePlacementMode()
                break
            end
            
            -- Draw placement instructions
            local screenCoords = GetScreenCoordFromWorldCoord(previewCoords.x, previewCoords.y, previewCoords.z + 1.0)
            if screenCoords then
                SetTextScale(0.35, 0.35)
                SetTextColor(255, 255, 255, 255)
                SetTextCentre(true)
                SetTextDropshadow(1, 0, 0, 0, 255)
                DisplayText(CreateVarString(10, "LITERAL_STRING", "WASD: Move | Q/E: Rotate | ENTER: Place | ESC: Cancel"), screenCoords.x, screenCoords.y)
            end
            
            Wait(0)
        end
    end)
end

-- Place furniture
function PlaceFurniture()
    if not SelectedFurniture or not DoesEntityExist(PreviewObject) then return end
    
    local coords = GetEntityCoords(PreviewObject)
    local heading = GetEntityHeading(PreviewObject)
    
    -- Send placement request to server
    TriggerServerEvent('rsg_housing:server:placeFurniture', CurrentProperty.id, SelectedFurniture.instanceId, {
        x = coords.x,
        y = coords.y,
        z = coords.z
    }, heading)
    
    -- Clean up
    DeleteEntity(PreviewObject)
    PreviewObject = nil
    SelectedFurniture = nil
    ExitFurniturePlacementMode()
end

-- Remove furniture (interaction)
function RemoveFurnitureInteraction(instanceId)
    local input = exports['rsg-input']:ShowInput({
        header = "Remove Furniture",
        submitText = "Confirm",
        inputs = {
            {
                text = "Type 'yes' to confirm removal",
                name = "confirm",
                type = "text",
                isRequired = true
            }
        }
    })
    
    if input and input.confirm and string.lower(input.confirm) == 'yes' then
        TriggerServerEvent('rsg_housing:server:removeFurniture', CurrentProperty.id, instanceId)
    end
end

-- Events
RegisterNetEvent('rsg_housing:client:spawnFurniture', function(propertyId, instanceId, furniture)
    if CurrentProperty and CurrentProperty.id == propertyId then
        SpawnFurnitureObject(instanceId, furniture)
    end
end)

RegisterNetEvent('rsg_housing:client:removeFurniture', function(propertyId, instanceId)
    if CurrentProperty and CurrentProperty.id == propertyId then
        RemoveFurnitureObject(instanceId)
    end
end)

RegisterNetEvent('rsg_housing:client:toggleFurniturePlacementMode', function(enabled, propertyId)
    if enabled then
        EnterFurniturePlacementMode(propertyId)
    else
        ExitFurniturePlacementMode()
    end
end)

RegisterNetEvent('rsg_housing:client:selectFurnitureForPlacement', function(data)
    SelectFurnitureForPlacement(data.instanceId, data.furniture)
end)

RegisterNetEvent('rsg_housing:client:exitFurniturePlacementMode', function()
    ExitFurniturePlacementMode()
end)

RegisterNetEvent('rsg_housing:client:purchaseFurnitureResult', function(success, instanceId)
    if success then
        RSGCore.Functions.Notify('Furniture purchased successfully', 'success')
    else
        RSGCore.Functions.Notify('Failed to purchase furniture', 'error')
    end
end)

RegisterNetEvent('rsg_housing:client:placeFurnitureResult', function(success)
    if success then
        RSGCore.Functions.Notify('Furniture placed successfully', 'success')
        LoadPropertyFurniture() -- Reload furniture to show placed item
    else
        RSGCore.Functions.Notify('Failed to place furniture', 'error')
    end
end)

RegisterNetEvent('rsg_housing:client:removeFurnitureResult', function(success)
    if success then
        RSGCore.Functions.Notify('Furniture removed successfully', 'success')
    else
        RSGCore.Functions.Notify('Failed to remove furniture', 'error')
    end
end)

-- Property entry/exit events
RegisterNetEvent('rsg_housing:client:enteredProperty', function(property)
    CurrentProperty = property
    LoadPropertyFurniture()
end)

RegisterNetEvent('rsg_housing:client:exitedProperty', function()
    ClearPropertyFurniture()
    CurrentProperty = nil
    ExitFurniturePlacementMode()
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        ClearPropertyFurniture()
        ExitFurniturePlacementMode()
    end
end)