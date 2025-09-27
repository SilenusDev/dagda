#!/bin/bash
# cauldron/cromlech/mariadb/manage.sh
# Script de gestion du service MariaDB avec init automatique dagda_db

SCRIPT_NAME="mariadb"

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

# Configuration du conteneur MariaDB
CONTAINER_NAME="${PROJECT_NAME}-mariadb-container"
POD_NAME="${PROJECT_NAME}-mariadb-pod"
IMAGE_NAME="docker.io/library/mariadb:latest"
MARIADB_DATA_DIR="${CROMLECH_DIR}/mariadb/data"
MARIADB_CONFIG_DIR="${CROMLECH_DIR}/mariadb/config"
MARIADB_INIT_DIR="${CROMLECH_DIR}/mariadb"
INIT_SQL_FILE="${MARIADB_INIT_DIR}/init-dagda.sql"

# Fonction de démarrage
start_mariadb() {
    echo "[$SCRIPT_NAME][start] Démarrage du service MariaDB"
    
    # Vérification des prérequis
    if ! command -v podman &> /dev/null; then
        echo "[$SCRIPT_NAME][error] Podman n'est pas installé"
        return 1
    fi
    
    # Vérification que le script d'init existe
    if [ ! -f "$INIT_SQL_FILE" ]; then
        echo "[$SCRIPT_NAME][error] Fichier init-dagda.sql non trouvé dans ${MARIADB_INIT_DIR}"
        echo "[$SCRIPT_NAME][error] Créez le fichier init-dagda.sql pour l'initialisation automatique"
        return 1
    fi
    
    # Création des répertoires de données
    mkdir -p "$MARIADB_DATA_DIR" "$MARIADB_CONFIG_DIR"
    
    # Vérification si le pod existe (en cours ou arrêté)
    if podman pod ls --format "{{.Name}}" | grep -q "^${POD_NAME}$"; then
        # Vérifier si le pod est en cours d'exécution
        if podman pod ls --filter "status=running" --format "{{.Name}}" | grep -q "^${POD_NAME}$"; then
            echo "[$SCRIPT_NAME][success] MariaDB est déjà en cours d'exécution"
            return 0
        else
            echo "[$SCRIPT_NAME][start] Pod existant détecté, démarrage..."
            podman pod start "$POD_NAME"
        fi
    else
        echo "[$SCRIPT_NAME][start] Création du nouveau pod et conteneur MariaDB"
        # Créer le pod d'abord
        podman pod create --name "$POD_NAME" -p "${HOST}:${DB_PORT}:3306"
        
        # Puis créer le conteneur dans le pod avec script d'init
        podman run -d \
            --name "$CONTAINER_NAME" \
            --pod "$POD_NAME" \
            -e MARIADB_ROOT_PASSWORD="$DB_ROOT_PASSWORD" \
            -e MARIADB_DATABASE="$DB_NAME" \
            -e MARIADB_USER="$DB_USER" \
            -e MARIADB_PASSWORD="$DB_PASSWORD" \
            -v "$MARIADB_DATA_DIR:/var/lib/mysql:Z" \
            -v "$MARIADB_CONFIG_DIR:/etc/mysql/conf.d:Z" \
            -v "$INIT_SQL_FILE:/docker-entrypoint-initdb.d/init-dagda.sql:Z" \
            --restart unless-stopped \
            "$IMAGE_NAME"
    fi
    
    if [ $? -eq 0 ]; then
        echo "[$SCRIPT_NAME][success] Service MariaDB démarré avec init dagda_db"
        echo "[$SCRIPT_NAME][success] Base dagda_db sera créée automatiquement"
        return 0
    else
        echo "[$SCRIPT_NAME][error] Échec du démarrage MariaDB"
        return 1
    fi
}

# Fonction d'arrêt
stop_mariadb() {
    echo "[$SCRIPT_NAME][stop] Arrêt du service MariaDB"
    
    if podman pod ls --format "{{.Name}}" | grep -q "^${POD_NAME}$"; then
        podman pod stop "$POD_NAME"
        if [ $? -eq 0 ]; then
            echo "[$SCRIPT_NAME][success] Service MariaDB arrêté"
        else
            echo "[$SCRIPT_NAME][error] Échec de l'arrêt MariaDB"
            return 1
        fi
    else
        echo "[$SCRIPT_NAME][error] Le pod MariaDB n'est pas en cours d'exécution"
    fi
}

# Fonction de statut
status_mariadb() {
    echo "[$SCRIPT_NAME][status] Vérification du statut MariaDB"
    
    if podman pod ls --format "{{.Name}}" | grep -q "^${POD_NAME}$"; then
        echo "[$SCRIPT_NAME][success] MariaDB est en cours d'exécution"
        podman pod ls --filter "name=${POD_NAME}" --format "table {{.Name}}\t{{.Status}}"
        
        # Test connexion dagda_db
        echo "[$SCRIPT_NAME][status] Test connexion dagda_db..."
        podman exec "$CONTAINER_NAME" mariadb -u "$DAGDA_DB_USER" -p"$DAGDA_DB_PASSWORD" -e "USE $DAGDA_DB_NAME; SELECT 'DAGDA DB OK' as status;" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "[$SCRIPT_NAME][success] Base $DAGDA_DB_NAME accessible"
        else
            echo "[$SCRIPT_NAME][error] Base $DAGDA_DB_NAME non accessible"
        fi
    else
        echo "[$SCRIPT_NAME][error] MariaDB n'est pas en cours d'exécution"
    fi
}

# Fonction de logs
logs_mariadb() {
    echo "[$SCRIPT_NAME][logs] Affichage des logs MariaDB"
    podman logs --tail 50 "$CONTAINER_NAME"
}

# Fonction de nettoyage
clean_mariadb() {
    echo "[$SCRIPT_NAME][clean] Nettoyage du conteneur MariaDB"
    
    # Arrêt du pod s'il est en cours d'exécution
    if podman pod ls --format "{{.Name}}" | grep -q "^${POD_NAME}$"; then
        echo "[$SCRIPT_NAME][clean] Arrêt du pod en cours..."
        podman pod stop "$POD_NAME"
    fi
    
    # Suppression forcée du pod s'il existe
    if podman pod ls --format "{{.Name}}" | grep -q "^${POD_NAME}$"; then
        echo "[$SCRIPT_NAME][clean] Suppression du pod existant..."
        podman pod rm -f "$POD_NAME"
        if [ $? -eq 0 ]; then
            echo "[$SCRIPT_NAME][success] Pod MariaDB supprimé"
        else
            echo "[$SCRIPT_NAME][error] Échec de la suppression du pod"
            return 1
        fi
    else
        echo "[$SCRIPT_NAME][clean] Aucun pod MariaDB à supprimer"
    fi
}

# Fonction d'aide
show_help() {
    echo "[$SCRIPT_NAME][help] Usage: $0 {start|stop|status|logs|clean|restart}"
    echo "[$SCRIPT_NAME][help] Commandes disponibles:"
    echo "[$SCRIPT_NAME][help]   start   - Démarre MariaDB avec init dagda_db automatique"
    echo "[$SCRIPT_NAME][help]   stop    - Arrête le service MariaDB"
    echo "[$SCRIPT_NAME][help]   status  - Affiche le statut + test connexion dagda_db"
    echo "[$SCRIPT_NAME][help]   logs    - Affiche les logs du service"
    echo "[$SCRIPT_NAME][help]   clean   - Supprime le pod (données conservées)"
    echo "[$SCRIPT_NAME][help]   restart - Redémarre le service"
}

# Gestion des arguments
case "$1" in
    start)
        start_mariadb
        ;;
    stop)
        stop_mariadb
        ;;
    status)
        status_mariadb
        ;;
    logs)
        logs_mariadb
        ;;
    clean)
        clean_mariadb
        ;;
    restart)
        echo "[$SCRIPT_NAME][restart] Redémarrage du service MariaDB"
        stop_mariadb
        sleep 2
        start_mariadb
        ;;
    *)
        show_help
        exit 1
        ;;
esac