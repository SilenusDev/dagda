#!/bin/bash
# dagda/awen-core/teine_engine.sh
# Dagda-Lite - Moteur générique des services
# Moteur unifié pour la gestion des pods

SCRIPT_NAME="teine_engine"

# Configuration des chemins
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Chargement des variables d'environnement (SÉCURISÉ)
if [ -z "$DAGDA_ROOT" ]; then
    echo "[teine_engine][error] Variable DAGDA_ROOT non définie" >&2
    exit 1
fi

if [ ! -f "${DAGDA_ROOT}/.env" ]; then
    echo "[teine_engine][error] Fichier .env non trouvé dans ${DAGDA_ROOT}" >&2
    exit 1
fi

source "${DAGDA_ROOT}/.env"

# Charger les utilitaires
source "$OLLAMH_SCRIPT" || { echo "[teine_engine][error] ollamh.sh non trouvé"; exit 1; }

# Fonctions utilitaires

# Détecter la catégorie d'un service depuis son chemin
detect_service_category() {
    local service_dir="$1"
    local category="cromlech"  # Par défaut
    
    if [[ "$service_dir" == *"/cromlech/"* ]]; then
        category="cromlech"
    elif [[ "$service_dir" == *"/fianna/"* ]]; then
        category="fianna"
    elif [[ "$service_dir" == *"/muirdris/"* ]]; then
        category="muirdris"
    elif [[ "$service_dir" == *"/geasa/"* ]]; then
        category="geasa"
    fi
    
    echo "$category"
}

# Obtenir le statut d'un pod
get_pod_status() {
    local pod_name=$1
    if ! check_pod_exists "$pod_name"; then
        echo "NotFound"
        return 1
    fi
    
    local status=$(podman pod ps --filter name="$pod_name" --format "{{.Status}}" 2>/dev/null | head -n1)
    echo "${status:-Unknown}"
}

# Obtenir le nombre de conteneurs dans un pod
get_pod_containers() {
    local pod_name=$1
    if ! check_pod_exists "$pod_name"; then
        echo "0"
        return 1
    fi
    
    podman pod ps --filter name="$pod_name" --format "{{.NumberOfContainers}}" 2>/dev/null | head -n1 || echo "0"
}

# Afficher les logs d'un conteneur
show_container_logs() {
    local pod_name=$1
    local lines=${2:-20}
    local context=${3:-""}
    
    local containers=$(podman ps -q --filter pod="$pod_name" 2>/dev/null || true)
    if [ -n "$containers" ]; then
        for container in $containers; do
            local container_name=$(podman inspect --format '{{.Name}}' "$container" 2>/dev/null || echo "inconnu")
            echo "[teine_engine][info] Logs de $container_name (${lines} dernières lignes):"
            podman logs --tail "$lines" "$container" 2>/dev/null || echo "[teine_engine][warning] Logs non disponibles pour $container_name"
            echo
        done
    else
        echo "[teine_engine][warning] Aucun conteneur trouvé dans le pod $pod_name"
    fi
}

# Afficher un résumé d'opération
show_summary() {
    local service_name=$1
    local port=$2
    local operation=$3
    local message=$4
    
    echo
    echo "[teine_engine][step] Résumé de l'opération '$operation' pour $service_name:"
    if [ -n "$port" ]; then
        echo "[teine_engine][info]   Service: $service_name (port $port)"
    else
        echo "[teine_engine][info]   Service: $service_name"
    fi
    echo "[teine_engine][info]   Résultat: $message"
    echo
}

# Lire la configuration d'un service depuis son pod.yml
read_service_config() {
    local service_dir=$1
    local config_file="$service_dir/pod.yml"
    
    if [ ! -f "$config_file" ]; then
        echo "[teine_engine][error] Fichier de configuration non trouvé: $config_file"
        return 1
    fi
    
    echo "$config_file"
}

# === ACTIONS PRINCIPALES DU MOTEUR ===

# Démarrage d'un service (start)
teine_start() {
    local service_dir="$1"
    local service_name="$(basename "$service_dir")"
    local pod_name=$(get_pod_name "$service_name")
    
    echo "[teine_engine][step] Démarrage du service $service_name..."
    
    # Charger la configuration
    local config_file=$(read_service_config "$service_dir")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Vérifier les prérequis
    if ! check_prerequisites "$service_name"; then
        return 1
    fi
    
    # Déterminer le port depuis le .env (convention: SERVICE_PORT)
    local port_var=$(echo "${service_name}_PORT" | tr '[:lower:]' '[:upper:]')
    local port="${!port_var}"
    
    # Nettoyer les processus existants sur le port si spécifié
    if [ -n "$port" ]; then
        kill_processes_on_port "$port" "$service_name"
    fi
    
    # Nettoyer les conteneurs/pods existants
    echo "[teine_engine][step] Nettoyage des anciens pods..."
    podman pod stop "$pod_name" 2>/dev/null || true
    podman pod rm -f "$pod_name" 2>/dev/null || true
    
    # Nettoyer les conteneurs orphelins
    local containers=$(podman ps -aq --filter name="$pod_name" 2>/dev/null || true)
    if [ -n "$containers" ]; then
        echo "[teine_engine][info] Nettoyage des conteneurs orphelins..."
        for container in $containers; do
            podman stop "$container" 2>/dev/null || true
            podman rm -f "$container" 2>/dev/null || true
        done
    fi
    
    # S'assurer que les répertoires existent
    ensure_directories "$service_name"
    
    # Créer le réseau si nécessaire
    local network=$(ensure_network)
    
    # Démarrer le pod avec Kubernetes YAML
    echo "[teine_engine][step] Démarrage du pod avec configuration..."
    cd "$service_dir"
    
    # Substituer les variables d'environnement dans pod.yml
    local temp_pod_file=$(mktemp)
    if command -v envsubst &> /dev/null; then
        envsubst < "pod.yml" > "$temp_pod_file"
    else
        # Fallback manuel si envsubst non disponible
        sed "s/\${DB_PORT}/$DB_PORT/g; \
             s/\${DB_ROOT_PASSWORD}/$DB_ROOT_PASSWORD/g; \
             s/\${DB_NAME}/$DB_NAME/g; \
             s/\${DB_USER}/$DB_USER/g; \
             s/\${DB_PASSWORD}/$DB_PASSWORD/g" "pod.yml" > "$temp_pod_file"
    fi
    
    if ! podman play kube "$temp_pod_file"; then
        echo "[teine_engine][error] Échec du démarrage du service $service_name"
        show_container_logs "$pod_name" 30 "$service_name"
        rm -f "$temp_pod_file"
        return 1
    fi
    
    # Nettoyer le fichier temporaire
    rm -f "$temp_pod_file"
    
    echo "[teine_engine][success] Service $service_name démarré avec succès"
    
    # Vérifier que le pod est en cours d'exécution
    echo "[teine_engine][step] Vérification de l'état du service..."
    sleep 3
    
    local pod_status=$(get_pod_status "$pod_name")
    if [ "$pod_status" = "NotFound" ]; then
        echo "[teine_engine][error] Service $service_name non trouvé après démarrage"
        return 1
    fi
    
    echo "[teine_engine][info] État du service: $pod_status"
    
    # Attendre que le port soit disponible si spécifié
    if [ -n "$port" ]; then
        if ! wait_for_service "$service_name" "$port" "$HOST" 30 2; then
            echo "[teine_engine][error] Le port $port n'est pas accessible pour $service_name"
            show_container_logs "$pod_name" 30 "$service_name"
            return 1
        fi
    fi
    
    # Mettre à jour le statut dans dolmen
    local category=$(detect_service_category "$service_dir")
    update_service_status "$service_name" "$category" "started" "$port"
    
    # Afficher les informations du pod
    echo "[teine_engine][step] Informations du service démarré..."
    podman pod ps --filter name="$pod_name" --format "table {{.Name}}\t{{.Status}}\t{{.Created}}\t{{.NumberOfContainers}}"
    
    # Résumé final
    show_summary "$service_name" "$port" "start" "Service démarré avec $(get_pod_containers "$pod_name") conteneur(s)"
    
    echo "[teine_engine][success] Démarrage du service $service_name terminé avec succès !"
}

# Arrêt d'un service (stop)
teine_stop() {
    local service_dir="$1"
    local service_name="$(basename "$service_dir")"
    local pod_name=$(get_pod_name "$service_name")
    
    echo "[teine_engine][step] Arrêt du service $service_name..."
    
    # Vérifier si le pod existe
    local pod_status=$(get_pod_status "$pod_name")
    if [ "$pod_status" = "NotFound" ]; then
        echo "[teine_engine][warning] Service $service_name déjà arrêté"
        show_summary "$service_name" "" "stop" "Service déjà arrêté"
        return 0
    fi
    
    echo "[teine_engine][info] État actuel du service: $pod_status"
    
    # Afficher les conteneurs avant arrêt
    echo "[teine_engine][step] Conteneurs dans le service avant arrêt:"
    podman ps --filter pod="$pod_name" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || true
    
    # Arrêter le pod gracieusement
    echo "[teine_engine][step] Arrêt gracieux du service..."
    if podman pod stop "$pod_name" 2>/dev/null; then
        echo "[teine_engine][success] Service $service_name arrêté avec succès"
    else
        echo "[teine_engine][warning] Échec de l'arrêt gracieux, forçage de l'arrêt..."
        podman pod kill "$pod_name" 2>/dev/null || true
    fi
    
    # Vérifier que le port est libéré
    local port_var=$(echo "${service_name}_PORT" | tr '[:lower:]' '[:upper:]')
    local port="${!port_var}"
    
    if [ -n "$port" ]; then
        echo "[teine_engine][step] Vérification de la libération du port $port..."
        sleep 2
        
        if check_port "$port" "$HOST" 2; then
            echo "[teine_engine][warning] Le port $port est encore occupé, nettoyage des processus..."
            kill_processes_on_port "$port" "$service_name"
        else
            echo "[teine_engine][success] Port $port libéré"
        fi
    fi
    
    # Vérifier le statut final
    local pod_status_final=$(get_pod_status "$pod_name")
    echo "[teine_engine][info] État final du service: $pod_status_final"
    
    # Mettre à jour le statut dans dolmen
    local category=$(detect_service_category "$service_dir")
    update_service_status "$service_name" "$category" "stopped" "$port"
    
    # Résumé final
    show_summary "$service_name" "$port" "stop" "Service arrêté, port libéré"
    
    echo "[teine_engine][success] Arrêt du service $service_name terminé avec succès !"
}

# État d'un service (status)
teine_status() {
    local service_dir="$1"
    local service_name="$(basename "$service_dir")"
    local detailed="$2"
    local pod_name=$(get_pod_name "$service_name")
    
    echo "[teine_engine][step] Consultation de l'état du service $service_name..."
    
    # Obtenir le statut du pod
    local pod_status=$(get_pod_status "$pod_name")
    
    if [ "$pod_status" = "NotFound" ]; then
        echo "[teine_engine][error] Service $service_name non trouvé"
        return 1
    fi
    
    # Affichage basique du statut
    echo "[teine_engine][info] État du service: $pod_status"
    
    # Obtenir le nombre de conteneurs
    local container_count=$(get_pod_containers "$pod_name")
    echo "[teine_engine][info] Nombre de conteneurs: $container_count"
    
    # Affichage détaillé si demandé
    if [ "$detailed" = "--detailed" ]; then
        echo
        echo "[teine_engine][step] Informations détaillées du service..."
        
        # Informations générales du pod
        podman pod ps --filter name="$pod_name" --format "table {{.Name}}\t{{.Status}}\t{{.Created}}\t{{.NumberOfContainers}}\t{{.Id}}"
        
        echo
        echo "[teine_engine][step] Conteneurs dans le service..."
        podman ps --filter pod="$pod_name" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Created}}\t{{.Size}}"
        
        # Statistiques des conteneurs
        echo
        echo "[teine_engine][step] Statistiques des conteneurs..."
        local containers=$(podman ps -q --filter pod="$pod_name" 2>/dev/null || true)
        if [ -n "$containers" ]; then
            for container in $containers; do
                local container_name=$(podman inspect --format '{{.Name}}' "$container" 2>/dev/null || echo "inconnu")
                echo "[teine_engine][info] Stats pour $container_name:"
                podman stats --no-stream --format "  CPU: {{.CPUPerc}} | Mémoire: {{.MemUsage}} | Réseau: {{.NetIO}}" "$container" 2>/dev/null || echo "[teine_engine][warning]   Statistiques non disponibles"
            done
        fi
        
        # Logs récents si le pod est en cours d'exécution
        if [ "$pod_status" = "Running" ]; then
            echo
            echo "[teine_engine][step] Logs récents (5 dernières lignes)..."
            show_container_logs "$pod_name" 5 "$service_name"
        fi
    fi
    
    # Déterminer le code de sortie basé sur le statut
    case "$pod_status" in
        "Running")
            echo "[teine_engine][success] Service $service_name fonctionne correctement"
            return 0
            ;;
        "Paused")
            echo "[teine_engine][warning] Service $service_name est en pause"
            return 2
            ;;
        "Exited"|"Stopped")
            echo "[teine_engine][warning] Service $service_name est arrêté"
            return 3
            ;;
        "Error"|"Dead")
            echo "[teine_engine][error] Service $service_name est en erreur"
            return 4
            ;;
        *)
            echo "[teine_engine][warning] Service $service_name dans un état inconnu: $pod_status"
            return 5
            ;;
    esac
}

# Santé d'un service (health)
teine_health() {
    local service_dir="$1"
    local service_name="$(basename "$service_dir")"
    local pod_name=$(get_pod_name "$service_name")
    
    echo "[teine_engine][step] Vérification de la santé du service $service_name..."
    
    # Vérifier d'abord si le pod existe et est en cours d'exécution
    local pod_status=$(get_pod_status "$pod_name")
    if [ "$pod_status" = "NotFound" ]; then
        echo "[teine_engine][error] Service $service_name non trouvé"
        return 1
    fi
    
    echo "[teine_engine][info] État du service: $pod_status"
    
    if [ "$pod_status" != "Running" ]; then
        echo "[teine_engine][error] Service $service_name n'est pas démarré (état: $pod_status)"
        return 2
    fi
    
    # Obtenir le port depuis les variables d'environnement
    local port_var=$(echo "${service_name}_PORT" | tr '[:lower:]' '[:upper:]')
    local port="${!port_var}"
    
    if [ -z "$port" ]; then
        echo "[teine_engine][warning] Port non défini pour $service_name dans .env"
        return 1
    fi
    
    # Test 1: Vérification du port
    echo "[teine_engine][step] Test 1/1: Vérification du port $port..."
    if check_port "$port" "$HOST" 5; then
        echo "[teine_engine][success] Port $port accessible sur $HOST"
        local port_ok=true
    else
        echo "[teine_engine][error] Port $port non accessible sur $HOST"
        local port_ok=false
    fi
    
    # Affichage des informations supplémentaires en cas de problème
    if [ "$port_ok" = false ]; then
        echo
        echo "[teine_engine][step] Informations de diagnostic..."
        
        # Afficher les conteneurs du pod
        echo "[teine_engine][info] Conteneurs dans le service:"
        podman ps --filter pod="$pod_name" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || true
        
        # Afficher les logs récents
        echo
        echo "[teine_engine][step] Logs récents (10 dernières lignes):"
        show_container_logs "$pod_name" 10 "$service_name"
        
        # Vérifier les processus sur le port
        if command -v lsof &> /dev/null; then
            echo
            echo "[teine_engine][step] Processus utilisant le port $port:"
            local port_processes=$(lsof -ti:$port 2>/dev/null || true)
            if [ -n "$port_processes" ]; then
                for pid in $port_processes; do
                    local process_info=$(ps -p $pid -o pid,ppid,cmd --no-headers 2>/dev/null || echo "$pid - processus introuvable")
                    echo "[teine_engine][info]   $process_info"
                done
            else
                echo "[teine_engine][warning]   Aucun processus trouvé sur le port $port"
            fi
        fi
    fi
    
    # Résumé final
    echo
    echo "[teine_engine][step] Résumé de la vérification de santé..."
    echo "[teine_engine][info] Service: $service_name"
    echo "[teine_engine][info] Port: $port"
    
    # Déterminer le résultat final
    if [ "$port_ok" = true ]; then
        echo "[teine_engine][success] Service $service_name en bonne santé !"
        echo "[teine_engine][success]    Port $port accessible"
        return 0
    else
        echo "[teine_engine][error] Service $service_name en mauvaise santé"
        echo "[teine_engine][error]    Port $port non accessible"
        return 4
    fi
}

# Nettoyage d'un service (clean)
teine_clean() {
    local service_dir="$1"
    local service_name="$(basename "$service_dir")"
    local pod_name=$(get_pod_name "$service_name")
    
    echo "[teine_engine][step] Nettoyage complet du service $service_name..."
    
    # Obtenir le port
    local port_var=$(echo "${service_name}_PORT" | tr '[:lower:]' '[:upper:]')
    local port="${!port_var}"
    
    # Nettoyer les processus sur le port si spécifié
    if [ -n "$port" ]; then
        kill_processes_on_port "$port" "$service_name"
    fi
    
    # Vérifier si le pod existe
    local pod_status=$(get_pod_status "$pod_name")
    if [ "$pod_status" = "NotFound" ]; then
        echo "[teine_engine][info] Service $service_name non trouvé, nettoyage des conteneurs orphelins..."
    else
        echo "[teine_engine][info] État actuel du service: $pod_status"
        
        # Afficher les conteneurs avant nettoyage
        echo "[teine_engine][step] Conteneurs dans le service avant nettoyage:"
        podman ps --filter pod="$pod_name" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || true
    fi
    
    # Arrêter le pod s'il existe
    if [ "$pod_status" != "NotFound" ]; then
        echo "[teine_engine][step] Arrêt du service..."
        podman pod stop "$pod_name" 2>/dev/null || true
        podman pod kill "$pod_name" 2>/dev/null || true
    fi
    
    # Nettoyer tous les conteneurs associés au pod
    echo "[teine_engine][step] Nettoyage des conteneurs..."
    local containers=$(podman ps -aq --filter name="$pod_name" 2>/dev/null || true)
    if [ -n "$containers" ]; then
        echo "[teine_engine][info] Conteneurs trouvés: $(echo $containers | wc -w)"
        for container in $containers; do
            local container_name=$(podman inspect --format '{{.Name}}' "$container" 2>/dev/null || echo "inconnu")
            echo "[teine_engine][debug] Suppression du conteneur $container_name ($container)"
            podman stop "$container" 2>/dev/null || true
            podman rm -f "$container" 2>/dev/null || true
        done
        echo "[teine_engine][success] Conteneurs nettoyés"
    else
        echo "[teine_engine][debug] Aucun conteneur trouvé pour $service_name"
    fi
    
    # Supprimer le pod
    if [ "$pod_status" != "NotFound" ]; then
        echo "[teine_engine][step] Suppression du service..."
        if podman pod rm -f "$pod_name" 2>/dev/null; then
            echo "[teine_engine][success] Service $service_name supprimé"
        else
            echo "[teine_engine][warning] Échec de la suppression du service $service_name"
        fi
    fi
    
    # Nettoyer les conteneurs orphelins avec des noms similaires
    echo "[teine_engine][step] Nettoyage des conteneurs orphelins..."
    local orphan_containers=$(podman ps -aq --filter name="*$pod_name*" 2>/dev/null || true)
    if [ -n "$orphan_containers" ]; then
        echo "[teine_engine][info] Conteneurs orphelins trouvés: $(echo $orphan_containers | wc -w)"
        for container in $orphan_containers; do
            local container_name=$(podman inspect --format '{{.Name}}' "$container" 2>/dev/null || echo "inconnu")
            echo "[teine_engine][debug] Suppression du conteneur orphelin $container_name ($container)"
            podman stop "$container" 2>/dev/null || true
            podman rm -f "$container" 2>/dev/null || true
        done
        echo "[teine_engine][success] Conteneurs orphelins nettoyés"
    else
        echo "[teine_engine][debug] Aucun conteneur orphelin trouvé"
    fi
    
    # Vérification finale du port
    if [ -n "$port" ]; then
        echo "[teine_engine][step] Vérification finale du port $port..."
        sleep 2
        
        if check_port "$port" "$HOST" 2; then
            echo "[teine_engine][warning] Le port $port est encore occupé après nettoyage"
            kill_processes_on_port "$port" "$service_name"
        else
            echo "[teine_engine][success] Port $port définitivement libéré"
        fi
    fi
    
    # Nettoyer les images inutilisées (optionnel)
    echo "[teine_engine][step] Nettoyage des images inutilisées..."
    podman image prune -f 2>/dev/null || true
    
    # Vérification finale
    local pod_status_final=$(get_pod_status "$pod_name")
    if [ "$pod_status_final" = "NotFound" ]; then
        echo "[teine_engine][success] Service $service_name complètement nettoyé"
    else
        echo "[teine_engine][warning] Service $service_name encore présent: $pod_status_final"
    fi
    
    # Mettre à jour le statut dans dolmen
    local category=$(detect_service_category "$service_dir")
    update_service_status "$service_name" "$category" "cleaned" ""
    
    # Résumé final
    show_summary "$service_name" "$port" "clean" "Service et conteneurs supprimés, port libéré"
    
    echo "[teine_engine][success] Nettoyage complet du service $service_name terminé !"
}

# Logs d'un service (logs)
teine_logs() {
    local service_dir="$1"
    local service_name="$(basename "$service_dir")"
    local lines="${2:-20}"
    local pod_name=$(get_pod_name "$service_name")
    
    echo "[teine_engine][step] Consultation des logs du service $service_name..."
    
    show_container_logs "$pod_name" "$lines" "$service_name"
}

# === FONCTION PRINCIPALE DU MOTEUR ===

# Point d'entrée principal
main() {
    local action="$1"
    local service_path="$2"
    local extra_args="${@:3}"
    
    if [ -z "$action" ] || [ -z "$service_path" ]; then
        echo "[teine_engine][error] Usage: $0 <action> <service_path> [args...]"
        echo "[teine_engine][error] Actions: start, stop, status, health, clean, logs"
        echo "[teine_engine][error] Exemple: $0 start /path/to/cauldron/cromlech/mariadb"
        echo "[teine_engine][error] Exemple: $0 status /path/to/cauldron/cromlech/mariadb --detailed"
        return 1
    fi
    
    if [ ! -d "$service_path" ]; then
        echo "[teine_engine][error] Répertoire de service non trouvé: $service_path"
        return 1
    fi
    
    case "$action" in
        "start")
            teine_start "$service_path"
            ;;
        "stop")
            teine_stop "$service_path"
            ;;
        "status")
            teine_status "$service_path" $extra_args
            ;;
        "health")
            teine_health "$service_path"
            ;;
        "clean")
            teine_clean "$service_path"
            ;;
        "logs")
            teine_logs "$service_path" $extra_args
            ;;
        *)
            echo "[teine_engine][error] Action non reconnue: $action"
            echo "[teine_engine][error] Actions disponibles: start, stop, status, health, clean, logs"
            return 1
            ;;
    esac
}

# Si le script est exécuté directement (pas sourcé)
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi