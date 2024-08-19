INSERT INTO `service_spaces` (`id`, `name`, `url_name`, `imagedata`, `imagemime`) VALUES
(8, 'Engineering Garage', NULL, NULL, NULL);

ALTER TABLE `preset_events` ADD COLUMN `service_space_id` int(11) DEFAULT 1;
ALTER TABLE `preset_emails` ADD COLUMN `service_space_id` int(11) DEFAULT 1;
ALTER TABLE `studio_spaces` ADD COLUMN `service_space_id` int(11) DEFAULT 1;

INSERT INTO `studio_spaces` (`name`, `service_space_id`) VALUES
('Engineering Garage', 8);

INSERT INTO `event_types` (`id`, `description`, `service_space_id`) VALUES
(12, 'New Membership Orientation', 8);

INSERT INTO `event_types` (`id`, `description`, `service_space_id`) VALUES
(13, 'Machine Training', 8);

INSERT INTO `event_types` (`id`, `description`, `service_space_id`) VALUES
(14, 'General Workshop', 8);

ALTER TABLE `users` ADD COLUMN `active` tinyint(1) DEFAULT 0;
UPDATE `users` SET `active` = 1;
