CREATE TABLE `lockouts` (
	`id` int(11) PRIMARY KEY AUTO_INCREMENT,
	`resource_id` int(11) NOT NULL,
	`initiated_by_user_id` int(11) DEFAULT NULL,
	`description` VARCHAR(255) DEFAULT NULL,
	`started_on` datetime DEFAULT CURRENT_TIMESTAMP,
	`released_on` datetime DEFAULT NULL,
	`released_by_user_id` int(11) DEFAULT NULL,
	`created_on` datetime DEFAULT CURRENT_TIMESTAMP,
	`updated_on` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	FOREIGN KEY (resource_id) REFERENCES resources(id) ON DELETE CASCADE,
	FOREIGN KEY (initiated_by_user_id) REFERENCES users(id) ON DELETE CASCADE,
	FOREIGN KEY (released_by_user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

INSERT INTO `permissions` (`id`, `name`) VALUES
(12, 'Manage Lockout'); 