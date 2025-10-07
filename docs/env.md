# Environnements Dev/Prod

## Démarrage

```bash
./dagda/eveil/taranis.sh dagda
# Choisir: 1) dev (localhost) ou 2) prod (IP serveur)
```

## Fichiers

- `.env` - Actif (auto-généré)
- `.env.dev` - Config localhost
- `.env.prod` - Config IP serveur

## Différences

| Paramètre | Dev | Prod |
|-----------|-----|------|
| HOST | localhost | 192.168.1.43 |
| FASTAPI_WORKERS | 2 | 4 |
| DB_NAME | *_dev | production |

## Commandes

```bash
# Changer d'environnement
./dagda/eveil/taranis.sh stop all
./dagda/eveil/taranis.sh dagda

# Forcer un environnement
./dagda/eveil/switch-env.sh dev|prod

# Voir environnement actuel
./dagda/eveil/switch-env.sh status
```

## Personnaliser

Modifier `.env.dev` ou `.env.prod` (jamais `.env` directement)
