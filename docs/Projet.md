#Dagda-Lite - Présentation Globale du Projet

## Vue d'Ensemble
Dagda-Lite est un orchestrateur ultra-léger de pods Podman conçu pour optimiser l'utilisation des ressources système par allumage/extinction à la demande des services. Inspiré de la mythologie celtique, le projet tire son nom du dieu Dagda et de son chaudron magique d'abondance.

**Version actuelle :** 2.3 - Architecture Faeries (IA)
**Statut :** Opérationnel (100% fonctionnel)
**Dernière mise à jour :** 7 octobre 2025

## Positionnement Produit
**Orchestrateur de développement avec IA intégrée et méthodologie diagnostic**
- Alternative légère à Kubernetes pour environnements de développement
- Économie de ressources CPU/RAM par démarrage à la demande
- Interface utilisateur moderne et intuitive
- Intégration native d'IA (Llama, Qwen) pour assistance au développement
- **NOUVEAU** : Règles diagnostic et méthodologie pour éviter les erreurs opérationnelles

## Architecture Technique

### Stack Technologique Core
- **Frontend** : SolidJS (~7KB gzippé) - Interface réactive ultra-légère
- **Backend** : FastAPI - API REST moderne avec intégration LLM
- **Base de données** : MariaDB - Base de données relationnelle robuste
- **Conteneurisation** : Podman - Gestion des pods rootless
- **Logs** : Système de logging standardisé centralisé
- **Diagnostic** : Règles méthodologiques intégrées (.windsurfrules)

### Structure du Projet (Architecture Moderne)
```
dagda-lite/
├── .env                            # Configuration active (auto-généré)
├── .env.dev                        # Config développement (localhost)
├── .env.prod                       # Config production (IP serveur)
├── dagda/                          # MOTEUR D'ORCHESTRATION 🎯
│   ├── eveil/                      # Scripts d'orchestration
│   │   ├── taranis.sh             # Orchestrateur + sélection env interactive
│   │   ├── switch-env.sh          # Basculement dev/prod
│   │   ├── launch-sidhe.sh        # Lancement interface SolidJS
│   │   └── stop_all.sh            # Arrêt global des services
│   ├── awen-core/                  # Moteur principal
│   │   └── teine_engine.sh         # Moteur générique pods
│   ├── awens-utils/                # Utilitaires communs
│   │   ├── ollamh.sh               # Fonctions communes
│   │   └── imbas-logging.sh        # Système de logs
│   └── bairille-dighe/             # Templates configuration
├── cauldron/                       # SERVICES CONTENEURISÉS 🔥
│   ├── cromlech/                   # Bases de données
│   │   ├── mariadb/               # Base de données MariaDB
│   │   └── yarn/                  # Environnement Node.js/SolidJS
│   ├── muirdris/                  # Système Python unifié
│   │   ├── fastapi/               # API REST (image locale taguée)
│   │   └── faeries/               # Services IA (LLM)
│   │       ├── llama/             # LLM principal
│   │       └── qwen/        # LLM alternatif
│   └── fianna/                    # Applications
│       ├── adminer/               # Interface base de données
│       └── n8n/                   # Automatisation workflow
├── sidhe/                          # INTERFACE UTILISATEUR 🎨
│   ├── src/                       # Code source SolidJS
│   ├── .env.example               # Variables interface
│   └── vite.config.ts             # Configuration Vite
├── dolmen/                        # MONITORING 📊
│   └── service_status.json        # État temps réel des services
├── docs/                          # DOCUMENTATION 📚
│   ├── Done-&-Doing.md           # État développement
│   ├── Projet.md                 # Présentation projet
│   ├── Todo.md                   # Tâches à faire
│   ├── architecture.md           # Architecture détaillée
│   ├── change.md                 # Journal des changements
│   └── error.md                  # Erreurs identifiées
├── .env.example                   # Template variables globales
├── .windsurfrules                 # Règles diagnostic et méthodologie
└── .windsurfrules.example         # Template règles
```

## Fonctionnalités Principales

### Orchestration Intelligente
- **Démarrage à la demande** : Services activés uniquement quand nécessaires
- **Gestion des dépendances** : Ordre de démarrage optimisé
- **Health checks** : Surveillance automatique de l'état des services
- **Logs centralisés** : Format uniforme `[script][event] message`
- **Affichage sexy** : IP:ports avec émojis et statut détaillé

### Services Intégrés

#### Services Essentiels
- **MariaDB** (port 8901) - Base de données relationnelle
- **FastAPI** (port 8902) - API REST avec intégration LLM
- **Yarn** (port 8907) - Environnement de développement SolidJS
- **Interface SolidJS** (port 8900) - Interface utilisateur moderne

#### Services IA (Faeries)
- **Llama** (port 8905) - Modèle IA principal (`/muirdris/faeries/llama/`)
- **Qwen** (port 8906) - Modèle IA alternatif (`/muirdris/faeries/qwen/`)

#### Applications
- **Adminer** (port 8903) - Interface base de données
- **N8N** (port 8904) - Automatisation workflow

### Sécurité et Conformité
- **Configuration externalisée** : Toutes les variables dans .env
- **Aucun hardcoding** : IP, ports, URLs via variables d'environnement
- **Chemins absolus** : Élimination des chemins relatifs
- **Validation stricte** : Vérification des prérequis avant démarrage

### Diagnostic et Méthodologie (NOUVEAU)
- **Checklist obligatoire** : Vérifications avant modification
- **Ordre diagnostic strict** : Ressources → Connectivité → Permissions → Config
- **Règles interaction utilisateur** : Signaux d'alerte et validation
- **Gestion d'erreurs** : Arrêt après 2 échecs, procédures rollback
- **Exemples concrets** : Diagnostic bon vs mauvais

## Commandes Principales

### Services Essentiels
```bash
# Démarrer les 3 services essentiels (MariaDB, FastAPI, Yarn)
./dagda/eveil/taranis.sh dagda
# ou
./dagda/eveil/taranis.sh start

# Statut avec affichage détaillé
./dagda/eveil/taranis.sh status dagda

# Arrêt propre
./dagda/eveil/taranis.sh stop dagda
```

### Services Individuels
```bash
# Démarrer un service spécifique
./dagda/eveil/taranis.sh {mariadb|fastapi|yarn|llama|qwen|adminer|n8n}

# Monitoring
./dagda/eveil/taranis.sh status {service}
./dagda/eveil/taranis.sh logs {service}
./dagda/eveil/taranis.sh health {service}
```

### Gestion Globale
```bash
# Vue d'ensemble
./dagda/eveil/taranis.sh status all

# Arrêt complet
./dagda/eveil/taranis.sh stop all
```

## Avantages Concurrentiels

### Performance
- **Démarrage rapide** : Services essentiels en moins de 30 secondes
- **Empreinte mémoire réduite** : Optimisation des ressources
- **Parallélisation** : Démarrage simultané des services indépendants
- **Cache intelligent** : Réutilisation des images Podman

### Développement
- **Hot reload** : Rechargement automatique du code
- **Debugging intégré** : Logs détaillés et structurés
- **IA assistée** : Intégration Llama/Qwen pour aide au développement
- **Interface moderne** : SolidJS réactif et performant

### Opérations
- **Monitoring temps réel** : service_status.json mis à jour automatiquement
- **Diagnostic automatisé** : Règles de vérification intégrées
- **Rollback automatique** : Restauration en cas d'échec
- **Documentation vivante** : Mise à jour automatique des guides

## Cas d'Usage

### Développement Local
- Environnement de développement complet
- Tests d'intégration avec IA
- Prototypage rapide d'applications
- Développement d'interfaces modernes

### Démonstrations
- Présentation de concepts IA
- Démonstration d'orchestration
- Formation aux technologies modernes
- Validation de concepts

### Production Légère
- Applications à faible charge
- Environnements de staging
- Services internes d'équipe
- Prototypes en production

## Évolutions Récentes

### Version 2.3 - Octobre 2025
- **Architecture Faeries** : Regroupement des services IA dans `/muirdris/faeries/`
- **Nettoyage architecture** : Suppression de `geasa/` et `ogmios/` (doublons)
- **Yarn déplacé** : De `geasa/` vers `cromlech/` (cohérence architecture)
- **Chemins corrigés** : Tous les scripts et docs mis à jour
- **Monitoring** : `dolmen/` à la racine pour suivi des services

### Version 2.2 - Septembre 2025
- **Correction FastAPI** : Problème registry Docker résolu
- **Règles diagnostic** : .windsurfrules avec méthodologie complète
- **Affichage amélioré** : IP:ports avec émojis et statut
- **Interface SolidJS** : Permissions corrigées, VITE_PORT ajouté
- **Procédures rollback** : Sauvegarde automatique avant modifications
- **Validation utilisateur** : Confirmation pour actions critiques

## Roadmap

### Court Terme (Q4 2025)
- Interface SolidJS complète
- Tests automatisés
- Monitoring avancé
- Optimisations performance

### Moyen Terme (Q1 2026)
- Intégration CI/CD
- Backup automatique
- Scaling horizontal
- API publique

### Long Terme (2026+)
- Support multi-environnements
- Intégration cloud
- Marketplace de services
- IA prédictive

## Conclusion

Dagda-Lite représente une approche moderne de l'orchestration de services pour le développement, combinant :
- **Simplicité d'usage** avec des commandes intuitives
- **Performance optimisée** par démarrage à la demande
- **Sécurité renforcée** par configuration externalisée
- **Méthodologie robuste** avec règles diagnostic intégrées
- **Innovation technologique** avec IA native et interface moderne

Le projet est maintenant en production stable avec une méthodologie de diagnostic qui garantit la fiabilité opérationnelle.