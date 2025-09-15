Config = {}

-- General Settings
Config.Debug = true -- Enable for testing, set to false in production
Config.UseTarget = true -- Use rsg-target for interactions
Config.RentPaymentInterval = 7 -- Days between rent payments
Config.MaxHousesPerPlayer = 3
Config.DefaultSpawn = vector4(-1035.71, -2731.87, 12.86, 0.0) -- Valentine

-- Database Settings
Config.UseOxMySQL = true

-- Blip Settings
Config.HouseBlip = {
    Sprite = 374778363, -- House blip sprite for RDR3
    Scale = 0.7,
    Color = 'BLIP_MODIFIER_MP_COLOR_32'
}

Config.RentedBlip = {
    Sprite = 374778363,
    Scale = 0.7,
    Color = 'BLIP_MODIFIER_MP_COLOR_8'
}

Config.OwnedBlip = {
    Sprite = 374778363,
    Scale = 0.7,
    Color = 'BLIP_MODIFIER_MP_COLOR_2'
}

-- Interaction Settings
Config.InteractionDistance = 2.0
Config.DrawTextDistance = 10.0

-- Storage Settings
Config.Storage = {
    MaxSlots = 50,
    MaxWeight = 400000, -- 400kg
    RestrictedItems = {
        'weapon_pistol',
        'weapon_rifle'
    }
}

-- Furniture Settings
Config.Furniture = {
    MaxItems = 100,
    Categories = {
        ['chairs'] = {
            label = 'Chairs',
            items = {
                ['chair_01'] = { label = 'Wooden Chair', price = 25, model = 'p_chair02x' },
                ['chair_02'] = { label = 'Fancy Chair', price = 50, model = 'p_chair05x' }
            }
        },
        ['tables'] = {
            label = 'Tables',
            items = {
                ['table_01'] = { label = 'Wooden Table', price = 75, model = 'p_table07x' },
                ['table_02'] = { label = 'Round Table', price = 100, model = 'p_table_poker01x' }
            }
        },
        ['beds'] = {
            label = 'Beds',
            items = {
                ['bed_01'] = { label = 'Simple Bed', price = 150, model = 'p_bed01x' },
                ['bed_02'] = { label = 'Double Bed', price = 300, model = 'p_bed_abigail01x' }
            }
        },
        ['decorations'] = {
            label = 'Decorations',
            items = {
                ['lamp_01'] = { label = 'Oil Lamp', price = 35, model = 'p_lamp_hanging05x' },
                ['painting_01'] = { label = 'Landscape Painting', price = 85, model = 'p_painting_family01x' }
            }
        }
    }
}

-- Property Types
Config.PropertyTypes = {
    ['house'] = {
        label = 'House',
        rentPrice = 50,
        buyPrice = 2500,
        storage = true,
        furniture = true,
        maxRoommates = 4
    },
    ['apartment'] = {
        label = 'Apartment',
        rentPrice = 25,
        buyPrice = 1000,
        storage = true,
        furniture = false,
        maxRoommates = 2
    },
    ['mansion'] = {
        label = 'Mansion',
        rentPrice = 200,
        buyPrice = 15000,
        storage = true,
        furniture = true,
        maxRoommates = 8
    },
    ['cabin'] = {
        label = 'Cabin',
        rentPrice = 30,
        buyPrice = 1500,
        storage = true,
        furniture = true,
        maxRoommates = 2
    }
}

-- Property Locations
Config.Properties = {
    -- Valentine Properties
    {
        id = 1,
        label = 'Valentine House #1',
        type = 'house',
        coords = vector3(-322.81, 803.68, 117.88),
        heading = 180.0,
        interior = 'rsg_housing_int_01',
        shell = 'rsg_housing_shell_01',
        garage = {
            coords = vector3(-325.81, 800.68, 117.88),
            heading = 180.0,
            maxVehicles = 2
        },
        price = {
            rent = 75,
            buy = 3500
        },
        images = {
            'valentine_house_1_1.jpg',
            'valentine_house_1_2.jpg'
        }
    },
    {
        id = 2,
        label = 'Valentine Apartment #1',
        type = 'apartment',
        coords = vector3(-240.12, 770.34, 118.19),
        heading = 90.0,
        interior = 'rsg_housing_int_02',
        shell = 'rsg_housing_shell_02',
        price = {
            rent = 35,
            buy = 1200
        },
        images = {
            'valentine_apt_1_1.jpg'
        }
    },
    -- Strawberry Properties
    {
        id = 3,
        label = 'Strawberry Cabin #1',
        type = 'cabin',
        coords = vector3(-1791.23, -386.45, 160.33),
        heading = 270.0,
        interior = 'rsg_housing_int_03',
        shell = 'rsg_housing_shell_03',
        price = {
            rent = 45,
            buy = 2000
        },
        images = {
            'strawberry_cabin_1_1.jpg',
            'strawberry_cabin_1_2.jpg'
        }
    },
    -- Saint Denis Properties
    {
        id = 4,
        label = 'Saint Denis Mansion #1',
        type = 'mansion',
        coords = vector3(2632.12, -1312.45, 51.23),
        heading = 0.0,
        interior = 'rsg_housing_int_04',
        shell = 'rsg_housing_shell_04',
        garage = {
            coords = vector3(2625.12, -1315.45, 51.23),
            heading = 0.0,
            maxVehicles = 4
        },
        price = {
            rent = 250,
            buy = 18000
        },
        images = {
            'saintdenis_mansion_1_1.jpg',
            'saintdenis_mansion_1_2.jpg',
            'saintdenis_mansion_1_3.jpg'
        }
    },
    -- Rhodes Properties
    {
        id = 5,
        label = 'Rhodes House #1',
        type = 'house',
        coords = vector3(1323.45, -1320.67, 77.89),
        heading = 180.0,
        interior = 'rsg_housing_int_05',
        shell = 'rsg_housing_shell_05',
        garage = {
            coords = vector3(1320.45, -1323.67, 77.89),
            heading = 180.0,
            maxVehicles = 2
        },
        price = {
            rent = 65,
            buy = 2800
        },
        images = {
            'rhodes_house_1_1.jpg'
        }
    }
}

-- Locales
Config.Locales = {
    ['en'] = {
        ['house_blip'] = 'House',
        ['apartment_blip'] = 'Apartment',
        ['mansion_blip'] = 'Mansion',
        ['cabin_blip'] = 'Cabin',
        ['owned_property'] = 'Owned Property',
        ['rented_property'] = 'Rented Property',
        ['available_property'] = 'Available Property',
        ['enter_property'] = 'Press [G] to enter property',
        ['exit_property'] = 'Press [G] to exit property',
        ['manage_property'] = 'Press [G] to manage property',
        ['property_locked'] = 'This property is locked',
        ['not_owner'] = 'You are not the owner of this property',
        ['property_purchased'] = 'Property purchased successfully',
        ['property_rented'] = 'Property rented successfully',
        ['insufficient_funds'] = 'You do not have enough money',
        ['property_sold'] = 'Property sold successfully',
        ['rent_paid'] = 'Rent paid successfully',
        ['rent_due'] = 'Your rent is due for: %s',
        ['evicted'] = 'You have been evicted from: %s',
        ['storage_access'] = 'Press [G] to access storage',
        ['furniture_mode'] = 'Furniture placement mode activated',
        ['furniture_placed'] = 'Furniture placed successfully',
        ['furniture_removed'] = 'Furniture removed successfully',
        ['max_furniture'] = 'Maximum furniture limit reached',
        ['roommate_added'] = 'Roommate added successfully',
        ['roommate_removed'] = 'Roommate removed successfully',
        ['max_roommates'] = 'Maximum roommate limit reached'
    }
}

-- Interior Shells (RedM/RSG Compatible)
-- These use offset coordinates from the property entrance
Config.Shells = {
    ['rsg_housing_shell_01'] = {
        label = 'Basic House Interior',
        hash = 'rsg_housing_shell_01',
        doorCoords = vector3(0.0, 2.0, 1.0), -- Interior entrance offset
        stashCoords = vector3(2.0, 5.0, 1.0), -- Storage location offset
        clothingCoords = vector3(-2.0, 5.0, 1.0), -- Wardrobe location offset
        logoutCoords = vector3(0.0, 8.0, 1.0) -- Logout/bed location offset
    },
    ['rsg_housing_shell_02'] = {
        label = 'Apartment Interior',
        hash = 'rsg_housing_shell_02',
        doorCoords = vector3(0.0, 1.5, 1.0),
        stashCoords = vector3(1.0, 3.0, 1.0),
        clothingCoords = vector3(-1.0, 3.0, 1.0),
        logoutCoords = vector3(0.0, 4.5, 1.0)
    },
    ['rsg_housing_shell_03'] = {
        label = 'Cabin Interior',
        hash = 'rsg_housing_shell_03',
        doorCoords = vector3(0.0, 2.5, 1.0),
        stashCoords = vector3(2.5, 4.0, 1.0),
        clothingCoords = vector3(-2.5, 4.0, 1.0),
        logoutCoords = vector3(0.0, 6.0, 1.0)
    },
    ['rsg_housing_shell_04'] = {
        label = 'Mansion Interior',
        hash = 'rsg_housing_shell_04',
        doorCoords = vector3(0.0, 3.0, 1.0),
        stashCoords = vector3(5.0, 10.0, 1.0),
        clothingCoords = vector3(-5.0, 10.0, 1.0),
        logoutCoords = vector3(0.0, 12.0, 1.0)
    },
    ['rsg_housing_shell_05'] = {
        label = 'Standard House Interior',
        hash = 'rsg_housing_shell_05',
        doorCoords = vector3(0.0, 2.0, 1.0),
        stashCoords = vector3(3.0, 6.0, 1.0),
        clothingCoords = vector3(-3.0, 6.0, 1.0),
        logoutCoords = vector3(0.0, 8.0, 1.0)
    }
}

-- Webhook Settings (for logging)
Config.Webhooks = {
    ['property_purchase'] = '',
    ['property_sale'] = '',
    ['rent_payment'] = '',
    ['eviction'] = '',
    ['furniture'] = ''
}