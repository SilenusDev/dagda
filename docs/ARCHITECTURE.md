# DAGDA-LITE - Architecture

**Version**: 2.3 - Faeries  
**Statut**: Production  
**Mise à jour**: 8 octobre 2025

---

## ⚠️ RÈGLE : 1 service = 1 emplacement

### ❌ INTERDICTIONS STRICTES

**NE JAMAIS créer ces dossiers** :
- `/cauldron/cromlech/fastapi/` ❌ (FastAPI est dans `/cauldron/muirdris/fastapi/`)
- `/cauldron/cromlech/sidhe/` ❌ (Sidhe pod est dans `/cauldron/ogmios/sidhe/`)

---

## ✅ ARCHITECTURE OFFICIELLE

```
dagda-lite/
├── .env                          # Config active (auto-généré)
├── .env.dev                      # Config développement (localhost)
├── .env.prod                     # Config production (IP serveur)
├── .env.example                  # Template configuration
├── .windsurfrules                # Règles sécurité et diagnostic
│
├── dagda/                        # MOTEUR D'ORCHESTRATION
│   ├── eveil/                    # Scripts d'orchestration
│   │   ├── taranis.sh            # Orchestrateur principal (start/stop/status)
│   │   ├── setup-sidhe.sh        # Installation automatisée Sidhe
│   │   ├── launch-sidhe.sh       # Lancement manuel Sidhe (legacy)
│   │   ├── switch-env.sh         # Basculement dev/prod
│   │   └── stop_all.sh           # Arrêt d'urgence
│   ├── awen-core/                # Moteur principal
│   │   └── teine_engine.sh       # Moteur générique pods (start/stop/clean)
│   ├── awens-utils/              # Utilitaires bash
│   │   ├── ollamh.sh             # Fonctions communes + détection architecture
│   │   └── imbas-logging.sh      # Système de logs standardisé
│   └── bairille-dighe/           # Templates configuration
│       └── coire-template.yml    # Template pod générique
│
├── cauldron/                     # SERVICES CONTENEURISÉS
│   │
│   ├── cromlech/                 # BASES DE DONNÉES UNIQUEMENT
│   │   ├── mariadb/              # ✅ MariaDB (port 8901)
│   │   │   ├── pod.yml           # Config Podman
│   │   │   ├── manage.sh         # Script gestion
│   │   │   ├── data/             # Données MariaDB
│   │   │   ├── config/           # Configuration MariaDB
│   │   │   └── init/             # Scripts d'initialisation SQL
│   │   │
│   │   └── yarn/                 # ✅ Gestionnaire Node.js (port 8907)
│   │       ├── pod.yml           # Config Podman
│   │       ├── data/             # Cache Yarn
│   │       └── config/           # Configuration Yarn
│   │
│   ├── muirdris/                 # SERVICES PYTHON
│   │   ├── fastapi/              # ✅ API principale (port 8902) - SEUL EMPLACEMENT
│   │   │   ├── pod.yml           # Config Podman
│   │   │   ├── manage.sh         # Script gestion
│   │   │   ├── Dockerfile        # Image personnalisée
│   │   │   ├── app/              # Code application
│   │   │   │   ├── main.py       # Point d'entrée FastAPI
│   │   │   │   ├── api/          # Endpoints API
│   │   │   │   │   ├── llm.py    # Routes LLM
│   │   │   │   │   └── system.py # Routes système
│   │   │   │   ├── web/          # Interface web
│   │   │   │   │   ├── static/   # Assets statiques
│   │   │   │   │   └── templates/ # Templates HTML
│   │   │   │   └── models.py     # Modèles Pydantic
│   │   │   ├── requirements.txt  # Dépendances Python
│   │   │   ├── data/             # Données application
│   │   │   └── config/           # Configuration FastAPI
│   │   │
│   │   ├── faeries/              # ✅ Services LLM (IA)
│   │   │   ├── llama/            # LLM Llama (port 8905)
│   │   │   │   ├── pod.yml       # Config Podman
│   │   │   │   ├── manage.sh     # Script gestion
│   │   │   │   ├── data/         # Modèles Llama
│   │   │   │   └── config/       # Configuration Llama
│   │   │   │
│   │   │   └── qwen/             # LLM Qwen2.5 (port 8906)
│   │   │       ├── pod.yml       # Config Podman
│   │   │       ├── manage.sh     # Script gestion
│   │   │       ├── data/         # Modèles Qwen
│   │   │       └── config/       # Configuration Qwen
│   │   │
│   │   └── specs.md              # Spécifications Muirdris
│   │
│   ├── ogmios/                   # INTERFACES UTILISATEUR
│   │   ├── sidhe/                # ✅ Interface SolidJS (port 8900) - SEUL POD
│   │   │   ├── pod.yml           # Config Podman
│   │   │   └── manage.sh         # Script gestion
│   │   │
│   │   └── dolmen/               # Monitoring
│   │       ├── pod.yml           # Config Podman (à implémenter)
│   │       └── manage.sh         # Script gestion (à implémenter)
│   │
│   └── fianna/                   # APPLICATIONS TIERCES
│       ├── adminer/              # Interface DB (port 8903)
│       │   ├── pod.yml           # Config Podman
│       │   ├── manage.sh         # Script gestion
│       │   └── data/             # Données Adminer
│       │
│       └── n8n/                  # Workflows (port 8904)
│           ├── pod.yml           # Config Podman
│           ├── manage.sh         # Script gestion
│           └── data/             # Données N8N
│
├── sidhe/                        # CODE SOURCE SolidJS (pas de pod ici)
│   ├── src/                      # Code source
│   │   ├── assets/               # Assets optimisés
│   │   │   └── img/              # Images optimisées par Vite
│   │   ├── components/           # Composants réutilisables
│   │   ├── pages/                # Pages application
│   │   │   └── Home.tsx          # Page d'accueil
│   │   ├── services/             # Clients API (vers FastAPI)
│   │   ├── App.tsx               # Application principale
│   │   ├── index.tsx             # Point d'entrée
│   │   ├── index.css             # CSS vanilla (280 lignes)
│   │   └── config.ts             # Configuration
│   ├── public/                   # Assets statiques
│   │   └── img/                  # Images (logos, favicons)
│   ├── dist/                     # Build production (généré)
│   ├── node_modules/             # Dépendances (généré)
│   ├── package.json              # Dépendances Node.js
│   ├── vite.config.ts            # Config Vite (polling)
│   ├── tsconfig.json             # Config TypeScript
│   └── README.md                 # Documentation Sidhe
│
├── dolmen/                       # MONITORING (legacy - à migrer dans ogmios)
│   └── service_status.json       # État temps réel des services
│
└── docs/                         # DOCUMENTATION
    ├── ARCHITECTURE.md           # Ce fichier - Structure + Règles
    ├── PROJECT.md                # TODO / DOING / DONE
    ├── USAGE.md                  # Commandes essentielles
    ├── SIDHE.md                  # Interface complète
    └── TROUBLESHOOTING.md        # Dépannage
```

---

## 📍 EMPLACEMENTS UNIQUES

### FastAPI
- **Pod** : `/cauldron/muirdris/fastapi/pod.yml`
- **Code** : `/cauldron/muirdris/fastapi/app/`
- **Jamais ailleurs** ❌

### Sidhe
- **Pod** : `/cauldron/ogmios/sidhe/pod.yml`
- **Code source** : `/sidhe/src/`
- **Jamais dans cromlech** ❌

### MariaDB
- **Pod** : `/cauldron/cromlech/mariadb/pod.yml`
- **Seul dans cromlech** ✅

### Yarn
- **Pod** : `/cauldron/cromlech/yarn/pod.yml`
- **Seul dans cromlech** ✅

---

## 🎯 RÈGLES PAR CATÉGORIE

### `cromlech/` - Bases de données
**Contient UNIQUEMENT** :
- ✅ `mariadb/`
- ✅ `yarn/`
- ❌ Rien d'autre

### `muirdris/` - Services Python
**Contient UNIQUEMENT** :
- ✅ `fastapi/` (API principale)
- ✅ `faeries/` (LLM : llama, qwen)
- ❌ Pas d'interfaces

### `ogmios/` - Interfaces utilisateur
**Contient UNIQUEMENT** :
- ✅ `sidhe/` (pod SolidJS)
- ✅ `dolmen/` (monitoring)
- ❌ Pas de services backend

### `fianna/` - Applications tierces
**Contient UNIQUEMENT** :
- ✅ `adminer/`
- ✅ `n8n/`
- ❌ Pas de services custom

---

## 🔍 VÉRIFICATION RAPIDE

### Commandes de vérification
```bash
# Vérifier qu'il n'y a PAS de doublons
ls -la cauldron/cromlech/        # Doit contenir UNIQUEMENT mariadb/ et yarn/
ls -la cauldron/muirdris/fastapi/ # Doit exister (SEUL FastAPI)
ls -la cauldron/ogmios/sidhe/    # Doit exister (SEUL pod Sidhe)

# Ces dossiers NE DOIVENT PAS exister
ls -la cauldron/cromlech/fastapi/ 2>/dev/null && echo "❌ DOUBLON DÉTECTÉ"
ls -la cauldron/cromlech/sidhe/ 2>/dev/null && echo "❌ DOUBLON DÉTECTÉ"
```

---

## 🚨 SI DOUBLONS DÉTECTÉS

### Nettoyage immédiat
```bash
# Supprimer les doublons
rm -rf cauldron/cromlech/fastapi
rm -rf cauldron/cromlech/sidhe

# Vérifier
ls -la cauldron/cromlech/  # Doit montrer UNIQUEMENT mariadb/ et yarn/
```

---

## 📝 HISTORIQUE DES CORRECTIONS

- **8 octobre 2025** : Suppression des doublons `cromlech/fastapi/` et `cromlech/sidhe/`
- **Architecture clarifiée** : Chaque service a UN SEUL emplacement
- **Documentation mise à jour** : `docs/architecture.md` corrigé

---

## ✅ CHECKLIST AVANT TOUTE MODIFICATION

Avant de créer un nouveau dossier dans `cauldron/`, vérifier :

1. ☐ Le service existe-t-il déjà ailleurs ?
2. ☐ Est-ce que je respecte la catégorisation (cromlech/muirdris/ogmios/fianna) ?
3. ☐ Ai-je vérifié qu'il n'y a pas de doublon ?
4. ☐ Ai-je mis à jour `docs/architecture.md` ?

---

## 🎯 RÉSUMÉ ULTRA-SIMPLE

**1 service = 1 emplacement**

- FastAPI → `/cauldron/muirdris/fastapi/`
- Sidhe pod → `/cauldron/ogmios/sidhe/`
- Sidhe code → `/sidhe/`
- MariaDB → `/cauldron/cromlech/mariadb/`
- Yarn → `/cauldron/cromlech/yarn/`

**FIN. Aucune exception.**
