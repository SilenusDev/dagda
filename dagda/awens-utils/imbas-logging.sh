#!/bin/bash
# dagda/awens-utils/imbas-logging.sh
# Dagda-Lite - Système de logging simplifié

# Couleurs pour l'affichage terminal (optionnelles)
if [[ -z "${GREEN:-}" ]]; then
    readonly GREEN='\033[0;32m'
    readonly BLUE='\033[0;34m'
    readonly YELLOW='\033[1;33m'
    readonly RED='\033[0;31m'
    readonly PURPLE='\033[0;35m'
    readonly CYAN='\033[0;36m'
    readonly NC='\033[0m' # No Color
fi

# Fonctions de logging conformes - FORMAT [script][evenement]
# Chaque script doit définir SCRIPT_NAME="nom_explicite" au début

log_info() { 
    echo -e "${BLUE}[${SCRIPT_NAME:-Runa...}][info]${NC} $1" 
}

log_success() { 
    echo -e "${GREEN}[${SCRIPT_NAME:-Runa...}][success]${NC} $1" 
}

log_warning() { 
    echo -e "${YELLOW}[${SCRIPT_NAME:-Runa...}][warning]${NC} $1" 
}

log_error() { 
    echo -e "${RED}[${SCRIPT_NAME:-Runa...}][error]${NC} $1" 
}

log_debug() { 
    echo -e "${PURPLE}[${SCRIPT_NAME:-Runa...}][debug]${NC} $1" 
}

log_step() { 
    echo -e "${CYAN}[${SCRIPT_NAME:-Runa...}][step]${NC} $1" 
}

# Fonction pour les erreurs fatales
fatal_error() {
    local message="$1"
    log_error "$message"
    exit 1
}

# Export des fonctions pour utilisation dans d'autres scripts
export -f log_info log_success log_warning log_error log_debug log_step fatal_error