CREATE TABLE `project_logs` (
    `id` int(11) PRIMARY KEY AUTO_INCREMENT,
    `checkout_user_id` int(11),
    `project_id` int(11),
    `project_name` varchar(255),
    `checked_date` datetime DEFAULT CURRENT_TIMESTAMP,
    `is_checking_in` boolean
);