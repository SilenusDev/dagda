-- cauldron/cromlech/mariadb/init-dagda.sql
-- Script d'initialisation automatique dagda_db
-- Version minimale : base + utilisateur uniquement

-- 1. Créer la base de données dagda_db
CREATE DATABASE IF NOT EXISTS dagda_db 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- 2. Créer l'utilisateur dagda_db_user avec accès limité
CREATE USER IF NOT EXISTS 'dagda_db_user'@'%' IDENTIFIED BY 'secure_dagda_db_password';

-- 3. Accorder UNIQUEMENT les privilèges sur dagda_db
GRANT ALL PRIVILEGES ON dagda_db.* TO 'dagda_db_user'@'%';

-- 4. Appliquer les changements
FLUSH PRIVILEGES;

-- 5. Confirmation
SELECT 'DAGDA_DB: Base et utilisateur créés avec succès' AS status;