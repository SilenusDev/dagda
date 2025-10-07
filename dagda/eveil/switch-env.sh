#!/bin/bash
# switch-env.sh
# Script de basculement entre environnements dev et prod pour Dagda-Lite

SCRIPT_NAME="switch-env"

# Détection automatique de DAGDA_ROOT (SÉCURISÉ)
if [ -z "$DAGDA_ROOT" ]; then
    # Détecter DAGDA_ROOT depuis l'emplacement du script
    SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
    DETECTED_DAGDA_ROOT="$(dirname "$(dirname "$(dirname "$SCRIPT_PATH")")")"
    
    # Vérifier que les fichiers .env existent à cet emplacement
    if [ -f "${DETECTED_DAGDA_ROOT}/.env" ] || [ -f "${DETECTED_DAGDA_ROOT}/.env.dev" ]; then
        export DAGDA_ROOT="$DETECTED_DAGDA_ROOT"
    else
        echo "[${SCRIPT_NAME}][error] Impossible de détecter DAGDA_ROOT" >&2
        echo "[${SCRIPT_NAME}][error] Fichiers .env non trouvés dans ${DETECTED_DAGDA_ROOT}" >&2
        exit 1
    fi
fi

ENV_FILE="${DAGDA_ROOT}/.env"
ENV_DEV="${DAGDA_ROOT}/.env.dev"
ENV_PROD="${DAGDA_ROOT}/.env.prod"
ENV_BACKUP="${DAGDA_ROOT}/.env.backup.$(date +%Y%m%d_%H%M%S)"

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage avec log
log_info() {
    echo -e "${BLUE}[${SCRIPT_NAME}][info]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[${SCRIPT_NAME}][success]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[${SCRIPT_NAME}][warning]${NC} $1"
}

log_error() {
    echo -e "${RED}[${SCRIPT_NAME}][error]${NC} $1" >&2
}

# Fonction pour détecter l'environnement actuel
detect_current_env() {
    if [ ! -f "$ENV_FILE" ]; then
        echo "none"
        return
    fi
    
    if grep -q "DAGDA_ENV=development" "$ENV_FILE" 2>/dev/null; then
        echo "dev"
    elif grep -q "DAGDA_ENV=production" "$ENV_FILE" 2>/dev/null; then
        echo "prod"
    else
        echo "unknown"
    fi
}

# Fonction pour afficher l'environnement actuel
show_current_env() {
    local current_env=$(detect_current_env)
    
    echo ""
    log_info "=========================================="
    log_info "🔍 ENVIRONNEMENT ACTUEL"
    log_info "=========================================="
    
    case "$current_env" in
        dev)
            log_success "📍 Environnement: DEVELOPMENT (localhost)"
            if [ -f "$ENV_FILE" ]; then
                local host=$(grep "^HOST=" "$ENV_FILE" | cut -d'=' -f2)
                log_info "🌐 Host: $host"
            fi
            ;;
        prod)
            log_success "📍 Environnement: PRODUCTION (serveur IP)"
            if [ -f "$ENV_FILE" ]; then
                local host=$(grep "^HOST=" "$ENV_FILE" | cut -d'=' -f2)
                log_info "🌐 Host: $host"
            fi
            ;;
        none)
            log_warning "⚠️  Aucun fichier .env trouvé"
            ;;
        unknown)
            log_warning "⚠️  Environnement non identifié"
            ;;
    esac
    
    log_info "=========================================="
    echo ""
}

# Fonction pour basculer vers un environnement
switch_to_env() {
    local target_env=$1
    local source_file=""
    local env_name=""
    
    case "$target_env" in
        dev|development)
            source_file="$ENV_DEV"
            env_name="DEVELOPMENT"
            ;;
        prod|production)
            source_file="$ENV_PROD"
            env_name="PRODUCTION"
            ;;
        *)
            log_error "Environnement invalide: $target_env"
            log_info "Utilisez: dev, development, prod, ou production"
            exit 1
            ;;
    esac
    
    # Vérifier que le fichier source existe
    if [ ! -f "$source_file" ]; then
        log_error "Fichier de configuration non trouvé: $source_file"
        exit 1
    fi
    
    log_info "=========================================="
    log_info "🔄 BASCULEMENT VERS $env_name"
    log_info "=========================================="
    
    # Sauvegarder le .env actuel si il existe
    if [ -f "$ENV_FILE" ]; then
        log_info "💾 Sauvegarde de la configuration actuelle..."
        cp "$ENV_FILE" "$ENV_BACKUP"
        log_success "Sauvegarde créée: $ENV_BACKUP"
    fi
    
    # Copier le fichier d'environnement cible
    log_info "📋 Application de la configuration $env_name..."
    cp "$source_file" "$ENV_FILE"
    
    if [ $? -eq 0 ]; then
        log_success "✅ Configuration $env_name appliquée avec succès"
        
        # Afficher les informations de l'environnement
        local host=$(grep "^HOST=" "$ENV_FILE" | cut -d'=' -f2)
        local api_port=$(grep "^API_PORT=" "$ENV_FILE" | cut -d'=' -f2)
        local vite_port=$(grep "^VITE_PORT=" "$ENV_FILE" | cut -d'=' -f2)
        local db_port=$(grep "^DB_PORT=" "$ENV_FILE" | cut -d'=' -f2)
        
        log_info "=========================================="
        log_info "📊 CONFIGURATION APPLIQUÉE"
        log_info "=========================================="
        log_info "🌐 Host: $host"
        log_info "🔧 API Port: $api_port"
        log_info "🎨 Vite Port: $vite_port"
        log_info "🗄️  DB Port: $db_port"
        log_info "=========================================="
        
        log_warning "⚠️  IMPORTANT: Redémarrez les services pour appliquer les changements"
        log_info "Commande: ${DAGDA_ROOT}/dagda/eveil/taranis.sh stop all && ${DAGDA_ROOT}/dagda/eveil/taranis.sh dagda"
        
    else
        log_error "❌ Échec de l'application de la configuration"
        
        # Restaurer la sauvegarde si elle existe
        if [ -f "$ENV_BACKUP" ]; then
            log_info "🔄 Restauration de la configuration précédente..."
            cp "$ENV_BACKUP" "$ENV_FILE"
            log_success "Configuration restaurée"
        fi
        
        exit 1
    fi
}

# Fonction pour créer les fichiers .env.dev et .env.prod si manquants
init_env_files() {
    log_info "=========================================="
    log_info "🔧 INITIALISATION DES FICHIERS D'ENVIRONNEMENT"
    log_info "=========================================="
    
    local files_created=0
    
    if [ ! -f "$ENV_DEV" ]; then
        log_warning ".env.dev manquant"
        if [ -f "${DAGDA_ROOT}/.env.example" ]; then
            log_info "Création de .env.dev depuis .env.example..."
            cp "${DAGDA_ROOT}/.env.example" "$ENV_DEV"
            # Modifier pour localhost
            sed -i 's/HOST=192\.168\.1\.43/HOST=localhost/g' "$ENV_DEV"
            sed -i 's/CONTAINER_REGISTRY=192\.168\.1\.43:8908/CONTAINER_REGISTRY=localhost:8908/g' "$ENV_DEV"
            sed -i 's/FASTAPI_ENV=production/FASTAPI_ENV=development/g' "$ENV_DEV"
            echo "DAGDA_ENV=development" >> "$ENV_DEV"
            log_success ".env.dev créé"
            files_created=$((files_created + 1))
        else
            log_error ".env.example non trouvé, impossible de créer .env.dev"
        fi
    fi
    
    if [ ! -f "$ENV_PROD" ]; then
        log_warning ".env.prod manquant"
        if [ -f "${DAGDA_ROOT}/.env.example" ]; then
            log_info "Création de .env.prod depuis .env.example..."
            cp "${DAGDA_ROOT}/.env.example" "$ENV_PROD"
            echo "DAGDA_ENV=production" >> "$ENV_PROD"
            log_success ".env.prod créé"
            files_created=$((files_created + 1))
        else
            log_error ".env.example non trouvé, impossible de créer .env.prod"
        fi
    fi
    
    if [ $files_created -eq 0 ]; then
        log_success "✅ Tous les fichiers d'environnement sont présents"
    else
        log_success "✅ $files_created fichier(s) d'environnement créé(s)"
    fi
    
    log_info "=========================================="
}

# Fonction d'aide
show_help() {
    echo ""
    echo "Usage: $0 [COMMANDE]"
    echo ""
    echo "Commandes disponibles:"
    echo "  dev, development    Basculer vers l'environnement de développement (localhost)"
    echo "  prod, production    Basculer vers l'environnement de production (IP serveur)"
    echo "  status, current     Afficher l'environnement actuel"
    echo "  init                Initialiser les fichiers .env.dev et .env.prod"
    echo "  help                Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0 dev              # Basculer en mode développement"
    echo "  $0 prod             # Basculer en mode production"
    echo "  $0 status           # Voir l'environnement actuel"
    echo ""
}

# Programme principal
main() {
    case "$1" in
        dev|development)
            switch_to_env "dev"
            ;;
        prod|production)
            switch_to_env "prod"
            ;;
        status|current|"")
            show_current_env
            ;;
        init)
            init_env_files
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Commande inconnue: $1"
            show_help
            exit 1
            ;;
    esac
}

# Exécution
main "$@"
