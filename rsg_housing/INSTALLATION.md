# RSG Housing System - Installation Guide

## Prerequisites

Before installing RSG Housing System, ensure you have:

1. **RSG Framework** properly installed and running
2. **MySQL/MariaDB** database server
3. **oxmysql** resource installed
4. Required dependencies (listed below)

## Dependencies

The following resources must be installed and running:

### Required Dependencies
- `rsg-core` - Core framework
- `rsg-menu` - Menu system
- `rsg-input` - Input dialogs
- `oxmysql` - Database connector

### Optional Dependencies
- `rsg-inventory` - For property storage functionality
- `rsg-clothing` - For wardrobe functionality
- `rsg-target` - If using target system instead of markers

## Step-by-Step Installation

### 1. Download and Extract
1. Download the RSG Housing System files
2. Extract to your server's `resources` folder
3. Rename the folder to `rsg_housing` if needed

### 2. Database Setup

#### Option A: Automatic Setup
The resource will automatically create tables on first run if they don't exist.

#### Option B: Manual Setup
Run the provided SQL file in your database:

```bash
mysql -u username -p database_name < rsg_housing.sql
```

Or import via phpMyAdmin/Adminer:
1. Open your database management tool
2. Select your server database
3. Import the `rsg_housing.sql` file

### 3. Server Configuration

Add to your `server.cfg`:

```cfg
# RSG Housing System
ensure rsg_housing
```

**Important**: Ensure dependencies are loaded before rsg_housing:

```cfg
# Dependencies
ensure rsg-core
ensure rsg-menu
ensure rsg-input
ensure oxmysql
ensure rsg-inventory
ensure rsg-clothing

# RSG Housing System
ensure rsg_housing
```

### 4. Configuration

#### Basic Configuration
Edit `config/config.lua` to match your server needs:

```lua
Config.Debug = false -- Set to true for debugging
Config.MaxPropertiesPerPlayer = 5 -- Adjust as needed
Config.MarkerDistance = 50.0 -- Marker visibility distance
Config.InteractionDistance = 3.0 -- Interaction distance
```

#### Property Locations
The system comes with 40+ pre-configured properties. To add more:

1. Edit `config/properties.lua`
2. Add new property entries following the existing format
3. Restart the resource

#### Marker Customization
Customize markers in `config/config.lua`:

```lua
Config.Markers = {
    ForSale = {
        type = 0x94FDAE17, -- Marker hash
        color = {r = 0, g = 255, b = 0, a = 200}, -- RGBA color
        scale = {x = 1.0, y = 1.0, z = 1.0} -- Scale
    }
}
```

### 5. Permissions (Optional)

If using a permission system, add these permissions:

```lua
-- Admin permissions
'housing.admin' -- Full housing management
'housing.create' -- Create new properties
'housing.delete' -- Delete properties

-- Player permissions (usually default)
'housing.buy' -- Purchase properties
'housing.rent' -- Rent properties
'housing.manage' -- Manage owned properties
```

## Verification

### 1. Check Resource Loading
After starting your server, verify in console:

```
[rsg_housing] Loading 40+ properties from database
[rsg_housing] RSG Housing System v2.0 loaded successfully
```

### 2. In-Game Testing
1. Join your server
2. Go to Valentine (coordinates: -322.89, 803.68, 117.88)
3. Look for green house markers
4. Press `G` near a marker to test interaction

### 3. Database Verification
Check that tables were created:

```sql
SHOW TABLES LIKE 'rsg_housing%';
```

Should show:
- `rsg_housing_properties`
- `rsg_housing_ownership`
- `rsg_housing_keys`
- `rsg_housing_storage`
- `rsg_housing_saloon_earnings`
- `rsg_housing_logs`

## Common Installation Issues

### Issue 1: Resource Not Loading
**Symptoms**: No console messages, markers not showing
**Solutions**:
- Check `server.cfg` syntax
- Verify resource name matches folder name
- Ensure dependencies are loaded first

### Issue 2: Database Connection Error
**Symptoms**: MySQL connection errors in console
**Solutions**:
- Verify oxmysql configuration
- Check database credentials
- Ensure database exists

### Issue 3: Markers Not Visible
**Symptoms**: No property markers in-game
**Solutions**:
- Check `Config.MarkerDistance` setting
- Verify properties loaded from database
- Enable debug mode to check console

### Issue 4: Menu Not Opening
**Symptoms**: Pressing G doesn't open menu
**Solutions**:
- Verify rsg-menu is installed and running
- Check for script errors in console
- Ensure proper key binding

### Issue 5: Purchase Not Working
**Symptoms**: Can't buy properties
**Solutions**:
- Check player money
- Verify database permissions
- Check max properties limit

## Advanced Configuration

### Custom Interior Shells
Add custom interiors in `config/config.lua`:

```lua
Config.Shells = {
    ['my_custom_interior'] = {
        label = 'My Custom Interior',
        coords = vector3(0.0, 2.0, 1.0),
        heading = 0.0,
        storage = vector3(2.0, 5.0, 1.0),
        wardrobe = vector3(-2.0, 5.0, 1.0),
        logout = vector3(0.0, 8.0, 1.0)
    }
}
```

### Webhook Integration
Configure webhooks for logging:

```lua
Config.Webhooks = {
    ['property_purchase'] = 'your_webhook_url_here',
    ['property_sale'] = 'your_webhook_url_here',
    ['saloon_purchase'] = 'your_webhook_url_here'
}
```

### Economy Settings
Adjust economic factors:

```lua
Config.Economy = {
    ['property_tax_multiplier'] = 0.02, -- 2% weekly tax
    ['rent_multiplier'] = 0.1, -- 10% of property value
    ['sale_tax'] = 0.05, -- 5% sale tax
    ['saloon_income_multiplier'] = 0.15 -- 15% daily income
}
```

## Performance Optimization

### Recommended Settings
For optimal performance:

```lua
Config.MarkerDistance = 50.0 -- Balance visibility/performance
Config.BlipUpdateInterval = 30000 -- 30 seconds
Config.MaxPropertiesPerPlayer = 5 -- Prevent hoarding
```

### Server Resources
- **RAM Usage**: ~10-15MB
- **CPU Usage**: Minimal (optimized loops)
- **Database**: Efficient queries with proper indexing

## Backup Recommendations

### Before Installation
1. Backup your database
2. Backup existing housing resources (if any)
3. Create server restore point

### Regular Backups
- Daily database backups
- Weekly full server backups
- Property data export monthly

## Support and Updates

### Getting Help
1. Check this installation guide
2. Review the main README.md
3. Enable debug mode for troubleshooting
4. Check server console for errors

### Updating
When updating the resource:
1. Stop the server
2. Backup current version
3. Replace files (keep config changes)
4. Run any new SQL updates
5. Restart server

## Security Considerations

### Database Security
- Use strong database passwords
- Limit database user permissions
- Regular security updates

### Server Security
- Validate all user inputs
- Use proper permission checks
- Monitor for exploits

---

**Installation Complete!** Your RSG Housing System should now be running. Players can start purchasing properties using the marker system throughout the map.