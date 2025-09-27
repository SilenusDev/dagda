#!/bin/bash
# cauldron/muirdris/fastapi/manage.sh
# Script de gestion du service FastAPI

SCRIPT_NAME="fastapi"

# Chargement des variables d'environnement (SÉCURISÉ)
if [ -z "$DAGDA_ROOT" ]; then
    echo "[$SCRIPT_NAME][error] Variable DAGDA_ROOT non définie" >&2
    echo "[$SCRIPT_NAME][error] Assurez-vous que DAGDA_ROOT est défini et que vous avez sourcé le .env" >&2
    exit 1
fi

if [ ! -f "${DAGDA_ROOT}/.env" ]; then
    echo "[$SCRIPT_NAME][error] Fichier .env non trouvé dans ${DAGDA_ROOT}" >&2
    exit 1
fi

source "${DAGDA_ROOT}/.env"

# Chargement des utilitaires (SÉCURISÉ)
source "${IMBAS_LOGGING_SCRIPT}" || { echo "[$SCRIPT_NAME][error] imbas-logging.sh non trouvé"; exit 1; }
source "${OLLAMH_SCRIPT}" || { echo "[$SCRIPT_NAME][error] ollamh.sh non trouvé"; exit 1; }

# Configuration du conteneur FastAPI (NOUVELLES VARIABLES)
CONTAINER_NAME="${PROJECT_NAME}-fastapi-container"
POD_NAME="${PROJECT_NAME}-fastapi-pod"
IMAGE_NAME="${CONTAINER_REGISTRY}/dagda-lite-fastapi:latest"
FASTAPI_DATA_DIR="${MUIRDRIS_DIR}/fastapi/data"
FASTAPI_CONFIG_DIR="${MUIRDRIS_DIR}/fastapi/config"

# Fonction de démarrage
start_fastapi() {
    log_info "Démarrage du service FastAPI"
    
    # Vérification des prérequis
    if ! command -v podman &> /dev/null; then
        log_error "Podman n'est pas installé"
        return 1
    fi
    
    # Création des répertoires de données
    mkdir -p "$FASTAPI_DATA_DIR" "$FASTAPI_CONFIG_DIR"
    
    # Vérification si le pod existe (en cours ou arrêté)
    if podman pod ls --format "{{.Name}}" | grep -q "^${POD_NAME}$"; then
        # Vérifier si le pod est en cours d'exécution
        if podman pod ls --filter "status=running" --format "{{.Name}}" | grep -q "^${POD_NAME}$"; then
            log_success "FastAPI est déjà en cours d'exécution"
            return 0
        else
            log_info "Pod existant détecté, démarrage..."
            podman pod start "$POD_NAME"
        fi
    else
        log_info "Création du nouveau pod et conteneur FastAPI"
        # Créer le pod d'abord
        podman pod create --name "$POD_NAME" -p "${HOST}:${API_PORT}:8000"
        
        # Puis créer le conteneur dans le pod
        podman run -d \
            --name "$CONTAINER_NAME" \
            --pod "$POD_NAME" \
            -e HOST="${HOST}" \
            -e LLAMA_PORT="${LLAMA_PORT}" \
            -e QWEN25_05_PORT="${QWEN25_05_PORT}" \
            -e FASTAPI_ENV="${FASTAPI_ENV}" \
            -e APP_HOME="${APP_HOME}" \
            -v "$FASTAPI_DATA_DIR:${APP_HOME}/data:Z" \
            -v "$FASTAPI_CONFIG_DIR:${APP_HOME}/config:Z" \
            --restart unless-stopped \
            "$IMAGE_NAME"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "Service FastAPI démarré"
        log_info "API accessible sur http://${HOST}:${API_PORT}"
        return 0
    else
        log_error "Échec du démarrage FastAPI"
        return 1
    fi
}

# Fonction d'arrêt
stop_fastapi() {
    log_info "Arrêt du service FastAPI"
    
    if podman pod ls --format "{{.Name}}" | grep -q "^${POD_NAME}$"; then
        podman pod stop "$POD_NAME"
        if [ $? -eq 0 ]; then
            log_success "Service FastAPI arrêté"
        else
            log_error "Échec de l'arrêt FastAPI"
            return 1
        fi
    else
        log_warning "Le pod FastAPI n'est pas en cours d'exécution"
    fi
}

# Fonction de statut
status_fastapi() {
    log_info "Vérification du statut FastAPI"
    
    if podman pod ls --format "{{.Name}}" | grep -q "^${POD_NAME}$"; then
        log_success "FastAPI est en cours d'exécution"
        podman pod ls --filter "name=${POD_NAME}" --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    else
        log_warning "FastAPI n'est pas en cours d'exécution"
    fi
}

# Fonction de logs
logs_fastapi() {
    log_info "Affichage des logs FastAPI"
    podman logs "$CONTAINER_NAME" --tail 50
}

# Fonction de nettoyage
clean_fastapi() {
    log_info "Nettoyage du conteneur FastAPI"
    
    # Arrêt du pod s'il est en cours d'exécution
    if podman pod ls --format "{{.Name}}" | grep -q "^${POD_NAME}$"; then
        log_info "Arrêt du pod en cours..."
        podman pod stop "$POD_NAME"
    fi
    
    # Suppression forcée du pod s'il existe
    if podman pod ls --format "{{.Name}}" | grep -q "^${POD_NAME}$"; then
        log_info "Suppression du pod existant..."
        podman pod rm -f "$POD_NAME"
        if [ $? -eq 0 ]; then
            log_success "Pod FastAPI supprimé"
        else
            log_error "Échec de la suppression du pod"
            return 1
        fi
    else
        log_warning "Aucun pod FastAPI à supprimer"
    fi
}

# Fonction d'aide
show_help() {
    echo "[$SCRIPT_NAME][help] Usage: $0 {start|stop|status|logs|clean|restart}"
    echo "[$SCRIPT_NAME][help] Commandes disponibles:"
    echo "[$SCRIPT_NAME][help]   start   - Démarre le service FastAPI"
    echo "[$SCRIPT_NAME][help]   stop    - Arrête le service FastAPI"
    echo "[$SCRIPT_NAME][help]   status  - Affiche le statut du service"
    echo "[$SCRIPT_NAME][help]   logs    - Affiche les logs du service"
    echo "[$SCRIPT_NAME][help]   clean   - Supprime le pod"
    echo "[$SCRIPT_NAME][help]   restart - Redémarre le service"
}

# Gestion des arguments
case "$1" in
    start)
        start_fastapi
        ;;
    stop)
        stop_fastapi
        ;;
    status)
        status_fastapi
        ;;
    logs)
        logs_fastapi
        ;;
    clean)
        clean_fastapi
        ;;
    restart)
        log_info "Redémarrage du service FastAPI"
        stop_fastapi
        sleep 2
        start_fastapi
        ;;
    *)
        show_help
        exit 1
        ;;
esac
