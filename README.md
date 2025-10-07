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
# Services essentiels
./dagda/eveil/taranis.sh dagda           # MariaDB + FastAPI + Yarn

# Services individuels
./dagda/eveil/taranis.sh sidhe           # Interface SolidJS
./dagda/eveil/taranis.sh mariadb|fastapi|llama|qwen|adminer|n8n

# Gestion
./dagda/eveil/taranis.sh stop all
./dagda/eveil/taranis.sh status all

# Environnements (dev/prod)
./dagda/eveil/switch-env.sh dev|prod
./dagda/eveil/switch-env.sh status
```

## Ports

| Service | Port | URL |
|---------|------|-----|
| Sidhe (Vite) | 8900 | http://localhost:8900 |
| MariaDB | 8901 | - |
| FastAPI | 8902 | http://localhost:8902/docs |
| Adminer | 8903 | http://localhost:8903 |
| Llama   | 8905 | http://localhost:8905 |
| Qwen    | 8906 | http://localhost:8906 |
| Yarn    | 8907 | - |

## Documentation

- `/docs/env.md` - Gestion environnements dev/prod
- `/docs/sidhe-interface.md` - Interface SolidJS
- `/docs/architecture.md` - Architecture détaillée
- `/docs/Projet.md` - Vue d'ensemble
