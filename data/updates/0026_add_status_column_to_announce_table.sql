-- Existing announcements are active by default; only one can be created at the current time and is automatically active.
ALTER TABLE `announcements` ADD COLUMN `status` BOOLEAN NOT NULL DEFAULT TRUE;

-- For future records, set the `status` column to FALSE by default
ALTER TABLE `announcements` ALTER COLUMN `status` SET DEFAULT FALSE;