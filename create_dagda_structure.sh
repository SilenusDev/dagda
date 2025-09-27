#!/bin/bash
# create_dagda_structure.sh
# Script de création de l'arborescence complète de Dagda-Lite
# chmod +x create_dagda_structure.sh
# ./create_dagda_structure.sh
# set -e

# Couleurs pour l'affichage
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

log_info() { 
    echo -e "${BLUE}[INFO]${NC} $1" 
}

log_success() { 
    echo -e "${GREEN}[SUCCESS]${NC} $1" 
}

log_step() { 
    echo -e "${CYAN}[STEP]${NC} $1" 
}

# Vérification que nous sommes dans le bon répertoire
if [[ ! -d ".git" ]] && [[ ! -f "README.md" ]] && [[ ${PWD##*/} != "dagda-lite" ]]; then
    echo -e "${YELLOW}[WARNING]${NC} Assurez-vous d'être dans le répertoire racine de dagda-lite"
    read -p "Continuer quand même ? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

log_step "Création de l'arborescence mythologique Dagda-Lite..."
echo

# Structure principale
log_info "Création des répertoires principaux..."

# dagda/ - L'ORCHESTRATEUR
mkdir -p dagda/{Daurdabla-api/{geantraige-controllers,suantraige-models,goltraige-config},sidhe-ui,lore-core,nemeta-database}

# Nemeton/ - LES PODS
mkdir -p Nemeton/{cromlech/{mariadb/{data,config},fastapi/{data,config}},fianna/{adminer/{config},n8n/{data,config},llama/{data,config},qwen/{data,config}},ogmios/{ogham-data,ogham-logs,ogham-config,dolmen}}

# coire-anseasc/ - SCRIPTS GÉNÉRIQUES
mkdir -p coire-anseasc/{cauldron-core,awens-utils,bairille-dighe}

# scripts/ - SCRIPTS D'ENTRÉE
mkdir -p scripts

log_success "Structure des dossiers créée"

# Création des fichiers de base
log_info "Création des fichiers essentiels..."

# Fichiers de configuration des pods
cat > Nemeton/cromlech/mariadb/pod.yml << 'EOF'
# Configuration du sigil Cernunnos (MariaDB)
metadata:
  name: mariadb
  category: cromlech
  description: "Seigneur des connexions - Base de données"
  
resources:
  priority: sacred
  memory_limit: "512Mi"
  cpu_limit: "1.0"
  auto_shutdown: false

network:
  ports:
    main: 8902
  expose: true

volumes:
  - type: data
    host: "./data"
    container: "/var/lib/mysql"
  - type: config
    host: "./config/init.sql"
    container: "/docker-entrypoint-initdb.d/init.sql"

image:
  source: "docker.io/library/mariadb:10.11"
  
environment:
  MYSQL_ROOT_PASSWORD: "${MYSQL_ROOT_PASSWORD}"
  MYSQL_DATABASE: "${MYSQL_DATABASE}"
  MYSQL_USER: "${MYSQL_USER}"
  MYSQL_PASSWORD: "${MYSQL_PASSWORD}"

health:
  check: "mysqladmin ping -h localhost"
  interval: 30s
  timeout: 5s
  retries: 3
EOF

cat > Nemeton/cromlech/fastapi/pod.yml << 'EOF'
# Configuration du sigil Belenos (FastAPI)
metadata:
  name: fastapi
  category: cromlech
  description: "Soleil resplendissant - API principale"
  
resources:
  priority: sacred
  memory_limit: "256Mi"
  cpu_limit: "0.5"
  auto_shutdown: false

network:
  ports:
    main: 8903
  expose: true

dependencies:
  requires: ["mariadb"]

image:
  source: "tiangolo/fastapi:python3.11"
  
health:
  check: "curl -f http://localhost:8000/health"
  interval: 30s
  timeout: 5s
  retries: 3
EOF

# Scripts de gestion unifiés
cat > Nemeton/cromlech/mariadb/manage.sh << 'EOF'
#!/bin/bash
# Cantique d'invocation pour Cernunnos (MariaDB)

POD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$POD_DIR/../../../coire-anseasc/cauldron-core/teine_engine.sh"

case "$1" in
    eveil)     teine_eveil "$POD_DIR" ;;      # start
    repos)     teine_repos "$POD_DIR" ;;      # stop  
    renouveau) teine_renouveau "$POD_DIR" ;;  # restart
    etat)      teine_etat "$POD_DIR" ;;       # status
    sante)     teine_sante "$POD_DIR" ;;      # health
    annales)   teine_annales "$POD_DIR" ;;    # logs
    purge)     teine_purge "$POD_DIR" ;;      # clean
    *)         
        echo "Usage: $0 {eveil|repos|renouveau|etat|sante|annales|purge}"
        echo "Cantiques disponibles pour Cernunnos:"
        echo "  eveil     - Réveiller le seigneur des connexions"
        echo "  repos     - Endormir le gardien" 
        echo "  renouveau - Cycle complet repos/eveil"
        echo "  etat      - Connaître l'état du sigil"
        echo "  sante     - Vérifier la vitalité"
        echo "  annales   - Consulter les chroniques"
        echo "  purge     - Purification complète"
        ;;
esac
EOF

cat > Nemeton/cromlech/fastapi/manage.sh << 'EOF'
#!/bin/bash
# Cantique d'invocation pour Belenos (FastAPI)

POD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$POD_DIR/../../../coire-anseasc/cauldron-core/teine_engine.sh"

case "$1" in
    eveil)     teine_eveil "$POD_DIR" ;;
    repos)     teine_repos "$POD_DIR" ;;
    renouveau) teine_renouveau "$POD_DIR" ;;
    etat)      teine_etat "$POD_DIR" ;;
    sante)     teine_sante "$POD_DIR" ;;
    annales)   teine_annales "$POD_DIR" ;;
    purge)     teine_purge "$POD_DIR" ;;
    *)         
        echo "Usage: $0 {eveil|repos|renouveau|etat|sante|annales|purge}"
        echo "Cantiques disponibles pour Belenos:"
        echo "  eveil     - Réveiller le soleil resplendissant"
        echo "  repos     - Apaiser la lumière" 
        echo "  renouveau - Renaissance solaire"
        echo "  etat      - État du lumineux"
        echo "  sante     - Vitalité de l'astre"
        echo "  annales   - Chroniques de lumière"
        echo "  purge     - Purification solaire"
        ;;
esac
EOF

# Rendre les scripts exécutables
chmod +x Nemeton/cromlech/mariadb/manage.sh
chmod +x Nemeton/cromlech/fastapi/manage.sh

# Template pour nouveaux pods
cat > coire-anseasc/bairille-dighe/coire-template.yml << 'EOF'
# Template de sigil pour nouveaux services
metadata:
  name: "{{POD_NAME}}"
  category: "{{CATEGORY}}"  # cromlech | fianna
  description: "{{DESCRIPTION}}"
  
resources:
  priority: "{{PRIORITY}}"  # sacred | noble | common
  memory_limit: "{{MEMORY}}"
  cpu_limit: "{{CPU}}"
  auto_shutdown: {{AUTO_SHUTDOWN}}

network:
  ports:
    main: {{PORT}}
  expose: true

dependencies:
  requires: {{DEPENDENCIES}}

volumes:
  - type: data
    host: "./data"
    container: "{{DATA_PATH}}"

image:
  source: "{{IMAGE}}"
  
environment:
  {{ENVIRONMENT_VARS}}

health:
  check: "{{HEALTH_COMMAND}}"
  interval: 30s
  timeout: 5s
  retries: 3
EOF

# Script principal (squelette)
cat > scripts/lug.sh << 'EOF'
#!/bin/bash
# lug.sh - Le Polytechnicien, maître de tous les arts
# Script principal d'orchestration Dagda-Lite

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🍀 Dagda-Lite - Le Chaudron s'éveille..."
echo "🎭 Lug Samildanach prépare l'orchestration..."

case "$1" in
    cromlech)
        echo "🏛️ Éveil des services essentiels..."
        # TODO: Implémenter l'éveil des cromlechs
        ;;
    fianna)
        echo "🏹 Rassemblement de la Fianna..."
        # TODO: Implémenter la gestion des services optionnels
        ;;
    nemeton)
        echo "🌳 Ouverture du sanctuaire..."
        # TODO: Lancer l'interface web
        ;;
    *)
        echo "Usage: $0 {cromlech|fianna|nemeton}"
        echo ""
        echo "Invocations du Polytechnicien:"
        echo "  cromlech  - Éveille les cercles de pierres sacrés"
        echo "  fianna    - Rassemble les guerriers-chasseurs"
        echo "  nemeton   - Ouvre le sanctuaire druidique"
        ;;
esac
EOF

chmod +x scripts/lug.sh

# Fichiers de statut
cat > Nemeton/ogmios/dolmen/anseasc_status.json << 'EOF'
{
  "cromlech": {
    "mariadb": {
      "status": "dormant",
      "port": 8902,
      "health": "unknown",
      "last_eveil": null
    },
    "fastapi": {
      "status": "dormant", 
      "port": 8903,
      "health": "unknown",
      "last_eveil": null
    }
  },
  "fianna": {
    "adminer": {
      "status": "dormant",
      "port": 8904
    },
    "n8n": {
      "status": "dormant", 
      "port": 8905
    }
  }
}
EOF

cat > Nemeton/ogmios/dolmen/torad.json << 'EOF'
{
  "network": "dagda-lite-network",
  "last_harvest": null,
  "active_sigils": [],
  "dormant_sigils": [],
  "failed_sigils": []
}
EOF

# Fichier .env d'exemple
cat > .env.example << 'EOF'
# Dagda-Lite - Grimoire des Secrets Anciens
# Configuration du Chaudron d'Abondance

# Identification du Druide
PROJECT_NAME=dagda-lite
HOST=192.168.1.43

# Ports des Sigils Sacrés (890X)
MARIADB_PORT=8902
FASTAPI_PORT=8903
ADMINER_PORT=8904
N8N_PORT=8905
LLAMA_PORT=8906
QWEN_PORT=8907

# Secrets du Cernunnos (MariaDB)
MYSQL_ROOT_PASSWORD=racine_secrete_du_chene
MYSQL_DATABASE=sidhe_data
MYSQL_USER=druide_data
MYSQL_PASSWORD=mot_de_passe_oghamique

# Chemins des Tertres Sacrés
APP_DIR=/var/www/dagda-lite
NEMETON_DATA_DIR=/opt/dagda-lite/nemeton
OGHAM_LOGS_DIR=/var/log/dagda-lite

# Configuration du Chaudron
AUTO_SHUTDOWN_TIMEOUT=300
RESOURCE_CHECK_INTERVAL=30
MAX_SIGILS_SIMULTANES=10
EOF

# README avec explication mythologique
cat > README.md << 'EOF'
# Dagda-Lite 🍀

> Orchestrateur ultra-léger de containers Podman inspiré de la mythologie celtique

**Dagda-Lite** transforme votre serveur en chaudron magique où chaque container devient un sigil oghamique, orchestré par la sagesse druidique ancestrale.

## Architecture Mythologique

- **dagda/** - Le druide suprême et son orchestration
- **Nemeton/** - Le sanctuaire des sigils (containers)
- **coire-anseasc/** - Le chaudron d'abondance (moteur générique)

## Installation

```bash
# Cloner le grimoire
git clone <votre-repo> dagda-lite
cd dagda-lite

# Créer l'arborescence sacrée
./create_dagda_structure.sh

# Éveiller le chaudron
cp .env.example .env
./scripts/lug.sh cromlech
```

## Premiers Sigils

- **Cernunnos** (MariaDB) - Seigneur des connexions
- **Belenos** (FastAPI) - Soleil resplendissant

---
*"Que la magie opère dans le monde numérique"* ✨
EOF

log_success "Structure complète créée !"
echo
log_step "Prochaines étapes :"
log_info "1. Copiez .env.example vers .env et configurez vos secrets"
log_info "2. Migrez votre utils.sh vers coire-anseasc/awens-utils/ollamh.sh"  
log_info "3. Implémentez le teine_engine.sh pour remplacer vos scripts pod_*"
log_info "4. Testez avec : ./scripts/lug.sh cromlech"
echo
log_success "Le chaudron de Dagda est prêt à accueillir la magie ! 🍀"