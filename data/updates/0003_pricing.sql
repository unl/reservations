CREATE TABLE IF NOT EXISTS `material_prices` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `category` varchar(255) NOT NULL,
    `subcategory` varchar(255) DEFAULT NULL,
    `name` varchar(255) NOT NULL,
    `price_cents` int(11) NOT NULL,
    `price_per_unit` varchar(255) DEFAULT NULL,
    `service_space_id` int(11) NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1;
