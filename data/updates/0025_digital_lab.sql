INSERT INTO `service_spaces` (`id`, `name`, `url_name`, `imagedata`, `imagemime`) VALUES
(9, 'Art School', NULL, NULL, NULL);

INSERT INTO `studio_spaces` (`id`, `name`, `service_space_id`) VALUES
(12, 'Laser Cutter', 9),
(13, 'Laser Graph', 9);

INSERT INTO `event_types` (`id`, `description`, `service_space_id`) VALUES
(18, 'New Member Orientation', 9),
(19, 'General Workshop', 9),
(20, 'Laser Cutter', 9),
(21, 'Laser Graph', 9);
