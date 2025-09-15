# Installation Guide - RSG Housing

This guide will walk you through the complete installation process for the RSG Housing system with enhanced blip functionality.

## Prerequisites

Before installing RSG Housing, ensure you have the following:

### Required Resources
- **RSG Core Framework v2** - The main framework
- **oxmysql** - Database connector
- **rsg-menu** - Menu system for interactions
- **rsg-input** - Input dialog system

### Optional Resources (Recommended)
- **rsg-target** - For enhanced interaction zones
- **rsg-inventory** - For storage system functionality
- **rsg-clothing** - For wardrobe functionality

## Step-by-Step Installation

### 1. Download the Resource

```bash
cd /path/to/your/server/resources
git clone https://github.com/yourusername/rsg_housing.git
```

Or download and extract the ZIP file to your resources folder.

### 2. Database Setup

#### Option A: Automatic Setup
1. Start your server with the resource
2. The system will automatically create the required tables

#### Option B: Manual Setup
1. Open your database management tool (phpMyAdmin, HeidiSQL, etc.)
2. Import the SQL file: `sql/housing.sql`
3. Verify all tables were created successfully

#### Required Tables
- `rsg_housing_properties`
- `rsg_housing_ownership`
- `rsg_housing_keys`
- `rsg_housing_furniture`
- `rsg_housing_storage`
- `rsg_housing_vehicles`
- `rsg_housing_logs`

### 3. Configuration

#### Basic Configuration
Edit `config.lua` and adjust the following settings:

```lua
-- Enable/disable debug mode
Config.Debug = false

-- Use rsg-target for interactions (recommended)
Config.UseTarget = true

-- Rent payment interval in days
Config.RentPaymentInterval = 7

-- Maximum properties per player
Config.MaxHousesPerPlayer = 3
```

#### Property Locations
The default configuration includes properties in:
- Valentine
- Strawberry
- Saint Denis
- Rhodes

You can modify these locations or add new ones in the `Config.Properties` table.

#### Storage Settings
```lua
Config.Storage = {
    MaxSlots = 50,          -- Default storage slots
    MaxWeight = 400000,     -- Default weight limit (400kg)
    RestrictedItems = {     -- Items that cannot be stored
        'weapon_pistol',
        'weapon_rifle'
    }
}
```

### 4. Server Configuration

Add the resource to your `server.cfg`:

```cfg
# RSG Housing System
ensure rsg_housing
```

Make sure it's loaded after the required dependencies:

```cfg
# Core Framework
ensure rsg-core
ensure oxmysql

# Menu Systems
ensure rsg-menu
ensure rsg-input

# Optional but recommended
ensure rsg-target
ensure rsg-inventory

# Housing System
ensure rsg_housing
```

### 5. Permissions Setup

#### Admin Commands
The following commands require admin permissions:
- `/createhouse` - Create new properties
- `/deletehouse` - Delete properties
- `/givehouse` - Give property to player
- `/removehouse` - Remove property from player

Ensure your admin system recognizes these permissions.

### 6. Testing the Installation

1. **Start the server**
2. **Join the game**
3. **Check for blips** - You should see property blips on the map
4. **Test interaction** - Approach a property and press G or use target
5. **Check console** - Look for any error messages

#### Testing the Blip System
1. **Enable debug mode** - Set `Config.Debug = true` in config.lua
2. **Restart the resource** - `/restart rsg_housing`
3. **Check console messages**:
   ```
   [RSG Housing] Housing system initialized successfully
   [RSG Housing] Loaded X properties
   [RSG Housing] Creating property blips...
   [RSG Housing] Created blip for property: Property Name (ID: X)
   [RSG Housing] Created X property blips
   ```
4. **Test blip colors**:
   - Available properties: Blue blips
   - Rented properties: Yellow blips  
   - Owned properties: Green blips
5. **Test ownership changes**:
   - Purchase a property
   - Verify blip color changes immediately
   - Use `/refreshblips` command if needed

#### Common Startup Messages
```
[RSG Housing] Housing system initialized successfully
[RSG Housing] Loaded X properties
[RSG Housing] Storage system initialized
[RSG Housing] Created X property blips
```

## Troubleshooting Installation

### Resource Not Starting
- Check server console for error messages
- Verify all dependencies are installed and started
- Ensure `fxmanifest.lua` is not corrupted

### Database Errors
- Verify MySQL/MariaDB is running
- Check database credentials in oxmysql configuration
- Ensure database user has CREATE and INSERT permissions

### No Property Blips
- Check if properties exist in database
- Verify coordinates are valid
- Enable debug mode to see detailed logs

### Permission Errors
- Ensure admin permissions are configured correctly
- Check RSG Core admin system setup
- Verify player has required permissions

## Post-Installation Setup

### 1. Create Additional Properties
Use the admin command to create more properties:
```
/createhouse house 2500
```

### 2. Configure Property Types
Add custom property types in `config.lua`:
```lua
Config.PropertyTypes['custom'] = {
    label = 'Custom Property',
    rentPrice = 100,
    buyPrice = 5000,
    storage = true,
    furniture = true,
    maxRoommates = 6
}
```

### 3. Add Custom Furniture
Extend the furniture catalog:
```lua
Config.Furniture.Categories['custom'] = {
    label = 'Custom Items',
    items = {
        ['custom_item'] = {
            label = 'Custom Item',
            price = 150,
            model = 'prop_custom_model'
        }
    }
}
```

### 4. Set Up Webhooks (Optional)
Configure Discord webhooks for logging:
```lua
Config.Webhooks = {
    ['property_purchase'] = 'your_webhook_url_here',
    ['property_sale'] = 'your_webhook_url_here',
    -- ... other webhooks
}
```

## Performance Optimization

### Database Optimization
- Regularly clean old log entries
- Index frequently queried columns
- Monitor database performance

### Server Performance
- Adjust property loading distance if needed
- Limit furniture objects per property
- Monitor memory usage

### Client Performance
- Reduce blip update frequency if needed
- Optimize furniture rendering distance
- Use LOD models for distant furniture

## Backup and Maintenance

### Regular Backups
Create regular backups of:
- Database tables (especially property data)
- Configuration files
- Custom modifications

### Maintenance Tasks
- Clean old log entries monthly
- Update property prices seasonally
- Review and update restricted items list

## Getting Help

If you encounter issues during installation:

1. **Check the logs** - Server console and database logs
2. **Review configuration** - Ensure all settings are correct
3. **Test dependencies** - Verify all required resources work
4. **Community support** - Ask for help in Discord/forums
5. **Create an issue** - Report bugs on GitHub

## Next Steps

After successful installation:
- Read the [User Guide](USER_GUIDE.md) for gameplay instructions
- Check the [API Documentation](API.md) for development
- Review [Configuration Options](CONFIGURATION.md) for customization

---

**Installation complete! Your players can now enjoy the RSG Housing system.**