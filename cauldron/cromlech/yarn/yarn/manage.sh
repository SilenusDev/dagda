#!/bin/bash
# cauldron/cromlech/yarn/manage.sh
# Script de gestion du service Yarn

SCRIPT_NAME="yarn"

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

# Configuration du conteneur Yarn (NOUVELLES VARIABLES)
CONTAINER_NAME="${PROJECT_NAME}-yarn-container"
POD_NAME="${PROJECT_NAME}-yarn-pod"
IMAGE_NAME="node:18-alpine"
YARN_DATA_DIR="${GEASA_DIR}/yarn/data"
YARN_CONFIG_DIR="${GEASA_DIR}/yarn/config"

# Créer les répertoires nécessaires
create_directories() {
    echo "[$SCRIPT_NAME][step] Création des répertoires de données..."
    
    mkdir -p "$YARN_DATA_DIR" || {
        echo "[$SCRIPT_NAME][error] Impossible de créer $YARN_DATA_DIR"
        return 1
    }
    
    mkdir -p "$YARN_CONFIG_DIR" || {
        echo "[$SCRIPT_NAME][error] Impossible de créer $YARN_CONFIG_DIR"
        return 1
    }
    
    echo "[$SCRIPT_NAME][success] Répertoires créés avec succès"
}

# Vérifier les prérequis
check_prerequisites() {
    echo "[$SCRIPT_NAME][step] Vérification des prérequis..."
    
    # Vérifier que Podman est installé
    if ! command -v podman &> /dev/null; then
        echo "[$SCRIPT_NAME][error] Podman n'est pas installé"
        return 1
    fi
    
    # Vérifier les variables d'environnement
    if [ -z "$YARN_PORT" ]; then
        echo "[$SCRIPT_NAME][error] Variable YARN_PORT non définie"
        return 1
    fi
    
    if [ -z "$GEASA_DIR" ]; then
        echo "[$SCRIPT_NAME][error] Variable GEASA_DIR non définie"
        return 1
    fi
    
    echo "[$SCRIPT_NAME][success] Prérequis vérifiés"
}

# Démarrer le service
start_service() {
    echo "[$SCRIPT_NAME][start] Démarrage du service Yarn..."
    
    check_prerequisites || return 1
    create_directories || return 1
    
    # Utiliser teine_engine pour démarrer le service
    echo "[$SCRIPT_NAME][step] Démarrage via teine_engine..."
    "${TEINE_ENGINE_SCRIPT}" start "${GEASA_DIR}/yarn"
    
    if [ $? -eq 0 ]; then
        echo "[$SCRIPT_NAME][success] Service Yarn démarré avec succès"
        echo "[$SCRIPT_NAME][info] Port: $YARN_PORT"
        echo "[$SCRIPT_NAME][info] Environnement prêt pour SolidJS"
    else
        echo "[$SCRIPT_NAME][error] Échec du démarrage du service Yarn"
        return 1
    fi
}

# Arrêter le service
stop_service() {
    echo "[$SCRIPT_NAME][step] Arrêt du service Yarn..."
    
    "${TEINE_ENGINE_SCRIPT}" stop "${GEASA_DIR}/yarn"
    
    if [ $? -eq 0 ]; then
        echo "[$SCRIPT_NAME][success] Service Yarn arrêté avec succès"
    else
        echo "[$SCRIPT_NAME][error] Échec de l'arrêt du service Yarn"
        return 1
    fi
}

# Afficher le statut
show_status() {
    echo "[$SCRIPT_NAME][step] Consultation du statut du service Yarn..."
    
    "${TEINE_ENGINE_SCRIPT}" status "${GEASA_DIR}/yarn"
}

# Afficher les logs
show_logs() {
    local lines=${1:-20}
    echo "[$SCRIPT_NAME][step] Consultation des logs du service Yarn..."
    
    "${TEINE_ENGINE_SCRIPT}" logs "${GEASA_DIR}/yarn" "$lines"
}

# Nettoyer le service
clean_service() {
    echo "[$SCRIPT_NAME][step] Nettoyage complet du service Yarn..."
    
    "${TEINE_ENGINE_SCRIPT}" clean "${GEASA_DIR}/yarn"
    
    if [ $? -eq 0 ]; then
        echo "[$SCRIPT_NAME][success] Service Yarn nettoyé avec succès"
    else
        echo "[$SCRIPT_NAME][error] Échec du nettoyage du service Yarn"
        return 1
    fi
}

# Vérifier la santé du service
health_check() {
    echo "[$SCRIPT_NAME][step] Vérification de la santé du service Yarn..."
    
    "${TEINE_ENGINE_SCRIPT}" health "${GEASA_DIR}/yarn"
}

# Fonction principale
main() {
    case "$1" in
        start)
            start_service
            ;;
        stop)
            stop_service
            ;;
        restart)
            echo "[$SCRIPT_NAME][step] Redémarrage du service Yarn..."
            stop_service
            sleep 2
            start_service
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs "$2"
            ;;
        clean)
            clean_service
            ;;
        health)
            health_check
            ;;
        *)
            echo "[$SCRIPT_NAME][help] Usage: $0 {start|stop|restart|status|logs|clean|health}"
            echo "[$SCRIPT_NAME][help]"
            echo "[$SCRIPT_NAME][help] Actions disponibles:"
            echo "[$SCRIPT_NAME][help]   start    - Démarrer le service Yarn"
            echo "[$SCRIPT_NAME][help]   stop     - Arrêter le service Yarn"
            echo "[$SCRIPT_NAME][help]   restart  - Redémarrer le service Yarn"
            echo "[$SCRIPT_NAME][help]   status   - Afficher le statut du service"
            echo "[$SCRIPT_NAME][help]   logs     - Afficher les logs (défaut: 20 lignes)"
            echo "[$SCRIPT_NAME][help]   clean    - Nettoyer complètement le service"
            echo "[$SCRIPT_NAME][help]   health   - Vérifier la santé du service"
            echo "[$SCRIPT_NAME][help]"
            echo "[$SCRIPT_NAME][help] Exemples:"
            echo "[$SCRIPT_NAME][help]   $0 start"
            echo "[$SCRIPT_NAME][help]   $0 logs 50"
            echo "[$SCRIPT_NAME][help]   $0 status"
            exit 1
            ;;
    esac
}

# Exécuter la fonction principale si le script est appelé directement
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
