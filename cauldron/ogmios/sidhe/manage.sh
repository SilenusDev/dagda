#!/bin/bash
# cauldron/ogmios/sidhe/manage.sh
# Script de gestion du service Sidhe

SERVICE_NAME="sidhe"
POD_NAME="dagda-lite-sidhe-pod"

case "$1" in
    start)
        echo "Démarrage de Sidhe..."
        podman play kube pod.yml
        ;;
    stop)
        echo "Arrêt de Sidhe..."
        podman pod stop "$POD_NAME"
        ;;
    restart)
        $0 stop
        sleep 2
        $0 start
        ;;
    status)
        podman pod ps --filter name="$POD_NAME"
        ;;
    logs)
        podman logs "$POD_NAME-$SERVICE_NAME"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        exit 1
        ;;
esac
