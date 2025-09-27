#!/bin/bash
# dagda/eveil/lug.sh
# Script principal d'orchestration Dagda-Lite

SCRIPT_NAME="lug"

# Chargement des variables d'environnement (SÉCURISÉ)
if [ -z "$DAGDA_ROOT" ]; then
    echo "[lug][error] Variable DAGDA_ROOT non définie" >&2
    echo "[lug][error] Assurez-vous que DAGDA_ROOT est défini et que vous avez sourcé le .env" >&2
    exit 1
fi

if [ ! -f "${DAGDA_ROOT}/.env" ]; then
    echo "[lug][error] Fichier .env non trouvé dans ${DAGDA_ROOT}" >&2
    exit 1
fi

source "${DAGDA_ROOT}/.env"

# Charger les utilitaires (SÉCURISÉ)
source "${OLLAMH_SCRIPT}" || { echo "[lug][error] ollamh.sh non trouvé"; exit 1; }

echo "[lug][start] Démarrage de l'orchestrateur Dagda-Lite"

case "$1" in
    dagda)
        echo "[lug][info] Démarrage des services essentiels DAGDA-LITE"
        echo "[lug][step] Démarrage de MariaDB..."
        "${TEINE_ENGINE_SCRIPT}" start "${CROMLECH_DIR}/mariadb"
        mariadb_status=$?
        
        echo "[lug][step] Démarrage de FastAPI..."
        "${TEINE_ENGINE_SCRIPT}" start "${MUIRDRIS_DIR}/fastapi"
        fastapi_status=$?
        
        echo "[lug][step] Démarrage de Yarn (environnement SolidJS)..."
        "${TEINE_ENGINE_SCRIPT}" start "${GEASA_DIR}/yarn"
        yarn_status=$?
        
        if [ $mariadb_status -eq 0 ] && [ $fastapi_status -eq 0 ] && [ $yarn_status -eq 0 ]; then
            echo "[lug][success] Services essentiels DAGDA-LITE démarrés avec succès"
            echo "[lug][info] MariaDB: | FastAPI: | Yarn: "
        else
            echo "[lug][error] Échec du démarrage de certains services essentiels"
            echo "[lug][info] MariaDB: $([ $mariadb_status -eq 0 ] && echo "" || echo "")"
            echo "[lug][info] FastAPI: $([ $fastapi_status -eq 0 ] && echo "" || echo "")"
            echo "[lug][info] Yarn: $([ $yarn_status -eq 0 ] && echo "" || echo "")"
            exit 1
        fi
        ;;
    mariadb)
        echo "[lug][info] Démarrage de MariaDB"
        "${TEINE_ENGINE_SCRIPT}" start "${CROMLECH_DIR}/mariadb"
        ;;
    fastapi)
        echo "[lug][info] Démarrage de FastAPI"
        "${TEINE_ENGINE_SCRIPT}" start "${MUIRDRIS_DIR}/fastapi"
        ;;
    llama)
        echo "[lug][info] Démarrage de Llama"
        "${TEINE_ENGINE_SCRIPT}" start "${MUIRDRIS_DIR}/llama"
        ;;
    qwen)
        echo "[lug][info] Démarrage de Qwen"
        "${TEINE_ENGINE_SCRIPT}" start "${MUIRDRIS_DIR}/qwen25-05b"
        ;;
    adminer)
        echo "[lug][info] Démarrage d'Adminer"
        "${TEINE_ENGINE_SCRIPT}" start "${FIANNA_DIR}/adminer"
        ;;
    n8n)
        echo "[lug][info] Démarrage de N8N"
        "${TEINE_ENGINE_SCRIPT}" start "${FIANNA_DIR}/n8n"
        ;;
    yarn)
        echo "[lug][info] Démarrage de Yarn"
        "${TEINE_ENGINE_SCRIPT}" start "${GEASA_DIR}/yarn"
        ;;
    stop)
        case "$2" in
            mariadb)
                echo "[lug][info] Arrêt de MariaDB"
                "${TEINE_ENGINE_SCRIPT}" stop "${CROMLECH_DIR}/mariadb"
                ;;
            fastapi)
                echo "[lug][info] Arrêt de FastAPI"
                "${TEINE_ENGINE_SCRIPT}" stop "${MUIRDRIS_DIR}/fastapi"
                ;;
            llama)
                echo "[lug][info] Arrêt de Llama"
                "${TEINE_ENGINE_SCRIPT}" stop "${MUIRDRIS_DIR}/llama"
                ;;
            qwen)
                echo "[lug][info] Arrêt de Qwen"
                "${TEINE_ENGINE_SCRIPT}" stop "${MUIRDRIS_DIR}/qwen25-05b"
                ;;
            adminer)
                echo "[lug][info] Arrêt d'Adminer"
                "${TEINE_ENGINE_SCRIPT}" stop "${FIANNA_DIR}/adminer"
                ;;
            n8n)
                echo "[lug][info] Arrêt de N8N"
                "${TEINE_ENGINE_SCRIPT}" stop "${FIANNA_DIR}/n8n"
                ;;
            yarn)
                echo "[lug][info] Arrêt de Yarn"
                "${TEINE_ENGINE_SCRIPT}" stop "${GEASA_DIR}/yarn"
                ;;
            dagda)
                echo "[lug][info] Arrêt des services essentiels DAGDA-LITE"
                "${TEINE_ENGINE_SCRIPT}" stop "${GEASA_DIR}/yarn" 2>/dev/null || true
                "${TEINE_ENGINE_SCRIPT}" stop "${MUIRDRIS_DIR}/fastapi" 2>/dev/null || true
                "${TEINE_ENGINE_SCRIPT}" stop "${CROMLECH_DIR}/mariadb" 2>/dev/null || true
                echo "[lug][success] Services essentiels DAGDA-LITE arrêtés"
                ;;
            all)
                echo "[lug][info] Arrêt de tous les services Dagda-Lite"
                echo "[lug][step] Arrêt des environnements..."
                "${TEINE_ENGINE_SCRIPT}" stop "${GEASA_DIR}/yarn" 2>/dev/null || true
                echo "[lug][step] Arrêt des applications..."
                "${TEINE_ENGINE_SCRIPT}" stop "${FIANNA_DIR}/n8n" 2>/dev/null || true
                "${TEINE_ENGINE_SCRIPT}" stop "${FIANNA_DIR}/adminer" 2>/dev/null || true
                echo "[lug][step] Arrêt de l'écosystème Python..."
                "${TEINE_ENGINE_SCRIPT}" stop "${MUIRDRIS_DIR}/qwen25-05b" 2>/dev/null || true
                "${TEINE_ENGINE_SCRIPT}" stop "${MUIRDRIS_DIR}/llama" 2>/dev/null || true
                "${TEINE_ENGINE_SCRIPT}" stop "${MUIRDRIS_DIR}/fastapi" 2>/dev/null || true
                echo "[lug][step] Arrêt des services essentiels..."
                "${TEINE_ENGINE_SCRIPT}" stop "${CROMLECH_DIR}/mariadb" 2>/dev/null || true
                echo "[lug][success] Tous les services Dagda-Lite arrêtés"
                ;;
            *)
                echo "[lug][error] Usage: $0 stop {mariadb|fastapi|llama|qwen|adminer|n8n|yarn|dagda|all}"
                exit 1
                ;;
        esac
        ;;
    status)
        case "$2" in
            mariadb)
                echo "[lug][info] Statut de MariaDB"
                "${TEINE_ENGINE_SCRIPT}" status "${CROMLECH_DIR}/mariadb"
                ;;
            fastapi)
                echo "[lug][info] Statut de FastAPI"
                "${TEINE_ENGINE_SCRIPT}" status "${MUIRDRIS_DIR}/fastapi"
                ;;
            llama)
                echo "[lug][info] Statut de Llama"
                "${TEINE_ENGINE_SCRIPT}" status "${MUIRDRIS_DIR}/llama"
                ;;
            qwen)
                echo "[lug][info] Statut de Qwen"
                "${TEINE_ENGINE_SCRIPT}" status "${MUIRDRIS_DIR}/qwen25-05b"
                ;;
            adminer)
                echo "[lug][info] Statut d'Adminer"
                "${TEINE_ENGINE_SCRIPT}" status "${FIANNA_DIR}/adminer"
                ;;
            n8n)
                echo "[lug][info] Statut de N8N"
                "${TEINE_ENGINE_SCRIPT}" status "${FIANNA_DIR}/n8n"
                ;;
            yarn)
                echo "[lug][info] Statut de Yarn"
                "${TEINE_ENGINE_SCRIPT}" status "${GEASA_DIR}/yarn"
                ;;
            dagda)
                echo "[lug][info] Statut des services essentiels DAGDA-LITE"
                echo "[lug][step] MariaDB:"
                "${TEINE_ENGINE_SCRIPT}" status "${CROMLECH_DIR}/mariadb" 2>/dev/null || echo "[lug][warning] MariaDB non disponible"
                echo "[lug][step] FastAPI:"
                "${TEINE_ENGINE_SCRIPT}" status "${MUIRDRIS_DIR}/fastapi" 2>/dev/null || echo "[lug][warning] FastAPI non disponible"
                echo "[lug][step] Yarn:"
                "${TEINE_ENGINE_SCRIPT}" status "${GEASA_DIR}/yarn" 2>/dev/null || echo "[lug][warning] Yarn non disponible"
                ;;
            all|"")
                echo "[lug][info] Statut global de tous les services Dagda-Lite"
                echo "[lug][step] === SERVICES ESSENTIELS (DAGDA) ==="
                echo "[lug][step] MariaDB:"
                "${TEINE_ENGINE_SCRIPT}" status "${CROMLECH_DIR}/mariadb" 2>/dev/null || echo "[lug][warning] MariaDB non disponible"
                echo "[lug][step] FastAPI:"
                "${TEINE_ENGINE_SCRIPT}" status "${MUIRDRIS_DIR}/fastapi" 2>/dev/null || echo "[lug][warning] FastAPI non disponible"
                echo "[lug][step] Yarn:"
                "${TEINE_ENGINE_SCRIPT}" status "${GEASA_DIR}/yarn" 2>/dev/null || echo "[lug][warning] Yarn non disponible"
                echo "[lug][step] === SERVICES OPTIONNELS ==="
                echo "[lug][step] Llama:"
                "${TEINE_ENGINE_SCRIPT}" status "${MUIRDRIS_DIR}/llama" 2>/dev/null || echo "[lug][warning] Llama non disponible"
                echo "[lug][step] Qwen:"
                "${TEINE_ENGINE_SCRIPT}" status "${MUIRDRIS_DIR}/qwen25-05b" 2>/dev/null || echo "[lug][warning] Qwen non disponible"
                echo "[lug][step] Adminer:"
                "${TEINE_ENGINE_SCRIPT}" status "${FIANNA_DIR}/adminer" 2>/dev/null || echo "[lug][warning] Adminer non disponible"
                echo "[lug][step] N8N:"
                "${TEINE_ENGINE_SCRIPT}" status "${FIANNA_DIR}/n8n" 2>/dev/null || echo "[lug][warning] N8N non disponible"
                ;;
            *)
                echo "[lug][error] Usage: $0 status {mariadb|fastapi|llama|qwen|adminer|n8n|yarn|dagda|all|''}"
                exit 1
                ;;
        esac
        ;;
    *)
        echo "[lug][help] Usage: $0 {COMMAND} [OPTIONS]"
        echo "[lug][help]"
        echo "[lug][help] === SERVICES ESSENTIELS ==="
        echo "[lug][help]   dagda                    - Démarrer les 3 services essentiels (mariadb, fastapi, yarn)"
        echo "[lug][help]   stop dagda               - Arrêter les services essentiels"
        echo "[lug][help]   status dagda             - Statut des services essentiels"
        echo "[lug][help]"
        echo "[lug][help] === SERVICES INDIVIDUELS ==="
        echo "[lug][help]   mariadb                  - Démarrer MariaDB (base de données)"
        echo "[lug][help]   fastapi                  - Démarrer FastAPI (API + interface web)"
        echo "[lug][help]   yarn                     - Démarrer Yarn (environnement SolidJS)"
        echo "[lug][help]   llama                    - Démarrer Llama (modèle LLM)"
        echo "[lug][help]   qwen                     - Démarrer Qwen (modèle LLM)"
        echo "[lug][help]   adminer                  - Démarrer Adminer (interface DB)"
        echo "[lug][help]   n8n                      - Démarrer N8N (workflows)"
        echo "[lug][help]"
        echo "[lug][help] === COMMANDES GLOBALES ==="
        echo "[lug][help]   stop {service|all}       - Arrêter un service ou tous"
        echo "[lug][help]   status {service|all}     - Statut d'un service ou tous"
        echo "[lug][help]"
        echo "[lug][help] === EXEMPLES ==="
        echo "[lug][help]   $0 dagda                 # Démarrer les services essentiels"
        echo "[lug][help]   $0 llama                 # Démarrer Llama individuellement"
        echo "[lug][help]   $0 status all            # Voir le statut de tous les services"
        echo "[lug][help]   $0 stop fastapi          # Arrêter FastAPI"
        echo "[lug][help]"
        echo "[lug][help] === DÉMARRAGE INDIVIDUEL AVEC TEINE_ENGINE ==="
        echo "[lug][help]   ${TEINE_ENGINE_SCRIPT} start ${CROMLECH_DIR}/mariadb"
        echo "[lug][help]   ${TEINE_ENGINE_SCRIPT} start ${MUIRDRIS_DIR}/fastapi"
        echo "[lug][help]   ${TEINE_ENGINE_SCRIPT} start ${MUIRDRIS_DIR}/llama"
        echo "[lug][help]   ${TEINE_ENGINE_SCRIPT} start ${MUIRDRIS_DIR}/qwen25-05b"
        echo "[lug][help]   ${TEINE_ENGINE_SCRIPT} start ${FIANNA_DIR}/adminer"
        echo "[lug][help]   ${TEINE_ENGINE_SCRIPT} start ${FIANNA_DIR}/n8n"
        echo "[lug][help]   ${TEINE_ENGINE_SCRIPT} start ${GEASA_DIR}/yarn"
        ;;
esac
