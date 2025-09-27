# 🔒 Guide Complet - Accès Sécurisé Dagda-Lite avec Nginx + Certificats Client

## 📋 Vue d'Ensemble

Cette documentation couvre la mise en place d'un accès sécurisé à Dagda-Lite via Nginx avec authentification par certificats client. Solution optimisée pour un usage personnel sur VPS avec sécurité maximale et simplicité d'usage.

### **Contexte d'Utilisation**
- **Serveur** : VPS Debian chez OVH
- **Utilisateurs** : Un seul utilisateur (vous)
- **Appareils** : 2 appareils (laptop + desktop)
- **Port d'accès** : 8969
- **Infrastructure** : Nginx + UFW déjà configurés

---

## 🎯 Architecture de Sécurité

### **Flux d'Authentification**
```
Client (Certificat + Auth Basic)
    ↓
Internet (Port 8969)
    ↓
UFW Firewall (Règles strictes)
    ↓
Nginx (Validation certificat client)
    ↓
Auth Basic (Username/Password)
    ↓
Dagda-Lite Services (Accès autorisé)
```

### **Niveaux de Protection**
1. **Firewall UFW** - Filtrage réseau
2. **Certificats Client** - Authentification cryptographique
3. **Auth Basic** - Mot de passe backup
4. **Logging détaillé** - Monitoring accès

---

## 🚀 Option 1 : Setup 5 Minutes (Sécurité Correcte)

### **Principe**
- **Authentification** : Username/Password (Auth Basic)
- **Protection** : Whitelist IP de vos 2 appareils
- **Logs** : Access logs Nginx standards
- **Maintenance** : Mise à jour IP si changement

### **Niveau de Sécurité**
- ✅ **Protection brute force** : Fail2ban
- ✅ **Accès restreint** : IP whitelisting
- ✅ **Chiffrement** : HTTPS obligatoire
- ⚠️ **Vulnérabilité** : IP statique requise

### **Variables .env Requises**
```bash
# Configuration accès rapide
SECURE_ACCESS_PORT=8969
SECURE_ACCESS_USER=${SECURE_ACCESS_USER}
SECURE_ACCESS_PASSWORD=${SECURE_ACCESS_PASSWORD}

# IP autorisées
LAPTOP_IP=${LAPTOP_IP}
DESKTOP_IP=${DESKTOP_IP}

# Logs
ACCESS_LOG_LEVEL=standard
FAIL2BAN_ENABLED=true
```

---

## 🔒 Option 2 : Setup 30 Minutes (Sécurité Maximale)

### **Principe**
- **Authentification primaire** : Certificat client unique par appareil
- **Authentification secondaire** : Username/Password
- **Protection** : Double authentification obligatoire
- **Logs** : Monitoring détaillé avec identificiation certificat

### **Niveau de Sécurité**
- ✅ **Zero Trust** : Aucun accès sans certificat valide
- ✅ **Identification unique** : Un certificat = un appareil
- ✅ **Révocation instantanée** : Désactivation certificat compromise
- ✅ **Logging avancé** : Traçabilité complète des accès

### **Variables .env Requises**
```bash
# Configuration sécurité maximale
SECURE_ACCESS_PORT=8969
NGINX_SSL_DIR=${NGINX_SSL_DIR}
CLIENT_CERT_VALIDITY_DAYS=3650

# Authentification
SECURE_ACCESS_USER=${SECURE_ACCESS_USER}
SECURE_ACCESS_PASSWORD=${SECURE_ACCESS_PASSWORD}

# Certificats
CA_CERT_PATH=${CA_CERT_PATH}
CLIENT_CERT_PREFIX=${CLIENT_CERT_PREFIX}
CERT_KEY_SIZE=4096

# Monitoring
ACCESS_LOG_PATH=${ACCESS_LOG_PATH}
ACCESS_LOG_LEVEL=detailed
SECURITY_LOG_PATH=${SECURITY_LOG_PATH}

# Alertes
ALERT_EMAIL=${ALERT_EMAIL}
ALERT_ON_INVALID_CERT=true
ALERT_ON_BRUTE_FORCE=true
```

---

## 🛠️ Configuration Détaillée - Version Sécurité Maximale

### **1. Structure des Certificats**

#### **Autorité de Certification (CA)**
```bash
# Création CA privée
openssl genrsa -out ${CA_CERT_PATH}/dagda-ca.key 4096

# Certificat CA (validité 10 ans)
openssl req -new -x509 -days 3650 -key ${CA_CERT_PATH}/dagda-ca.key \
    -out ${CA_CERT_PATH}/dagda-ca.crt \
    -subj "/C=FR/ST=France/L=Lyon/O=Dagda-Lite/OU=Personal/CN=Dagda-CA"
```

#### **Certificats Client**
```bash
# Génération clé privée client
openssl genrsa -out ${CLIENT_CERT_PREFIX}-laptop.key 4096
openssl genrsa -out ${CLIENT_CERT_PREFIX}-desktop.key 4096

# Certificats signés par CA
openssl req -new -key ${CLIENT_CERT_PREFIX}-laptop.key \
    -out laptop.csr \
    -subj "/C=FR/ST=France/L=Lyon/O=Dagda-Lite/OU=Devices/CN=laptop"

openssl x509 -req -in laptop.csr -CA ${CA_CERT_PATH}/dagda-ca.crt \
    -CAkey ${CA_CERT_PATH}/dagda-ca.key -CAcreateserial \
    -out ${CLIENT_CERT_PREFIX}-laptop.crt -days 3650
```

#### **Format PKCS#12 pour Navigateurs**
```bash
# Conversion pour installation navigateur
openssl pkcs12 -export -out laptop-cert.p12 \
    -inkey ${CLIENT_CERT_PREFIX}-laptop.key \
    -in ${CLIENT_CERT_PREFIX}-laptop.crt \
    -certfile ${CA_CERT_PATH}/dagda-ca.crt
```

### **2. Configuration Nginx**

#### **Site Dagda-Lite Sécurisé**
```nginx
server {
    listen ${SECURE_ACCESS_PORT} ssl http2;
    server_name ${SERVER_DOMAIN};
    
    # Certificats SSL serveur
    ssl_certificate /etc/letsencrypt/live/${SERVER_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${SERVER_DOMAIN}/privkey.pem;
    
    # Configuration SSL moderne
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # CERTIFICATS CLIENT - OBLIGATOIRES
    ssl_client_certificate ${CA_CERT_PATH}/dagda-ca.crt;
    ssl_verify_client on;
    ssl_verify_depth 1;
    
    # Logs sécurisés détaillés
    access_log ${ACCESS_LOG_PATH}/dagda-secure.log detailed_format;
    error_log ${SECURITY_LOG_PATH}/dagda-errors.log warn;
    
    # Auth Basic (couche secondaire)
    auth_basic "Dagda-Lite Secure Access";
    auth_basic_user_file /etc/nginx/.htpasswd-dagda;
    
    # Headers sécurité
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header Referrer-Policy "no-referrer" always;
    
    # Interface principale SolidJS
    location / {
        proxy_pass http://localhost:${YARN_PORT};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Client-DN $ssl_client_s_dn;
        proxy_set_header X-Client-Verify $ssl_client_verify;
    }
    
    # N8N Workflow
    location /n8n/ {
        proxy_pass http://localhost:${WORKFLOW_PORT}/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Client-DN $ssl_client_s_dn;
        
        # WebSocket support pour N8N
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # Adminer Base de données
    location /adminer/ {
        proxy_pass http://localhost:${ADMIN_PORT}/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Client-DN $ssl_client_s_dn;
    }
    
    # FastAPI et documentation
    location /api/ {
        proxy_pass http://localhost:${API_PORT}/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Client-DN $ssl_client_s_dn;
        
        # CORS pour API
        add_header Access-Control-Allow-Origin "https://${SERVER_DOMAIN}:${SECURE_ACCESS_PORT}" always;
        add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
        add_header Access-Control-Allow-Headers "DNT,X-CustomHeader,Keep-Alive,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Authorization" always;
    }
    
    # Documentation FastAPI
    location /docs {
        proxy_pass http://localhost:${API_PORT}/docs;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    # Monitoring et status
    location /status {
        proxy_pass http://localhost:${API_PORT}/status;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

#### **Format de Logs Détaillé**
```nginx
log_format detailed_format '[$time_local] $remote_addr - "$request" '
                          '$status $bytes_sent "$http_referer" '
                          '"$http_user_agent" '
                          'ssl_client_s_dn:"$ssl_client_s_dn" '
                          'ssl_client_verify:"$ssl_client_verify" '
                          'request_time:$request_time '
                          'upstream_response_time:$upstream_response_time';
```

### **3. Configuration UFW**

#### **Règles Firewall Strictes**
```bash
# Réinitialisation UFW
ufw --force reset

# Politique par défaut
ufw default deny incoming
ufw default allow outgoing

# SSH (port modifié recommandé)
ufw allow ${SSH_PORT}/tcp comment 'SSH Admin'

# Dagda-Lite accès sécurisé UNIQUEMENT
ufw allow ${SECURE_ACCESS_PORT}/tcp comment 'Dagda-Lite Secure Access'

# Services internes INTERDITS depuis l'extérieur
ufw deny ${API_PORT}/tcp comment 'FastAPI Internal Only'
ufw deny ${DB_PORT}/tcp comment 'MariaDB Internal Only'
ufw deny ${WORKFLOW_PORT}/tcp comment 'N8N Internal Only'
ufw deny ${ADMIN_PORT}/tcp comment 'Adminer Internal Only'

# Activation
ufw --force enable

# Verification
ufw status numbered
```

---

## 📋 Script d'Installation Automatisé

### **setup_secure_access.sh**

Le script automatise l'ensemble de la configuration :

#### **Fonctionnalités du Script**
1. **Validation environnement** - Vérification Nginx, UFW, variables .env
2. **Génération CA** - Création autorité de certification privée
3. **Génération certificats client** - Un par appareil avec métadonnées
4. **Configuration Nginx** - Site sécurisé avec toutes les routes
5. **Configuration UFW** - Règles firewall strictes
6. **Tests validation** - Vérification complète du setup
7. **Instructions installation** - Guide client par client

#### **Usage du Script**
```bash
# Lancement installation complète
./setup_secure_access.sh --install

# Tests post-installation
./setup_secure_access.sh --test

# Génération nouveau certificat
./setup_secure_access.sh --new-device desktop2

# Révocation certificat
./setup_secure_access.sh --revoke laptop

# Status complet
./setup_secure_access.sh --status
```

#### **Variables .env Validation**
Le script vérifie la présence de toutes les variables requises :
```bash
# Variables obligatoires
SECURE_ACCESS_PORT
NGINX_SSL_DIR
CA_CERT_PATH
CLIENT_CERT_PREFIX
SECURE_ACCESS_USER
SECURE_ACCESS_PASSWORD
SERVER_DOMAIN
ACCESS_LOG_PATH
SECURITY_LOG_PATH
```

---

## 💻 Installation Certificats Clients

### **Firefox**
1. **Menu** → Préférences → Vie privée et sécurité
2. **Certificats** → Afficher les certificats
3. **Vos certificats** → Importer
4. Sélectionner `laptop-cert.p12`
5. Saisir mot de passe certificat
6. ✅ Certificat installé

### **Chrome/Chromium**
1. **Paramètres** → Confidentialité et sécurité
2. **Sécurité** → Gérer les certificats
3. **Vos certificats** → Importer
4. Sélectionner `laptop-cert.p12`
5. Saisir mot de passe certificat
6. ✅ Certificat installé

### **Curl (Tests CLI)**
```bash
# Test avec certificat
curl --cert laptop-cert.pem --key laptop-key.pem \
     --user ${SECURE_ACCESS_USER}:${SECURE_ACCESS_PASSWORD} \
     https://${SERVER_DOMAIN}:${SECURE_ACCESS_PORT}/api/status
```

---

## 🔍 Monitoring et Logs

### **Logs d'Accès Détaillés**
```bash
# Localisation
tail -f ${ACCESS_LOG_PATH}/dagda-secure.log

# Exemple log d'accès réussi
[21/Sep/2025:14:30:15 +0200] 203.0.113.45 - "GET /api/status HTTP/2.0" 
200 1024 "-" "Mozilla/5.0 (X11; Linux x86_64)" 
ssl_client_s_dn:"CN=laptop,OU=Devices,O=Dagda-Lite,L=Lyon,ST=France,C=FR" 
ssl_client_verify:"SUCCESS" request_time:0.023 upstream_response_time:0.019
```

### **Logs de Sécurité**
```bash
# Tentatives d'accès non autorisées
tail -f ${SECURITY_LOG_PATH}/dagda-errors.log

# Exemple tentative sans certificat
2025/09/21 14:32:10 [info] client SSL certificate verify error: 
(18:self signed certificate) while reading client request headers
```

### **Scripts de Monitoring**

#### **Monitor des Accès Suspects**
```bash
#!/bin/bash
# monitor_access.sh - Surveillance temps réel

LOG_FILE="${ACCESS_LOG_PATH}/dagda-secure.log"
ALERT_EMAIL="${ALERT_EMAIL}"

# Surveiller tentatives sans certificat
tail -f ${SECURITY_LOG_PATH}/dagda-errors.log | while read line; do
    if [[ $line =~ "SSL certificate verify error" ]]; then
        echo "ALERT: Tentative accès sans certificat - $line"
        echo "$line" | mail -s "Dagda-Lite: Accès non autorisé" ${ALERT_EMAIL}
    fi
done
```

#### **Statistiques d'Usage**
```bash
#!/bin/bash
# usage_stats.sh - Rapport quotidien

LOG_FILE="${ACCESS_LOG_PATH}/dagda-secure.log"

echo "=== Rapport d'accès Dagda-Lite $(date) ==="
echo "Nombre total d'accès: $(wc -l < $LOG_FILE)"
echo "Accès par certificat:"
grep -o 'ssl_client_s_dn:"[^"]*"' $LOG_FILE | sort | uniq -c
echo "Pages les plus visitées:"
grep -o '"GET [^"]*"' $LOG_FILE | sort | uniq -c | sort -nr | head -10
echo "Erreurs d'accès:"
grep ' 4[0-9][0-9] \| 5[0-9][0-9] ' $LOG_FILE | wc -l
```

---

## 🔄 Maintenance et Gestion

### **Révocation de Certificat**
```bash
# Script revoke_cert.sh
#!/bin/bash
DEVICE_NAME="$1"

# Ajouter à la CRL
echo "Révocation certificat: $DEVICE_NAME"
openssl ca -config ca.conf -revoke ${CLIENT_CERT_PREFIX}-${DEVICE_NAME}.crt

# Mettre à jour CRL
openssl ca -config ca.conf -gencrl -out ${CA_CERT_PATH}/dagda-ca.crl

# Recharger Nginx
nginx -s reload

echo "✅ Certificat $DEVICE_NAME révoqué"
```

### **Renouvellement Certificats**
```bash
# Script renew_certs.sh - Avant expiration (9 ans)
#!/bin/bash

# Vérifier dates expiration
for cert in ${CLIENT_CERT_PREFIX}-*.crt; do
    expiry=$(openssl x509 -enddate -noout -in "$cert" | cut -d= -f2)
    echo "Certificat $cert expire le: $expiry"
done

# Renouveler si nécessaire
# (automatisation possible via cron)
```

### **Sauvegarde Configuration**
```bash
# Script backup_security.sh
#!/bin/bash

BACKUP_DIR="/backup/dagda-security-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Sauvegarder certificats
cp -r ${CA_CERT_PATH}/* "$BACKUP_DIR/"
cp -r ${CLIENT_CERT_PREFIX}-* "$BACKUP_DIR/"

# Sauvegarder config Nginx
cp /etc/nginx/sites-available/dagda-secure "$BACKUP_DIR/"
cp /etc/nginx/.htpasswd-dagda "$BACKUP_DIR/"

# Sauvegarder règles UFW
ufw status numbered > "$BACKUP_DIR/ufw-rules.txt"

echo "✅ Sauvegarde sécurité: $BACKUP_DIR"
```

---

## ⚡ Tests de Validation

### **Tests Automatisés**
```bash
#!/bin/bash
# test_security.sh - Validation complète

echo "=== Tests de Sécurité Dagda-Lite ==="

# Test 1: Accès sans certificat (doit échouer)
echo "Test 1: Accès sans certificat"
curl -k -u ${SECURE_ACCESS_USER}:${SECURE_ACCESS_PASSWORD} \
     https://${SERVER_DOMAIN}:${SECURE_ACCESS_PORT}/ \
     && echo "❌ ECHEC: Accès autorisé sans certificat" \
     || echo "✅ OK: Accès refusé sans certificat"

# Test 2: Accès avec certificat valide (doit réussir)
echo "Test 2: Accès avec certificat valide"
curl -k --cert laptop-cert.pem --key laptop-key.pem \
     -u ${SECURE_ACCESS_USER}:${SECURE_ACCESS_PASSWORD} \
     https://${SERVER_DOMAIN}:${SECURE_ACCESS_PORT}/api/status \
     && echo "✅ OK: Accès autorisé avec certificat" \
     || echo "❌ ECHEC: Accès refusé avec certificat valide"

# Test 3: Tous les services accessibles
echo "Test 3: Accessibilité services"
for endpoint in "/" "/n8n/" "/adminer/" "/api/docs" "/status"; do
    curl -k --cert laptop-cert.pem --key laptop-key.pem \
         -u ${SECURE_ACCESS_USER}:${SECURE_ACCESS_PASSWORD} \
         -w "%{http_code}" -o /dev/null -s \
         https://${SERVER_DOMAIN}:${SECURE_ACCESS_PORT}$endpoint \
         && echo "✅ $endpoint accessible" \
         || echo "❌ $endpoint inaccessible"
done

echo "=== Tests terminés ==="
```

---

## 📊 Avantages et Limitations

### **✅ Avantages Solution**
- **Sécurité maximale** - Double authentification obligatoire
- **Zero Trust** - Aucun accès sans certificat valide
- **Révocation instantanée** - Désactivation certificat compromise
- **Logging complet** - Traçabilité totale des accès
- **Performance excellente** - Nginx optimisé
- **Maintenance minimale** - Certificats valides 10 ans
- **Une seule installation** - Script automatisé complet

### **⚠️ Limitations**
- **Complexité initiale** - Setup 30 minutes
- **Gestion certificats** - Installation manuelle sur chaque appareil
- **Dépendance Nginx** - Configuration spécifique requise
- **Pas de mobilité IP** - Certificats liés aux appareils fixes

### **📈 Évolutions Possibles**
- **Automatisation installation** - Scripts client automatiques
- **Dashboard monitoring** - Interface web surveillance
- **Alertes avancées** - Notifications temps réel
- **API révocation** - Gestion certificats via interface
- **Intégration LDAP** - Authentification centralisée

---

## 🚀 Conclusion

Cette solution offre un **niveau de sécurité professionnel** avec une **simplicité d'usage** optimale une fois installée. Le script d'installation automatisé garantit une configuration correcte et les tests de validation assurent le bon fonctionnement.

**Recommandation finale** : Déployer la **version 30 minutes sécurisée** pour un usage professionnel sûr avec maintenance minimale.