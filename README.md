# Dagda-Lite 

> Orchestrateur ultra-léger de containers Podman inspiré de la mythologie celtique

**Dagda-Lite** transforme votre serveur en chaudron magique où chaque container devient un service orchestré par la sagesse druidique ancestrale.

## Architecture

- **dagda/** - Le druide suprême et son orchestration
  - **awen-core/** - Moteur générique d'orchestration (`teine_engine.sh`)
  - **awens-utils/** - Utilitaires communs (`ollamh.sh`, `imbas-logging.sh`)
  - **eveil/** - Scripts d'orchestration (`taranis.sh`, `stop_all.sh`)
- **cauldron/** - Le chaudron des services (containers)
  - **cromlech/** - Services essentiels (MariaDB, FastAPI, Llama)
  - **fianna/** - Services optionnels (Adminer, N8N)
  - **muirdris/** - Écosystème Python (FastAPI, Llama, Qwen)
  - **geasa/** - Environnements (Yarn, Composer)

## Installation

```bash
# Cloner le projet
git clone <votre-repo> dagda-lite
cd dagda-lite

# Créer l'arborescence
./create_dagda_structure.sh

# Configuration
cp .env.example .env
# Éditer .env avec vos paramètres
```

## Utilisation

### Services Essentiels (Dagda)
```bash
# Démarrer les 3 services essentiels : MariaDB, FastAPI, Yarn
./dagda/eveil/taranis.sh dagda

# Arrêter les services essentiels
./dagda/eveil/taranis.sh stop dagda

# Statut des services essentiels
./dagda/eveil/taranis.sh status dagda
```

### Services Individuels
```bash
# Démarrer un service spécifique
./dagda/eveil/taranis.sh mariadb
./dagda/eveil/taranis.sh fastapi
./dagda/eveil/taranis.sh yarn
./dagda/eveil/taranis.sh llama
./dagda/eveil/taranis.sh qwen
./dagda/eveil/taranis.sh adminer
./dagda/eveil/taranis.sh n8n

# Arrêter un service spécifique
./dagda/eveil/taranis.sh stop mariadb

# Statut d'un service
./dagda/eveil/taranis.sh status mariadb
```

### Commandes Globales
```bash
# Statut de tous les services
./dagda/eveil/taranis.sh status all

# Arrêter tous les services
./dagda/eveil/taranis.sh stop all
# ou
./dagda/eveil/stop_all.sh

# Aide
./dagda/eveil/taranis.sh help
```

## Services Disponibles

### Services Essentiels (Dagda)
- **MariaDB** (port 8901) - Base de données
- **FastAPI** (port 8902) - API REST
- **Yarn** (port 8907) - Environnement SolidJS

### Services Optionnels
- **Llama** (port 8903) - Modèle IA
- **Qwen** (port 8904) - Modèle IA alternatif
- **Adminer** (port 8905) - Interface base de données
- **N8N** (port 8906) - Automatisation workflow

## Variables d'Environnement

Principales variables dans `.env` :
```bash
# Projet
PROJECT_NAME=dagda-lite
DAGDA_ROOT=/path/to/dagda-lite

# Ports services
DB_PORT=8901
API_PORT=8902
YARN_PORT=8907
LLAMA_PORT=8903
QWEN_PORT=8904

# Scripts
TARANIS_SCRIPT=${DAGDA_ROOT}/dagda/eveil/taranis.sh
TEINE_ENGINE_SCRIPT=${DAGDA_ROOT}/dagda/awen-core/teine_engine.sh
```

## Développement

### Structure des Services
Chaque service suit la structure :
```
cauldron/{categorie}/{service}/
├── pod.yml          # Configuration Podman
├── manage.sh        # Script de gestion
├── Dockerfile       # Image container
└── config/          # Configuration spécifique
```

### Logs et Debugging
```bash
# Logs d'un service
./dagda/eveil/taranis.sh logs mariadb

# Statut détaillé
./dagda/eveil/taranis.sh status all

# Nettoyage des pods
./dagda/eveil/taranis.sh clean mariadb
```

### Connexions Adminer

Adminer est accessible via `http://${HOST}:${ADMIN_PORT}` (par défaut `http://192.168.1.43:8903`)

#### Connexion Base Principale (application_data)
```
Système: MySQL
Serveur: ${HOST}:${DB_PORT}
Utilisateur: ${DB_USER}
Mot de passe: ${DB_PASSWORD}
Base: ${DB_NAME}
```

#### Connexion Base DAGDA Orchestrator (dagda_db)
```
Système: MySQL
Serveur: ${HOST}:${DB_PORT}
Utilisateur: ${DAGDA_DB_USER}
Mot de passe: ${DAGDA_DB_PASSWORD}
Base: ${DAGDA_DB_NAME}
```

#### Connexion Administrateur (toutes les bases)
```
Système: MySQL
Serveur: ${HOST}:${DB_PORT}
Utilisateur: root
Mot de passe: ${DB_ROOT_PASSWORD}
Base: (laisser vide)
```

**Note:** La visibilité des bases de données dans Adminer dépend de l'utilisateur utilisé pour la connexion.

---
*"Que la magie opère dans le monde numérique"* 
