#!/bin/bash
# cauldron/muirdris/qwen25-05b/manage.sh
# Script de gestion du service Qwen2.5-0.5B

SCRIPT_NAME="qwen25-05b"

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

# Configuration du conteneur Qwen2.5-0.5B
CONTAINER_NAME="${PROJECT_NAME}-qwen25-05b-container"
POD_NAME="${PROJECT_NAME}-qwen25-05b-pod"
IMAGE_NAME="ghcr.io/ggml-org/llama.cpp:server"

# Fonction de démarrage
start_qwen() {
    log_info "Démarrage du service Qwen2.5-0.5B"
    
    # Vérification des prérequis
    if ! command -v podman &> /dev/null; then
        log_error "Podman n'est pas installé"
        return 1
    fi
    
    # Création des répertoires nécessaires
    mkdir -p "${DATA_DIR}/faeries/qwen25-05b/data"
    mkdir -p "${DATA_DIR}/faeries/qwen25-05b/config"
    
    # Arrêt du conteneur existant s'il existe
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        log_info "Arrêt du pod existant"
        podman pod stop "$POD_NAME" 2>/dev/null
        podman pod rm "$POD_NAME" 2>/dev/null
    fi
    
    # Création du nouveau pod
    log_info "Création du nouveau pod et conteneur Qwen2.5-0.5B"
    envsubst < pod.yml | podman play kube -
    
    if [ $? -eq 0 ]; then
        log_success "Service Qwen2.5-0.5B démarré"
        log_info "API accessible sur http://${HOST}:${QWEN25_05_PORT}"
        log_info "Placez votre modèle GGUF Qwen2.5-0.5B dans ${DATA_DIR}/faeries/qwen25-05b/data/model.gguf"
        log_info "Téléchargez avec: huggingface-cli download Qwen/Qwen2-0.5B-Instruct-GGUF qwen2-0_5b-instruct-q5_k_m.gguf"
    else
        log_error "Échec du démarrage de Qwen2.5-0.5B"
        return 1
    fi
}

# Fonction d'arrêt
stop_qwen() {
    log_info "Arrêt du service Qwen2.5-0.5B"
    
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        podman pod stop "$POD_NAME"
        if [ $? -eq 0 ]; then
            log_success "Service Qwen2.5-0.5B arrêté"
        else
            log_error "Erreur lors de l'arrêt"
            return 1
        fi
    else
        log_warning "Service Qwen2.5-0.5B déjà arrêté"
    fi
}

# Fonction de redémarrage
restart_qwen() {
    log_info "Redémarrage du service Qwen2.5-0.5B"
    stop_qwen
    sleep 2
    start_qwen
}

# Fonction de statut
status_qwen() {
    log_info "Statut du service Qwen2.5-0.5B"
    
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        local status=$(podman pod ps --filter name="$POD_NAME" --format "{{.Status}}")
        log_info "État du pod: $status"
        
        if [[ "$status" == *"Running"* ]]; then
            log_success "Service Qwen2.5-0.5B en cours d'exécution"
            log_info "API accessible sur http://${HOST}:${QWEN25_05_PORT}"
        else
            log_warning "Service Qwen2.5-0.5B arrêté"
        fi
    else
        log_warning "Pod Qwen2.5-0.5B non trouvé"
    fi
}

# Fonction de logs
logs_qwen() {
    log_info "Logs du service Qwen2.5-0.5B"
    
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        podman logs "$CONTAINER_NAME"
    else
        log_error "Pod Qwen2.5-0.5B non trouvé"
        return 1
    fi
}

# Fonction de nettoyage
clean_qwen() {
    log_info "Nettoyage du service Qwen2.5-0.5B"
    
    # Arrêt et suppression du pod
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        podman pod stop "$POD_NAME" 2>/dev/null
        podman pod rm "$POD_NAME" 2>/dev/null
    fi
    
    # Suppression de l'image si demandé
    read -p "Supprimer aussi l'image Docker ? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        podman rmi "$IMAGE_NAME" 2>/dev/null
        log_info "Image supprimée"
    fi
    
    log_success "Nettoyage terminé"
}

# Fonction d'aide
show_help() {
    echo "Usage: $0 {start|stop|restart|status|logs|clean}"
    echo "  start   - Démarre le service Qwen2.5-0.5B"
    echo "  stop    - Arrête le service Qwen2.5-0.5B"
    echo "  restart - Redémarre le service Qwen2.5-0.5B"
    echo "  status  - Affiche le statut du service"
    echo "  logs    - Affiche les logs du service"
    echo "  clean   - Nettoie le service et ses ressources"
}

# Point d'entrée principal
case "${1:-}" in
    start)
        start_qwen
        ;;
    stop)
        stop_qwen
        ;;
    restart)
        restart_qwen
        ;;
    status)
        status_qwen
        ;;
    logs)
        logs_qwen
        ;;
    clean)
        clean_qwen
        ;;
    *)
        show_help
        exit 1
        ;;
esac

exit $?