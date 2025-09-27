# SPÉCIFICATIONS MUIRDRIS - ÉCOSYSTÈME PYTHON DAGDA-LITE (MISE À JOUR)

## Vue d'ensemble

**Muirdris** (serpent en irlandais) est l'écosystème Python unifié de Dagda-Lite, conçu pour optimiser les performances et la gestion des ressources tout en maintenant la modularité et la légèreté du système. **MISE À JOUR** : Intégration complète de l'orchestrateur Dagda dans FastAPI avec monitoring intelligent et interface SolidJS.

## Objectifs stratégiques

- **Légèreté maximale** : Démarrage à la demande, extinction granulaire
- **Modularité totale** : Chaque service reste indépendant
- **Mutualisation intelligente** : Partage des ressources communes (modèles, cache)
- **Performance optimisée** : Communication réseau locale, volumes partagés
- **Orchestration intelligente** : FastAPI devient le cerveau central de Dagda-Lite
- **Monitoring en temps réel** : Surveillance proactive des ressources système
- **Interface moderne** : SolidJS pour pilotage intuitif

## Architecture mise à jour

### Structure des répertoires
```
Nemeton/muirdris/
├── fastapi/                    # SERVICE ORCHESTRATEUR CENTRAL ⭐
│   ├── pod.yml                # Configuration Kubernetes
│   ├── manage.sh              # Script de gestion du service
│   ├── Dockerfile             # Image Python personnalisée
│   ├── app/                   # Code source FastAPI ÉTENDU
│   │   ├── main.py           # API REST + WebSocket + Orchestrateur
│   │   ├── database.py       # NOUVEAU - Configuration SQLAlchemy
│   │   ├── models/           # NOUVEAU - Modèles SQLAlchemy
│   │   │   ├── __init__.py
│   │   │   ├── pods.py       # Table pods
│   │   │   ├── workflows.py  # Table workflows
│   │   │   ├── system_resources.py # Table monitoring
│   │   │   └── alerts.py     # Table alertes
│   │   ├── api/              # Routes API étendues
│   │   │   ├── llm.py        # Routes LLM existantes
│   │   │   ├── system.py     # Routes système existantes
│   │   │   ├── orchestrator.py # NOUVEAU - Gestion pods/workflows
│   │   │   ├── monitoring.py   # NOUVEAU - Monitoring temps réel
│   │   │   └── logs.py         # NOUVEAU - Logs centralisés
│   │   ├── services/         # NOUVEAU - Logique métier
│   │   │   ├── __init__.py
│   │   │   ├── pod_manager.py    # Interface avec taranis.sh
│   │   │   ├── resource_monitor.py # Monitoring psutil + podman
│   │   │   ├── workflow_engine.py  # Moteur workflows
│   │   │   └── alert_manager.py    # Gestion alertes
│   │   ├── web/              # Templates HTML (si existant)
│   │   └── models.py         # Modèles Pydantic étendus
│   ├── requirements.txt       # Dépendances Python mises à jour
│   ├── data/                  # Données spécifiques FastAPI
│   └── config/                # Configuration FastAPI
├── llama/                     # Service LLM Llama (optionnel)
│   ├── pod.yml               # Configuration Kubernetes
│   ├── manage.sh             # Script de gestion
│   ├── Dockerfile            # Image Llama optimisée
│   ├── app/                  # Service Llama
│   ├── data/                 # Symlink vers shared/models/llama/
│   └── config/               # Configuration Llama
├── qwen/                     # Service LLM Qwen (optionnel)
│   ├── pod.yml               # Configuration Kubernetes
│   ├── manage.sh             # Script de gestion
│   ├── Dockerfile            # Image Qwen optimisée
│   ├── app/                  # Service Qwen
│   ├── data/                 # Symlink vers shared/models/qwen/
│   └── config/               # Configuration Qwen
└── shared/                   # Ressources communes
    ├── models/               # Stockage modèles partagé
    │   ├── llama/           # Modèles Llama (.gguf)
    │   ├── qwen/            # Modèles Qwen (.gguf)
    │   └── cache/           # Cache temporaire
    ├── python/              # Dépendances Python communes
    │   ├── requirements.txt # Dépendances partagées
    │   └── wheels/          # Packages Python en cache
    └── config/              # Configuration globale
        ├── logging.conf     # Configuration logs Python
        └── model-registry.json # Registre des modèles disponibles
```

### Architecture de données - Base de données unifiée

#### Structure MariaDB étendue
```sql
-- Base de données dagda_orchestrator dans MariaDB existant
-- Utilisateur dagda_api avec accès spécifique

-- Table pods : Catalogue de tous les pods système
CREATE TABLE pods (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    category ENUM('essential', 'optional') NOT NULL,
    status ENUM('stopped', 'starting', 'running', 'stopping', 'error') DEFAULT 'stopped',
    port INT,
    cpu_limit DECIMAL(3,1) DEFAULT 1.0,
    ram_limit INT DEFAULT 512,
    current_cpu DECIMAL(5,2) DEFAULT 0.00,
    current_ram INT DEFAULT 0,
    health_endpoint VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Table workflows : Catalogue des combinaisons de services
CREATE TABLE workflows (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    required_pods JSON NOT NULL,  -- ["llama", "qwen", "fastapi"]
    estimated_cpu DECIMAL(4,1) NOT NULL,
    estimated_ram INT NOT NULL,
    priority INT DEFAULT 5,  -- 1=critique, 10=optionnel
    is_active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table system_resources : Historique monitoring
CREATE TABLE system_resources (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cpu_usage DECIMAL(5,2),
    ram_usage DECIMAL(5,2),
    ram_total INT,
    disk_usage DECIMAL(5,2),
    active_pods JSON,
    system_load DECIMAL(4,2),
    INDEX idx_timestamp (timestamp)
);

-- Table resource_alerts : Système d'alertes
CREATE TABLE resource_alerts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    alert_type ENUM('cpu_high', 'ram_high', 'disk_high', 'pod_down', 'workflow_failed') NOT NULL,
    message TEXT NOT NULL,
    severity ENUM('info', 'warning', 'critical') NOT NULL,
    resolved BOOLEAN DEFAULT FALSE,
    pod_name VARCHAR(50),
    threshold_value DECIMAL(5,2),
    current_value DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMP NULL
);
```

## Services et responsabilités mis à jour

### FastAPI - Orchestrateur Central ⭐
- **Rôle** : Cerveau central de Dagda-Lite, API REST + orchestrateur + monitoring
- **Port** : 8902 (via FASTAPI_PORT)
- **Démarrage** : Automatique avec MariaDB (service essentiel)
- **Dépendances** : MariaDB (obligatoire), taranis.sh (interface)
- **Nouvelles fonctionnalités** :
  - **Orchestrateur de pods** : Start/stop via taranis.sh
  - **Moteur de workflows** : Gestion combinaisons services
  - **Monitoring temps réel** : CPU/RAM système et pods
  - **Système d'alertes** : Seuils configurables
  - **Mode économique** : Suggestions arrêt pods
  - **WebSocket** : Communication temps réel avec SolidJS
  - **Health checks** : Surveillance automatique services
  - **Logs centralisés** : Agrégation logs tous services

### Llama - Service LLM (optionnel, surveillé)
- **Rôle** : Service LLM Llama spécialisé + monitoring ressources
- **Port** : 8905 (via LLAMA_PORT)
- **Démarrage** : Sur demande uniquement, via orchestrateur
- **Monitoring** : Ressources surveillées en continu quand actif
- **Communication** : Enregistrement automatique auprès FastAPI

### Qwen - Service LLM (optionnel, surveillé)
- **Rôle** : Service LLM Qwen spécialisé + monitoring ressources
- **Port** : 8906 (via QWEN_PORT)
- **Démarrage** : Sur demande uniquement, via orchestrateur
- **Monitoring** : Ressources surveillées en continu quand actif
- **Communication** : Enregistrement automatique auprès FastAPI

## Communication inter-services étendue

### Architecture de communication
```
SolidJS (8900) ←→ FastAPI (8902) ←→ taranis.sh ←→ manage.sh ←→ Pods
                      ↓
                 MariaDB (8901)
                      ↓
              Monitoring/Alertes
```

### Nouveaux endpoints FastAPI

#### Orchestrateur
```python
# Gestion pods
GET    /api/orchestrator/pods                    # Liste tous les pods
POST   /api/orchestrator/pods/{name}/start       # Démarre un pod
POST   /api/orchestrator/pods/{name}/stop        # Arrête un pod
GET    /api/orchestrator/pods/{name}/status      # Statut détaillé pod

# Gestion workflows
GET    /api/orchestrator/workflows               # Catalogue workflows
POST   /api/orchestrator/workflows/{id}/start    # Démarre workflow
POST   /api/orchestrator/workflows/{id}/stop     # Arrête workflow
POST   /api/orchestrator/workflows/{id}/check    # Vérif ressources

# Mode économique
GET    /api/orchestrator/resources/check         # État ressources
POST   /api/orchestrator/resources/optimize      # Suggestions optimisation
```

#### Monitoring
```python
# Monitoring système
GET    /api/monitoring/system/resources          # Ressources temps réel
GET    /api/monitoring/system/history           # Historique ressources
GET    /api/monitoring/pods/{name}/resources     # Ressources pod spécifique

# Alertes
GET    /api/monitoring/alerts                   # Alertes actives
POST   /api/monitoring/alerts/{id}/resolve      # Résoudre alerte
GET    /api/monitoring/alerts/history          # Historique alertes

# Logs
GET    /api/monitoring/logs/{pod}               # Logs pod spécifique
GET    /api/monitoring/logs/system             # Logs système globaux
```

#### WebSocket temps réel
```python
# WebSocket endpoints
WS     /ws/monitoring                          # Monitoring temps réel
WS     /ws/logs                               # Logs en streaming
WS     /ws/alerts                             # Alertes temps réel
```

## Interface SolidJS - Architecture

### Structure frontend
```
dagda/sidhe-ui/
├── src/
│   ├── App.jsx                  # Composant principal avec routing
│   ├── index.jsx                # Point d'entrée
│   ├── components/              # Composants réutilisables
│   │   ├── PodCard.jsx          # Card pod avec actions start/stop
│   │   ├── ResourceChart.jsx    # Graphiques ressources temps réel
│   │   ├── WorkflowCard.jsx     # Card workflow avec estimations
│   │   ├── AlertBanner.jsx      # Bannière alertes système
│   │   ├── SystemStatus.jsx     # Overview système global
│   │   └── LogsViewer.jsx       # Viewer logs temps réel
│   ├── pages/                   # Pages principales
│   │   ├── Dashboard.jsx        # Vue d'ensemble système
│   │   ├── Pods.jsx             # Gestion pods individuels
│   │   ├── Workflows.jsx        # Catalogue et gestion workflows
│   │   ├── Monitoring.jsx       # Graphiques détaillés + historique
│   │   ├── Logs.jsx             # Logs centralisés
│   │   └── Settings.jsx         # Configuration seuils/alertes
│   ├── services/                # Services API
│   │   ├── api.js               # Client HTTP vers FastAPI
│   │   ├── websocket.js         # WebSocket client
│   │   └── notifications.js     # Système notifications
│   ├── stores/                  # État global (Solid Store)
│   │   ├── systemStore.js       # État système + ressources
│   │   ├── podsStore.js         # État pods + actions
│   │   ├── workflowsStore.js    # État workflows
│   │   └── alertsStore.js       # État alertes
│   └── styles/                  # CSS/Tailwind
├── public/
├── package.json
└── vite.config.js
```

### Pages détaillées

#### Dashboard principal
- **Vue d'ensemble système** : CPU/RAM global temps réel
- **Pods essentiels** : MariaDB, FastAPI, Yarn avec statuts
- **Workflows actifs** : Services multi-pods en cours
- **Alertes récentes** : Notifications système importantes
- **Actions rapides** : Boutons workflows prédéfinis

#### Gestion pods
- **Liste tous les pods** : Essentiels + optionnels avec statuts
- **Actions par pod** : Start/Stop/Restart/Logs
- **Monitoring par pod** : Ressources détaillées
- **Health checks** : Statut santé services
- **Configuration** : Limites CPU/RAM par pod

#### Catalogue workflows
- **Workflows prédéfinis** : "IA Complete", "Workflow Auto"
- **Vérification ressources** : Estimation avant démarrage
- **Mode économique** : Suggestions optimisation
- **Création custom** : Combinaisons personnalisées
- **Historique** : Workflows précédemment utilisés

## Gestion des ressources intelligente

### Monitoring proactif
```python
# services/resource_monitor.py - Fonctionnalités étendues
class ResourceMonitor:
    def get_system_resources(self) -> Dict:
        """Ressources système complètes"""
        return {
            "cpu_percent": psutil.cpu_percent(interval=1),
            "ram_percent": psutil.virtual_memory().percent,
            "ram_total": psutil.virtual_memory().total // (1024*1024),
            "ram_available": psutil.virtual_memory().available // (1024*1024),
            "disk_percent": psutil.disk_usage('/').percent,
            "load_avg": os.getloadavg()[0],
            "timestamp": datetime.now().isoformat()
        }
    
    def get_pod_resources(self, pod_name: str) -> Dict:
        """Ressources pod via podman stats"""
        # Parse JSON output podman stats
        
    def check_thresholds(self, resources: Dict) -> List[Dict]:
        """Vérification seuils et génération alertes"""
        # Logique alertes configurables
        
    def suggest_optimization(self) -> Dict:
        """Suggestions mode économique"""
        # Analyse pods optionnels vs ressources disponibles
```

### Seuils configurables
```bash
# Variables .env pour seuils
ALERT_RAM_THRESHOLD=80          # % RAM critique
ALERT_CPU_THRESHOLD=70          # % CPU critique
ALERT_DISK_THRESHOLD=85         # % Disk critique
MONITORING_INTERVAL=5           # Secondes entre checks
HISTORY_RETENTION_DAYS=7        # Rétention historique
ECONOMIC_MODE_AUTO=false        # Mode éco automatique
```

### Mode économique intelligent
- **Détection automatique** : Ressources insuffisantes pour workflow
- **Priorisation pods** : Essentiels vs optionnels
- **Suggestions utilisateur** : Pods à arrêter avec impact estimé
- **Sauvegarde état** : Restauration automatique quand ressources OK
- **Configuration** : Seuils personnalisables par utilisateur

## Démarrage et arrêt orchestré

### Séquences étendues
```bash
# Démarrage orchestrateur (services essentiels)
./dagda/eveil/taranis.sh dagda
# -> MariaDB + FastAPI (avec orchestrateur) + Yarn

# Interface utilisateur
# -> SolidJS sur port 8900 se connecte automatiquement à FastAPI

# Workflows via interface
# -> Sélection "IA Complete" dans SolidJS
# -> Vérification ressources automatique
# -> Démarrage Llama + Qwen si ressources OK
# -> Monitoring temps réel activé
```

### Scripts de gestion étendus
```bash
# Nouveaux scripts orchestrateur
./Nemeton/muirdris/fastapi/manage.sh orchestrator {start|stop|status}
./Nemeton/muirdris/fastapi/manage.sh monitoring {enable|disable|status}
./Nemeton/muirdris/fastapi/manage.sh workflows {list|start|stop}

# Interface avec taranis.sh
# FastAPI appelle automatiquement taranis.sh pour actions pods
# Pas de duplication de logique, réutilisation existant
```

## Configuration réseau mise à jour

### Variables d'environnement étendues
```bash
# Ports services muirdris
FASTAPI_PORT=8902               # FastAPI orchestrateur
LLAMA_PORT=8905                 # Service Llama
QWEN_PORT=8906                  # Service Qwen
SOLIDJS_PORT=8900              # Interface SolidJS

# Configuration orchestrateur
MYSQL_API_USER=dagda_api        # Utilisateur DB orchestrateur
MYSQL_API_PASSWORD=secure_pwd   # Password sécurisé
ORCHESTRATOR_DB=dagda_orchestrator

# Configuration monitoring
MONITORING_INTERVAL=5           # Intervalle monitoring (secondes)
ALERT_RAM_THRESHOLD=80         # Seuil alerte RAM (%)
ALERT_CPU_THRESHOLD=70         # Seuil alerte CPU (%)
WEBSOCKET_ENABLED=true         # WebSocket temps réel

# Configuration workflows
ECONOMIC_MODE_AUTO=false       # Mode économique automatique
WORKFLOW_TIMEOUT=300          # Timeout démarrage workflow (sec)
HEALTH_CHECK_INTERVAL=30      # Intervalle health checks (sec)
```

## Logging et monitoring centralisé

### Convention de logs étendue
```bash
# FastAPI orchestrateur
[fastapi][orchestrator][info] Démarrage workflow "IA Complete"
[fastapi][monitoring][warning] RAM système à 85%
[fastapi][alert][critical] Échec démarrage pod llama

# Intégration logs existants
[llama][start] via [fastapi][orchestrator] Démarrage service Llama
[qwen][error] via [fastapi][orchestrator] Modèle manquant

# Logs SolidJS (frontend)
[solidjs][user] Utilisateur lance workflow "IA Complete"
[solidjs][websocket] Connexion monitoring temps réel établie
```

### Health checks étendus
```python
# Health checks orchestrateur
GET /api/health/system          # Santé système global
GET /api/health/orchestrator    # Santé orchestrateur
GET /api/health/pods           # Santé tous les pods
GET /api/health/workflows      # Santé workflows actifs

# Réponses structurées
{
    "status": "healthy|degraded|critical",
    "components": {
        "database": "healthy",
        "monitoring": "healthy", 
        "pods": {"llama": "running", "qwen": "stopped"},
        "resources": {"ram": 45, "cpu": 23}
    },
    "alerts": [],
    "uptime": "2h 34m"
}
```

## Migration et déploiement

### Étapes de migration FastAPI
1. **Audit existant** : Vérifier structure actuelle FastAPI
2. **Extension base** : Ajouter SQLAlchemy + nouvelles routes