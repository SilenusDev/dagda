#!/bin/bash
# dagda/eveil/launch-sidhe.sh
# Script de lancement de l'interface SolidJS
# Logique d'installation et mise en route

SCRIPT_NAME="launch-sidhe"

# Chargement des variables d'environnement (SÉCURISÉ)
if [ -z "$DAGDA_ROOT" ]; then
    echo "[$SCRIPT_NAME][error] Variable DAGDA_ROOT non définie" >&2
    exit 1
fi

if [ ! -f "${DAGDA_ROOT}/.env" ]; then
    echo "[$SCRIPT_NAME][error] Fichier .env non trouvé dans ${DAGDA_ROOT}" >&2
    exit 1
fi

source "${DAGDA_ROOT}/.env"

# Charger les utilitaires
source "${IMBAS_LOGGING_SCRIPT}" || { echo "[$SCRIPT_NAME][error] imbas-logging.sh non trouvé"; exit 1; }
source "${OLLAMH_SCRIPT}" || { echo "[$SCRIPT_NAME][error] ollamh.sh non trouvé"; exit 1; }

# Configuration
SIDHE_SOURCE="${DAGDA_ROOT}/sidhe"
CONTAINER_NAME="dagda-lite-yarn-pod-dagda-lite-yarn"

# Vérifier que les pods essentiels sont actifs
check_prerequisites() {
    echo "[$SCRIPT_NAME][step] Vérification des prérequis..."
    
    # Vérifier que le pod Yarn est actif
    if ! podman pod exists "dagda-lite-yarn-pod"; then
        echo "[$SCRIPT_NAME][error] Pod Yarn non trouvé - démarrez d'abord les services essentiels"
        return 1
    fi
    
    # Vérifier que le répertoire source existe
    if [ ! -d "$SIDHE_SOURCE" ]; then
        echo "[$SCRIPT_NAME][error] Répertoire sidhe non trouvé: $SIDHE_SOURCE"
        return 1
    fi
    
    echo "[$SCRIPT_NAME][success] Prérequis vérifiés"
}

# Copier les fichiers SolidJS dans le conteneur
deploy_files() {
    echo "[$SCRIPT_NAME][step] Déploiement des fichiers SolidJS..."
    
    # Copier tous les fichiers SolidJS dans le conteneur
    podman cp "$SIDHE_SOURCE/." "$CONTAINER_NAME:/tmp/sidhe/" || {
        echo "[$SCRIPT_NAME][error] Échec de la copie des fichiers"
        return 1
    }
    
    echo "[$SCRIPT_NAME][success] Fichiers déployés avec succès"
    echo "[$SCRIPT_NAME][info] Source: $SIDHE_SOURCE"
    echo "[$SCRIPT_NAME][info] Destination: conteneur $CONTAINER_NAME"
}

# Installer les dépendances et démarrer
install_and_start() {
    echo "[$SCRIPT_NAME][step] Installation des dépendances..."
    
    podman exec "$CONTAINER_NAME" sh -c "cd /tmp/sidhe && yarn install" || {
        echo "[$SCRIPT_NAME][error] Échec de l'installation des dépendances"
        return 1
    }
    
    echo "[$SCRIPT_NAME][success] Dépendances installées avec succès"
    
    echo "[$SCRIPT_NAME][step] Démarrage du serveur SolidJS..."
    echo "[$SCRIPT_NAME][info] Interface accessible sur http://${HOST}:${VITE_PORT}/"
    echo "[$SCRIPT_NAME][info] Appuyez sur Ctrl+C pour arrêter"
    
    podman exec -it "$CONTAINER_NAME" sh -c "cd /tmp/sidhe && VITE_HOST=${HOST} VITE_PORT=${VITE_PORT} yarn dev --host 0.0.0.0 --port ${VITE_PORT}"
}

# Fonction principale
main() {
    echo "[$SCRIPT_NAME][start] Lancement de l'interface SolidJS..."
    
    check_prerequisites || exit 1
    deploy_files || exit 1
    
    install_and_start
}

# Exécuter si appelé directement
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi
