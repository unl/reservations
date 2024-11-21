ALTER TABLE `users` DROP COLUMN `user_nuid`;
ALTER TABLE `users` ADD COLUMN `user_nuid` varchar(255) DEFAULT NULL;