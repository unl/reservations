CREATE TABLE `projects` (
 `id` int(11) PRIMARY KEY AUTO_INCREMENT,
 `owner_user_id` int(11) NOT NULL,
 `title` varchar(255) DEFAULT NULL,
 `description` text DEFAULT NULL,
`bin_id` int(11) DEFAULT NULL,
 `last_checked_in` datetime DEFAULT NULL,
`last_checked_out` datetime DEFAULT NULL,
`created_on` datetime DEFAULT NULL,
`updated_on` datetime DEFAULT NULL,
FOREIGN KEY (owner_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;