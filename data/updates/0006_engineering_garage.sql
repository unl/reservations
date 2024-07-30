INSERT INTO `service_spaces` (`id`, `name`, `url_name`, `imagedata`, `imagemime`) VALUES
(8, 'Engineering Garage', NULL, NULL, NULL);

ALTER TABLE `preset_events` ADD COLUMN `service_space_id` int(11) DEFAULT 1;
ALTER TABLE `preset_emails` ADD COLUMN `service_space_id` int(11) DEFAULT 1;
ALTER TABLE `studio_spaces` ADD COLUMN `service_space_id` int(11) DEFAULT 1;

INSERT INTO `studio_spaces` (`name`, `service_space_id`) VALUES
('Engineering Garage', 8);

INSERT INTO `event_type` (`id`, `description`, `service_space_id`) VALUES
(12, 'New Membership Orientation', 8);
