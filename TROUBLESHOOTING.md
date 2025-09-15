# RSG Housing - Troubleshooting Guide

This guide covers common issues and their solutions for the RSG Housing system.

## Common Errors

### 1. CreateInterior Function Error

**Error Message:**
```
SCRIPT ERROR: attempt to call a nil value (global 'CreateInterior')
```

**Cause:** The `CreateInterior` function doesn't exist in RedM/RSG framework.

**Solution:** This has been fixed in the latest version. The system now uses coordinate-based teleportation instead of interior creation.

**If you still see this error:**
1. Ensure you're using the latest version of the resource
2. Restart the resource: `/restart rsg_housing`
3. Check that your RedM server is up to date

### 2. Property Blips Not Showing

**Symptoms:**
- No property blips appear on the map
- Console shows "Created 0 property blips"

**Solutions:**
1. **Enable debug mode:**
   ```lua
   Config.Debug = true
   ```

2. **Check database:**
   ```sql
   SELECT * FROM rsg_housing_properties;
   ```

3. **Refresh blips manually:**
   ```
   /refreshblips
   ```

4. **Verify coordinates:**
   - Ensure property coordinates are valid
   - Check that properties exist in the database

### 3. Database Connection Issues

**Error Messages:**
- "Table doesn't exist"
- "Access denied for user"
- "Unknown database"

**Solutions:**
1. **Run the SQL file:**
   ```bash
   mysql -u username -p database_name < rsg_housing.sql
   ```

2. **Check oxmysql configuration:**
   - Verify database credentials
   - Ensure oxmysql is started before rsg_housing

3. **Check permissions:**
   ```sql
   GRANT ALL PRIVILEGES ON database_name.* TO 'username'@'localhost';
   FLUSH PRIVILEGES;
   ```

### 4. Property Entry/Exit Issues

**Symptoms:**
- Can't enter properties
- Teleportation doesn't work
- Screen stays black

**Solutions:**
1. **Check shell configuration:**
   - Verify shell exists in Config.Shells
   - Check coordinate offsets are reasonable

2. **Enable debug logging:**
   ```lua
   Config.Debug = true
   ```

3. **Check property data:**
   - Ensure property has valid coordinates
   - Verify shell is assigned to property

### 5. Menu/UI Not Working

**Symptoms:**
- Property menu doesn't open
- UI elements not responding
- JavaScript errors in F8 console

**Solutions:**
1. **Check dependencies:**
   - Ensure rsg-menu is installed and working
   - Verify rsg-input is available
   - Check rsg-core is properly loaded

2. **Clear browser cache:**
   - Press F8 in game
   - Type: `resmon`
   - Look for high resource usage

3. **Check NUI callbacks:**
   - Enable debug mode
   - Check server console for callback errors

### 6. Storage System Issues

**Symptoms:**
- Can't access storage
- Items disappearing
- Storage not saving

**Solutions:**
1. **Check inventory system:**
   - Ensure rsg-inventory is installed
   - Verify inventory callbacks are working

2. **Database check:**
   ```sql
   SELECT * FROM rsg_housing_storage WHERE property_id = YOUR_PROPERTY_ID;
   ```

3. **Clear storage cache:**
   - Restart the resource
   - Check for duplicate storage entries

## Debug Commands

### Admin Commands
- `/createhouse [type] [price]` - Create a new property
- `/deletehouse [id]` - Delete a property
- `/givehouse [id] [player]` - Give property to player
- `/removehouse [id] [player]` - Remove property from player

### Debug Commands
- `/refreshblips` - Refresh all property blips
- `/housingdebug` - Toggle debug mode
- `/checkproperty [id]` - Check property information

## Performance Issues

### High Resource Usage

**Symptoms:**
- Server lag when near properties
- High memory usage
- FPS drops

**Solutions:**
1. **Optimize blip updates:**
   ```lua
   Config.BlipUpdateInterval = 5000 -- Increase interval
   ```

2. **Limit property loading:**
   ```lua
   Config.PropertyLoadDistance = 100.0 -- Reduce distance
   ```

3. **Reduce furniture objects:**
   ```lua
   Config.MaxFurniturePerProperty = 50 -- Lower limit
   ```

### Database Performance

**Solutions:**
1. **Add database indexes:**
   ```sql
   CREATE INDEX idx_property_coords ON rsg_housing_properties(x, y, z);
   CREATE INDEX idx_ownership_player ON rsg_housing_ownership(player_id);
   ```

2. **Clean old data:**
   ```sql
   DELETE FROM rsg_housing_logs WHERE created_at < DATE_SUB(NOW(), INTERVAL 30 DAY);
   ```

## Getting Help

### Before Asking for Help

1. **Check the console:**
   - Look for error messages
   - Enable debug mode for detailed logs

2. **Verify installation:**
   - All dependencies installed
   - Database tables created
   - Resource started after dependencies

3. **Test with minimal setup:**
   - Disable other resources temporarily
   - Test with default configuration

### Information to Provide

When asking for help, include:
- Full error message from console
- Server framework version (RSG-Core)
- Resource version/commit hash
- Steps to reproduce the issue
- Server configuration details

### Common Solutions

1. **Restart in correct order:**
   ```
   restart rsg-core
   restart oxmysql
   restart rsg-menu
   restart rsg-input
   restart rsg_housing
   ```

2. **Clear cache:**
   - Clear server cache
   - Clear client cache (F8 > resmon)
   - Restart FiveM/RedM client

3. **Check file permissions:**
   - Ensure resource files are readable
   - Check database file permissions
   - Verify log file write permissions

## Advanced Troubleshooting

### Network Issues

If players can't see property changes:
1. Check server events are firing
2. Verify client events are registered
3. Test with single player first

### Compatibility Issues

With other resources:
1. Check for conflicting exports
2. Verify shared dependencies
3. Test load order

### Custom Modifications

If you've modified the resource:
1. Compare with original files
2. Check syntax errors
3. Test modifications incrementally

---

**Still having issues?** Create an issue on GitHub with detailed information about your problem.