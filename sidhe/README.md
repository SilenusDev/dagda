# Sidhe - Interface DAGDA-LITE

Interface utilisateur moderne pour DAGDA-LITE construite avec SolidJS.

## 🎨 Stack Technique

- **Framework**: SolidJS
- **Build Tool**: Vite
- **Styling**: TailwindCSS 4.x
- **Composants UI**: Kobalte Core
- **Icônes**: Lucide Solid
- **Router**: @solidjs/router

## 📦 Installation

Les dépendances sont installées automatiquement au démarrage du conteneur Sidhe.

Pour installer manuellement :
```bash
podman exec dagda-lite-sidhe-pod-dagda-lite-sidhe sh -c "cd /app && yarn install"
```

## 🚀 Démarrage

L'interface démarre automatiquement avec les services essentiels :
```bash
./dagda/eveil/taranis.sh dagda
```

Accès : http://localhost:8900

## 📁 Structure

```
sidhe/
├── public/              # Assets statiques
│   └── img/            # Images (logos, favicons)
├── src/
│   ├── assets/         # Assets optimisés
│   │   └── img/       # Images optimisées par Vite
│   ├── components/     # Composants réutilisables
│   │   ├── Button.tsx # Bouton avec variants
│   │   └── Card.tsx   # Carte de contenu
│   ├── pages/          # Pages de l'application
│   ├── services/       # Clients API
│   ├── App.tsx         # Composant principal
│   ├── index.tsx       # Point d'entrée
│   └── index.css       # Styles globaux + TailwindCSS
├── tailwind.config.js  # Configuration TailwindCSS
├── postcss.config.js   # Configuration PostCSS
└── vite.config.ts      # Configuration Vite
```

## 🎨 Utilisation TailwindCSS

### Classes utilitaires
```tsx
<div class="bg-primary-500 text-white p-4 rounded-lg">
  Contenu
</div>
```

### Composants personnalisés
```tsx
import Button from './components/Button';

<Button variant="primary" size="md">
  Cliquez ici
</Button>
```

## 🎭 Icônes Lucide

```tsx
import { Server, Activity, Database } from 'lucide-solid';

<Server class="w-6 h-6 text-primary-500" />
```

## 🧩 Composants Kobalte

Pour les composants complexes (modals, dropdowns, tooltips, etc.) :
```tsx
import { Dialog } from '@kobalte/core';

// Voir documentation : https://kobalte.dev/docs/core/overview/introduction
```

## 🎨 Thème

Couleurs personnalisées définies dans `tailwind.config.js` :
- **Primary**: Violet (#667eea)
- **Success**: Vert
- **Warning**: Orange
- **Error**: Rouge
- **Info**: Bleu

## 📝 Variables d'environnement

Configurées automatiquement via `.env` :
- `VITE_HOST` : Adresse du serveur
- `VITE_API_PORT` : Port FastAPI (8902)
- `VITE_ADMIN_PORT` : Port Adminer (8903)
- `VITE_WORKFLOW_PORT` : Port N8N (8904)

Accès dans le code :
```tsx
const apiUrl = `http://${import.meta.env.VITE_HOST}:${import.meta.env.VITE_API_PORT}`;
```

## 🔧 Développement

### Hot Module Replacement (HMR)
Le HMR est activé automatiquement en mode développement.

### Build de production
```bash
podman exec dagda-lite-sidhe-pod-dagda-lite-sidhe sh -c "cd /app && yarn build"
```

Le build sera généré dans `/sidhe/dist/` et servi par FastAPI.

## 📚 Ressources

- [SolidJS](https://www.solidjs.com/)
- [TailwindCSS](https://tailwindcss.com/)
- [Kobalte](https://kobalte.dev/)
- [Lucide](https://lucide.dev/)
- [Vite](https://vitejs.dev/)
