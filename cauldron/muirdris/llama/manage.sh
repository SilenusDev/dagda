#!/bin/bash
# cauldron/muirdris/llama/manage.sh
# Script de gestion du service Llama

SCRIPT_NAME="llama"

# Chargement des variables d'environnement
if [ ! -f "${DAGDA_ROOT}/.env" ]; then
    echo "[$SCRIPT_NAME][error] Fichier .env non trouvé dans ${DAGDA_ROOT}"
    echo "[$SCRIPT_NAME][error] Assurez-vous que DAGDA_ROOT est défini et que vous avez sourcé le .env"
    exit 1
fi
source "${DAGDA_ROOT}/.env"

# Chargement des utilitaires
source "$IMBAS_LOGGING_SCRIPT" || { echo "[$SCRIPT_NAME][error] imbas-logging.sh non trouvé"; exit 1; }
source "$OLLAMH_SCRIPT" || { echo "[$SCRIPT_NAME][error] ollamh.sh non trouvé"; exit 1; }

# Configuration du conteneur Llama
CONTAINER_NAME="${PROJECT_NAME}-llama-container"
POD_NAME="${PROJECT_NAME}-llama-pod"
IMAGE_NAME="docker.io/ollama/ollama:latest"

# Fonction de démarrage
start_llama() {
    log_info "Démarrage du service Llama.cpp"
    
    # Vérification des prérequis
    if ! command -v podman &> /dev/null; then
        log_error "Podman n'est pas installé"
        return 1
    fi
    
    # Création des répertoires nécessaires
    mkdir -p "${DATA_DIR}/faeries/llama/data"
    mkdir -p "${DATA_DIR}/faeries/llama/config"
    
    # Arrêt du conteneur existant s'il existe
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        log_info "Arrêt du pod existant"
        podman pod stop "$POD_NAME" 2>/dev/null
        podman pod rm "$POD_NAME" 2>/dev/null
    fi
    
    # Création du nouveau pod
    log_info "Création du nouveau pod et conteneur Llama.cpp"
    envsubst < pod.yml | podman play kube -
    
    if [ $? -eq 0 ]; then
        log_success "Service Llama.cpp démarré"
        log_info "API accessible sur http://${HOST}:${LLAMA_PORT}"
        log_info "Placez votre modèle GGUF dans ${DATA_DIR}/faeries/llama/data/model.gguf"
    else
        log_error "Échec du démarrage de Llama.cpp"
        return 1
    fi
}

# Fonction d'arrêt
stop_llama() {
    log_info "Arrêt du service Llama"
    
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        podman pod stop "$POD_NAME"
        if [ $? -eq 0 ]; then
            log_success "Service Llama arrêté"
        else
            log_error "Échec de l'arrêt de Llama"
            return 1
        fi
    else
        log_info "Aucun pod Llama en cours d'exécution"
    fi
}

# Fonction de statut
status_llama() {
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        if podman pod ps --filter "name=$POD_NAME" --format "{{.Status}}" | grep -q "Running"; then
            log_success "Llama est en cours d'exécution"
            podman pod ps --filter "name=$POD_NAME" --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
        else
            log_info "Pod Llama existe mais n'est pas en cours d'exécution"
        fi
    else
        log_info "Aucun pod Llama trouvé"
    fi
}

# Fonction de nettoyage
clean_llama() {
    log_info "Nettoyage du conteneur Llama"
    
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        log_info "Arrêt du pod en cours..."
        podman pod stop "$POD_NAME" 2>/dev/null
        podman pod rm "$POD_NAME"
        log_success "Pod Llama supprimé"
    else
        log_info "Aucun pod Llama à nettoyer"
    fi
}

# Fonction de redémarrage
restart_llama() {
    log_info "Redémarrage du service Llama"
    stop_llama
    sleep 2
    start_llama
}

# Fonction d'affichage des logs
logs_llama() {
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        log_info "Affichage des logs Llama"
        podman logs "$CONTAINER_NAME"
    else
        log_error "Aucun pod Llama en cours d'exécution"
    fi
}

# Fonction d'aide
show_help() {
    echo "[$SCRIPT_NAME][help] Usage: $0 {start|stop|restart|status|logs|clean}"
    echo "[$SCRIPT_NAME][help] Commandes disponibles:"
    echo "[$SCRIPT_NAME][help]   start   - Démarre le service Llama"
    echo "[$SCRIPT_NAME][help]   stop    - Arrête le service Llama"
    echo "[$SCRIPT_NAME][help]   restart - Redémarre le service Llama"
    echo "[$SCRIPT_NAME][help]   status  - Affiche le statut du service"
    echo "[$SCRIPT_NAME][help]   logs    - Affiche les logs du service"
    echo "[$SCRIPT_NAME][help]   clean   - Nettoie les conteneurs"
}

# Point d'entrée principal
case "$1" in
    start)
        start_llama
        ;;
    stop)
        stop_llama
        ;;
    restart)
        restart_llama
        ;;
    status)
        status_llama
        ;;
    logs)
        logs_llama
        ;;
    clean)
        clean_llama
        ;;
    *)
        show_help
        exit 1
        ;;
esac

exit $?
