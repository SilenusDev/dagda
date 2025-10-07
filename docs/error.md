# ERREURS ACTUELLES DAGDA-LITE

> **État au 21/09/2025 16:59** - Erreurs identifiées par audit complet

## ERREURS CRITIQUES À CORRIGER

### 1. HARDCODING SÉCURITÉ - VIOLATION RÈGLES .windsurfrules

**Fichiers concernés :**
- `dagda/awens-utils/ollamh.sh` (3 occurrences)
- `cauldron/muirdris/fastapi/manage.sh` (2 occurrences) 
- `cauldron/muirdris/fastapi/pod.yml` (1 occurrence)
- `cauldron/cromlech/mariadb/manage.sh` (1 occurrence)

**Détails :**
```bash
# INTERDIT - Hardcoding localhost
local host=${2:-${HOST:-localhost}}  # ollamh.sh ligne 162, 261
echo "• URL: http://${HOST:-localhost}:${port}"  # ollamh.sh ligne 467
image: localhost/dagda-lite-fastapi:latest  # fastapi/pod.yml ligne 16
podman pod create --name "$POD_NAME" -p "${HOST}:${API_PORT}:8000"  # fastapi/manage.sh ligne 58
podman pod create --name "$POD_NAME" -p "${HOST}:${DB_PORT}:3306"  # mariadb/manage.sh ligne 58
IMAGE_NAME="localhost/dagda-lite-fastapi:latest"  # fastapi/manage.sh ligne 28
```

**Solution requise :** Remplacer par variables d'environnement `${CONTAINER_REGISTRY}`, `${DEFAULT_HOST}`

### 2. CHEMINS RELATIFS INTERDITS

**Fichier :** `create_dagda_structure.sh`
```bash
# INTERDIT - Chemins relatifs
source "$POD_DIR/../../../coire-anseasc/cauldron-core/teine_engine.sh"  # lignes 140, 169
```

**Solution requise :** Utiliser variables d'environnement pour tous les chemins

### 3. VARIABLES OBSOLÈTES NON MIGRÉES

**Fichiers concernés :**
- `dagda/awen-core/teine_engine.sh` (ligne 181-185)
- `create_dagda_structure.sh` (lignes 327-338)

**Détails :**
```bash
# OBSOLÈTE - Variables non migrées
MARIADB_PORT=8902  # Doit être DB_PORT
FASTAPI_PORT=8903  # Doit être API_PORT
MYSQL_ROOT_PASSWORD  # Doit être DB_ROOT_PASSWORD
MYSQL_DATABASE  # Doit être DB_NAME
MYSQL_USER  # Doit être DB_USER
MYSQL_PASSWORD  # Doit être DB_PASSWORD
```

### 4. RÉFÉRENCES ARCHITECTURE OBSOLÈTE

**Fichiers concernés :**
- `dagda/awens-utils/imbas-logging.sh` (ligne 2)
- `cauldron/muirdris/faeries/qwen/pod.yml` (ligne 1)
- `cauldron/muirdris/faeries/qwen/manage.sh` (ligne 2)
- `cauldron/muirdris/faeries/llama/manage.sh` (ligne 2)

**Détails :**
```bash
# OBSOLÈTE - Références anciennes
# coire-anseasc/awens-utils/imbas-logging.sh  # Doit être dagda/awens-utils/
# Nemeton/faeries/qwen/pod.yml  # Doit être cauldron/muirdris/faeries/
# Nemeton/faeries/llama/manage.sh  # Doit être cauldron/muirdris/faeries/
```

### 5. SCRIPT OBSOLÈTE DANGEREUX

**Fichier :** `create_dagda_structure.sh`
- Contient architecture obsolète Nemeton/coire-anseasc
- Génère des scripts avec chemins relatifs interdits
- Utilise `source .env` non sécurisé
- Références mythologiques dans la logique métier

**Action requise :** Suppression complète du fichier

### 6. DOCUMENTATION INCOHÉRENTE

**Fichier :** `cauldron/muirdris/specs.md`
```bash
# OBSOLÈTE - Références scripts inexistants
./scripts/lug.sh cromlech  # Script n'existe pas
./scripts/lug.sh muirdris  # Commande obsolète
```

**Solution :** Mettre à jour avec `./dagda/eveil/taranis.sh dagda`

---

## RÉSUMÉ AUDIT

| Catégorie | Erreurs | Criticité |
|-----------|---------|-----------|
| Hardcoding sécurité | 7 | 🔴 CRITIQUE |
| Chemins relatifs | 2 | 🔴 CRITIQUE |
| Variables obsolètes | 6 | 🟡 MAJEURE |
| Références obsolètes | 4 | 🟡 MAJEURE |
| Scripts dangereux | 1 | 🔴 CRITIQUE |
| Documentation | 3 | 🟠 MINEURE |

**TOTAL : 23 erreurs identifiées**

---

## VALIDATION CONTINUE

### Commandes de vérification automatique
```bash
# Vérification hardcoding (doit retourner 0 résultat)
grep -r "localhost\|127.0.0.1\|:3306\|:8000" . --include="*.sh" --include="*.yml"

# Vérification chemins relatifs (doit retourner 0 résultat)  
grep -r "\.\.\/" . --include="*.sh"

# Vérification variables obsolètes
grep -r "MARIADB_PORT\|FASTAPI_PORT\|MYSQL_" . --include="*.sh" --include="*.yml"
```

### Priorités de correction
1. **URGENT** : Éliminer tout hardcoding (règles sécurité)
2. **URGENT** : Supprimer chemins relatifs
3. **IMPORTANT** : Migrer variables obsolètes
4. **MOYEN** : Nettoyer références obsolètes