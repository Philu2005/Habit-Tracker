-- Datenbank anlegen (einmalig, als root)
-- CREATE DATABASE habit_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- CREATE USER 'habit_app'@'localhost' IDENTIFIED BY 'super-secure-password';
-- GRANT ALL PRIVILEGES ON habit_db.* TO 'habit_app'@'localhost';
-- FLUSH PRIVILEGES;

-- Tabelle
CREATE TABLE IF NOT EXISTS habits (
  id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  due_date DATE NOT NULL,
  PRIMARY KEY (id),
  KEY idx_due_date (due_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
