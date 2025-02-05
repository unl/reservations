CREATE TABLE `tools` (
	`id` int(11) PRIMARY KEY AUTO_INCREMENT,
	`tool_name` VARCHAR(255) NOT NULL,
	`category_id` VARCHAR(255) DEFAULT NULL,
	`description` VARCHAR(255) DEFAULT NULL,
	`service_space_id` int(11) NOT NULL,
	`model_number` VARCHAR(255) DEFAULT NULL,
	`serial_number` VARCHAR(255) DEFAULT NULL,
	`INOP` tinyint(1) DEFAULT 0,
	`last_checked_in` datetime DEFAULT NULL,
	`last_checked_out` datetime DEFAULT NULL,
	`created_on` datetime DEFAULT CURRENT_TIMESTAMP,
	`updated_on` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;