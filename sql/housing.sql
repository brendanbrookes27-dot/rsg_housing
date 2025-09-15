-- RSG Housing Database Schema
-- Compatible with oxmysql and MySQL/MariaDB

-- Properties table - stores all property information
CREATE TABLE IF NOT EXISTS `rsg_housing_properties` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `label` varchar(255) NOT NULL,
    `type` varchar(50) NOT NULL DEFAULT 'house',
    `coords` longtext NOT NULL,
    `heading` float NOT NULL DEFAULT 0.0,
    `interior` varchar(100) DEFAULT NULL,
    `shell` varchar(100) DEFAULT NULL,
    `garage_coords` longtext DEFAULT NULL,
    `garage_heading` float DEFAULT 0.0,
    `max_vehicles` int(11) DEFAULT 0,
    `rent_price` int(11) NOT NULL DEFAULT 0,
    `buy_price` int(11) NOT NULL DEFAULT 0,
    `images` longtext DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_type` (`type`),
    KEY `idx_coords` (`coords`(255))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Property ownership table - tracks who owns/rents what
CREATE TABLE IF NOT EXISTS `rsg_housing_ownership` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `property_id` int(11) NOT NULL,
    `citizenid` varchar(50) NOT NULL,
    `ownership_type` enum('owned','rented') NOT NULL DEFAULT 'rented',
    `purchase_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `rent_due_date` timestamp NULL DEFAULT NULL,
    `rent_paid` tinyint(1) NOT NULL DEFAULT 0,
    `eviction_date` timestamp NULL DEFAULT NULL,
    `is_locked` tinyint(1) NOT NULL DEFAULT 1,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_property_owner` (`property_id`),
    KEY `idx_citizenid` (`citizenid`),
    KEY `idx_ownership_type` (`ownership_type`),
    KEY `idx_rent_due` (`rent_due_date`),
    FOREIGN KEY (`property_id`) REFERENCES `rsg_housing_properties` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Property keys table - tracks who has keys to properties
CREATE TABLE IF NOT EXISTS `rsg_housing_keys` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `property_id` int(11) NOT NULL,
    `citizenid` varchar(50) NOT NULL,
    `key_type` enum('owner','roommate','temporary') NOT NULL DEFAULT 'temporary',
    `granted_by` varchar(50) NOT NULL,
    `granted_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expires_at` timestamp NULL DEFAULT NULL,
    `is_active` tinyint(1) NOT NULL DEFAULT 1,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_property_citizen` (`property_id`, `citizenid`),
    KEY `idx_citizenid` (`citizenid`),
    KEY `idx_key_type` (`key_type`),
    KEY `idx_active` (`is_active`),
    FOREIGN KEY (`property_id`) REFERENCES `rsg_housing_properties` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Property furniture table - stores placed furniture
CREATE TABLE IF NOT EXISTS `rsg_housing_furniture` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `property_id` int(11) NOT NULL,
    `citizenid` varchar(50) NOT NULL,
    `furniture_type` varchar(100) NOT NULL,
    `furniture_id` varchar(100) NOT NULL,
    `model` varchar(100) NOT NULL,
    `coords` longtext NOT NULL,
    `heading` float NOT NULL DEFAULT 0.0,
    `metadata` longtext DEFAULT NULL,
    `placed_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_property_id` (`property_id`),
    KEY `idx_citizenid` (`citizenid`),
    KEY `idx_furniture_type` (`furniture_type`),
    FOREIGN KEY (`property_id`) REFERENCES `rsg_housing_properties` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Property storage table - tracks storage containers
CREATE TABLE IF NOT EXISTS `rsg_housing_storage` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `property_id` int(11) NOT NULL,
    `storage_type` varchar(50) NOT NULL DEFAULT 'stash',
    `storage_id` varchar(100) NOT NULL,
    `max_slots` int(11) NOT NULL DEFAULT 50,
    `max_weight` int(11) NOT NULL DEFAULT 400000,
    `coords` longtext DEFAULT NULL,
    `metadata` longtext DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_storage_id` (`storage_id`),
    KEY `idx_property_id` (`property_id`),
    KEY `idx_storage_type` (`storage_type`),
    FOREIGN KEY (`property_id`) REFERENCES `rsg_housing_properties` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Property vehicles table - tracks vehicles in garages
CREATE TABLE IF NOT EXISTS `rsg_housing_vehicles` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `property_id` int(11) NOT NULL,
    `citizenid` varchar(50) NOT NULL,
    `vehicle_plate` varchar(20) NOT NULL,
    `vehicle_model` varchar(100) NOT NULL,
    `vehicle_data` longtext NOT NULL,
    `parked_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `is_parked` tinyint(1) NOT NULL DEFAULT 1,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `unique_vehicle_plate` (`vehicle_plate`),
    KEY `idx_property_id` (`property_id`),
    KEY `idx_citizenid` (`citizenid`),
    KEY `idx_parked` (`is_parked`),
    FOREIGN KEY (`property_id`) REFERENCES `rsg_housing_properties` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Property logs table - audit trail for property actions
CREATE TABLE IF NOT EXISTS `rsg_housing_logs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `property_id` int(11) NOT NULL,
    `citizenid` varchar(50) NOT NULL,
    `action` varchar(100) NOT NULL,
    `details` longtext DEFAULT NULL,
    `metadata` longtext DEFAULT NULL,
    `ip_address` varchar(45) DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_property_id` (`property_id`),
    KEY `idx_citizenid` (`citizenid`),
    KEY `idx_action` (`action`),
    KEY `idx_created_at` (`created_at`),
    FOREIGN KEY (`property_id`) REFERENCES `rsg_housing_properties` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default properties (examples)
INSERT INTO `rsg_housing_properties` (`id`, `label`, `type`, `coords`, `heading`, `interior`, `shell`, `garage_coords`, `garage_heading`, `max_vehicles`, `rent_price`, `buy_price`, `images`) VALUES
(1, 'Valentine House #1', 'house', '{"x": -322.81, "y": 803.68, "z": 117.88}', 180.0, 'rsg_housing_int_01', 'rsg_housing_shell_01', '{"x": -325.81, "y": 800.68, "z": 117.88}', 180.0, 2, 75, 3500, '["valentine_house_1_1.jpg", "valentine_house_1_2.jpg"]'),
(2, 'Valentine Apartment #1', 'apartment', '{"x": -240.12, "y": 770.34, "z": 118.19}', 90.0, 'rsg_housing_int_02', 'rsg_housing_shell_02', NULL, 0.0, 0, 35, 1200, '["valentine_apt_1_1.jpg"]'),
(3, 'Strawberry Cabin #1', 'cabin', '{"x": -1791.23, "y": -386.45, "z": 160.33}', 270.0, 'rsg_housing_int_03', 'rsg_housing_shell_03', NULL, 0.0, 0, 45, 2000, '["strawberry_cabin_1_1.jpg", "strawberry_cabin_1_2.jpg"]'),
(4, 'Saint Denis Mansion #1', 'mansion', '{"x": 2632.12, "y": -1312.45, "z": 51.23}', 0.0, 'rsg_housing_int_04', 'rsg_housing_shell_04', '{"x": 2625.12, "y": -1315.45, "z": 51.23}', 0.0, 4, 250, 18000, '["saintdenis_mansion_1_1.jpg", "saintdenis_mansion_1_2.jpg", "saintdenis_mansion_1_3.jpg"]'),
(5, 'Rhodes House #1', 'house', '{"x": 1323.45, "y": -1320.67, "z": 77.89}', 180.0, 'rsg_housing_int_05', 'rsg_housing_shell_05', '{"x": 1320.45, "y": -1323.67, "z": 77.89}', 180.0, 2, 65, 2800, '["rhodes_house_1_1.jpg"]');

-- Create indexes for better performance
CREATE INDEX idx_housing_ownership_rent_due ON rsg_housing_ownership(rent_due_date) WHERE rent_due_date IS NOT NULL;
CREATE INDEX idx_housing_keys_active ON rsg_housing_keys(is_active, property_id);
CREATE INDEX idx_housing_furniture_property ON rsg_housing_furniture(property_id, furniture_type);
CREATE INDEX idx_housing_logs_recent ON rsg_housing_logs(created_at DESC, property_id);