local RSGCore = exports['rsg-core']:GetCoreObject()

-- Property Lock Toggle
RegisterNetEvent('rsg_housing:client:toggleLock', function(property)
    TriggerServerEvent('rsg_housing:server:toggleLock', property.id)
end)

-- Give Keys
RegisterNetEvent('rsg_housing:client:giveKeys', function(property)
    local input = exports['rsg-input']:ShowInput({
        header = 'Give Keys',
        submitText = 'Give Keys',
        inputs = {
            {
                text = 'Player ID',
                name = 'playerId',
                type = 'number',
                isRequired = true
            }
        }
    })
    
    if input and input.playerId then
        TriggerServerEvent('rsg_housing:server:giveKeys', property.id, tonumber(input.playerId))
    end
end)

-- Remove Keys
RegisterNetEvent('rsg_housing:client:removeKeys', function(property)
    RSGCore.Functions.TriggerCallback('rsg_housing:server:getPropertyKeys', function(keyHolders)
        if #keyHolders == 0 then
            RSGCore.Functions.Notify('No one has keys to this property', 'error')
            return
        end
        
        local options = {}
        for _, holder in pairs(keyHolders) do
            table.insert(options, {
                value = holder.player_id,
                text = holder.player_name
            })
        end
        
        local input = exports['rsg-input']:ShowInput({
            header = 'Remove Keys',
            submitText = 'Remove Keys',
            inputs = {
                {
                    text = 'Select Player',
                    name = 'playerId',
                    type = 'select',
                    options = options,
                    isRequired = true
                }
            }
        })
        
        if input and input.playerId then
            TriggerServerEvent('rsg_housing:server:removeKeys', property.id, input.playerId)
        end
    end, property.id)
end)

-- Sell Property
RegisterNetEvent('rsg_housing:client:sellProperty', function(property)
    local salePrice = math.floor(property.price * 0.8) -- 80% of original price
    
    local input = exports['rsg-input']:ShowInput({
        header = 'Sell Property',
        submitText = 'Sell',
        inputs = {
            {
                text = 'Confirm Sale',
                name = 'confirm',
                type = 'select',
                options = {
                    { value = 'yes', text = 'Yes, sell for $' .. salePrice },
                    { value = 'no', text = 'No, cancel' }
                }
            }
        }
    })
    
    if input and input.confirm == 'yes' then
        TriggerServerEvent('rsg_housing:server:sellProperty', property.id)
    end
end)

-- Ring Doorbell
RegisterNetEvent('rsg_housing:client:ringDoorbell', function(property)
    TriggerServerEvent('rsg_housing:server:ringDoorbell', property.id)
end)

-- View Saloon Earnings
RegisterNetEvent('rsg_housing:client:viewEarnings', function(property)
    RSGCore.Functions.TriggerCallback('rsg_housing:server:getSaloonEarnings', function(earnings)
        local menuOptions = {
            {
                title = 'Saloon Earnings',
                description = property.label,
                icon = 'fas fa-chart-line'
            }
        }
        
        local totalEarnings = 0
        for _, earning in pairs(earnings) do
            totalEarnings = totalEarnings + earning.amount
            table.insert(menuOptions, {
                title = earning.date,
                description = '$' .. earning.amount,
                icon = 'fas fa-dollar-sign'
            })
        end
        
        table.insert(menuOptions, 1, {
            title = 'Total Earnings',
            description = '$' .. totalEarnings,
            icon = 'fas fa-money-bill-wave'
        })
        
        exports['rsg-menu']:openMenu(menuOptions)
    end, property.id)
end)

-- Collect Saloon Earnings
RegisterNetEvent('rsg_housing:client:collectEarnings', function(property)
    TriggerServerEvent('rsg_housing:server:collectEarnings', property.id)
end)

-- Manage Saloon Staff
RegisterNetEvent('rsg_housing:client:manageStaff', function(property)
    local menuOptions = {
        {
            title = 'Hire Bartender',
            description = 'Hire a bartender (+10% earnings)',
            icon = 'fas fa-user-plus',
            event = 'rsg_housing:client:hireStaff',
            args = { property = property, type = 'bartender' }
        },
        {
            title = 'Hire Security',
            description = 'Hire security (+5% earnings, -theft)',
            icon = 'fas fa-shield-alt',
            event = 'rsg_housing:client:hireStaff',
            args = { property = property, type = 'security' }
        },
        {
            title = 'Fire Staff',
            description = 'Fire existing staff',
            icon = 'fas fa-user-minus',
            event = 'rsg_housing:client:fireStaff',
            args = property
        }
    }
    
    exports['rsg-menu']:openMenu(menuOptions)
end)

-- Hire Staff
RegisterNetEvent('rsg_housing:client:hireStaff', function(data)
    local cost = data.type == 'bartender' and 500 or 300
    
    local input = exports['rsg-input']:ShowInput({
        header = 'Hire ' .. data.type:gsub("^%l", string.upper),
        submitText = 'Hire',
        inputs = {
            {
                text = 'Confirm Hire',
                name = 'confirm',
                type = 'select',
                options = {
                    { value = 'yes', text = 'Yes, hire for $' .. cost },
                    { value = 'no', text = 'No, cancel' }
                }
            }
        }
    })
    
    if input and input.confirm == 'yes' then
        TriggerServerEvent('rsg_housing:server:hireStaff', data.property.id, data.type)
    end
end)

-- Fire Staff
RegisterNetEvent('rsg_housing:client:fireStaff', function(property)
    RSGCore.Functions.TriggerCallback('rsg_housing:server:getPropertyStaff', function(staff)
        if #staff == 0 then
            RSGCore.Functions.Notify('No staff to fire', 'error')
            return
        end
        
        local options = {}
        for _, member in pairs(staff) do
            table.insert(options, {
                value = member.id,
                text = member.type:gsub("^%l", string.upper) .. ' - $' .. member.wage .. '/day'
            })
        end
        
        local input = exports['rsg-input']:ShowInput({
            header = 'Fire Staff',
            submitText = 'Fire',
            inputs = {
                {
                    text = 'Select Staff Member',
                    name = 'staffId',
                    type = 'select',
                    options = options,
                    isRequired = true
                }
            }
        })
        
        if input and input.staffId then
            TriggerServerEvent('rsg_housing:server:fireStaff', property.id, tonumber(input.staffId))
        end
    end, property.id)
end)

-- Interior Storage Access
RegisterNetEvent('rsg_housing:client:accessStorage', function(property)
    if not InsideProperty or not CurrentProperty then
        RSGCore.Functions.Notify('You must be inside the property', 'error')
        return
    end
    
    TriggerServerEvent('rsg_housing:server:openStorage', property.id)
end)

-- Interior Wardrobe Access
RegisterNetEvent('rsg_housing:client:accessWardrobe', function(property)
    if not InsideProperty or not CurrentProperty then
        RSGCore.Functions.Notify('You must be inside the property', 'error')
        return
    end
    
    TriggerEvent('rsg-clothing:client:openOutfitMenu')
end)

-- Server Response Events
RegisterNetEvent('rsg_housing:client:propertyPurchased', function(property)
    RSGCore.Functions.Notify(Lang:t('success.property_purchased', {property.price}), 'success')
    TriggerServerEvent('rsg_housing:server:loadProperties') -- Refresh properties
end)

RegisterNetEvent('rsg_housing:client:propertyRented', function(property)
    RSGCore.Functions.Notify(Lang:t('success.property_rented', {property.rent}), 'success')
    TriggerServerEvent('rsg_housing:server:loadProperties') -- Refresh properties
end)

RegisterNetEvent('rsg_housing:client:propertySold', function(salePrice)
    RSGCore.Functions.Notify(Lang:t('success.property_sold', {salePrice}), 'success')
    TriggerServerEvent('rsg_housing:server:loadProperties') -- Refresh properties
end)

RegisterNetEvent('rsg_housing:client:lockToggled', function(isLocked)
    local message = isLocked and Lang:t('success.property_locked') or Lang:t('success.property_unlocked')
    RSGCore.Functions.Notify(message, 'success')
end)

RegisterNetEvent('rsg_housing:client:keysGiven', function(playerName)
    RSGCore.Functions.Notify(Lang:t('success.keys_given', {playerName}), 'success')
end)

RegisterNetEvent('rsg_housing:client:keysRemoved', function(playerName)
    RSGCore.Functions.Notify(Lang:t('success.keys_removed', {playerName}), 'success')
end)

RegisterNetEvent('rsg_housing:client:doorbellRang', function(propertyLabel, playerName)
    RSGCore.Functions.Notify(playerName .. ' is at the door of ' .. propertyLabel, 'primary', 5000)
end)

RegisterNetEvent('rsg_housing:client:earningsCollected', function(amount)
    RSGCore.Functions.Notify('Collected $' .. amount .. ' in earnings', 'success')
end)

RegisterNetEvent('rsg_housing:client:staffHired', function(staffType, cost)
    RSGCore.Functions.Notify('Hired ' .. staffType .. ' for $' .. cost, 'success')
end)

RegisterNetEvent('rsg_housing:client:staffFired', function(staffType)
    RSGCore.Functions.Notify('Fired ' .. staffType, 'success')
end)