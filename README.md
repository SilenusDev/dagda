# Dagda-Lite 

Orchestrateur ultra-léger de containers Podman avec gestion multi-environnements (dev/prod).

## Structure

- **dagda/** - Moteur d'orchestration
  - `taranis.sh` - Orchestrateur principal + sélection env
  - `switch-env.sh` - Basculement dev/prod
- **cauldron/** - Services (MariaDB, FastAPI, Llama, Qwen, Adminer, N8N)
- **sidhe/** - Interface SolidJS

## Démarrage rapide

```bash
# Démarrer (sélection interactive dev/prod)
./dagda/eveil/taranis.sh dagda

# Arrêter
./dagda/eveil/taranis.sh stop all
```

## Commandes

```bash
# Services
./dagda/eveil/taranis.sh dagda           # Démarrer essentiels
./dagda/eveil/taranis.sh mariadb|fastapi|llama|qwen|adminer|n8n
./dagda/eveil/taranis.sh stop all
./dagda/eveil/taranis.sh status all

# Environnements
./dagda/eveil/switch-env.sh dev|prod     # Forcer env
./dagda/eveil/switch-env.sh status       # Voir env actuel
```

## Ports

| Service | Port |
|---------|------|
| MariaDB | 8901 |
| FastAPI | 8902 |
| Adminer | 8903 |
| Llama   | 8905 |
| Qwen    | 8906 |
| Yarn    | 8907 |
| Vite    | 8900 |

## Documentation

- `/docs/env.md` - Gestion environnements dev/prod
- `/docs/architecture.md` - Architecture détaillée
- `/docs/Projet.md` - Vue d'ensemble 
