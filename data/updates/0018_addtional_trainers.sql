ALTER TABLE `events` ADD COLUMN `trainer_2_id` int(11) DEFAULT NULL AFTER `trainer_id`;
ALTER TABLE `events` ADD COLUMN `trainer_2_confirmed` tinyint(4) DEFAULT 0 AFTER `trainer_confirmed`;
ALTER TABLE `events` ADD COLUMN `trainer_3_id` int(11) DEFAULT NULL AFTER `trainer_2_id`;
ALTER TABLE `events` ADD COLUMN `trainer_3_confirmed` tinyint(4) DEFAULT 0 AFTER `trainer_2_confirmed`;

ALTER TABLE `events`
    ADD KEY `FK_trainer_2_id` (`trainer_2_id`);
ALTER TABLE `events`
    ADD KEY `FK_trainer_3_id` (`trainer_3_id`);

ALTER TABLE `events`
    ADD CONSTRAINT `FK_trainer_2_id` FOREIGN KEY (`trainer_2_id`) REFERENCES `users` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
ALTER TABLE `events`
    ADD CONSTRAINT `FK_trainer_3_id` FOREIGN KEY (`trainer_3_id`) REFERENCES `users` (`id`) ON DELETE NO ACTION ON UPDATE NO ACTION;
