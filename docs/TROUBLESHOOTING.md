# DAGDA-LITE - Dépannage

**Solutions rapides aux problèmes courants**

---

## 🚨 Problèmes fréquents

### Service ne démarre pas

**Symptôme**: `./dagda/eveil/taranis.sh {service}` échoue

**Diagnostic**:
```bash
# 1. Vérifier les logs
podman logs --tail 100 dagda-lite-{service}-pod-dagda-lite-{service}

# 2. Vérifier le pod existe
podman pod ps | grep dagda-lite-{service}-pod

# 3. Vérifier les variables
source .env && env | grep -E "DAGDA_ROOT|{SERVICE}_PORT"
```

**Solutions**:
- Variables manquantes → Vérifier `.env`
- Port occupé → Changer le port dans `.env.dev`
- Image manquante → Reconstruire l'image

---

### Port déjà utilisé

**Symptôme**: `Error: address already in use`

**Diagnostic**:
```bash
# Trouver le processus
lsof -i :{port}
# ou
ss -tulpn | grep :{port}
```

**Solutions**:
```bash
# Option 1: Tuer le processus
kill {PID}

# Option 2: Changer le port dans .env.dev
# Exemple: VITE_PORT=8901
```

---

### Interface Sidhe - Erreur EMFILE

**Symptôme**: `Error: EMFILE: too many open files`

**Cause**: Vite essaie de surveiller trop de fichiers

**Solution**: ✅ Déjà résolu dans `vite.config.ts`
```typescript
watch: {
  usePolling: true,
  ignored: ['**/node_modules/**']
}
```

Si le problème persiste:
```bash
# Supprimer node_modules et réinstaller
rm -rf sidhe/node_modules
source .env && ${TEINE_ENGINE_SCRIPT} stop ${DAGDA_ROOT}/cauldron/ogmios/sidhe
source .env && ${TEINE_ENGINE_SCRIPT} start ${DAGDA_ROOT}/cauldron/ogmios/sidhe
```

---

### Styles CSS ne s'appliquent pas

**Symptôme**: Interface sans styles

**Diagnostic**:
```bash
# Vérifier que index.css existe
ls -la sidhe/src/index.css

# Vérifier l'import dans index.tsx
grep "import './index.css'" sidhe/src/index.tsx
```

**Solutions**:
```bash
# Si index.css manque
./dagda/eveil/setup-sidhe.sh

# Redémarrer Sidhe
source .env && ${TEINE_ENGINE_SCRIPT} stop ${DAGDA_ROOT}/cauldron/ogmios/sidhe
source .env && ${TEINE_ENGINE_SCRIPT} start ${DAGDA_ROOT}/cauldron/ogmios/sidhe
```

---

### FastAPI - Image registry inaccessible

**Symptôme**: `Error: unable to pull image`

**Diagnostic**:
```bash
# Vérifier les images locales
podman images | grep fastapi
```

**Solution**:
```bash
# Tagger l'image locale
podman tag localhost/dagda-lite-fastapi:latest ${CONTAINER_REGISTRY}/dagda-lite-fastapi:latest
```

---

### MariaDB - Connexion refusée

**Symptôme**: `Can't connect to MySQL server`

**Diagnostic**:
```bash
# Vérifier que MariaDB est actif
./dagda/eveil/taranis.sh status mariadb

# Tester la connexion
podman exec -it dagda-lite-mariadb-pod-dagda-lite-mariadb mysql -u root -p
```

**Solutions**:
- Service arrêté → `./dagda/eveil/taranis.sh mariadb`
- Mot de passe incorrect → Vérifier `DB_PASSWORD` dans `.env`
- Port incorrect → Vérifier `DB_PORT` dans `.env`

---

### Variables d'environnement non chargées

**Symptôme**: `Variable XXX non définie`

**Diagnostic**:
```bash
# Vérifier que .env existe
ls -la .env

# Vérifier le contenu
grep "DAGDA_ROOT" .env
```

**Solutions**:
```bash
# Si .env manque, choisir un environnement
./dagda/eveil/switch-env.sh dev

# Ou copier depuis l'exemple
cp .env.example .env.dev
```

---

### Tous les services plantent

**Symptôme**: Rien ne fonctionne

**Solution d'urgence**:
```bash
# 1. Arrêt complet
./dagda/eveil/stop_all.sh

# 2. Nettoyer
podman pod rm -f $(podman pod ps -aq)

# 3. Redémarrer proprement
./dagda/eveil/taranis.sh dagda
```

---

## 🔍 Commandes de diagnostic

### Vérifier l'architecture

```bash
# Vérifier qu'il n'y a PAS de doublons
ls -la cauldron/cromlech/        # Doit contenir UNIQUEMENT mariadb/ et yarn/
ls -la cauldron/muirdris/fastapi/ # Doit exister (SEUL FastAPI)
ls -la cauldron/ogmios/sidhe/    # Doit exister (SEUL pod Sidhe)

# Ces dossiers NE DOIVENT PAS exister
ls -la cauldron/cromlech/fastapi/ 2>/dev/null && echo "❌ DOUBLON"
ls -la cauldron/cromlech/sidhe/ 2>/dev/null && echo "❌ DOUBLON"
```

### Vérifier la conformité sécurité

```bash
# Aucun hardcoding (doit retourner 0)
grep -r "localhost\|127.0.0.1" dagda/ --include="*.sh" | grep -v "# " | wc -l

# Aucun chemin relatif (doit retourner 0)
grep -r "\.\.\/" dagda/ --include="*.sh" | wc -l

# Variables correctes
source .env && env | grep -E "DAGDA_ROOT|DB_|API_|VITE_"
```

### Vérifier les pods actifs

```bash
# Tous les pods
podman pod ps

# Services essentiels
podman ps --filter pod=dagda-lite-mariadb-pod
podman ps --filter pod=dagda-lite-fastapi-pod
podman ps --filter pod=dagda-lite-sidhe-pod
```

---

## 📞 Escalation

**Si 2 tentatives échouent** :
1. Arrêter tout : `./dagda/eveil/stop_all.sh`
2. Vérifier les logs : `podman logs --tail 200 {container}`
3. Consulter : `docs/ARCHITECTURE.md` et `docs/USAGE.md`
4. Restaurer depuis backup si nécessaire

---

## ✅ Checklist de santé

```bash
# Services essentiels actifs
./dagda/eveil/taranis.sh status dagda

# Interfaces accessibles
curl -f http://localhost:8900  # Sidhe
curl -f http://localhost:8902/docs  # FastAPI
curl -f http://localhost:8903  # Adminer

# Base de données accessible
podman exec dagda-lite-mariadb-pod-dagda-lite-mariadb mysql -u root -p${DB_PASSWORD} -e "SHOW DATABASES;"

# Logs sans erreurs critiques
podman logs --tail 50 dagda-lite-fastapi-pod-dagda-lite-fastapi | grep -i error
```

---

## 🔧 Maintenance préventive

### Nettoyage régulier

```bash
# Supprimer les pods arrêtés
podman pod prune -f

# Supprimer les images inutilisées
podman image prune -f

# Nettoyer les volumes orphelins
podman volume prune -f
```

### Backup avant modifications

```bash
# Sauvegarder .env
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)

# Sauvegarder la base de données
podman exec dagda-lite-mariadb-pod-dagda-lite-mariadb mysqldump -u root -p${DB_PASSWORD} dagda_db > backup.sql
```
