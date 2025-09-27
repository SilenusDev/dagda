# Architecture DAGDA-LITE - Post-Migration

**Version :** 2.1 (Services essentiels validés)  
**Date :** 21 septembre 2025  
**Statut :** Production Ready (100% complété)

---

## 🏗️ STRUCTURE PROJET

```
dagda-lite/
├── .env                          # Configuration centralisée
├── .env.example                  # Template configuration
├── dagda/                        # Moteur d'orchestration (ex: coire-anseasc)
│   ├── eveil/                    # Scripts d'orchestration
│   │   ├── taranis.sh            # Orchestrateur principal (ex: lug.sh)
│   │   └── stop_all.sh           # Arrêt d'urgence tous services
│   ├── awens-utils/              # Utilitaires bash (ex: awens-utils)
│   │   ├── ollamh.sh             # Fonctions communes + détection architecture
│   │   └── imbas-logging.sh      # Système de logs unifié
│   ├── awen-core/                # Moteur principal (ex: cauldron-core)
│   │   └── teine_engine.sh       # Moteur générique pods
│   ├── bairille-dighe/           # Templates configuration
│   │   └── coire-template.yml    # Template pod générique
│   └── scripts/                  # Scripts obsolètes (redirection)
│       └── lug.sh                # Redirige vers dagda/eveil/taranis.sh
├── cauldron/                     # Services conteneurisés (ex: Nemeton)
│   ├── cromlech/                 # Services essentiels - Base de données uniquement
│   │   └── mariadb/              # Base de données 
│   │       ├── pod.yml           # Configuration Podman
│   │       ├── manage.sh         # Script de gestion
│   │       ├── data/             # Données persistantes
│   │       └── config/           # Configuration MariaDB
│   ├── muirdris/                 # Système Python unifié (FastAPI + LLM)
│   │   ├── fastapi/              # Service API + Interface Web 
│   │   │   ├── pod.yml           # Configuration Podman
│   │   │   ├── manage.sh         # Script de gestion
│   │   │   ├── Dockerfile        # Image personnalisée
│   │   │   ├── app/              # Code application
│   │   │   │   ├── main.py       # API REST + serveur web
│   │   │   │   ├── api/          # Endpoints API
│   │   │   │   │   ├── llm.py    # Routes LLM
│   │   │   │   │   └── system.py # Routes système
│   │   │   │   ├── web/          # Interface web
│   │   │   │   │   ├── static/   # Assets statiques
│   │   │   │   │   └── templates/ # Templates HTML
│   │   │   │   └── models.py     # Modèles Pydantic
│   │   │   ├── requirements.txt  # Dépendances Python
│   │   │   ├── data/             # Données application
│   │   │   └── config/           # Configuration FastAPI
│   │   ├── llama/                # Service LLM Llama
│   │   │   ├── pod.yml           # Configuration Podman
│   │   │   ├── manage.sh         # Script de gestion
│   │   │   ├── data/             # Modèles Llama
│   │   │   └── config/           # Configuration Llama
│   │   └── qwen25-05b/           # Service LLM Qwen2.5-0.5B
│   │       ├── pod.yml           # Configuration Podman
│   │       ├── manage.sh         # Script de gestion
│   │       ├── data/             # Modèles Qwen
│   │       └── config/           # Configuration Qwen
│   ├── fianna/                   # Applications (ex: applications)
│   │   ├── adminer/              # Interface base de données
│   │   │   ├── pod.yml           # Configuration Podman
│   │   │   ├── manage.sh         # Script de gestion
│   │   │   └── data/             # Données Adminer
│   │   └── n8n/                  # Automatisation workflows
│   │       ├── pod.yml           # Configuration Podman
│   │       ├── manage.sh         # Script de gestion
│   │       └── data/             # Données N8N
│   └── geasa/                    # Environnements (nouveau)
│       └── yarn/                 # Gestionnaire paquets Node.js 
│           ├── pod.yml           # Configuration Podman
│           ├── manage.sh         # Script de gestion
│           ├── data/             # Cache Yarn
│           ├── config/           # Configuration Yarn
│           └── workspace/        # Espace de travail SolidJS
└── sidhe/                        # Interface utilisateur SolidJS (à implémenter)
    ├── dist/                     # Build SolidJS (servi par FastAPI)
    ├── src/                      # Code source SolidJS
    │   ├── components/           # Composants réutilisables
    │   ├── pages/                # Pages application
    │   └── services/             # Clients API (vers FastAPI)
    ├── package.json              # Dépendances Node.js
    └── vite.config.ts            # Configuration build
```

---

## 🎯 SERVICES ESSENTIELS DAGDA

### **Services Validés et Opérationnels**

#### **MariaDB - Base de données**
- **Port :** DB_PORT=8901
- **Statut :**  (2 conteneurs)
- **Fonction :** Base de données principale
- **Localisation :** `/cauldron/cromlech/mariadb/`

#### **FastAPI - API + Interface Web**
- **Port :** API_PORT=8902
- **Statut :**  (2 conteneurs)
- **Fonction :** API REST + Interface web
- **Localisation :** `/cauldron/muirdris/fastapi/`

#### **Yarn - Environnement SolidJS**
- **Port :** YARN_PORT=8907
- **Statut :**  (2 conteneurs)
- **Fonction :** Gestionnaire paquets Node.js + environnement SolidJS
- **Localisation :** `/cauldron/geasa/yarn/`

### **Services Optionnels** (démarrage individuel)

#### **LLM Services - Système Python Unifié**
- **llama** : Modèle LLM Llama (LLAMA_PORT=8905) - `/cauldron/muirdris/llama/`
- **qwen** : Modèle LLM Qwen2.5-0.5B (QWEN_PORT=8906) - `/cauldron/muirdris/qwen25-05b/`

#### **Applications**
- **adminer** : Interface base de données (ADMIN_PORT=8903)
- **n8n** : Automatisation workflows (WORKFLOW_PORT=8904)

---

## 🚀 ORCHESTRATION

### Script Principal : `./dagda/eveil/taranis.sh`

**Commandes validées :**
```bash
# Services essentiels (3 pods validés)
./dagda/eveil/taranis.sh dagda         # MariaDB + FastAPI + Yarn

# Services individuels
./dagda/eveil/taranis.sh mariadb       # Base de données
./dagda/eveil/taranis.sh fastapi       # API + Interface web
./dagda/eveil/taranis.sh yarn          # Environnement SolidJS
./dagda/eveil/taranis.sh llama         # Modèle LLM Llama
./dagda/eveil/taranis.sh qwen          # Modèle LLM Qwen
./dagda/eveil/taranis.sh adminer       # Interface DB
./dagda/eveil/taranis.sh n8n           # Workflows

# Commandes de statut
./dagda/eveil/taranis.sh status dagda  # Statut services essentiels
./dagda/eveil/taranis.sh status all    # Statut tous services
./dagda/eveil/taranis.sh status {service} # Statut service individuel

# Commandes d'arrêt
./dagda/eveil/taranis.sh stop dagda    # Arrêt services essentiels
./dagda/eveil/taranis.sh stop all      # Arrêt tous services
./dagda/eveil/taranis.sh stop {service} # Arrêt service individuel

# Arrêt d'urgence
./dagda/eveil/stop_all.sh              # Arrêt forcé + nettoyage
```

---

## 🔧 CONFIGURATION

### Variables d'Environnement Validées
```bash
# Project Configuration
PROJECT_NAME=dagda-lite
HOST=192.168.1.43

# Service Ports (890X range) - VALIDÉS
DB_PORT=8901      # MariaDB 
API_PORT=8902     # FastAPI 
ADMIN_PORT=8903   # Adminer
WORKFLOW_PORT=8904 # N8N
LLAMA_PORT=8905   # Llama
QWEN_PORT=8906    # Qwen
YARN_PORT=8907    # Yarn 

# Project root
DAGDA_ROOT=/path/to/dagda-lite

# Engine scripts
OLLAMH_SCRIPT=${DAGDA_ROOT}/dagda/awens-utils/ollamh.sh
TEINE_ENGINE_SCRIPT=${DAGDA_ROOT}/dagda/awen-core/teine_engine.sh
TARANIS_SCRIPT=${DAGDA_ROOT}/dagda/eveil/taranis.sh

# Service directories
CAULDRON_DIR=${DAGDA_ROOT}/cauldron
CROMLECH_DIR=${CAULDRON_DIR}/cromlech
MUIRDRIS_DIR=${CAULDRON_DIR}/muirdris
FIANNA_DIR=${CAULDRON_DIR}/fianna
GEASA_DIR=${CAULDRON_DIR}/geasa
```

### Installation et Démarrage
```bash
# Configuration initiale
cd dagda-lite
cp .env.example .env
# Éditer .env avec vos paramètres

# Permissions scripts
chmod +x ./dagda/eveil/taranis.sh
chmod +x ./dagda/eveil/stop_all.sh

# Démarrage services essentiels
./dagda/eveil/taranis.sh dagda

# Vérification
./dagda/eveil/taranis.sh status dagda
```

### Séquence de Test Validée
```bash
# 1. Services essentiels (VALIDÉ )
./dagda/eveil/taranis.sh dagda
# → MariaDB:  (port 8901)
# → FastAPI:  (port 8902)  
# → Yarn:  (port 8907)

# 2. Services optionnels (démarrage individuel)
./dagda/eveil/taranis.sh llama
./dagda/eveil/taranis.sh qwen
./dagda/eveil/taranis.sh adminer
./dagda/eveil/taranis.sh n8n

# 3. Vérification globale
./dagda/eveil/taranis.sh status all

# 4. Arrêt propre
./dagda/eveil/taranis.sh stop dagda
```

---

## 📊 STATUT MIGRATION

### **COMPLÉTÉ (100%)**
- **Architecture** : Migration Nemeton→cauldron terminée
- **Cromlech** : Contient uniquement MariaDB (base de données)
- **Muirdris** : Système Python unifié (FastAPI + LLM Llama + Qwen)
- **Scripts** : ollamh.sh, teine_engine.sh, taranis.sh opérationnels
- **Services essentiels** : MariaDB, FastAPI, Yarn validés
- **Orchestration** : taranis.sh fonctionnel avec 3 services essentiels
- **Configuration** : Variables d'environnement externalisées
- **Sécurité** : Aucun hardcoding, logging standardisé

### **PROCHAINES ÉTAPES**
1. **Interface SolidJS** : Développement dans `/sidhe/`
2. **Services LLM** : Tests Llama et Qwen
3. **Monitoring** : Dashboard de statut des services
4. **Documentation** : Guides utilisateur détaillés

---

## 🔐 SÉCURITÉ ET CONFORMITÉ

### **Standards Respectés**
- **Variables d'environnement** : Toutes externalisées
- **Logging** : Format `[script][event] message` standardisé
- **Chemins** : Aucun hardcoding, utilisation exclusive des variables .env
- **Permissions** : Scripts exécutables, données protégées
- **Ports** : Range 890X dédié, pas de conflits

### **Bonnes Pratiques**
- Chargement sécurisé du `.env`
- Vérification des prérequis avant démarrage
- Nettoyage automatique des anciens pods
- Gestion gracieuse des arrêts
- Monitoring des ports et processus