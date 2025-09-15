# RSG Housing System v2.0

A comprehensive property management system for RedM servers using the RSG Framework. This system features marker-based property purchasing, extensive property locations across the map, and specialized saloon business management.

## Features

### 🏠 Property System
- **40+ Properties** across all major towns and wilderness areas
- **Multiple Property Types**: Houses, Apartments, Cabins, Mansions, Saloons, Shops
- **Marker-Based Purchasing**: Visual markers show available properties
- **Blip System**: Map blips for easy property identification
- **Interior Shells**: RedM-compatible interior system using coordinate teleportation

### 🍺 Saloon Business System
- **12 Saloon Locations** across the map including Valentine, Saint Denis, Rhodes, etc.
- **Daily Earnings**: Automatic income generation for saloon owners
- **Staff Management**: Hire bartenders and security for increased profits
- **Earnings Collection**: Collect accumulated profits from your saloon

### 🔑 Property Management
- **Ownership System**: Buy or rent properties
- **Key Management**: Give/remove keys to other players
- **Lock System**: Secure your properties
- **Storage System**: Property-based storage with configurable capacity
- **Wardrobe Access**: Clothing management in properties

### 🗺️ Extensive Locations

#### Valentine Area
- Valentine Family Home ($2,500)
- Valentine Cottage ($2,000)
- Valentine Apartment ($1,200)
- Keane's Saloon ($15,000)

#### Saint Denis Area
- Saint Denis Grand Estate ($15,000)
- Multiple Apartments ($1,600-$1,800)
- Saint Denis Townhouse ($5,500)
- Doyle's Tavern ($25,000)
- The Riverboat Saloon ($22,000)

#### Rhodes Area
- Rhodes Manor ($8,500)
- Rhodes Family Home ($3,200)
- Rhodes Cottage ($2,700)
- Bastille Saloon ($18,000)

#### Strawberry Area
- Strawberry Mountain Home ($3,500)
- Strawberry Cabin ($2,800)
- Strawberry Lodge ($4,200)
- Strawberry Welcome Center Saloon ($12,000)

#### Blackwater Area
- Blackwater Riverside Home ($4,500)
- Blackwater Family Estate ($12,000)
- Blackwater Apartment ($1,400)
- Blackwater Saloon ($20,000)

#### Wilderness Locations
- Grizzlies Cabin ($3,200)
- Big Valley Cabin ($2,900)
- Roanoke Ridge Cabin ($2,600)
- Bayou Cabin ($2,300)

#### Additional Towns
- **Armadillo**: Desert homes and saloon
- **Tumbleweed**: Ghost town properties
- **Annesburg**: Miner's houses and saloon
- **Van Horn**: Trading post properties
- **Emerald Ranch**: Ranch saloon
- **MacFarlane's Ranch**: Cattle country saloon

## Installation

### 1. Database Setup
```sql
-- Import the provided SQL file
source rsg_housing.sql
```

### 2. Resource Installation
1. Place the `rsg_housing` folder in your resources directory
2. Add to your `server.cfg`:
```
ensure rsg_housing
```

### 3. Dependencies
Ensure you have these resources installed:
- `rsg-core`
- `rsg-menu`
- `rsg-input`
- `oxmysql`
- `rsg-inventory` (for storage)
- `rsg-clothing` (for wardrobe)

## Configuration

### Config.lua Settings
```lua
Config.MaxPropertiesPerPlayer = 5  -- Maximum properties per player
Config.PropertyTaxRate = 0.02      -- 2% weekly tax rate
Config.MarkerDistance = 50.0       -- Distance to show markers
Config.InteractionDistance = 3.0   -- Distance to interact
```

### Property Types
- **House**: Standard residential property with storage and wardrobe
- **Apartment**: Smaller residential unit with limited storage
- **Cabin**: Rustic wilderness property
- **Mansion**: Luxury property with large storage capacity
- **Saloon**: Business property with earning potential
- **Shop**: Commercial property for business use

## Usage

### For Players

#### Purchasing Properties
1. Approach any property marker (green house icon)
2. Press `G` to interact
3. Select "Purchase Property" from the menu
4. Confirm the purchase

#### Renting Properties
1. Find a property that allows rentals
2. Press `G` to interact
3. Select "Rent Property"
4. Pay weekly rent to maintain access

#### Managing Properties
1. Approach your owned property
2. Press `G` to interact
3. Access management options:
   - Enter/Exit property
   - Lock/Unlock
   - Give/Remove keys
   - Sell property

#### Saloon Management
1. Purchase a saloon property
2. Access saloon management menu
3. Options available:
   - View daily/total earnings
   - Collect accumulated profits
   - Hire staff (bartenders, security)
   - Manage business operations

### For Administrators

#### Adding New Properties
1. Edit `config/properties.lua`
2. Add new property entry:
```lua
{
    id = 'unique_property_id',
    label = 'Property Name',
    type = 'house', -- or apartment, cabin, mansion, saloon
    coords = vector3(x, y, z),
    heading = 0.0,
    price = 2500,
    rent = 150, -- 0 for no rent option
    shell = 'basic_house',
    garage = false,
    description = 'Property description'
}
```

#### Database Management
- Property ownership: `rsg_housing_ownership`
- Property keys: `rsg_housing_keys`
- Storage data: `rsg_housing_storage`
- Saloon earnings: `rsg_housing_saloon_earnings`
- Activity logs: `rsg_housing_logs`

## Commands

### Player Commands
- `/exitproperty` - Exit current property (also F7 key)

### Admin Commands (if implemented)
- Add admin commands as needed for your server

## API/Exports

### Client Exports
```lua
-- Check if player is inside property
local isInside = exports['rsg_housing']:IsInsideProperty()

-- Get current property
local property = exports['rsg_housing']:GetCurrentProperty()
```

### Server Exports
```lua
-- Get player properties
local properties = exports['rsg_housing']:GetPlayerProperties(citizenid)

-- Check property access
local hasAccess = exports['rsg_housing']:HasPropertyAccess(citizenid, propertyId)
```

## Customization

### Markers
Customize marker appearance in `config/config.lua`:
```lua
Config.Markers = {
    ForSale = {
        type = 0x94FDAE17,
        color = {r = 0, g = 255, b = 0, a = 200},
        scale = {x = 1.0, y = 1.0, z = 1.0}
    }
}
```

### Interior Shells
Add custom interior configurations:
```lua
Config.Shells = {
    ['custom_interior'] = {
        label = 'Custom Interior',
        coords = vector3(0.0, 2.0, 1.0),
        heading = 0.0,
        storage = vector3(2.0, 5.0, 1.0),
        wardrobe = vector3(-2.0, 5.0, 1.0)
    }
}
```

## Troubleshooting

### Common Issues

1. **Markers not showing**
   - Check if properties are loaded in database
   - Verify marker distance settings
   - Ensure client scripts are running

2. **Purchase not working**
   - Check player money
   - Verify property availability
   - Check max properties limit

3. **Interior not loading**
   - Verify shell configuration
   - Check coordinate accuracy
   - Ensure proper heading values

### Debug Mode
Enable debug mode in config:
```lua
Config.Debug = true
```

## Performance

### Optimization Features
- Efficient marker rendering with distance checks
- Optimized database queries
- Minimal resource usage
- Smart blip management

### Recommended Settings
- Marker Distance: 50.0 (balance between visibility and performance)
- Blip Update Interval: 30 seconds
- Property limit per player: 5

## Support

For support and updates:
1. Check the documentation
2. Review configuration files
3. Enable debug mode for troubleshooting
4. Check server console for errors

## Changelog

### Version 2.0.0
- Complete rewrite from scratch
- Marker-based property system
- 40+ property locations
- Saloon business system
- Enhanced UI/UX
- RedM compatibility improvements
- Comprehensive database schema
- Advanced property management

## License

This resource is provided as-is for RSG Framework servers. Modify as needed for your server requirements.

---

**RSG Housing System v2.0** - Advanced Property Management for RedM