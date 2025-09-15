Config = {}

-- General Settings
Config.Debug = false
Config.UseTarget = false -- Set to true if using rsg-target
Config.MarkerDistance = 50.0 -- Distance to show markers
Config.InteractionDistance = 3.0 -- Distance to interact with properties
Config.BlipUpdateInterval = 30000 -- Update blips every 30 seconds

-- Property Settings
Config.MaxPropertiesPerPlayer = 5
Config.PropertyTaxRate = 0.02 -- 2% of property value per week
Config.RentPaymentInterval = 7 -- Days between rent payments
Config.DefaultRentPrice = 50 -- Default weekly rent if not specified

-- Marker Settings
Config.Markers = {
    ForSale = {
        type = 0x94FDAE17, -- Green house marker
        color = {r = 0, g = 255, b = 0, a = 200},
        scale = {x = 1.0, y = 1.0, z = 1.0},
        bobUpAndDown = true,
        faceCamera = false,
        rotate = true
    },
    Owned = {
        type = 0x94FDAE17, -- Blue house marker
        color = {r = 0, g = 100, b = 255, a = 200},
        scale = {x = 0.8, y = 0.8, z = 0.8},
        bobUpAndDown = false,
        faceCamera = false,
        rotate = false
    },
    Saloon = {
        type = 0x6903B113, -- Saloon marker
        color = {r = 255, g = 165, b = 0, a = 200},
        scale = {x = 1.2, y = 1.2, z = 1.2},
        bobUpAndDown = true,
        faceCamera = false,
        rotate = true
    }
}

-- Blip Settings
Config.Blips = {
    ForSale = {
        sprite = 0x6503D4F, -- House for sale
        color = 'GREEN',
        scale = 0.8
    },
    Owned = {
        sprite = 0x6503D4F, -- Owned house
        color = 'BLUE',
        scale = 0.7
    },
    Saloon = {
        sprite = 0x6503D4F, -- Saloon
        color = 'ORANGE',
        scale = 1.0
    }
}

-- Property Types
Config.PropertyTypes = {
    ['house'] = {
        label = 'House',
        description = 'A residential property',
        icon = 'house',
        canRent = true,
        canSell = true,
        storage = 100,
        wardrobe = true
    },
    ['apartment'] = {
        label = 'Apartment',
        description = 'A small residential unit',
        icon = 'building',
        canRent = true,
        canSell = true,
        storage = 50,
        wardrobe = true
    },
    ['cabin'] = {
        label = 'Cabin',
        description = 'A rustic cabin in the wilderness',
        icon = 'tree',
        canRent = true,
        canSell = true,
        storage = 75,
        wardrobe = true
    },
    ['mansion'] = {
        label = 'Mansion',
        description = 'A luxurious large property',
        icon = 'crown',
        canRent = false,
        canSell = true,
        storage = 200,
        wardrobe = true
    },
    ['saloon'] = {
        label = 'Saloon',
        description = 'A business establishment for drinks and entertainment',
        icon = 'glass',
        canRent = false,
        canSell = true,
        storage = 150,
        wardrobe = false,
        business = true
    },
    ['shop'] = {
        label = 'Shop',
        description = 'A commercial property for business',
        icon = 'store',
        canRent = true,
        canSell = true,
        storage = 100,
        wardrobe = false,
        business = true
    }
}

-- Job Permissions for House Creation
Config.HouseCreationJobs = {
    ['vallaw'] = {
        minGrade = 2, -- Minimum job grade required
        label = 'Valentine Law'
    }
    -- Add more jobs here if needed
    -- ['sheriff'] = {
    --     minGrade = 1,
    --     label = 'Sheriff Department'
    -- }
}

-- MLO Interiors (RedM Compatible)
Config.MLOs = {
    -- Add your MLO configurations here
    -- Example:
    -- ['custom_house_mlo'] = {
    --     label = 'Custom House MLO',
    --     coords = vector3(0.0, 0.0, 0.0), -- Relative spawn point inside MLO
    --     heading = 0.0,
    --     storage = vector3(5.0, 5.0, 0.0),
    --     wardrobe = vector3(-5.0, 5.0, 0.0),
    --     logout = vector3(0.0, 10.0, 0.0)
    -- }
}

-- Interior Shells (RedM Compatible)
Config.Shells = {
    ['basic_house'] = {
        label = 'Basic House Interior',
        coords = vector3(0.0, 2.0, 1.0),
        heading = 0.0,
        storage = vector3(2.0, 5.0, 1.0),
        wardrobe = vector3(-2.0, 5.0, 1.0),
        logout = vector3(0.0, 8.0, 1.0)
    },
    ['apartment'] = {
        label = 'Apartment Interior',
        coords = vector3(0.0, 1.5, 1.0),
        heading = 0.0,
        storage = vector3(1.0, 3.0, 1.0),
        wardrobe = vector3(-1.0, 3.0, 1.0),
        logout = vector3(0.0, 4.5, 1.0)
    },
    ['cabin'] = {
        label = 'Cabin Interior',
        coords = vector3(0.0, 2.5, 1.0),
        heading = 0.0,
        storage = vector3(2.5, 4.0, 1.0),
        wardrobe = vector3(-2.5, 4.0, 1.0),
        logout = vector3(0.0, 6.0, 1.0)
    },
    ['mansion'] = {
        label = 'Mansion Interior',
        coords = vector3(0.0, 3.0, 1.0),
        heading = 0.0,
        storage = vector3(5.0, 10.0, 1.0),
        wardrobe = vector3(-5.0, 10.0, 1.0),
        logout = vector3(0.0, 12.0, 1.0)
    },
    ['saloon'] = {
        label = 'Saloon Interior',
        coords = vector3(0.0, 5.0, 1.0),
        heading = 180.0,
        storage = vector3(-8.0, 2.0, 1.0),
        bar = vector3(0.0, -3.0, 1.0),
        office = vector3(8.0, 8.0, 1.0)
    }
}

-- Interaction Keys
Config.Keys = {
    ['G'] = 0x760A9C6F,
    ['E'] = 0xDFF812F9,
    ['F'] = 0xB2F377E8,
    ['H'] = 0x24978A28
}

-- Webhook Settings
Config.Webhooks = {
    ['property_purchase'] = '',
    ['property_sale'] = '',
    ['property_rent'] = '',
    ['saloon_purchase'] = ''
}

-- Economy Settings
Config.Economy = {
    ['property_tax_multiplier'] = 0.02,
    ['rent_multiplier'] = 0.1,
    ['sale_tax'] = 0.05,
    ['saloon_income_multiplier'] = 0.15
}