#!/bin/bash
# dagda/eveil/stop_all.sh
# Script d'arrêt d'urgence pour tous les pods Dagda-Lite

SCRIPT_NAME="stop_all"

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

# Charger les utilitaires
source "$OLLAMH_SCRIPT" || { echo "[$SCRIPT_NAME][error] ollamh.sh non trouvé"; exit 1; }

echo "[$SCRIPT_NAME][start] Arrêt d'urgence de tous les pods Dagda-Lite"

# Vérifier si Podman est disponible
if ! command -v podman &> /dev/null; then
    echo "[$SCRIPT_NAME][error] Podman n'est pas installé ou accessible"
    exit 1
fi

# Fonction pour arrêter un pod
stop_pod() {
    local pod_name=$1
    echo "[$SCRIPT_NAME][step] Arrêt du pod: $pod_name"
    
    if podman pod exists "$pod_name" 2>/dev/null; then
        if podman pod stop "$pod_name" 2>/dev/null; then
            echo "[$SCRIPT_NAME][success] Pod $pod_name arrêté"
            
            # Supprimer le pod après arrêt
            if podman pod rm "$pod_name" 2>/dev/null; then
                echo "[$SCRIPT_NAME][success] Pod $pod_name supprimé"
            else
                echo "[$SCRIPT_NAME][warning] Impossible de supprimer le pod $pod_name"
            fi
        else
            echo "[$SCRIPT_NAME][error] Échec de l'arrêt du pod $pod_name"
        fi
    else
        echo "[$SCRIPT_NAME][info] Pod $pod_name n'existe pas ou déjà arrêté"
    fi
}

# Fonction pour arrêter un conteneur
stop_container() {
    local container_name=$1
    echo "[$SCRIPT_NAME][step] Arrêt du conteneur: $container_name"
    
    if podman container exists "$container_name" 2>/dev/null; then
        if podman stop "$container_name" 2>/dev/null; then
            echo "[$SCRIPT_NAME][success] Conteneur $container_name arrêté"
            
            # Supprimer le conteneur après arrêt
            if podman rm "$container_name" 2>/dev/null; then
                echo "[$SCRIPT_NAME][success] Conteneur $container_name supprimé"
            else
                echo "[$SCRIPT_NAME][warning] Impossible de supprimer le conteneur $container_name"
            fi
        else
            echo "[$SCRIPT_NAME][error] Échec de l'arrêt du conteneur $container_name"
        fi
    else
        echo "[$SCRIPT_NAME][info] Conteneur $container_name n'existe pas ou déjà arrêté"
    fi
}

# Liste des pods/conteneurs Dagda-Lite à arrêter
DAGDA_PODS=(
    "dagda-lite-mariadb-pod"
    "dagda-lite-fastapi-pod"
    "dagda-lite-llama-pod"
    "dagda-lite-qwen25-05b-pod"
    "dagda-lite-adminer-pod"
    "dagda-lite-n8n-pod"
    "dagda-lite-yarn-pod"
)

DAGDA_CONTAINERS=(
    "dagda-lite-mariadb"
    "dagda-lite-fastapi"
    "dagda-lite-llama"
    "dagda-lite-qwen25-05b"
    "dagda-lite-adminer"
    "dagda-lite-n8n"
    "dagda-lite-yarn"
)

# Arrêter tous les pods Dagda-Lite
echo "[$SCRIPT_NAME][info] Arrêt des pods Dagda-Lite..."
for pod in "${DAGDA_PODS[@]}"; do
    stop_pod "$pod"
done

# Arrêter tous les conteneurs Dagda-Lite (au cas où ils ne seraient pas dans des pods)
echo "[$SCRIPT_NAME][info] Arrêt des conteneurs Dagda-Lite..."
for container in "${DAGDA_CONTAINERS[@]}"; do
    stop_container "$container"
done

# Arrêter tous les conteneurs avec le préfixe dagda-lite (sécurité)
echo "[$SCRIPT_NAME][info] Recherche d'autres conteneurs Dagda-Lite..."
OTHER_CONTAINERS=$(podman ps -a --format "{{.Names}}" | grep "^dagda-lite" 2>/dev/null || true)

if [ -n "$OTHER_CONTAINERS" ]; then
    echo "[$SCRIPT_NAME][info] Conteneurs supplémentaires trouvés:"
    echo "$OTHER_CONTAINERS"
    
    while IFS= read -r container; do
        if [ -n "$container" ]; then
            stop_container "$container"
        fi
    done <<< "$OTHER_CONTAINERS"
else
    echo "[$SCRIPT_NAME][info] Aucun autre conteneur Dagda-Lite trouvé"
fi

# Nettoyer les ressources orphelines
echo "[$SCRIPT_NAME][step] Nettoyage des ressources orphelines..."
if podman system prune -f 2>/dev/null; then
    echo "[$SCRIPT_NAME][success] Nettoyage des ressources terminé"
else
    echo "[$SCRIPT_NAME][warning] Échec du nettoyage automatique"
fi

# Mettre à jour le statut des services
echo "[$SCRIPT_NAME][step] Mise à jour du statut des services..."
update_service_status "mariadb" "cromlech" "stopped"
update_service_status "fastapi" "muirdris" "stopped"
update_service_status "llama" "muirdris" "stopped"
update_service_status "qwen25-05b" "muirdris" "stopped"
update_service_status "adminer" "fianna" "stopped"
update_service_status "n8n" "fianna" "stopped"
update_service_status "yarn" "geasa" "stopped"

echo "[$SCRIPT_NAME][success] Arrêt d'urgence terminé - Tous les services Dagda-Lite sont arrêtés"
echo "[$SCRIPT_NAME][info] Pour redémarrer les services: ./dagda/eveil/lug.sh <categorie> start"
