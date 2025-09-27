#!/bin/bash
# dagda/awens-utils/ollamh.sh
# Dagda-Lite - Utilitaires communs pour la gestion des services
# GESTION CENTRALISÉE DES CHEMINS - VERSION PROPRE

SCRIPT_NAME="ollamh"

# =============================================================================
# DÉTECTION AUTOMATIQUE DU RÉPERTOIRE RACINE DAGDA-LITE
# =============================================================================

find_project_root() {
    local start_dir="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
    local current_dir="$(cd "$start_dir" && pwd)"
    local max_depth=10
    local depth=0
    
    while [ $depth -lt $max_depth ]; do
        # Chercher les marqueurs uniques du projet dagda-lite (nouvelle architecture)
        if [ -f "$current_dir/.env" ] && \
           [ -f "$current_dir/README.md" ] && \
           [ -d "$current_dir/cauldron" ] && \
           [ -d "$current_dir/dagda" ]; then
            echo "$current_dir"
            return 0
        fi
        
        # Remonter d'un niveau
        local parent_dir="$(dirname "$current_dir")"
        if [ "$parent_dir" = "$current_dir" ]; then
            break
        fi
        current_dir="$parent_dir"
        depth=$((depth + 1))
    done
    
    return 1
}

# =============================================================================
# INITIALISATION DES CHEMINS GLOBAUX
# =============================================================================

# Détection automatique du répertoire racine si DAGDA_ROOT n'est pas défini
if [ -z "$DAGDA_ROOT" ]; then
    PROJECT_DIR=$(find_project_root)
    if [ $? -eq 0 ]; then
        export DAGDA_ROOT="$PROJECT_DIR"
        echo "[$SCRIPT_NAME][info] DAGDA_ROOT détecté automatiquement: $DAGDA_ROOT"
    else
        echo "[$SCRIPT_NAME][error] Impossible de détecter le répertoire racine dagda-lite" >&2
        echo "[$SCRIPT_NAME][error] Définissez DAGDA_ROOT manuellement" >&2
        return 1 2>/dev/null || exit 1
    fi
else
    PROJECT_DIR="$DAGDA_ROOT"
fi

# Vérifier que le répertoire racine existe
if [ ! -d "$PROJECT_DIR" ]; then
    echo "[$SCRIPT_NAME][error] Répertoire racine non trouvé: $PROJECT_DIR" >&2
    return 1 2>/dev/null || exit 1
fi

# =============================================================================
# DÉFINITION DES CHEMINS PRINCIPAUX (NOUVELLE ARCHITECTURE)
# =============================================================================

if [ -n "$PROJECT_DIR" ]; then
    # Chemins principaux
    CAULDRON_DIR="$PROJECT_DIR/cauldron"
    DAGDA_DIR="$PROJECT_DIR/dagda"
    SIDHE_DIR="$PROJECT_DIR/sidhe"
    
    # Chemins moteur
    EVEIL_DIR="$DAGDA_DIR/eveil"
    AWENS_UTILS_DIR="$DAGDA_DIR/awens-utils"
    AWEN_CORE_DIR="$DAGDA_DIR/awen-core"
    
    # Chemins services
    CROMLECH_DIR="$CAULDRON_DIR/cromlech"
    MUIRDRIS_DIR="$CAULDRON_DIR/muirdris"
    FIANNA_DIR="$CAULDRON_DIR/fianna"
    GEASA_DIR="$CAULDRON_DIR/geasa"
    
    # Export des variables pour les sous-scripts
    export PROJECT_DIR CAULDRON_DIR DAGDA_DIR SIDHE_DIR
    export EVEIL_DIR AWENS_UTILS_DIR AWEN_CORE_DIR
    export CROMLECH_DIR MUIRDRIS_DIR FIANNA_DIR GEASA_DIR
fi

# Charger le système de logging
if [ -f "$AWENS_UTILS_DIR/imbas-logging.sh" ]; then
    source "$AWENS_UTILS_DIR/imbas-logging.sh"
else
    echo "[$SCRIPT_NAME][error] imbas-logging.sh non trouvé dans $AWENS_UTILS_DIR" >&2
    return 1 2>/dev/null || exit 1
fi

# =============================================================================
# GESTION ENVIRONNEMENT
# =============================================================================

load_env() {
    local env_file="$PROJECT_DIR/.env"
    
    if [ -f "$env_file" ]; then
        set -a
        source "$env_file"
        set +a
        echo "[$SCRIPT_NAME][debug] Variables d'environnement chargées depuis $env_file"
        return 0
    else
        echo "[$SCRIPT_NAME][error] Fichier .env non trouvé: $env_file"
        return 1
    fi
}

validate_env_vars() {
    local required_vars=(
        "PROJECT_NAME"
        "HOST"
        "DB_PORT"
        "API_PORT"
        "ADMIN_PORT"
        "WORKFLOW_PORT"
        "LLAMA_PORT"
        "QWEN_PORT"
        "YARN_PORT"
        "DB_NAME"
        "DB_USER"
        "DB_PASSWORD"
    )
    
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo "[$SCRIPT_NAME][error] Variables d'environnement manquantes:"
        for var in "${missing_vars[@]}"; do
            echo "[$SCRIPT_NAME][error]   - $var"
        done
        echo "[$SCRIPT_NAME][error] Vérifiez votre fichier .env"
        return 1
    fi
    
    echo "[$SCRIPT_NAME][debug] Toutes les variables d'environnement requises sont présentes"
    return 0
}

# =============================================================================
# FONCTIONS VÉRIFICATION RÉSEAU
# =============================================================================

check_port() {
    local port=$1
    local host=${2:-${DEFAULT_HOST:-${HOST}}}
    local timeout=${3:-5}
    
    echo "[$SCRIPT_NAME][debug] Vérification du port $port sur $host (timeout: ${timeout}s)"
    
    if timeout "$timeout" bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

check_http_health() {
    local url=$1
    local timeout=${2:-10}
    local expected_status=${3:-200}
    
    echo "[$SCRIPT_NAME][debug] Vérification HTTP: $url (timeout: ${timeout}s)"
    
    if ! command -v curl &> /dev/null; then
        echo "[$SCRIPT_NAME][warning] curl non installé, impossible de vérifier HTTP"
        return 1
    fi
    
    local status_code
    status_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$timeout" "$url" 2>/dev/null || echo "000")
    
    if [ "$status_code" = "$expected_status" ]; then
        return 0
    else
        echo "[$SCRIPT_NAME][debug] Status code reçu: $status_code (attendu: $expected_status)"
        return 1
    fi
}

# =============================================================================
# FONCTIONS PODMAN
# =============================================================================

check_podman() {
    if ! command -v podman &> /dev/null; then
        return 1
    fi
    
    if podman --version &> /dev/null; then
        return 0
    else
        return 1
    fi
}

check_pod_exists() {
    local pod_name=$1
    podman pod exists "$pod_name" 2>/dev/null
}

check_container_exists() {
    local container_name=$1
    podman container exists "$container_name" 2>/dev/null
}

check_container_running() {
    local container_name=$1
    [ "$(podman ps -q -f name="$container_name")" != "" ]
}

stop_container() {
    local container_name=$1
    local timeout=${2:-10}
    
    if check_container_exists "$container_name"; then
        if check_container_running "$container_name"; then
            echo "[$SCRIPT_NAME][info] Arrêt du conteneur $container_name..."
            podman stop --time "$timeout" "$container_name" || true
        fi
        echo "[$SCRIPT_NAME][info] Suppression du conteneur $container_name..."
        podman rm "$container_name" || true
    fi
}

stop_pod() {
    local pod_name=$1
    local timeout=${2:-10}
    
    if check_pod_exists "$pod_name"; then
        echo "[$SCRIPT_NAME][info] Arrêt du pod $pod_name..."
        podman pod stop --time "$timeout" "$pod_name" || true
        echo "[$SCRIPT_NAME][info] Suppression du pod $pod_name..."
        podman pod rm "$pod_name" || true
    fi
}

# =============================================================================
# FONCTIONS ATTENTE
# =============================================================================

wait_for_service() {
    local service_name=$1
    local port=$2
    local host=${3:-${DEFAULT_HOST:-${HOST}}}
    local max_attempts=${4:-30}
    local sleep_interval=${5:-2}
    
    echo "[$SCRIPT_NAME][info] Attente de $service_name sur $host:$port..."
    
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        if check_port "$port" "$host" 2; then
            echo "[$SCRIPT_NAME][success] $service_name est disponible !"
            return 0
        fi
        
        echo "[$SCRIPT_NAME][debug] Tentative $attempt/$max_attempts - $service_name non disponible, attente ${sleep_interval}s..."
        sleep "$sleep_interval"
        ((attempt++))
    done
    
    echo "[$SCRIPT_NAME][error] $service_name n'est pas disponible après $((max_attempts * sleep_interval))s"
    return 1
}

wait_for_http_service() {
    local service_name=$1
    local url=$2
    local max_attempts=${3:-30}
    local sleep_interval=${4:-2}
    local expected_status=${5:-200}
    
    echo "[$SCRIPT_NAME][info] Attente de $service_name sur $url..."
    
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        if check_http_health "$url" 5 "$expected_status"; then
            echo "[$SCRIPT_NAME][success] $service_name est disponible !"
            return 0
        fi
        
        echo "[$SCRIPT_NAME][debug] Tentative $attempt/$max_attempts - $service_name non disponible, attente ${sleep_interval}s..."
        sleep "$sleep_interval"
        ((attempt++))
    done
    
    echo "[$SCRIPT_NAME][error] $service_name n'est pas disponible après $((max_attempts * sleep_interval))s"
    return 1
}

kill_processes_on_port() {
    local port=$1
    local service_name=${2:-"Service"}
    
    if ! command -v lsof &> /dev/null; then
        echo "[$SCRIPT_NAME][warning] lsof non installé, impossible de nettoyer le port $port"
        return 1
    fi
    
    local pids
    pids=$(lsof -ti:$port 2>/dev/null || true)
    
    if [ -n "$pids" ]; then
        echo "[$SCRIPT_NAME][warning] Processus trouvés sur le port $port pour $service_name"
        echo "$pids" | xargs -r kill -9 2>/dev/null || true
        echo "[$SCRIPT_NAME][info] Processus nettoyés sur le port $port"
    fi
}

# =============================================================================
# FONCTIONS DAGDA-LITE
# =============================================================================

check_prerequisites() {
    local service_name=${1:-"Service"}
    
    echo "[$SCRIPT_NAME][step] Vérification des prérequis pour $service_name..."
    
    if ! load_env; then
        echo "[$SCRIPT_NAME][error] Impossible de charger les variables d'environnement"
        return 1
    fi
    
    if ! validate_env_vars; then
        echo "[$SCRIPT_NAME][error] Variables d'environnement invalides"
        return 1
    fi
    
    if ! check_podman; then
        echo "[$SCRIPT_NAME][error] Podman requis pour $service_name"
        return 1
    fi
    
    echo "[$SCRIPT_NAME][success] Prérequis OK pour $service_name"
    return 0
}

get_pod_name() {
    local service=$1
    echo "${PROJECT_NAME:-dagda-lite}-${service}-pod"
}

get_container_name() {
    local service=$1
    echo "${PROJECT_NAME:-dagda-lite}-${service}"
}

get_image_name() {
    local service=$1
    case $service in
        "mariadb")
            echo "docker.io/library/mariadb:10.11"
            ;;
        "fastapi")
            echo "tiangolo/fastapi:python3.11"
            ;;
        "adminer")
            echo "docker.io/library/adminer:latest"
            ;;
        "n8n")
            echo "n8nio/n8n:latest"
            ;;
        "llama")
            echo "ollama/ollama:latest"
            ;;
        "qwen")
            echo "ollama/qwen:latest"
            ;;
        *)
            echo "${PROJECT_NAME:-dagda-lite}/${service}:latest"
            ;;
    esac
}

get_service_status() {
    local service=$1
    local category=${2:-"cromlech"}
    local status_file="$DOLMEN_DIR/service_status.json"
    
    if ! command -v jq &> /dev/null; then
        echo "[$SCRIPT_NAME][warning] jq non installé, impossible de lire le statut"
        echo "unknown"
        return 1
    fi
    
    if [ -f "$status_file" ]; then
        jq -r ".${category}.${service}.status // \"unknown\"" "$status_file" 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

update_service_status() {
    local service=$1
    local category=$2
    local status=$3
    local port=${4:-""}
    local status_file="$DOLMEN_DIR/service_status.json"
    
    if ! command -v jq &> /dev/null; then
        echo "[$SCRIPT_NAME][warning] jq non installé, impossible de mettre à jour le statut"
        return 1
    fi
    
    mkdir -p "$DOLMEN_DIR"
    
    if [ ! -f "$status_file" ]; then
        echo '{"cromlech": {}, "muirdris": {}, "fianna": {}, "geasa": {}}' > "$status_file"
    fi
    
    local timestamp=$(date -Iseconds)
    local temp_file=$(mktemp) || return 1
    
    if [ -n "$port" ]; then
        if jq ".${category}.${service} = {\"status\": \"$status\", \"port\": $port, \"health\": \"unknown\", \"last_start\": \"$timestamp\"}" "$status_file" > "$temp_file"; then
            mv "$temp_file" "$status_file"
        else
            rm -f "$temp_file"
            return 1
        fi
    else
        if jq ".${category}.${service}.status = \"$status\" | .${category}.${service}.last_start = \"$timestamp\"" "$status_file" > "$temp_file"; then
            mv "$temp_file" "$status_file"
        else
            rm -f "$temp_file"
            return 1
        fi
    fi
}

ensure_directories() {
    local service=$1
    local service_dir="$CROMLECH_DIR/$service"
    
    mkdir -p "$service_dir/data"
    mkdir -p "$service_dir/config"
    mkdir -p "$OGMIOS_CONFIG_DIR"
    mkdir -p "$OGMIOS_DATA_DIR"
    mkdir -p "$OGMIOS_LOGS_DIR"
    mkdir -p "$DOLMEN_DIR"
}

show_service_info() {
    local service_name=$1
    local port=$2
    local container_name=$3
    
    echo
    echo "[$SCRIPT_NAME][step] Informations pour $service_name:"
    echo "[$SCRIPT_NAME][info]   • URL: http://${DEFAULT_HOST:-${HOST}}:${port}"
    echo "[$SCRIPT_NAME][info]   • Logs: podman logs $container_name"
    echo "[$SCRIPT_NAME][info]   • Shell: podman exec -it $container_name sh"
    echo "[$SCRIPT_NAME][info]   • Statut: $(get_service_status "$service_name")"
    echo
}

ensure_network() {
    local network_name="${PROJECT_NAME:-dagda-lite}-network"
    
    if ! podman network exists "$network_name" 2>/dev/null; then
        echo "[$SCRIPT_NAME][info] Création du réseau $network_name..."
        if podman network create "$network_name"; then
            echo "[$SCRIPT_NAME][success] Réseau $network_name créé"
        else
            echo "[$SCRIPT_NAME][error] Impossible de créer le réseau $network_name"
            return 1
        fi
    fi
    
    echo "$network_name"
}