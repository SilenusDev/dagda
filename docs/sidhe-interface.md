# Interface Sidhe - SolidJS

## D\u00e9marrage

```bash
# D\u00e9marrer l'interface
./dagda/eveil/taranis.sh sidhe

# Acc\u00e9der
# Dev: http://localhost:8900
# Prod: http://192.168.1.43:8900
```

## Architecture

```
sidhe/                      # Code source (racine projet)
\u251c\u2500\u2500 src/
\u2502   \u251c\u2500\u2500 App.tsx             # Application principale
\u2502   \u251c\u2500\u2500 config.ts           # Configuration (variables env)
\u2502   \u2514\u2500\u2500 pages/Home.tsx      # Page d'accueil
\u251c\u2500\u2500 package.json
\u2514\u2500\u2500 vite.config.ts

cauldron/ogmios/sidhe/      # Pod Podman
\u251c\u2500\u2500 pod.yml                 # Configuration conteneur
\u2514\u2500\u2500 manage.sh               # Script de gestion
```

## Configuration

### Variables d'environnement

Le pod Sidhe injecte automatiquement :
- `VITE_HOST` - localhost (dev) ou IP (prod)
- `VITE_API_PORT` - Port FastAPI (8902)
- `VITE_ADMIN_PORT` - Port Adminer (8903)
- `VITE_WORKFLOW_PORT` - Port N8N (8904)

### Fichier config.ts

```typescript
const HOST = import.meta.env.VITE_HOST || 'localhost';
const API_PORT = import.meta.env.VITE_API_PORT || '8902';

export const config = {
  apiUrl: `http://${HOST}:${API_PORT}`,
  adminerUrl: `http://${HOST}:8903`,
  // ...
};
```

## D\u00e9veloppement

### Modifier le code

Le code source est dans `/sidhe` \u00e0 la racine du projet.
Les modifications sont hot-reload\u00e9es automatiquement par Vite.

### Arr\u00eater/Red\u00e9marrer

```bash
./dagda/eveil/taranis.sh stop sidhe
./dagda/eveil/taranis.sh sidhe
```

### Logs

```bash
podman logs dagda-lite-sidhe-pod-dagda-lite-sidhe
```

## Fonctionnalit\u00e9s

- Interface responsive SolidJS
- Configuration multi-environnements (dev/prod)
- Hot Module Replacement (HMR)
- Liens vers tous les services (Adminer, FastAPI, N8N)
- Affichage de l'\u00e9tat du syst\u00e8me

## Technologies

- **SolidJS** 1.8 - Framework r\u00e9actif
- **Vite** 5.0 - Build tool
- **TypeScript** 5.0
- **@solidjs/router** 0.10 - Routing
