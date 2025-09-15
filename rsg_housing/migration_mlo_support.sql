-- Migration script to add MLO support to existing RSG Housing installations
-- Run this if you already have the housing system installed

-- Add MLO column to properties table
ALTER TABLE `rsg_housing_properties` 
ADD COLUMN `mlo` varchar(100) DEFAULT NULL AFTER `shell`;

-- Add created_by and created_date columns for tracking custom properties
ALTER TABLE `rsg_housing_properties` 
ADD COLUMN `created_by` varchar(50) DEFAULT NULL AFTER `description`,
ADD COLUMN `created_date` timestamp NULL DEFAULT NULL AFTER `created_by`;

-- Make shell column nullable (since we can use MLO instead)
ALTER TABLE `rsg_housing_properties` 
MODIFY COLUMN `shell` varchar(50) DEFAULT 'basic_house';

-- Update existing properties to have proper shell values
UPDATE `rsg_housing_properties` SET `shell` = 'basic_house' WHERE `shell` IS NULL OR `shell` = '';