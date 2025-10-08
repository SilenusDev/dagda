# DAGDA-LITE - Guide d'utilisation

**Commandes essentielles pour utiliser DAGDA-LITE**

---

## 🚀 Démarrage rapide

```bash
# 1. Démarrer les services essentiels (MariaDB + FastAPI + Sidhe)
./dagda/eveil/taranis.sh dagda

# 2. Vérifier le statut
./dagda/eveil/taranis.sh status dagda

# 3. Accéder aux interfaces
# - Sidhe: http://localhost:8900
# - FastAPI: http://localhost:8902/docs
# - Adminer: http://localhost:8903
```

---

## 📋 Commandes principales

### Services essentiels

```bash
# Démarrer (MariaDB + FastAPI + Sidhe)
./dagda/eveil/taranis.sh dagda

# Statut
./dagda/eveil/taranis.sh status dagda

# Arrêter
./dagda/eveil/taranis.sh stop dagda
```

### Services individuels

```bash
# Démarrer un service
./dagda/eveil/taranis.sh {mariadb|fastapi|sidhe|llama|qwen|adminer|n8n}

# Exemples
./dagda/eveil/taranis.sh mariadb
./dagda/eveil/taranis.sh fastapi
./dagda/eveil/taranis.sh sidhe
```

### Gestion globale

```bash
# Statut de tous les services
./dagda/eveil/taranis.sh status all

# Arrêter tous les services
./dagda/eveil/taranis.sh stop all

# Arrêt d'urgence
./dagda/eveil/stop_all.sh
```

---

## 🎨 Interface Sidhe

### Installation automatisée

```bash
# 1. Démarrer les services
./dagda/eveil/taranis.sh dagda

# 2. Installer Sidhe (si première fois)
./dagda/eveil/setup-sidhe.sh

# 3. Redémarrer Sidhe
source .env && ${TEINE_ENGINE_SCRIPT} stop ${DAGDA_ROOT}/cauldron/ogmios/sidhe
source .env && ${TEINE_ENGINE_SCRIPT} start ${DAGDA_ROOT}/cauldron/ogmios/sidhe
```

### Accès
- **Interface**: http://localhost:8900
- **Logs**: `podman logs --tail 50 dagda-lite-sidhe-pod-dagda-lite-sidhe`

---

## 🔧 Environnements

### Basculer dev/prod

```bash
# Au démarrage, choisir:
./dagda/eveil/taranis.sh dagda
# 1) dev  - localhost
# 2) prod - IP serveur

# Ou forcer un environnement
./dagda/eveil/switch-env.sh dev
./dagda/eveil/switch-env.sh prod

# Voir environnement actuel
./dagda/eveil/switch-env.sh status
```

### Fichiers de configuration

| Fichier | Usage |
|---------|-------|
| `.env` | Actif (auto-généré, ne pas modifier) |
| `.env.dev` | Développement (localhost) |
| `.env.prod` | Production (IP serveur) |

---

## 🗄️ Base de données

### Accès MariaDB

```bash
# Via Adminer (interface web)
http://localhost:8903

# Via CLI
podman exec -it dagda-lite-mariadb-pod-dagda-lite-mariadb mysql -u root -p
```

### Connexion depuis FastAPI

Variables dans `.env`:
```bash
DB_HOST=localhost
DB_PORT=8901
DB_USER=root
DB_PASSWORD=dagda_root_2024
DB_NAME=dagda_db
```

---

## 🔍 Monitoring

### Logs

```bash
# Logs d'un service (dernières 50 lignes)
podman logs --tail 50 dagda-lite-{service}-pod-dagda-lite-{service}

# Exemples
podman logs --tail 50 dagda-lite-mariadb-pod-dagda-lite-mariadb
podman logs --tail 50 dagda-lite-fastapi-pod-dagda-lite-fastapi
podman logs --tail 50 dagda-lite-sidhe-pod-dagda-lite-sidhe

# Suivre en temps réel
podman logs -f dagda-lite-fastapi-pod-dagda-lite-fastapi
```

### Statut des pods

```bash
# Tous les pods
podman pod ps

# Conteneurs d'un pod
podman ps --filter pod={pod-name}

# Exemple
podman ps --filter pod=dagda-lite-mariadb-pod
```

---

## 🛠️ Dépannage rapide

### Service ne démarre pas

```bash
# 1. Vérifier les logs
podman logs --tail 100 dagda-lite-{service}-pod-dagda-lite-{service}

# 2. Vérifier le statut
./dagda/eveil/taranis.sh status {service}

# 3. Redémarrer
./dagda/eveil/taranis.sh stop {service}
./dagda/eveil/taranis.sh {service}
```

### Port déjà utilisé

```bash
# Trouver le processus
lsof -i :{port}

# Ou modifier le port dans .env.dev ou .env.prod
```

### Variables d'environnement

```bash
# Vérifier les variables chargées
source .env && env | grep DAGDA

# Recharger
source .env
```

---

## 📦 Ports utilisés

| Service | Port | URL |
|---------|------|-----|
| Sidhe | 8900 | http://localhost:8900 |
| MariaDB | 8901 | mysql://localhost:8901 |
| FastAPI | 8902 | http://localhost:8902/docs |
| Adminer | 8903 | http://localhost:8903 |
| N8N | 8904 | http://localhost:8904 |
| Llama | 8905 | http://localhost:8905 |
| Qwen | 8906 | http://localhost:8906 |
| Yarn | 8907 | (dev uniquement) |

---

## 🔐 Variables d'environnement critiques

```bash
# Projet
DAGDA_ROOT=/home/sam/Bureau/dagda
PROJECT_NAME=dagda-lite
HOST=localhost  # ou IP serveur en prod

# Base de données
DB_HOST=localhost
DB_PORT=8901
DB_USER=root
DB_PASSWORD=dagda_root_2024
DB_NAME=dagda_db

# Services
API_PORT=8902
VITE_PORT=8900
ADMIN_PORT=8903
WORKFLOW_PORT=8904

# Scripts
TEINE_ENGINE_SCRIPT=${DAGDA_ROOT}/dagda/awen-core/teine_engine.sh
OLLAMH_SCRIPT=${DAGDA_ROOT}/dagda/awens-utils/ollamh.sh
IMBAS_LOGGING_SCRIPT=${DAGDA_ROOT}/dagda/awens-utils/imbas-logging.sh
```

---

## 🎯 Workflow quotidien

```bash
# Matin - Démarrer
./dagda/eveil/taranis.sh dagda
# Choisir: 1) dev

# Développer...
# - Sidhe: http://localhost:8900
# - API: http://localhost:8902/docs
# - DB: http://localhost:8903

# Soir - Arrêter
./dagda/eveil/taranis.sh stop dagda
```
