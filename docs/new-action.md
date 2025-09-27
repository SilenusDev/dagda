# 🎯 PLAN D'ACTION DÉTAILLÉ - DAGDA-LITE ORCHESTRATEUR

## **ANALYSE SITUATION ACTUELLE**

**État confirmé :**
- ✅ taranis.sh opérationnel pour démarrer FastAPI
- ❌ FastAPI existe mais contenu à auditer
- ❌ Base de données MariaDB vide (pas d'utilisateurs, pas de tables)
- ❌ Communication LLM non implémentée
- ❌ Monitoring non implémenté
- ✅ SolidJS prévu sur port 8900

---

## **PHASE 1 - AUDIT ET FONDATIONS (Semaine 1)**

### **Jour 1-2 : Audit Complet Existant**

#### **1.1 Audit FastAPI**
```bash
# Vérifications à effectuer
cd Nemeton/muirdris/fastapi/app/
ls -la                           # Structure réelle
cat main.py                      # Point d'entrée
cat requirements.txt             # Dépendances actuelles
cat api/llm.py                   # Routes LLM existantes
cat api/system.py                # Routes système existantes
cat models.py                    # Modèles Pydantic
```

**Checklist audit :**
- [ ] FastAPI démarre-t-il correctement ?
- [ ] Quelles routes existent déjà ?
- [ ] SQLAlchemy configuré ?
- [ ] Connexion MariaDB fonctionnelle ?
- [ ] Quelles dépendances Python installées ?

#### **1.2 Test MariaDB Connexion**
```bash
# Vérifier accès MariaDB depuis FastAPI
podman exec -it dagda-lite-mariadb-container mysql -u root -p
SHOW DATABASES;
SHOW USERS;
```

**Actions requises :**
- [ ] Créer utilisateur `dagda_api` 
- [ ] Créer base de données `dagda_orchestrator`
- [ ] Tester connexion depuis FastAPI

#### **1.3 Test Communication Inter-Services**
```bash
# Vérifier réseau Podman
podman network ls | grep dagda
podman exec -it fastapi-container curl http://llama:8000/health
```

### **Jour 3-4 : Configuration Base de Données**

#### **1.4 Structure Base de Données**
```sql
-- Création utilisateur et base
CREATE USER 'dagda_api'@'%' IDENTIFIED BY '${MYSQL_API_PASSWORD}';
CREATE DATABASE dagda_orchestrator;
GRANT ALL PRIVILEGES ON dagda_orchestrator.* TO 'dagda_api'@'%';

-- Tables principales
CREATE TABLE pods (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    category ENUM('essential', 'optional') NOT NULL,
    status ENUM('stopped', 'starting', 'running', 'stopping', 'error') DEFAULT 'stopped',
    port INT,
    cpu_limit DECIMAL(3,1) DEFAULT 1.0,
    ram_limit INT DEFAULT 512,
    current_cpu DECIMAL(5,2) DEFAULT 0.00,
    current_ram INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE workflows (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    required_pods JSON NOT NULL,
    estimated_cpu DECIMAL(4,1) NOT NULL,
    estimated_ram INT NOT NULL,
    is_active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE system_resources (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    cpu_usage DECIMAL(5,2),
    ram_usage DECIMAL(5,2),
    ram_total INT,
    disk_usage DECIMAL(5,2),
    active_pods JSON,
    INDEX idx_timestamp (timestamp)
);

CREATE TABLE resource_alerts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    alert_type ENUM('cpu_high', 'ram_high', 'disk_high', 'pod_down') NOT NULL,
    message TEXT NOT NULL,
    severity ENUM('info', 'warning', 'critical') NOT NULL,
    resolved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### **1.5 Configuration SQLAlchemy FastAPI**
```python
# app/database.py - Nouvelle création
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os

SQLALCHEMY_DATABASE_URL = f"mysql+pymysql://{os.getenv('MYSQL_API_USER')}:{os.getenv('MYSQL_API_PASSWORD')}@{os.getenv('DB_HOST')}:{os.getenv('DB_PORT')}/dagda_orchestrator"

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
```

### **Jour 5-7 : Architecture FastAPI Orchestrateur**

#### **1.6 Extension Structure FastAPI**
```
app/
├── main.py                      # Point d'entrée existant + nouvelles routes
├── database.py                  # NOUVEAU - Configuration SQLAlchemy
├── models/                      # NOUVEAU - Modèles SQLAlchemy
│   ├── __init__.py
│   ├── pods.py                  # Table pods
│   ├── workflows.py             # Table workflows
│   ├── system_resources.py      # Table system_resources
│   └── alerts.py                # Table resource_alerts
├── api/                         # Existant à étendre
│   ├── llm.py                   # Routes LLM existantes
│   ├── system.py                # Routes système existantes  
│   ├── orchestrator.py          # NOUVEAU - Gestion pods/workflows
│   ├── monitoring.py            # NOUVEAU - Monitoring système
│   └── logs.py                  # NOUVEAU - Logs centralisés
├── services/                    # NOUVEAU - Logique métier
│   ├── __init__.py
│   ├── pod_manager.py           # Interface avec taranis.sh
│   ├── resource_monitor.py      # Monitoring psutil + podman
│   ├── workflow_engine.py       # Moteur workflows
│   └── alert_manager.py         # Gestion alertes
├── web/                         # Existant (templates HTML si présent)
└── models.py                    # Modèles Pydantic existants à étendre
```

---

## **PHASE 2 - ORCHESTRATEUR CORE (Semaine 2-3)**

### **Jour 8-10 : Service Pod Manager**

#### **2.1 Interface avec taranis.sh**
```python
# services/pod_manager.py
import subprocess
import json
from typing import List, Dict

class PodManager:
    def __init__(self):
        self.taranis_path = "/path/to/dagda/eveil/taranis.sh"
    
    def start_pod(self, pod_name: str) -> Dict:
        """Démarre un pod via taranis.sh"""
        try:
            result = subprocess.run([self.taranis_path, pod_name], 
                                  capture_output=True, text=True, timeout=60)
            return {"success": result.returncode == 0, "output": result.stdout}
        except subprocess.TimeoutExpired:
            return {"success": False, "error": "Timeout"}
    
    def stop_pod(self, pod_name: str) -> Dict:
        """Arrête un pod via taranis.sh"""
        # Implémentation similaire
    
    def get_pod_status(self, pod_name: str) -> str:
        """Récupère le statut via taranis.sh status"""
        # Parse output de taranis.sh status
```

#### **2.2 Monitoring Système**
```python
# services/resource_monitor.py
import psutil
import subprocess
import json
from typing import Dict

class ResourceMonitor:
    def get_system_resources(self) -> Dict:
        """Récupère ressources système via psutil"""
        return {
            "cpu_percent": psutil.cpu_percent(interval=1),
            "ram_percent": psutil.virtual_memory().percent,
            "ram_total": psutil.virtual_memory().total // (1024*1024),
            "disk_percent": psutil.disk_usage('/').percent
        }
    
    def get_pod_resources(self, pod_name: str) -> Dict:
        """Récupère ressources pod via podman stats"""
        try:
            result = subprocess.run(
                ["podman", "stats", "--no-stream", "--format", "json", pod_name],
                capture_output=True, text=True
            )
            return json.loads(result.stdout) if result.returncode == 0 else {}
        except:
            return {}
```

### **Jour 11-14 : API Routes Orchestrateur**

#### **2.3 Routes Pods**
```python
# api/orchestrator.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from services.pod_manager import PodManager
from database import get_db

router = APIRouter(prefix="/api/orchestrator", tags=["orchestrator"])

@router.get("/pods")
def list_pods(db: Session = Depends(get_db)):
    """Liste tous les pods avec leur statut"""
    
@router.post("/pods/{pod_name}/start")
def start_pod(pod_name: str, db: Session = Depends(get_db)):
    """Démarre un pod spécifique"""
    
@router.post("/pods/{pod_name}/stop") 
def stop_pod(pod_name: str, db: Session = Depends(get_db)):
    """Arrête un pod spécifique"""

@router.get("/workflows")
def list_workflows(db: Session = Depends(get_db)):
    """Liste tous les workflows disponibles"""

@router.post("/workflows/{workflow_id}/start")
def start_workflow(workflow_id: int, db: Session = Depends(get_db)):
    """Démarre un workflow complet"""
```

#### **2.4 Routes Monitoring**
```python
# api/monitoring.py  
@router.get("/system/resources")
def get_system_status():
    """Statut système temps réel"""
    
@router.get("/system/pods/{pod_name}/resources")
def get_pod_resources(pod_name: str):
    """Ressources d'un pod spécifique"""

@router.get("/system/alerts")
def get_active_alerts():
    """Alertes actives du système"""
```

---

## **PHASE 3 - INTERFACE SOLIDJS (Semaine 4-5)**

### **Jour 15-17 : Structure SolidJS**

#### **3.1 Architecture Frontend**
```
dagda/sidhe-ui/
├── src/
│   ├── App.jsx                  # Composant principal
│   ├── index.jsx                # Point d'entrée
│   ├── components/              # Composants réutilisables
│   │   ├── PodCard.jsx          # Card pour un pod
│   │   ├── ResourceChart.jsx    # Graphiques ressources
│   │   ├── WorkflowCard.jsx     # Card workflow
│   │   └── AlertBanner.jsx      # Bannière alertes
│   ├── pages/                   # Pages principales
│   │   ├── Dashboard.jsx        # Vue d'ensemble système
│   │   ├── Pods.jsx             # Gestion pods individuels
│   │   ├── Workflows.jsx        # Catalogue workflows
│   │   ├── Monitoring.jsx       # Graphiques détaillés
│   │   └── Logs.jsx             # Logs temps réel
│   ├── services/                # Services API
│   │   ├── api.js               # Client HTTP vers FastAPI
│   │   └── websocket.js         # WebSocket pour temps réel
│   ├── stores/                  # État global (Solid Store)
│   │   ├── systemStore.js       # État système
│   │   ├── podsStore.js         # État pods
│   │   └── workflowsStore.js    # État workflows
│   └── styles/                  # CSS/Tailwind
├── public/
├── package.json
└── vite.config.js
```

### **Jour 18-21 : Pages Principales**

#### **3.2 Dashboard Principal**
```jsx
// pages/Dashboard.jsx
export default function Dashboard() {
    return (
        <div class="dashboard">
            {/* Système Overview */}
            <SystemStatus />
            
            {/* Pods Essentiels */}
            <EssentialPods />
            
            {/* Workflows Actifs */}
            <ActiveWorkflows />
            
            {/* Alertes */}
            <AlertsPanel />
        </div>
    );
}
```

#### **3.3 Gestion Pods**
```jsx
// pages/Pods.jsx  
export default function Pods() {
    return (
        <div class="pods-page">
            {/* Filtres et contrôles */}
            <PodFilters />
            
            {/* Liste pods avec actions */}
            <PodsList />
            
            {/* Monitoring par pod */}
            <PodMonitoring />
        </div>
    );
}
```

---

## **PHASE 4 - FONCTIONNALITÉS AVANCÉES (Semaine 6-7)**

### **Jour 22-25 : Temps Réel et WebSocket**

#### **4.1 WebSocket FastAPI**
```python
# main.py - Ajout WebSocket
from fastapi import WebSocket

@app.websocket("/ws/monitoring")
async def websocket_monitoring(websocket: WebSocket):
    """WebSocket pour monitoring temps réel"""
    await websocket.accept()
    while True:
        data = resource_monitor.get_system_resources()
        await websocket.send_json(data)
        await asyncio.sleep(5)  # Envoi toutes les 5s
```

#### **4.2 Client WebSocket SolidJS**
```javascript
// services/websocket.js
export class MonitoringWebSocket {
    connect(onMessage) {
        this.ws = new WebSocket('ws://localhost:8902/ws/monitoring');
        this.ws.onmessage = (event) => {
            onMessage(JSON.parse(event.data));
        };
    }
}
```

### **Jour 26-28 : Mode Économique**

#### **4.3 Engine Mode Économique**
```python
# services/workflow_engine.py
class WorkflowEngine:
    def can_start_workflow(self, workflow_id: int) -> Dict:
        """Vérifie si ressources suffisantes"""
        current_resources = self.monitor.get_system_resources()
        workflow = self.get_workflow(workflow_id)
        
        if current_resources['ram_percent'] + workflow.estimated_ram > 80:
            return {
                "can_start": False,
                "reason": "RAM insuffisante",
                "suggested_actions": self.suggest_pods_to_stop()
            }
        return {"can_start": True}
    
    def suggest_pods_to_stop(self) -> List[str]:
        """Suggère pods optionnels à arrêter"""
        # Logique de priorisation des pods
```

---

## **PHASE 5 - TESTS ET DÉPLOIEMENT (Semaine 8)**

### **Jour 29-31 : Tests Intégration**

#### **5.1 Tests API**
```python
# tests/test_orchestrator.py
def test_start_pod():
    response = client.post("/api/orchestrator/pods/llama/start")
    assert response.status_code == 200

def test_workflow_resource_check():
    response = client.post("/api/orchestrator/workflows/1/start")
    # Vérifier gestion ressources insuffisantes
```

#### **5.2 Tests Frontend**
```javascript
// tests/Dashboard.test.jsx
test('Dashboard affiche statut système', () => {
    render(<Dashboard />);
    expect(screen.getByText('Système')).toBeInTheDocument();
});
```

### **Jour 32-35 : Documentation et Déploiement**

#### **5.3 Documentation API**
- Endpoints FastAPI documentés automatiquement via `/docs`
- Guide utilisateur SolidJS
- Architecture technique

#### **5.4 Variables .env Finales**
```bash
# Nouvelles variables requises
MYSQL_API_USER=dagda_api
MYSQL_API_PASSWORD=secure_password
SOLIDJS_PORT=8900
MONITORING_INTERVAL=5
ALERT_RAM_THRESHOLD=80
ALERT_CPU_THRESHOLD=70
```

---

## **CHECKLIST DE VALIDATION**

### **Fonctionnalités Core**
- [ ] Démarrage/arrêt pods via interface
- [ ] Monitoring temps réel CPU/RAM
- [ ] Catalogue workflows fonctionnel
- [ ] Mode économique automatique
- [ ] Logs centralisés visibles
- [ ] Alertes système actives

### **Performance**
- [ ] Interface SolidJS < 2s chargement
- [ ] API FastAPI < 100ms réponse
- [ ] WebSocket stable sans déconnexions
- [ ] Consommation RAM orchestrateur < 256MB

### **Sécurité**
- [ ] Aucun hardcoding credentials
- [ ] Variables .env externalisées
- [ ] Validation entrées utilisateur
- [ ] Logs sécurisés (pas de passwords)

---

**Estimation totale : 8 semaines**
**Objectif : Système complet et opérationnel**