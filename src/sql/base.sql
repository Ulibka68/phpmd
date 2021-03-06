CREATE DATABASE IF NOT EXISTS `phpmd` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `phpmd`;

-- Места размещения устройств (древовидная структура)
CREATE TABLE `places` (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `pid` int(10) UNSIGNED DEFAULT NULL,
  `name` text NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `places_places_ibfk_1` FOREIGN KEY (`pid`) REFERENCES `places` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Модули
CREATE TABLE `modules` (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `namespace` varchar(64) NOT NULL,
  `daemon` tinyint(1) NOT NULL DEFAULT 0,
  `settings` tinyint(1) NOT NULL DEFAULT 0,
  `disabled` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Устройства
CREATE TABLE devices (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `unique_name` varchar(64) NOT NULL,
  `module_id` int(10) UNSIGNED NOT NULL,
  `uid` varchar(64) NOT NULL,
  `description` text NOT NULL,
  `classname` varchar(64) NULL DEFAULT NULL,
  `init_data` text NULL DEFAULT NULL,
  `place_id` int(10) UNSIGNED NULL,
  `disabled` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE (`unique_name`),
  UNIQUE (`module_id`,`uid`),
  CONSTRAINT `devices_places_ibfk_1` FOREIGN KEY (`place_id`) REFERENCES `places` (`id`),
  CONSTRAINT `devices_modules_ibfk_1` FOREIGN KEY (`module_id`) REFERENCES `modules` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Типы измеряемых параметров, сохраняемых в истории
CREATE TABLE meter_units (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` text NOT NULL,
  `unit` varchar(64) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Измерительные датчики
CREATE TABLE meters (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `device_id` int(10) UNSIGNED NOT NULL,
  `property` varchar(64) NOT NULL,
  `meter_unit_id` int (10) UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY (`device_id`,`property`),
  CONSTRAINT `meters_devices_ibfk_1` FOREIGN KEY (`device_id`) REFERENCES `devices` (`id`),
  CONSTRAINT `meters_meter_units_ibfk_1` FOREIGN KEY (`meter_unit_id`) REFERENCES `meter_units` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- История показаний измерительных датчиков устройств
CREATE TABLE meter_history (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `meter_id` int(10) UNSIGNED NOT NULL,
  `place_id` int(10) UNSIGNED NOT NULL,
  `meter_unit_id` int(10) UNSIGNED NOT NULL,
  `value` float NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `meter_history_meters_ibfk_1` FOREIGN KEY (`meter_id`) REFERENCES `meters` (`id`),
  CONSTRAINT `meter_history_places_ibfk_1` FOREIGN KEY (`place_id`) REFERENCES `places` (`id`),
  CONSTRAINT `meter_history_meter_units_ibfk_1` FOREIGN KEY (`meter_unit_id`) REFERENCES `meter_units` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Сигнализационные датчики
CREATE TABLE indicators (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `device_id` int(10) UNSIGNED NOT NULL,
  `property` varchar(64) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY (`device_id`,`property`),
  CONSTRAINT `indicators_devices_ibfk_1` FOREIGN KEY (`device_id`) REFERENCES `devices` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- История срабатывания датчиков сигнализации устройств
CREATE TABLE indicator_history (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `indicator_id` int(10) UNSIGNED NOT NULL,
  `place_id` int(10) UNSIGNED NOT NULL,
  `value` tinyint(1) NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  CONSTRAINT `indicator_history_sensors_ibfk_1` FOREIGN KEY (`indicator_id`) REFERENCES `indicators` (`id`),
  CONSTRAINT `indicator_history_places_ibfk_1` FOREIGN KEY (`place_id`) REFERENCES `places` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE variables (
  `name` varchar(64) NOT NULL,
  `value` text NULL DEFAULT NULL,
  UNIQUE KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `modules` (`id`, `name`, `namespace`, `disabled`) VALUES
(1, 'xiaomi', 'Xiaomi', 1, 0, 0),
(2, 'yeelight', 'Yeelight', 1, 0, 0),
(3, 'yandex', 'Yandex', 0, 1, 0);
