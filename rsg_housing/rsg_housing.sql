-- RSG Housing Database Schema
-- Make sure to run this SQL file in your database

CREATE TABLE IF NOT EXISTS `rsg_housing_properties` (
    `id` varchar(50) NOT NULL,
    `label` varchar(255) NOT NULL,
    `type` varchar(50) NOT NULL DEFAULT 'house',
    `coords` longtext NOT NULL,
    `heading` float NOT NULL DEFAULT 0.0,
    `price` int(11) NOT NULL DEFAULT 0,
    `rent` int(11) NOT NULL DEFAULT 0,
    `shell` varchar(50) NOT NULL DEFAULT 'basic_house',
    `garage` tinyint(1) NOT NULL DEFAULT 0,
    `description` text DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `rsg_housing_ownership` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `property_id` varchar(50) NOT NULL,
    `player_id` varchar(50) NOT NULL,
    `player_name` varchar(255) NOT NULL,
    `ownership_type` enum('owned','rented') NOT NULL DEFAULT 'owned',
    `purchase_date` timestamp NOT NULL DEFAULT current_timestamp(),
    `rent_due` timestamp NULL DEFAULT NULL,
    `rent_paid` tinyint(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    KEY `property_id` (`property_id`),
    KEY `player_id` (`player_id`),
    CONSTRAINT `fk_ownership_property` FOREIGN KEY (`property_id`) REFERENCES `rsg_housing_properties` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `rsg_housing_keys` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `property_id` varchar(50) NOT NULL,
    `player_id` varchar(50) NOT NULL,
    `player_name` varchar(255) NOT NULL,
    `given_by` varchar(50) NOT NULL,
    `given_date` timestamp NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `property_id` (`property_id`),
    KEY `player_id` (`player_id`),
    CONSTRAINT `fk_keys_property` FOREIGN KEY (`property_id`) REFERENCES `rsg_housing_properties` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `rsg_housing_storage` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `property_id` varchar(50) NOT NULL,
    `items` longtext DEFAULT NULL,
    `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
    PRIMARY KEY (`id`),
    UNIQUE KEY `property_id` (`property_id`),
    CONSTRAINT `fk_storage_property` FOREIGN KEY (`property_id`) REFERENCES `rsg_housing_properties` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `rsg_housing_saloon_earnings` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `property_id` varchar(50) NOT NULL,
    `amount` int(11) NOT NULL DEFAULT 0,
    `date` date NOT NULL,
    `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `property_id` (`property_id`),
    KEY `date` (`date`),
    CONSTRAINT `fk_earnings_property` FOREIGN KEY (`property_id`) REFERENCES `rsg_housing_properties` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `rsg_housing_logs` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `property_id` varchar(50) NOT NULL,
    `player_id` varchar(50) NOT NULL,
    `action` varchar(100) NOT NULL,
    `details` text DEFAULT NULL,
    `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`),
    KEY `property_id` (`property_id`),
    KEY `player_id` (`player_id`),
    KEY `created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert default properties from config
INSERT IGNORE INTO `rsg_housing_properties` (`id`, `label`, `type`, `coords`, `heading`, `price`, `rent`, `shell`, `garage`, `description`) VALUES
-- Valentine Area
('valentine_house_01', 'Valentine Family Home', 'house', '{"x": -322.89, "y": 803.68, "z": 117.88}', 180.0, 2500, 150, 'basic_house', 0, 'A cozy family home in the heart of Valentine'),
('valentine_house_02', 'Valentine Cottage', 'house', '{"x": -365.12, "y": 786.45, "z": 116.18}', 90.0, 2000, 120, 'basic_house', 0, 'Small cottage with a beautiful view'),
('valentine_apartment_01', 'Valentine Apartment', 'apartment', '{"x": -240.67, "y": 777.89, "z": 118.50}', 270.0, 1200, 80, 'apartment', 0, 'Affordable apartment above the general store'),
('valentine_saloon', 'Keane\'s Saloon', 'saloon', '{"x": -313.40, "y": 805.20, "z": 118.98}', 0.0, 15000, 0, 'saloon', 0, 'The famous Keane\'s Saloon in Valentine - prime business location'),

-- Strawberry Area
('strawberry_house_01', 'Strawberry Mountain Home', 'house', '{"x": -1791.23, "y": -392.45, "z": 160.33}', 45.0, 3500, 200, 'basic_house', 1, 'Beautiful mountain home with scenic views'),
('strawberry_house_02', 'Strawberry Cabin', 'cabin', '{"x": -1820.67, "y": -348.12, "z": 164.65}', 180.0, 2800, 170, 'cabin', 0, 'Rustic cabin perfect for hunters and outdoorsmen'),
('strawberry_house_03', 'Strawberry Lodge', 'house', '{"x": -1758.89, "y": -385.67, "z": 157.89}', 270.0, 4200, 250, 'basic_house', 1, 'Large lodge with multiple rooms'),
('strawberry_saloon', 'Strawberry Welcome Center Saloon', 'saloon', '{"x": -1805.01, "y": -374.23, "z": 162.33}', 90.0, 12000, 0, 'saloon', 0, 'Mountain saloon catering to travelers and locals'),

-- Rhodes Area
('rhodes_house_01', 'Rhodes Manor', 'mansion', '{"x": 1225.67, "y": -1293.45, "z": 76.03}', 0.0, 8500, 0, 'mansion', 1, 'Elegant manor house in the prestigious Rhodes area'),
('rhodes_house_02', 'Rhodes Family Home', 'house', '{"x": 1298.45, "y": -1278.90, "z": 75.89}', 180.0, 3200, 190, 'basic_house', 0, 'Traditional southern home with front porch'),
('rhodes_house_03', 'Rhodes Cottage', 'house', '{"x": 1367.23, "y": -1312.67, "z": 76.45}', 270.0, 2700, 160, 'basic_house', 0, 'Charming cottage near the train station'),
('rhodes_saloon', 'Bastille Saloon', 'saloon', '{"x": 1340.50, "y": -1373.20, "z": 80.48}', 180.0, 18000, 0, 'saloon', 0, 'The famous Bastille Saloon - Rhodes\' premier establishment'),

-- Saint Denis Area
('saintdenis_mansion_01', 'Saint Denis Grand Estate', 'mansion', '{"x": 2632.45, "y": -1224.67, "z": 53.38}', 90.0, 15000, 0, 'mansion', 1, 'Luxurious estate in the heart of Saint Denis'),
('saintdenis_apartment_01', 'Saint Denis Apartment Complex A', 'apartment', '{"x": 2504.23, "y": -1308.45, "z": 48.95}', 0.0, 1800, 110, 'apartment', 0, 'Modern apartment in the city center'),
('saintdenis_apartment_02', 'Saint Denis Apartment Complex B', 'apartment', '{"x": 2458.67, "y": -1367.89, "z": 46.31}', 180.0, 1600, 95, 'apartment', 0, 'Affordable city living'),
('saintdenis_house_01', 'Saint Denis Townhouse', 'house', '{"x": 2578.90, "y": -1135.23, "z": 49.67}', 270.0, 5500, 320, 'basic_house', 1, 'Elegant townhouse in upscale neighborhood'),
('saintdenis_saloon_01', 'Doyle\'s Tavern', 'saloon', '{"x": 2635.20, "y": -1225.40, "z": 53.38}', 0.0, 25000, 0, 'saloon', 0, 'Premium saloon in Saint Denis\' business district'),
('saintdenis_saloon_02', 'The Riverboat Saloon', 'saloon', '{"x": 2795.67, "y": -1167.89, "z": 47.93}', 90.0, 22000, 0, 'saloon', 0, 'Waterfront saloon with river views'),

-- Blackwater Area
('blackwater_house_01', 'Blackwater Riverside Home', 'house', '{"x": -875.23, "y": -1327.45, "z": 43.96}', 180.0, 4500, 270, 'basic_house', 1, 'Beautiful home overlooking the river'),
('blackwater_house_02', 'Blackwater Family Estate', 'mansion', '{"x": -932.67, "y": -1201.89, "z": 54.45}', 0.0, 12000, 0, 'mansion', 1, 'Grand estate with panoramic views'),
('blackwater_apartment_01', 'Blackwater Apartment', 'apartment', '{"x": -785.45, "y": -1367.23, "z": 43.88}', 90.0, 1400, 85, 'apartment', 0, 'Cozy apartment near the town center'),
('blackwater_saloon', 'Blackwater Saloon', 'saloon', '{"x": -813.50, "y": -1367.80, "z": 43.75}', 270.0, 20000, 0, 'saloon', 0, 'The main saloon in Blackwater - always busy'),

-- Additional properties (truncated for brevity - add more as needed)
('armadillo_saloon', 'Armadillo Saloon', 'saloon', '{"x": -3705.40, "y": -2599.20, "z": -13.43}', 90.0, 8000, 0, 'saloon', 0, 'The only saloon in Armadillo - desert oasis'),
('tumbleweed_saloon', 'Tumbleweed Saloon', 'saloon', '{"x": -5518.90, "y": -2906.45, "z": -1.36}', 0.0, 5000, 0, 'saloon', 0, 'Historic saloon in the ghost town - unique opportunity'),
('annesburg_saloon', 'Annesburg Saloon', 'saloon', '{"x": 2947.80, "y": 1320.40, "z": 44.82}', 270.0, 11000, 0, 'saloon', 0, 'Miners\' favorite watering hole'),
('vanhorn_saloon', 'Van Horn Saloon', 'saloon', '{"x": 2947.20, "y": 520.80, "z": 44.32}', 180.0, 9500, 0, 'saloon', 0, 'Rough and tumble saloon for traders and outlaws');