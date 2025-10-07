#!/bin/bash
# dagda/eveil/taranis.sh
# Script principal d'orchestration Dagda-Lite

SCRIPT_NAME="taranis"

# Détection automatique de DAGDA_ROOT (SÉCURISÉ)
if [ -z "$DAGDA_ROOT" ]; then
    # Détecter DAGDA_ROOT depuis l'emplacement du script
    SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
    DETECTED_DAGDA_ROOT="$(dirname "$(dirname "$(dirname "$SCRIPT_PATH")")")"
    
    # Vérifier que .env.dev ou .env.prod existe
    if [ -f "${DETECTED_DAGDA_ROOT}/.env.dev" ] || [ -f "${DETECTED_DAGDA_ROOT}/.env.prod" ]; then
        export DAGDA_ROOT="$DETECTED_DAGDA_ROOT"
        echo "[taranis][info] DAGDA_ROOT détecté: ${DAGDA_ROOT}"
    else
        echo "[taranis][error] Impossible de détecter DAGDA_ROOT" >&2
        echo "[taranis][error] Fichiers .env.dev/.env.prod non trouvés dans ${DETECTED_DAGDA_ROOT}" >&2
        exit 1
    fi
fi


echo "[taranis][start] Démarrage de l'orchestrateur Dagda-Lite"

# Vérifier si .env existe et est valide (doit être une copie de .env.dev ou .env.prod)
if [ ! -f "${DAGDA_ROOT}/.env" ] || ! grep -q "^OLLAMH_SCRIPT=" "${DAGDA_ROOT}/.env" 2>/dev/null; then
    echo "[taranis][warning] Fichier .env manquant ou incomplet"
    echo "[taranis][info] Initialisation requise - copie de .env.dev ou .env.prod"
    echo ""
    echo "Choisissez l'environnement:"
    echo "  1) dev  - Développement (localhost)"
    echo "  2) prod - Production (IP serveur)"
    echo ""
    read -p "Votre choix [1/2]: " init_choice
    
    case "$init_choice" in
        1)
            if [ ! -f "${DAGDA_ROOT}/.env.dev" ]; then
                echo "[taranis][error] Fichier .env.dev non trouvé"
                exit 1
            fi
            echo "[taranis][info] Copie de .env.dev vers .env..."
            cp "${DAGDA_ROOT}/.env.dev" "${DAGDA_ROOT}/.env"
            echo "[taranis][success] Environnement DEVELOPMENT activé"
            ;;
        2)
            if [ ! -f "${DAGDA_ROOT}/.env.prod" ]; then
                echo "[taranis][error] Fichier .env.prod non trouvé"
                exit 1
            fi
            echo "[taranis][info] Copie de .env.prod vers .env..."
            cp "${DAGDA_ROOT}/.env.prod" "${DAGDA_ROOT}/.env"
            echo "[taranis][success] Environnement PRODUCTION activé"
            ;;
        *)
            echo "[taranis][error] Choix invalide"
            exit 1
            ;;
    esac
    echo ""
fi

# Charger le .env (maintenant complet)
source "${DAGDA_ROOT}/.env"

# Charger les utilitaires
if [ -z "$OLLAMH_SCRIPT" ] || [ ! -f "$OLLAMH_SCRIPT" ]; then
    echo "[taranis][error] OLLAMH_SCRIPT invalide: ${OLLAMH_SCRIPT}" >&2
    exit 1
fi

source "${OLLAMH_SCRIPT}"

case "$1" in
    start|dagda)
        echo "[taranis][start] 🚀 ÉVEIL DES SERVICES ESSENTIELS DAGDA-LITE"
        echo "[taranis][info] =========================================="
        
        echo "[taranis][step] 🗄️  Démarrage de MariaDB..."
        "${TEINE_ENGINE_SCRIPT}" start "${CROMLECH_DIR}/mariadb"
        mariadb_status=$?
        
        echo "[taranis][step] 🔧 Démarrage de FastAPI..."
        "${TEINE_ENGINE_SCRIPT}" start "${MUIRDRIS_DIR}/fastapi"
        fastapi_status=$?
        
        echo "[taranis][step] 📦 Démarrage de Yarn (environnement SolidJS)..."
        "${TEINE_ENGINE_SCRIPT}" start "${GEASA_DIR}/yarn"
        yarn_status=$?
        
        echo "[taranis][info] =========================================="
        echo "[taranis][step] 📊 VÉRIFICATION DES SERVICES ESSENTIELS"
        
        if [ $mariadb_status -eq 0 ] && [ $fastapi_status -eq 0 ] && [ $yarn_status -eq 0 ]; then
            echo "[taranis][success] ✅ Services essentiels DAGDA-LITE démarrés avec succès"
            echo "[taranis][info] 🗄️  MariaDB    : http://${HOST}:${DB_PORT}/"
            echo "[taranis][info] 🔧 FastAPI    : http://${HOST}:${API_PORT}/"
            echo "[taranis][info] 📦 Yarn       : http://${HOST}:${YARN_PORT}/"
            echo "[taranis][info] =========================================="
            
            echo "[taranis][step] 🎨 Lancement automatique de l'interface SolidJS..."
            "${DAGDA_ROOT}/dagda/eveil/launch-sidhe.sh"
            
            echo "[taranis][info] =========================================="
            echo "[taranis][success] 🎉 DAGDA-LITE OPÉRATIONNEL"
            echo "[taranis][info] 🎨 Interface SolidJS : http://${HOST}:${VITE_PORT}/"
            echo "[taranis][info] =========================================="
        else
            echo "[taranis][error] ❌ Échec du démarrage de certains services essentiels"
            echo "[taranis][info] 🗄️  MariaDB : $([ $mariadb_status -eq 0 ] && echo "✅" || echo "❌")"
            echo "[taranis][info] 🔧 FastAPI : $([ $fastapi_status -eq 0 ] && echo "✅" || echo "❌")"
            echo "[taranis][info] 📦 Yarn    : $([ $yarn_status -eq 0 ] && echo "✅" || echo "❌")"
            exit 1
        fi
        ;;
    # Commandes par pod individuel
    mariadb)
        echo "[taranis][info] Démarrage de MariaDB"
        "${TEINE_ENGINE_SCRIPT}" start "${CROMLECH_DIR}/mariadb"
        ;;
    fastapi)
        echo "[taranis][info] Démarrage de FastAPI"
        "${TEINE_ENGINE_SCRIPT}" start "${MUIRDRIS_DIR}/fastapi"
        ;;
    llama)
        echo "[taranis][info] Démarrage de Llama"
        "${TEINE_ENGINE_SCRIPT}" start "${MUIRDRIS_DIR}/llama"
        ;;
    qwen)
        echo "[taranis][info] Démarrage de Qwen"
        "${TEINE_ENGINE_SCRIPT}" start "${MUIRDRIS_DIR}/qwen25-05b"
        ;;
    adminer)
        echo "[taranis][info] Démarrage d'Adminer"
        "${TEINE_ENGINE_SCRIPT}" start "${FIANNA_DIR}/adminer"
        ;;
    n8n)
        echo "[taranis][info] Démarrage de N8N"
        "${TEINE_ENGINE_SCRIPT}" start "${FIANNA_DIR}/n8n"
        ;;
    yarn)
        echo "[taranis][info] Démarrage de Yarn"
        "${TEINE_ENGINE_SCRIPT}" start "${GEASA_DIR}/yarn"
        ;;
    sidhe)
        echo "[taranis][info] Démarrage de Sidhe"
        "${TEINE_ENGINE_SCRIPT}" start "${DAGDA_ROOT}/cauldron/ogmios/sidhe"
        ;;
    # Commandes d'arrêt par pod
    stop)
        case "$2" in
            mariadb)
                echo "[taranis][info] Arrêt de MariaDB"
                "${TEINE_ENGINE_SCRIPT}" stop "${CROMLECH_DIR}/mariadb"
                ;;
            fastapi)
                echo "[taranis][info] Arrêt de FastAPI"
                "${TEINE_ENGINE_SCRIPT}" stop "${MUIRDRIS_DIR}/fastapi"
                ;;
            llama)
                echo "[taranis][info] Arrêt de Llama"
                "${TEINE_ENGINE_SCRIPT}" stop "${MUIRDRIS_DIR}/llama"
                ;;
            qwen)
                echo "[taranis][info] Arrêt de Qwen"
                "${TEINE_ENGINE_SCRIPT}" stop "${MUIRDRIS_DIR}/qwen25-05b"
                ;;
            adminer)
                echo "[taranis][info] Arrêt d'Adminer"
                "${TEINE_ENGINE_SCRIPT}" stop "${FIANNA_DIR}/adminer"
                ;;
            n8n)
                echo "[taranis][info] Arrêt de N8N"
                "${TEINE_ENGINE_SCRIPT}" stop "${FIANNA_DIR}/n8n"
                ;;
            yarn)
                echo "[taranis][info] Arrêt de Yarn"
                "${TEINE_ENGINE_SCRIPT}" stop "${GEASA_DIR}/yarn"
                ;;
            sidhe)
                echo "[taranis][info] Arrêt de Sidhe"
                "${TEINE_ENGINE_SCRIPT}" stop "${DAGDA_ROOT}/cauldron/ogmios/sidhe"
                ;;
            dagda)
                echo "[taranis][info] Arrêt des services essentiels DAGDA-LITE"
                "${TEINE_ENGINE_SCRIPT}" stop "${GEASA_DIR}/yarn" 2>/dev/null || true
                "${TEINE_ENGINE_SCRIPT}" stop "${MUIRDRIS_DIR}/fastapi" 2>/dev/null || true
                "${TEINE_ENGINE_SCRIPT}" stop "${CROMLECH_DIR}/mariadb" 2>/dev/null || true
                echo "[taranis][success] Services essentiels DAGDA-LITE arrêtés"
                ;;
            all)
                echo "[taranis][info] Arrêt de tous les services Dagda-Lite"
                echo "[taranis][step] Arrêt des environnements..."
                "${TEINE_ENGINE_SCRIPT}" stop "${GEASA_DIR}/yarn" 2>/dev/null || true
                echo "[taranis][step] Arrêt des applications..."
                "${TEINE_ENGINE_SCRIPT}" stop "${FIANNA_DIR}/n8n" 2>/dev/null || true
                "${TEINE_ENGINE_SCRIPT}" stop "${FIANNA_DIR}/adminer" 2>/dev/null || true
                echo "[taranis][step] Arrêt de l'écosystème Python..."
                "${TEINE_ENGINE_SCRIPT}" stop "${MUIRDRIS_DIR}/qwen25-05b" 2>/dev/null || true
                "${TEINE_ENGINE_SCRIPT}" stop "${MUIRDRIS_DIR}/llama" 2>/dev/null || true
                "${TEINE_ENGINE_SCRIPT}" stop "${MUIRDRIS_DIR}/fastapi" 2>/dev/null || true
                echo "[taranis][step] Arrêt des services essentiels..."
                "${TEINE_ENGINE_SCRIPT}" stop "${CROMLECH_DIR}/mariadb" 2>/dev/null || true
                echo "[taranis][success] Tous les services Dagda-Lite arrêtés"
                ;;
            *)
                echo "[taranis][error] Usage: $0 stop {mariadb|fastapi|llama|qwen|adminer|n8n|yarn|dagda|all}"
                exit 1
                ;;
        esac
        ;;
    # Commande de nettoyage complet
    clean)
        case "$2" in
            dagda|"")
                echo "[taranis][info] Nettoyage complet des services essentiels DAGDA-LITE"
                echo "[taranis][step] Nettoyage de Yarn..."
                "${TEINE_ENGINE_SCRIPT}" clean "${GEASA_DIR}/yarn" 2>/dev/null || true
                echo "[taranis][step] Nettoyage de FastAPI..."
                "${TEINE_ENGINE_SCRIPT}" clean "${MUIRDRIS_DIR}/fastapi" 2>/dev/null || true
                echo "[taranis][step] Nettoyage de MariaDB..."
                "${TEINE_ENGINE_SCRIPT}" clean "${CROMLECH_DIR}/mariadb" 2>/dev/null || true
                echo "[taranis][success] Services essentiels DAGDA-LITE nettoyés"
                ;;
            all)
                echo "[taranis][info] Nettoyage complet de tous les services Dagda-Lite"
                echo "[taranis][step] Nettoyage des environnements..."
                "${TEINE_ENGINE_SCRIPT}" clean "${GEASA_DIR}/yarn" 2>/dev/null || true
                echo "[taranis][step] Nettoyage des applications..."
                "${TEINE_ENGINE_SCRIPT}" clean "${FIANNA_DIR}/n8n" 2>/dev/null || true
                "${TEINE_ENGINE_SCRIPT}" clean "${FIANNA_DIR}/adminer" 2>/dev/null || true
                echo "[taranis][step] Nettoyage de l'écosystème Python..."
                "${TEINE_ENGINE_SCRIPT}" clean "${MUIRDRIS_DIR}/qwen25-05b" 2>/dev/null || true
                "${TEINE_ENGINE_SCRIPT}" clean "${MUIRDRIS_DIR}/llama" 2>/dev/null || true
                "${TEINE_ENGINE_SCRIPT}" clean "${MUIRDRIS_DIR}/fastapi" 2>/dev/null || true
                echo "[taranis][step] Nettoyage des services essentiels..."
                "${TEINE_ENGINE_SCRIPT}" clean "${CROMLECH_DIR}/mariadb" 2>/dev/null || true
                echo "[taranis][success] Tous les services Dagda-Lite nettoyés"
                ;;
            mariadb)
                echo "[taranis][info] Nettoyage de MariaDB"
                "${TEINE_ENGINE_SCRIPT}" clean "${CROMLECH_DIR}/mariadb"
                ;;
            fastapi)
                echo "[taranis][info] Nettoyage de FastAPI"
                "${TEINE_ENGINE_SCRIPT}" clean "${MUIRDRIS_DIR}/fastapi"
                ;;
            yarn)
                echo "[taranis][info] Nettoyage de Yarn"
                "${TEINE_ENGINE_SCRIPT}" clean "${GEASA_DIR}/yarn"
                ;;
            llama)
                echo "[taranis][info] Nettoyage de Llama"
                "${TEINE_ENGINE_SCRIPT}" clean "${MUIRDRIS_DIR}/llama"
                ;;
            qwen)
                echo "[taranis][info] Nettoyage de Qwen"
                "${TEINE_ENGINE_SCRIPT}" clean "${MUIRDRIS_DIR}/qwen25-05b"
                ;;
            adminer)
                echo "[taranis][info] Nettoyage d'Adminer"
                "${TEINE_ENGINE_SCRIPT}" clean "${FIANNA_DIR}/adminer"
                ;;
            n8n)
                echo "[taranis][info] Nettoyage de N8N"
                "${TEINE_ENGINE_SCRIPT}" clean "${FIANNA_DIR}/n8n"
                ;;
            *)
                echo "[taranis][error] Usage: $0 clean {dagda|mariadb|fastapi|yarn|llama|qwen|adminer|n8n|all|''}"
                exit 1
                ;;
        esac
        ;;
    # Commandes de statut par pod
    status)
        case "$2" in
            mariadb)
                echo "[taranis][info] Statut de MariaDB"
                "${TEINE_ENGINE_SCRIPT}" status "${CROMLECH_DIR}/mariadb"
                ;;
            fastapi)
                echo "[taranis][info] Statut de FastAPI"
                "${TEINE_ENGINE_SCRIPT}" status "${MUIRDRIS_DIR}/fastapi"
                ;;
            llama)
                echo "[taranis][info] Statut de Llama"
                "${TEINE_ENGINE_SCRIPT}" status "${MUIRDRIS_DIR}/llama"
                ;;
            qwen)
                echo "[taranis][info] Statut de Qwen"
                "${TEINE_ENGINE_SCRIPT}" status "${MUIRDRIS_DIR}/qwen25-05b"
                ;;
            adminer)
                echo "[taranis][info] Statut d'Adminer"
                "${TEINE_ENGINE_SCRIPT}" status "${FIANNA_DIR}/adminer"
                ;;
            n8n)
                echo "[taranis][info] Statut de N8N"
                "${TEINE_ENGINE_SCRIPT}" status "${FIANNA_DIR}/n8n"
                ;;
            yarn)
                echo "[taranis][info] Statut de Yarn"
                "${TEINE_ENGINE_SCRIPT}" status "${GEASA_DIR}/yarn"
                ;;
            dagda)
                echo "[taranis][info] Statut des services essentiels DAGDA-LITE"
                echo "[taranis][step] MariaDB:"
                "${TEINE_ENGINE_SCRIPT}" status "${CROMLECH_DIR}/mariadb" 2>/dev/null || echo "[taranis][warning] MariaDB non disponible"
                echo "[taranis][step] FastAPI:"
                "${TEINE_ENGINE_SCRIPT}" status "${MUIRDRIS_DIR}/fastapi" 2>/dev/null || echo "[taranis][warning] FastAPI non disponible"
                echo "[taranis][step] Yarn:"
                "${TEINE_ENGINE_SCRIPT}" status "${GEASA_DIR}/yarn" 2>/dev/null || echo "[taranis][warning] Yarn non disponible"
                ;;
            all|"")
                echo "[taranis][info] Statut global de tous les services Dagda-Lite"
                echo "[taranis][step] === SERVICES ESSENTIELS (DAGDA) ==="
                echo "[taranis][step] MariaDB:"
                "${TEINE_ENGINE_SCRIPT}" status "${CROMLECH_DIR}/mariadb" 2>/dev/null || echo "[taranis][warning] MariaDB non disponible"
                echo "[taranis][step] FastAPI:"
                "${TEINE_ENGINE_SCRIPT}" status "${MUIRDRIS_DIR}/fastapi" 2>/dev/null || echo "[taranis][warning] FastAPI non disponible"
                echo "[taranis][step] Yarn:"
                "${TEINE_ENGINE_SCRIPT}" status "${GEASA_DIR}/yarn" 2>/dev/null || echo "[taranis][warning] Yarn non disponible"
                echo "[taranis][step] === SERVICES OPTIONNELS ==="
                echo "[taranis][step] Llama:"
                "${TEINE_ENGINE_SCRIPT}" status "${MUIRDRIS_DIR}/llama" 2>/dev/null || echo "[taranis][warning] Llama non disponible"
                echo "[taranis][step] Qwen:"
                "${TEINE_ENGINE_SCRIPT}" status "${MUIRDRIS_DIR}/qwen25-05b" 2>/dev/null || echo "[taranis][warning] Qwen non disponible"
                echo "[taranis][step] Adminer:"
                "${TEINE_ENGINE_SCRIPT}" status "${FIANNA_DIR}/adminer" 2>/dev/null || echo "[taranis][warning] Adminer non disponible"
                echo "[taranis][step] N8N:"
                "${TEINE_ENGINE_SCRIPT}" status "${FIANNA_DIR}/n8n" 2>/dev/null || echo "[taranis][warning] N8N non disponible"
                ;;
            *)
                echo "[taranis][error] Usage: $0 status {mariadb|fastapi|llama|qwen|adminer|n8n|yarn|dagda|all|''}"
                exit 1
                ;;
        esac
        ;;
    *)
        echo "[taranis][help] Usage: $0 {COMMAND} [OPTIONS]"
        echo "[taranis][help]"
        echo "[taranis][help] === SERVICES ESSENTIELS ==="
        echo "[taranis][help]   dagda                    - Démarrer les 3 services essentiels (mariadb, fastapi, yarn)"
        echo "[taranis][help]   stop dagda               - Arrêter les services essentiels"
        echo "[taranis][help]   status dagda             - Statut des services essentiels"
        echo "[taranis][help]"
        echo "[taranis][help] === SERVICES INDIVIDUELS ==="
        echo "[taranis][help]   mariadb                  - Démarrer MariaDB (base de données)"
        echo "[taranis][help]   fastapi                  - Démarrer FastAPI (API + interface web)"
        echo "[taranis][help]   yarn                     - Démarrer Yarn (environnement SolidJS)"
        echo "[taranis][help]   llama                    - Démarrer Llama (modèle LLM)"
        echo "[taranis][help]   qwen                     - Démarrer Qwen (modèle LLM)"
        echo "[taranis][help]   adminer                  - Démarrer Adminer (interface DB)"
        echo "[taranis][help]   n8n                      - Démarrer N8N (workflows)"
        echo "[taranis][help]"
        echo "[taranis][help] === COMMANDES GLOBALES ==="
        echo "[taranis][help]   stop {service|all}       - Arrêter un service ou tous"
        echo "[taranis][help]   status {service|all}     - Statut d'un service ou tous"
        echo "[taranis][help]   clean {service|all}      - Nettoyer un service ou tous"
        echo "[taranis][help]"
        echo "[taranis][help] === EXEMPLES ==="
        echo "[taranis][help]   $0 dagda                 # Démarrer les services essentiels"
        echo "[taranis][help]   $0 llama                 # Démarrer Llama individuellement"
        echo "[taranis][help]   $0 status all            # Voir le statut de tous les services"
        echo "[taranis][help]   $0 stop fastapi          # Arrêter FastAPI"
        echo "[taranis][help]   $0 clean all             # Nettoyer tous les services"
        echo "[taranis][help]"
        echo "[taranis][help] === DÉMARRAGE INDIVIDUEL AVEC TEINE_ENGINE ==="
        echo "[taranis][help]   ${TEINE_ENGINE_SCRIPT} start ${CROMLECH_DIR}/mariadb"
        echo "[taranis][help]   ${TEINE_ENGINE_SCRIPT} start ${MUIRDRIS_DIR}/fastapi"
        echo "[taranis][help]   ${TEINE_ENGINE_SCRIPT} start ${MUIRDRIS_DIR}/llama"
        echo "[taranis][help]   ${TEINE_ENGINE_SCRIPT} start ${MUIRDRIS_DIR}/qwen25-05b"
        echo "[taranis][help]   ${TEINE_ENGINE_SCRIPT} start ${FIANNA_DIR}/adminer"
        echo "[taranis][help]   ${TEINE_ENGINE_SCRIPT} start ${FIANNA_DIR}/n8n"
        echo "[taranis][help]   ${TEINE_ENGINE_SCRIPT} start ${GEASA_DIR}/yarn"
        ;;
esac
