# RSG Housing - Advanced Features

## Overview
This document covers the advanced features added to the RSG Housing system, including MLO support, dynamic house creation, and job-based permissions.

## Features

### 1. MLO Support
The housing system now supports both traditional shells and MLO (Map Load Object) interiors.

#### Configuration
MLOs are configured in `config/config.lua`:

```lua
Config.MLOs = {
    ['custom_house_mlo'] = {
        label = 'Custom House MLO',
        coords = vector3(0.0, 0.0, 0.0), -- Relative spawn point inside MLO
        heading = 0.0,
        storage = vector3(5.0, 5.0, 0.0),
        wardrobe = vector3(-5.0, 5.0, 0.0),
        logout = vector3(0.0, 10.0, 0.0)
    }
}
```

#### Usage
- Properties can use either `shell` or `mlo` field
- If `mlo` is specified and not empty, it takes precedence over `shell`
- If MLO config is not found, the system falls back to property coordinates
- Shell system remains as fallback for compatibility

### 2. Dynamic House Creation
Authorized players can create new houses dynamically using the `/createhouse` command.

#### Job Permissions
Configure which jobs can create houses in `config/config.lua`:

```lua
Config.HouseCreationJobs = {
    ['vallaw'] = {
        minGrade = 2, -- Minimum job grade required
        label = 'Valentine Law'
    }
    -- Add more jobs as needed
}
```

#### Usage
1. Player with authorized job uses `/createhouse` command
2. System checks job and grade permissions
3. Player walks to desired location and presses ENTER to set position
4. Configuration menu opens to set:
   - House label/name
   - Property type (house, apartment, cabin, etc.)
   - Purchase price
   - Weekly rent (optional)
   - MLO interior (optional)
5. Player confirms creation
6. House is added to database and appears for all players

#### Controls
- **ENTER**: Set house location
- **ESC**: Cancel house creation

### 3. RedM Compatibility Fixes
Fixed text drawing functions for RedM compatibility:

#### Text Drawing Updates
- Replaced `SetTextFont()` with `CreateVarString()` and `DisplayText()`
- Updated `SetTextColour()` to `SetTextColor()`
- Added proper text centering with `SetTextCentre(true)`

#### Example Fix
```lua
-- Old (FiveM)
SetTextFont(4)
SetTextColour(255, 255, 255, 255)
DrawText(0.5, 0.05)

-- New (RedM)
local str = CreateVarString(10, "LITERAL_STRING", text)
SetTextScale(0.35, 0.35)
SetTextColor(255, 255, 255, 255)
SetTextCentre(true)
DisplayText(str, 0.5, 0.05)
```

## Database Changes

### New Columns
The `rsg_housing_properties` table has been updated with:
- `mlo` varchar(100) - MLO interior name
- `created_by` varchar(50) - Creator's citizen ID
- `created_date` timestamp - Creation timestamp

### Migration
For existing installations, run `migration_mlo_support.sql` to add the new columns.

## Installation

### New Installation
1. Run `rsg_housing.sql` to create all tables with MLO support

### Existing Installation
1. Run `migration_mlo_support.sql` to add MLO support to existing tables

## Configuration Examples

### Adding MLO Support
```lua
-- In config/config.lua
Config.MLOs = {
    ['rdr2_house_01'] = {
        label = 'RDR2 House Interior',
        coords = vector3(0.0, 0.0, 0.0),
        heading = 0.0,
        storage = vector3(3.0, 5.0, 0.0),
        wardrobe = vector3(-3.0, 5.0, 0.0),
        logout = vector3(0.0, 8.0, 0.0)
    }
}
```

### Adding Job Permissions
```lua
-- In config/config.lua
Config.HouseCreationJobs = {
    ['vallaw'] = { minGrade = 2, label = 'Valentine Law' },
    ['sheriff'] = { minGrade = 1, label = 'Sheriff Department' },
    ['realestate'] = { minGrade = 0, label = 'Real Estate Agent' }
}
```

## Commands

### `/createhouse`
- **Permission**: Configured jobs with minimum grade
- **Usage**: `/createhouse`
- **Description**: Start dynamic house creation process

## Events

### Client Events
- `rsg_housing:client:startHouseCreation` - Start house creation mode
- `rsg_housing:client:updateProperties` - Update properties list
- `rsg_housing:client:refreshMarkers` - Refresh property markers
- `rsg_housing:client:refreshBlips` - Refresh property blips

### Server Events
- `rsg_housing:server:createHouse` - Handle house creation from client

## Troubleshooting

### Common Issues

1. **Text not displaying properly**
   - Ensure RedM-compatible text functions are used
   - Check `CreateVarString()` and `DisplayText()` implementation

2. **MLO not working**
   - Verify MLO is properly configured in `Config.MLOs`
   - Check MLO coordinates are relative to property location
   - Ensure MLO resource is started before housing script

3. **House creation permission denied**
   - Check player's job name matches config
   - Verify player's job grade meets minimum requirement
   - Ensure `Config.HouseCreationJobs` is properly configured

4. **Database errors**
   - Run migration script for existing installations
   - Check all required columns exist in database
   - Verify foreign key constraints are intact

## Performance Considerations

- MLO support adds minimal overhead
- Dynamic house creation is event-driven (no continuous loops)
- Property refresh only occurs when new houses are created
- Text drawing optimizations for RedM compatibility

## Future Enhancements

Potential future additions:
- House deletion command for authorized users
- Property editing/modification system
- Advanced MLO configuration with multiple spawn points
- Property categories and filtering
- Bulk property import/export system