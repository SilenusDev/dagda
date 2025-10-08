# SIDHE - Interface DAGDA-LITE

**Stack ULTRA-LIGHT**: SolidJS + CSS Vanilla + Lucide  
**Port**: 8900  
**Statut**: ✅ Opérationnel

---

## 🚀 Installation

```bash
# 1. Démarrer les services
./dagda/eveil/taranis.sh dagda

# 2. Installer Sidhe
./dagda/eveil/setup-sidhe.sh

# 3. Redémarrer Sidhe
source .env && ${TEINE_ENGINE_SCRIPT} stop ${DAGDA_ROOT}/cauldron/ogmios/sidhe
source .env && ${TEINE_ENGINE_SCRIPT} start ${DAGDA_ROOT}/cauldron/ogmios/sidhe
```

**Interface accessible**: http://localhost:8900

---

## 📦 Stack technique

| Composant | Version | Poids |
|-----------|---------|-------|
| SolidJS | 1.8.0 | ~7KB |
| @solidjs/router | 0.10.0 | ~3KB |
| Lucide Solid | 0.545.0 | ~50KB |
| CSS Vanilla | Custom | 280 lignes |

**Total**: ~60KB (ultra-léger)

---

## 📁 Structure

```
sidhe/                          # Code source (racine)
├── src/
│   ├── assets/img/            # Images optimisées par Vite
│   ├── components/            # Composants réutilisables
│   ├── pages/                 # Pages (Home.tsx, etc.)
│   ├── services/              # Clients API
│   ├── App.tsx                # Application principale
│   ├── index.tsx              # Point d'entrée
│   ├── index.css              # CSS vanilla (280 lignes)
│   └── config.ts              # Configuration
├── public/img/                # Images statiques
├── vite.config.ts             # Config Vite (polling)
└── package.json

cauldron/ogmios/sidhe/         # Pod configuration
├── pod.yml                    # Configuration Podman
└── manage.sh                  # Script de gestion
```

---

## 🎨 Utilisation

### Images

**Statiques** (logos, favicons):
```tsx
// Placer dans: sidhe/public/img/
<img src="/img/logo.svg" alt="Logo" />
```

**Optimisées** (photos, illustrations):
```tsx
// Placer dans: sidhe/src/assets/img/
import hero from './assets/img/hero.jpg';
<img src={hero} alt="Hero" />
```

### Icônes Lucide

```tsx
import { Server, Database, Activity } from 'lucide-solid';

<Server size={32} color="var(--color-primary)" />
<Database size={24} color="#48bb78" />
```

### Classes CSS

```tsx
// Utiliser les classes définies dans index.css
<div class="card">
  <h3 class="card-title">Titre</h3>
  <p class="card-content">Contenu</p>
  <a href="#" class="btn btn-primary">Action</a>
</div>

<div class="grid lg:grid-cols-4 md:grid-cols-2 grid-cols-1">
  {/* Contenu responsive */}
</div>
```

### Variables CSS

```css
/* Définies dans index.css */
var(--color-primary)      /* #667eea */
var(--color-primary-dark) /* #5a67d8 */
var(--color-success)      /* #48bb78 */
var(--color-warning)      /* #ed8936 */
var(--color-error)        /* #f56565 */
var(--shadow-md)          /* Ombre carte */
var(--radius)             /* 8px */
```

---

## 🔧 Développement

### Commandes

```bash
# Voir les logs
podman logs --tail 50 dagda-lite-sidhe-pod-dagda-lite-sidhe

# Suivre en temps réel
podman logs -f dagda-lite-sidhe-pod-dagda-lite-sidhe

# Accéder au conteneur
podman exec -it dagda-lite-sidhe-pod-dagda-lite-sidhe sh

# Réinstaller les dépendances
podman exec dagda-lite-sidhe-pod-dagda-lite-sidhe sh -c "cd /app && yarn install"
```

### Hot Module Replacement (HMR)

Le HMR est actif :
- Modifiez un fichier dans `/sidhe/src/`
- Vite détecte et recharge automatiquement
- Pas besoin de redémarrer

---

## 🐛 Dépannage

### Interface ne charge pas

```bash
# 1. Vérifier que Sidhe est actif
./dagda/eveil/taranis.sh status dagda

# 2. Voir les logs
podman logs --tail 100 dagda-lite-sidhe-pod-dagda-lite-sidhe

# 3. Redémarrer
source .env && ${TEINE_ENGINE_SCRIPT} stop ${DAGDA_ROOT}/cauldron/ogmios/sidhe
source .env && ${TEINE_ENGINE_SCRIPT} start ${DAGDA_ROOT}/cauldron/ogmios/sidhe
```

### Erreur EMFILE (too many open files)

✅ **Résolu** - Vite configuré avec polling dans `vite.config.ts`:
```typescript
watch: {
  usePolling: true,
  interval: 1000,
  ignored: ['**/node_modules/**', '**/.git/**']
}
```

### Styles CSS ne s'appliquent pas

```bash
# Vérifier que index.css est importé
grep "import './index.css'" sidhe/src/index.tsx

# Redémarrer Sidhe
source .env && ${TEINE_ENGINE_SCRIPT} stop ${DAGDA_ROOT}/cauldron/ogmios/sidhe
source .env && ${TEINE_ENGINE_SCRIPT} start ${DAGDA_ROOT}/cauldron/ogmios/sidhe
```

---

## 📚 Classes CSS disponibles

### Layout
- `.container` - Conteneur centré max-width 1280px
- `.grid` - Grid layout
- `.grid-cols-{1-4}` - Colonnes (responsive avec md:, lg:)

### Composants
- `.card` - Carte avec ombre
- `.card-title` - Titre de carte
- `.card-header` - En-tête avec icône
- `.card-content` - Contenu de carte

### Boutons
- `.btn` - Bouton de base
- `.btn-primary` - Bouton principal (violet)
- `.btn-secondary` - Bouton secondaire (gris)

### Statut
- `.status-indicator` - Indicateur avec point
- `.status-dot` - Point animé (pulse)

### Utilities
- `.text-center` - Texte centré
- `.text-primary` - Couleur primaire
- `.flex`, `.flex-col` - Flexbox
- `.items-center` - Alignement vertical
- `.gap-{1-3}` - Espacement
- `.mb-{4,6}` - Margin bottom
- `.py-8` - Padding vertical

---

## 🎯 Prochaines étapes

1. **Créer des pages** dans `/sidhe/src/pages/`
2. **Ajouter des composants** dans `/sidhe/src/components/`
3. **Intégrer l'API** via `/sidhe/src/services/`
4. **Ajouter vos images** dans `/sidhe/public/img/` ou `/sidhe/src/assets/img/`
