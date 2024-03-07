INSERT INTO event_types (id, description, service_space_id) VALUES (11, "HRC Training", 1);

ALTER TABLE `events` ADD COLUMN `hrc_feed` tinyint(1) NOT NULL DEFAULT 0 AFTER `is_private`;