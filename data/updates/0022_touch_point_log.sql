CREATE TABLE `touch_point_logs` (
	`id` int(11) PRIMARY KEY AUTO_INCREMENT,
  `touch_point_count` int(11) NOT NULL,
	`created_on` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;
