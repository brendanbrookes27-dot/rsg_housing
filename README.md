# RSG Housing - Advanced Housing System for RedM

A comprehensive housing system designed specifically for the RSG Framework v2, providing players with the ability to buy, rent, and manage properties in the Red Dead Redemption 2 world.

## 🏠 Features

### Core Features
- **Property Management**: Buy, rent, and sell properties
- **Multiple Property Types**: Houses, apartments, mansions, and cabins
- **Rent System**: Automated rent collection with eviction system
- **Key Management**: Give keys to friends and roommates
- **Property Security**: Lock/unlock properties
- **Blip System**: Visual indicators for property status

### Advanced Features
- **Furniture System**: Purchase and place furniture in properties
- **Storage System**: Secure storage containers with upgrade options
- **Interior Shells**: Support for custom MLO/IPL interiors
- **Roommate System**: Share properties with other players
- **Admin Tools**: Create and manage properties via commands
- **Logging System**: Comprehensive audit trail for all actions

### User Interface
- **Modern Web UI**: Responsive HTML/CSS/JS interface
- **Mobile Friendly**: Works on all screen sizes
- **Interactive Menus**: Easy-to-use property management
- **Real-time Updates**: Live property status updates

## 📋 Requirements

- **RSG Core Framework v2**
- **oxmysql** (Database)
- **rsg-target** (Optional, for interaction zones)
- **rsg-menu** (Menu system)
- **rsg-input** (Input dialogs)
- **rsg-inventory** (Optional, for storage system)

## 🚀 Installation

1. **Download and Extract**
   ```bash
   cd resources
   git clone https://github.com/yourusername/rsg_housing.git
   ```

2. **Database Setup**
   - Import the SQL file: `sql/housing.sql`
   - This will create all necessary tables and insert example properties

3. **Configuration**
   - Edit `config.lua` to customize settings
   - Adjust property locations, prices, and features
   - Configure storage limits and furniture options

4. **Add to server.cfg**
   ```
   ensure rsg_housing
   ```

5. **Restart Server**

## ⚙️ Configuration

### Basic Settings
```lua
Config.Debug = false                    -- Enable debug mode
Config.UseTarget = true                 -- Use rsg-target for interactions
Config.RentPaymentInterval = 7          -- Days between rent payments
Config.MaxHousesPerPlayer = 3           -- Maximum properties per player
```

### Property Types
```lua
Config.PropertyTypes = {
    ['house'] = {
        label = 'House',
        rentPrice = 50,
        buyPrice = 2500,
        storage = true,
        furniture = true,
        maxRoommates = 4
    }
}
```

### Storage Configuration
```lua
Config.Storage = {
    MaxSlots = 50,
    MaxWeight = 400000,
    RestrictedItems = {
        'weapon_pistol',
        'weapon_rifle'
    }
}
```

## 🎮 Usage

### For Players

#### Buying/Renting Properties
1. Approach any available property (marked with blips)
2. Press `G` to interact or use the target system
3. Choose to buy or rent the property
4. Confirm the transaction

#### Managing Properties
- **Enter Property**: Press `G` at the door
- **Lock/Unlock**: Use the property management menu
- **Give Keys**: Add friends or roommates
- **Pay Rent**: Use the property menu when rent is due

#### Furniture System
1. Enter your property
2. Open the furniture store from the property menu
3. Purchase furniture items
4. Enter placement mode to position furniture
5. Use WASD to move, Q/E to rotate, ENTER to place

#### Storage System
1. Enter your property
2. Approach the storage area
3. Press `G` to access storage
4. Upgrade storage capacity through the storage menu

### For Administrators

#### Creating Properties
```
/createhouse [type] [price]
```
- Stand at the desired location
- Use the command to create a new property
- Fill in the details through the input dialog

#### Managing Properties
```
/deletehouse [id]        -- Delete a property
/givehouse [id] [player] -- Give property to player
/removehouse [id]        -- Remove property from player
```

## 🗄️ Database Schema

The system uses 7 main tables:

- **rsg_housing_properties**: Property definitions
- **rsg_housing_ownership**: Property ownership records
- **rsg_housing_keys**: Key access management
- **rsg_housing_furniture**: Placed furniture items
- **rsg_housing_storage**: Storage containers
- **rsg_housing_vehicles**: Garage vehicle storage
- **rsg_housing_logs**: Action audit trail

## 🔧 API Reference

### Server Exports

```lua
-- Check if player owns property
exports['rsg_housing']:PlayerOwnsProperty(citizenid, propertyId)

-- Check if player has keys
exports['rsg_housing']:PlayerHasKeys(citizenid, propertyId)

-- Get property information
exports['rsg_housing']:GetProperty(propertyId)

-- Get property ownership
exports['rsg_housing']:GetPropertyOwnership(propertyId)
```

### Client Events

```lua
-- Open property UI
TriggerEvent('rsg_housing:client:openUI', propertyData)

-- Enter property
TriggerEvent('rsg_housing:client:enterProperty', propertyId)

-- Toggle furniture mode
TriggerEvent('rsg_housing:client:toggleFurnitureMode', propertyId)
```

## 🎨 Customization

### Adding New Property Types
1. Edit `config.lua` and add to `Config.PropertyTypes`
2. Create corresponding interior shells in `Config.Shells`
3. Add properties to the database or use admin commands

### Custom Furniture
1. Add furniture items to `Config.Furniture.Categories`
2. Specify model names and prices
3. Furniture will automatically appear in the store

### Interior Shells
```lua
Config.Shells = {
    ['your_shell_name'] = {
        label = 'Custom Interior',
        hash = 'your_shell_hash',
        doorCoords = vector3(0.0, 0.0, 0.0),
        stashCoords = vector3(2.0, 3.0, 1.0),
        clothingCoords = vector3(-2.0, 3.0, 1.0),
        logoutCoords = vector3(0.0, 5.0, 1.0)
    }
}
```

## 🐛 Troubleshooting

### Common Issues

**Properties not showing blips**
- Check if properties exist in database
- Verify coordinates are correct
- Ensure resource started properly

**Storage not working**
- Verify rsg-inventory is installed and started
- Check storage table exists in database
- Ensure player has property access

**Furniture not spawning**
- Check model names in config
- Verify furniture table has correct data
- Ensure player is inside property

### Debug Mode
Enable debug mode in config.lua:
```lua
Config.Debug = true
```

This will show additional console output for troubleshooting.

## 📝 Changelog

### Version 2.0.0
- Complete rewrite for RSG Framework v2
- Added furniture placement system
- Implemented storage upgrades
- New modern web UI
- Enhanced security features
- Improved performance and stability

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue on GitHub
- Join our Discord server
- Check the documentation wiki

## 🙏 Credits

- **RSG Framework Team** - Core framework
- **Community Contributors** - Testing and feedback
- **RedM Community** - Inspiration and resources

---

**Made with ❤️ for the RedM community**