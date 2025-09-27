-- Script d'initialisation pour DAGDA Orchestrator
-- Création automatique de la base dagda et de l'utilisateur dagda_user

-- Créer la base de données dagda si elle n'existe pas
CREATE DATABASE IF NOT EXISTS `dagda` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Créer l'utilisateur dagda_user s'il n'existe pas
CREATE USER IF NOT EXISTS 'dagda_user'@'%' IDENTIFIED BY 'secure_dagda_password';

-- Accorder tous les privilèges sur la base dagda à dagda_user
GRANT ALL PRIVILEGES ON `dagda`.* TO 'dagda_user'@'%';

-- Appliquer les changements
FLUSH PRIVILEGES;

-- Log de confirmation
SELECT 'DAGDA Orchestrator database and user created successfully' AS status;
