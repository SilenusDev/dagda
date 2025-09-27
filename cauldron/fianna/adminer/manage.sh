#!/bin/bash
# cauldron/fianna/adminer/manage.sh
# Script de gestion du service Adminer

SCRIPT_NAME="adminer"

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

# Configuration du conteneur Adminer (NOUVELLES VARIABLES)
CONTAINER_NAME="${PROJECT_NAME}-adminer-container"
POD_NAME="${PROJECT_NAME}-adminer-pod"
IMAGE_NAME="docker.io/library/adminer:latest"
ADMINER_DATA_DIR="${FIANNA_DIR}/adminer/data"
ADMINER_CONFIG_DIR="${FIANNA_DIR}/adminer/config"

# Fonction de démarrage
start_adminer() {
    log_info "Démarrage du service Adminer"
    
    # Vérification des prérequis
    if ! command -v podman &> /dev/null; then
        log_error "Podman n'est pas installé"
        return 1
    fi
    
    # Création des répertoires nécessaires
    mkdir -p "$ADMINER_CONFIG_DIR"
    mkdir -p "$ADMINER_DATA_DIR"
    
    # Arrêt du conteneur existant s'il existe
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        log_info "Arrêt du pod existant"
        podman pod stop "$POD_NAME" 2>/dev/null
        podman pod rm "$POD_NAME" 2>/dev/null
    fi
    
    # Création du nouveau pod
    log_info "Création du nouveau pod et conteneur Adminer"
    # Créer le pod d'abord
    podman pod create --name "$POD_NAME" -p "${HOST}:${ADMIN_PORT}:8080"
    
    # Puis créer le conteneur dans le pod
    podman run -d \
        --name "$CONTAINER_NAME" \
        --pod "$POD_NAME" \
        -v "$ADMINER_CONFIG_DIR:/var/www/html/plugins-enabled:Z" \
        --restart unless-stopped \
        "$IMAGE_NAME"
    
    if [ $? -eq 0 ]; then
        log_success "Service Adminer démarré"
        log_info "Interface accessible sur http://${HOST}:${ADMIN_PORT}"
    else
        log_error "Échec du démarrage d'Adminer"
        return 1
    fi
}

# Fonction d'arrêt
stop_adminer() {
    log_info "Arrêt du service Adminer"
    
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        podman pod stop "$POD_NAME"
        if [ $? -eq 0 ]; then
            log_success "Service Adminer arrêté"
        else
            log_error "Échec de l'arrêt d'Adminer"
            return 1
        fi
    else
        log_info "Aucun pod Adminer en cours d'exécution"
    fi
}

# Fonction de statut
status_adminer() {
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        if podman pod ps --filter "name=$POD_NAME" --format "{{.Status}}" | grep -q "Running"; then
            log_success "Adminer est en cours d'exécution"
            podman pod ps --filter "name=$POD_NAME" --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
        else
            log_info "Pod Adminer existe mais n'est pas en cours d'exécution"
        fi
    else
        log_info "Aucun pod Adminer trouvé"
    fi
}

# Fonction de nettoyage
clean_adminer() {
    log_info "Nettoyage du conteneur Adminer"
    
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        log_info "Arrêt du pod en cours..."
        podman pod stop "$POD_NAME" 2>/dev/null
        podman pod rm "$POD_NAME"
        log_success "Pod Adminer supprimé"
    else
        log_info "Aucun pod Adminer à nettoyer"
    fi
}

# Fonction de redémarrage
restart_adminer() {
    log_info "Redémarrage du service Adminer"
    stop_adminer
    sleep 2
    start_adminer
}

# Fonction d'affichage des logs
logs_adminer() {
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        log_info "Affichage des logs Adminer"
        podman logs "$CONTAINER_NAME"
    else
        log_error "Aucun pod Adminer en cours d'exécution"
    fi
}

# Fonction d'aide
show_help() {
    echo "[$SCRIPT_NAME][help] Usage: $0 {start|stop|restart|status|logs|clean}"
    echo "[$SCRIPT_NAME][help] Commandes disponibles:"
    echo "[$SCRIPT_NAME][help]   start   - Démarre le service Adminer"
    echo "[$SCRIPT_NAME][help]   stop    - Arrête le service Adminer"
    echo "[$SCRIPT_NAME][help]   restart - Redémarre le service Adminer"
    echo "[$SCRIPT_NAME][help]   status  - Affiche le statut du service"
    echo "[$SCRIPT_NAME][help]   logs    - Affiche les logs du service"
    echo "[$SCRIPT_NAME][help]   clean   - Nettoie les conteneurs"
}

# Point d'entrée principal
case "$1" in
    start)
        start_adminer
        ;;
    stop)
        stop_adminer
        ;;
    restart)
        restart_adminer
        ;;
    status)
        status_adminer
        ;;
    logs)
        logs_adminer
        ;;
    clean)
        clean_adminer
        ;;
    *)
        show_help
        exit 1
        ;;
esac

exit $?
