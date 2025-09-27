#!/bin/bash
# cauldron/fianna/n8n/manage.sh
# Script de gestion du service N8N

SCRIPT_NAME="n8n"

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

# Configuration du conteneur N8N (NOUVELLES VARIABLES)
CONTAINER_NAME="${PROJECT_NAME}-n8n-container"
POD_NAME="${PROJECT_NAME}-n8n-pod"
IMAGE_NAME="n8nio/n8n:latest"
N8N_DATA_DIR="${FIANNA_DIR}/n8n/data"
N8N_CONFIG_DIR="${FIANNA_DIR}/n8n/config"

# Fonction de démarrage
start_n8n() {
    log_info "Démarrage du service N8N"
    
    # Vérification des prérequis
    if ! command -v podman &> /dev/null; then
        log_error "Podman n'est pas installé"
        return 1
    fi
    
    # Création des répertoires de données
    mkdir -p "$N8N_DATA_DIR" "$N8N_CONFIG_DIR"
    
    # Vérification si le pod existe (en cours ou arrêté)
    if podman pod ls --format "{{.Name}}" | grep -q "^${POD_NAME}$"; then
        # Vérifier si le pod est en cours d'exécution
        if podman pod ls --filter "status=running" --format "{{.Name}}" | grep -q "^${POD_NAME}$"; then
            log_success "N8N est déjà en cours d'exécution"
            return 0
        else
            log_info "Pod existant détecté, démarrage..."
            podman pod start "$POD_NAME"
        fi
    else
        log_info "Création du nouveau pod et conteneur N8N"
        # Créer le pod d'abord
        podman pod create --name "$POD_NAME" -p "${HOST}:${WORKFLOW_PORT}:5678"
        
        # Puis créer le conteneur dans le pod
        podman run -d \
            --name "$CONTAINER_NAME" \
            --pod "$POD_NAME" \
            -e N8N_HOST="${HOST}" \
            -e N8N_PORT="5678" \
            -e N8N_PROTOCOL="http" \
            -v "$N8N_DATA_DIR:/home/node/.n8n:Z" \
            --restart unless-stopped \
            "$IMAGE_NAME"
    fi
    
    if [ $? -eq 0 ]; then
        log_success "Service N8N démarré"
        log_info "N8N accessible sur http://${HOST}:${WORKFLOW_PORT}"
        return 0
    else
        log_error "Échec du démarrage N8N"
        return 1
    fi
}

# Fonction d'arrêt
stop_n8n() {
    log_info "Arrêt du service N8N"
    
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        podman pod stop "$POD_NAME"
        if [ $? -eq 0 ]; then
            log_success "Service N8N arrêté"
        else
            log_error "Échec de l'arrêt de N8N"
            return 1
        fi
    else
        log_info "Aucun pod N8N en cours d'exécution"
    fi
}

# Fonction de statut
status_n8n() {
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        if podman pod ps --filter "name=$POD_NAME" --format "{{.Status}}" | grep -q "Running"; then
            log_success "N8N est en cours d'exécution"
            podman pod ps --filter "name=$POD_NAME" --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
        else
            log_info "Pod N8N existe mais n'est pas en cours d'exécution"
        fi
    else
        log_info "Aucun pod N8N trouvé"
    fi
}

# Fonction de nettoyage
clean_n8n() {
    log_info "Nettoyage du conteneur N8N"
    
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        log_info "Arrêt du pod en cours..."
        podman pod stop "$POD_NAME" 2>/dev/null
        podman pod rm "$POD_NAME"
        log_success "Pod N8N supprimé"
    else
        log_info "Aucun pod N8N à nettoyer"
    fi
}

# Fonction de redémarrage
restart_n8n() {
    log_info "Redémarrage du service N8N"
    stop_n8n
    sleep 2
    start_n8n
}

# Fonction d'affichage des logs
logs_n8n() {
    if podman pod exists "$POD_NAME" 2>/dev/null; then
        log_info "Affichage des logs N8N"
        podman logs "$CONTAINER_NAME"
    else
        log_error "Aucun pod N8N en cours d'exécution"
    fi
}

# Fonction d'aide
show_help() {
    echo "[$SCRIPT_NAME][help] Usage: $0 {start|stop|restart|status|logs|clean}"
    echo "[$SCRIPT_NAME][help] Commandes disponibles:"
    echo "[$SCRIPT_NAME][help]   start   - Démarre le service N8N"
    echo "[$SCRIPT_NAME][help]   stop    - Arrête le service N8N"
    echo "[$SCRIPT_NAME][help]   restart - Redémarre le service N8N"
    echo "[$SCRIPT_NAME][help]   status  - Affiche le statut du service"
    echo "[$SCRIPT_NAME][help]   logs    - Affiche les logs du service"
    echo "[$SCRIPT_NAME][help]   clean   - Nettoie les conteneurs"
}

# Point d'entrée principal
case "$1" in
    start)
        start_n8n
        ;;
    stop)
        stop_n8n
        ;;
    restart)
        restart_n8n
        ;;
    status)
        status_n8n
        ;;
    logs)
        logs_n8n
        ;;
    clean)
        clean_n8n
        ;;
    *)
        show_help
        exit 1
        ;;
esac

exit $?
