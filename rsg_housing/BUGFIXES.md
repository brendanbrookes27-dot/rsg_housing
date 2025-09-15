# RSG Housing System v2.0 - Bug Fixes

## Fixed Issues

### 1. RegisterKeyMapping Error
**Problem:** `SCRIPT ERROR: attempt to call a nil value (global 'RegisterKeyMapping')`
- RegisterKeyMapping is not available in RedM framework

**Solution:**
- Replaced RegisterKeyMapping with RegisterCommand for the exit property function
- Added manual key detection thread for F7 key using RedM-compatible key code (0x3C0A40F2)
- Both command and key press now work for exiting properties

### 2. PropertyMarkers Table Nil Error
**Problem:** `SCRIPT ERROR: bad argument #1 to 'for iterator' (table expected, got nil)`
- PropertyMarkers was declared as local in main.lua but accessed in markers.lua

**Solution:**
- Made PropertyMarkers a global variable accessible across all client files
- Added safety check `if PropertyMarkers and next(PropertyMarkers) then` before iteration
- Prevents nil value errors during property marker processing

### 3. PropertyBlips Table Nil Error
**Problem:** `SCRIPT ERROR: attempt to index a nil value (global 'PropertyBlips')`
- PropertyBlips was declared as local in main.lua but accessed in blips.lua

**Solution:**
- Made PropertyBlips a global variable accessible across all client files
- Added initialization checks in all functions that use PropertyBlips
- Added safety checks before table operations to prevent nil errors

## Technical Changes

### File: client/main.lua
- Changed `local PropertyBlips = {}` to `PropertyBlips = {}` (global)
- Changed `local PropertyMarkers = {}` to `PropertyMarkers = {}` (global)
- Replaced RegisterKeyMapping with RegisterCommand + manual key detection
- Added safety check in RemoveAllBlips() function

### File: client/markers.lua
- Added `if PropertyMarkers and next(PropertyMarkers) then` check before iteration
- Fixed indentation and structure of the property checking loop

### File: client/blips.lua
- Added PropertyBlips initialization checks in all functions:
  - CreatePropertyBlip()
  - UpdatePropertyBlip()
  - RemovePropertyBlip()

## RedM Compatibility Notes

1. **Key Codes:** RedM uses different key codes than FiveM
   - F7 key code: `0x3C0A40F2`

2. **Global Variables:** Variables shared across client files must be global, not local

3. **Function Availability:** Some FiveM functions like RegisterKeyMapping are not available in RedM

## Testing Recommendations

1. Test property marker visibility and interaction
2. Test property blip creation and removal
3. Test F7 key for exiting properties
4. Test `/exitproperty` command
5. Verify no script errors in server console

## Version Information

- **Fixed Version:** v2.0.1
- **Commit:** 89d1307
- **Branch:** feature/fresh-rsg-housing-system-v2
- **Compatibility:** RedM RSG Framework v2