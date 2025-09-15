# RSG Housing - Blip System Guide

## Overview
The RSG Housing system now includes a comprehensive blip management system that ensures houses show properly on the map with different colors based on ownership status.

## Blip Colors & Status
- **Available Properties**: Blue (BLIP_MODIFIER_MP_COLOR_32)
- **Rented Properties**: Yellow (BLIP_MODIFIER_MP_COLOR_8) 
- **Owned Properties**: Green (BLIP_MODIFIER_MP_COLOR_2)

## Key Features

### 1. Proper Loading Order
- Properties are loaded from database first
- Blips are created only after properties are fully loaded
- Prevents timing issues that caused missing blips

### 2. Dynamic Updates
- Blips automatically update when property ownership changes
- Real-time color changes when properties are bought/sold/rented
- All clients receive updates simultaneously

### 3. Error Handling
- Validates property data before creating blips
- Checks for existing blips to prevent duplicates
- Comprehensive debug logging for troubleshooting

### 4. Cleanup System
- Automatic cleanup on resource stop
- Player disconnect cleanup
- Memory leak prevention

## Testing the System

### 1. Enable Debug Mode
Set `Config.Debug = true` in `config.lua` to see detailed logging.

### 2. Test Commands
- `/refreshblips` - Manually refresh all property blips (debug mode only)
- `/housing` - View your owned properties

### 3. Test Scenarios

#### Basic Functionality
1. Start the resource
2. Check console for "Housing system initialized successfully"
3. Look for "Loaded X properties" message
4. Verify "Created X property blips" message
5. Check map for property blips

#### Ownership Changes
1. Purchase a property (buy or rent)
2. Verify blip color changes immediately
3. Sell the property
4. Verify blip returns to available color

#### Multiple Players
1. Have multiple players online
2. One player purchases a property
3. All players should see the blip color change

### 4. Troubleshooting

#### No Blips Showing
- Check if properties exist in database
- Verify `rsg_housing_properties` table has data
- Check console for error messages
- Use `/refreshblips` command

#### Wrong Colors
- Verify ownership data in `rsg_housing_ownership` table
- Check if property IDs match between tables
- Look for debug messages about ownership status

#### Blips Not Updating
- Check server console for ownership change events
- Verify client receives `propertyOwnershipChanged` event
- Test with `/refreshblips` command

## Debug Information

### Console Messages
When `Config.Debug = true`, you'll see:
```
[RSG Housing] Housing system initialized successfully
[RSG Housing] Loaded X properties
[RSG Housing] Creating property blips...
[RSG Housing] Created blip for property: Property Name (ID: X)
[RSG Housing] Created X property blips
[RSG Housing] Property ownership changed: X
```

### Common Issues
1. **Blips appear but wrong color**: Database ownership data issue
2. **No blips at all**: Properties not loading from database
3. **Blips don't update**: Event system not working properly
4. **Duplicate blips**: Cleanup system not working

## Configuration

### Blip Settings in config.lua
```lua
Config.HouseBlip = {
    Sprite = 374778363, -- House blip sprite for RDR3
    Scale = 0.7,
    Color = 'BLIP_MODIFIER_MP_COLOR_32' -- Available (Blue)
}

Config.RentedBlip = {
    Sprite = 374778363,
    Scale = 0.7,
    Color = 'BLIP_MODIFIER_MP_COLOR_8' -- Rented (Yellow)
}

Config.OwnedBlip = {
    Sprite = 374778363,
    Scale = 0.7,
    Color = 'BLIP_MODIFIER_MP_COLOR_2' -- Owned (Green)
}
```

## Performance Considerations
- Blips are only created once per property
- Updates only affect specific changed properties
- Cleanup prevents memory leaks
- Efficient table operations for large property counts

## Integration Notes
- Works with existing RSG-Core framework
- Compatible with rsg-target system
- Integrates with property ownership system
- Supports multiple database systems (MySQL/oxmysql)