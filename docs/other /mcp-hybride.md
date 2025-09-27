# Architecture MCP Hybride - Dagda-Lite
## Intégration Model Context Protocol avec système de Registry Intelligent

**Version :** 1.0  
**Date :** Septembre 2025  
**Scope :** Intégration MCP dans l'écosystème Dagda-Lite

---

## 🎯 OBJECTIFS

### Vision stratégique
- **Intégration MCP native** dans l'architecture Dagda-Lite existante
- **Architecture hybride** : services MCP essentiels + extensions optionnelles
- **Compatibilité Registry** : téléchargement MCP à la demande
- **Performance optimisée** : communication via FastAPI orchestrateur
- **Modularité maximale** : start/stop indépendant des composants MCP

### Périmètre d'intégration
- **Inclus** : MCP-Core (essentiels), MCP-Extensions (optionnels)
- **Compatible** : Tous LLM dans `/muirdris` (Llama, Qwen, SmolVLA)
- **Orchestré** : Via FastAPI comme point d'entrée unique
- **Registry** : Extensions MCP via système de téléchargement intelligent

---

## 🏗️ ARCHITECTURE GLOBALE

### Structure système hybride
```
dagda-lite/
├── registry/                     # Registry MCP Extensions
│   ├── mcp-catalog.json         # Catalogue serveurs MCP disponibles
│   ├── manifests/               # Spécifications MCP
│   │   ├── web-search-mcp.yml   # Serveur recherche web
│   │   ├── slack-mcp.yml        # Intégration Slack
│   │   ├── github-mcp.yml       # Intégration GitHub
│   │   ├── jira-mcp.yml         # Intégration Jira
│   │   └── custom-api-mcp.yml   # APIs personnalisées
│   └── cache/mcp/               # Cache serveurs MCP
├── cauldron/muirdris/
│   ├── fastapi/                 # 🔧 Orchestrateur MCP
│   │   ├── routers/
│   │   │   └── mcp_router.py    # Routes MCP
│   │   ├── services/
│   │   │   ├── mcp_manager.py   # Gestionnaire MCP
│   │   │   └── llm_mcp_bridge.py # Pont LLM-MCP
│   │   └── config/
│   │       └── mcp_config.yml   # Configuration MCP
│   ├── llama/                   # LLM principal (inchangé)
│   ├── mcp-core/               # 🆕 Services MCP essentiels
│   │   ├── manage.sh
│   │   ├── pod.yml
│   │   ├── servers/            # Serveurs MCP intégrés
│   │   │   ├── database_server.py
│   │   │   ├── filesystem_server.py
│   │   │   ├── logs_server.py
│   │   │   └── dagda_server.py
│   │   ├── config/
│   │   │   └── core_servers.yml
│   │   └── requirements.txt
│   ├── mcp-extensions/         # 🆕 Extensions MCP (optionnelles)
│   │   ├── manage.sh
│   │   ├── pod.yml
│   │   ├── servers/            # Serveurs téléchargés
│   │   │   └── .registry-installed/
│   │   ├── config/
│   │   └── requirements.txt
│   └── qwen25-05b/            # Autres LLM (compatibles MCP)
└── dagda/
    └── mcp-manager/            # 🆕 Scripts gestion MCP
        ├── mcp-registry.sh     # Gestion registry MCP
        ├── mcp-installer.sh    # Installation serveurs
        └── mcp-monitor.sh      # Monitoring MCP
```

---

## 🔧 SPÉCIFICATIONS TECHNIQUES

### Architecture MCP Core

#### **Serveurs MCP essentiels** (toujours installés)
```yaml
# config/core_servers.yml
mcp_core_servers:
  database:
    name: "dagda-database"
    description: "Accès MariaDB via MCP"
    protocol: "stdio"
    command: ["python", "servers/database_server.py"]
    capabilities:
      - "resources"
      - "tools"
    resources:
      - "database://tables"
      - "database://queries"
    
  filesystem:
    name: "dagda-filesystem" 
    description: "Accès système de fichiers"
    protocol: "stdio"
    command: ["python", "servers/filesystem_server.py"]
    capabilities:
      - "resources"
      - "tools"
    resources:
      - "file://logs"
      - "file://configs"
    
  logs:
    name: "dagda-logs"
    description: "Accès logs système"
    protocol: "stdio" 
    command: ["python", "servers/logs_server.py"]
    capabilities:
      - "resources"
    resources:
      - "logs://system"
      - "logs://services"
      
  dagda:
    name: "dagda-system"
    description: "État et contrôle services Dagda"
    protocol: "stdio"
    command: ["python", "servers/dagda_server.py"] 
    capabilities:
      - "tools"
      - "resources"
    tools:
      - "start_service"
      - "stop_service"
      - "get_service_status"
    resources:
      - "services://status"
      - "services://logs"
```

### Registry MCP Extensions

#### **Catalogue MCP** (`registry/mcp-catalog.json`)
```json
{
  "version": "1.0",
  "last_updated": "2025-09-23T10:00:00Z",
  "mcp_servers": {
    "web-search": {
      "name": "Web Search MCP",
      "version": "1.2.0",
      "description": "Recherche web via DuckDuckGo/Bing",
      "size_mb": 45,
      "capabilities": ["tools"],
      "tools": ["web_search", "summarize_results"],
      "popularity": 9.1,
      "status": "available"
    },
    "slack": {
      "name": "Slack Integration MCP", 
      "version": "2.0.1",
      "description": "Intégration complète Slack",
      "size_mb": 78,
      "capabilities": ["tools", "resources"],
      "tools": ["send_message", "get_channels", "search_messages"],
      "resources": ["slack://messages", "slack://users"],
      "popularity": 8.7,
      "status": "available"
    },
    "github": {
      "name": "GitHub Integration MCP",
      "version": "1.5.3", 
      "description": "Gestion repositories GitHub",
      "size_mb": 92,
      "capabilities": ["tools", "resources"],
      "tools": ["create_issue", "get_repo_info", "search_code"],
      "resources": ["github://repos", "github://issues"],
      "popularity": 8.9,
      "status": "available"
    }
  }
}
```

#### **Manifest MCP Extension** (`registry/manifests/web-search-mcp.yml`)
```yaml
name: "web-search"
display_name: "Web Search MCP Server"
version: "1.2.0"
category: "productivity"

# Ressources requises
resources:
  ram_mb: 256
  disk_mb: 45
  network: true

# Installation
downloads:
  source_code:
    url: "https://github.com/mcp-servers/web-search/archive/v1.2.0.tar.gz"
    sha256: "f1e2d3c4b5a6..."
    size_mb: 15
  
  dependencies:
    requirements_file: "requirements.txt"
    additional_packages: ["beautifulsoup4", "requests"]

# Configuration MCP
mcp_config:
  protocol: "stdio"
  command: ["python", "web_search_server.py"]
  capabilities:
    - "tools"
  tools:
    - name: "web_search"
      description: "Recherche sur le web"
      parameters:
        query: "string"
        max_results: "integer"
    - name: "summarize_results"
      description: "Résume les résultats de recherche"
      parameters:
        results: "array"
        
# Variables d'environnement requises
environment:
  WEB_SEARCH_API_KEY: "optional"
  MAX_SEARCH_RESULTS: "10"
  SEARCH_PROVIDER: "duckduckgo"

# Métadonnées
metadata:
  description: "Serveur MCP pour recherche web avec DuckDuckGo"
  license: "MIT"
  homepage: "https://github.com/mcp-servers/web-search"
  tags: ["search", "web", "productivity"]
```

---

## ⚙️ INTÉGRATION FASTAPI

### Architecture de communication
```
Client → FastAPI → MCP Manager → MCP-Core/Extensions → LLM
                              ↓
                         Base de données / APIs externes
```

### Code FastAPI - MCP Router

#### **MCP Router** (`fastapi/routers/mcp_router.py`)
```python
from fastapi import APIRouter, HTTPException
from typing import Dict, List, Any
from ..services.mcp_manager import MCPManager
from ..services.llm_mcp_bridge import LLMMCPBridge

router = APIRouter(prefix="/api/mcp", tags=["mcp"])
mcp_manager = MCPManager()
llm_bridge = LLMMCPBridge()

@router.post("/chat-with-context")
async def chat_with_mcp_context(
    query: str,
    llm_model: str = "llama",
    mcp_sources: List[str] = None
):
    """Chat avec enrichissement contextuel via MCP"""
    try:
        # 1. Analyser la requête pour identifier les sources MCP nécessaires
        required_sources = await mcp_manager.analyze_query_sources(query)
        if mcp_sources:
            required_sources.extend(mcp_sources)
        
        # 2. Récupérer le contexte via MCP
        context = await mcp_manager.gather_context(required_sources, query)
        
        # 3. Enrichir la requête avec le contexte MCP
        enriched_query = await llm_bridge.enrich_query(query, context)
        
        # 4. Appeler le LLM avec le contexte enrichi
        response = await llm_bridge.call_llm(llm_model, enriched_query)
        
        return {
            "response": response,
            "context_sources": required_sources,
            "context_data": context
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/servers/status")
async def get_mcp_servers_status():
    """État de tous les serveurs MCP"""
    return await mcp_manager.get_all_servers_status()

@router.post("/servers/{server_name}/execute")
async def execute_mcp_tool(
    server_name: str,
    tool_name: str,
    parameters: Dict[str, Any]
):
    """Exécuter un outil MCP spécifique"""
    return await mcp_manager.execute_tool(server_name, tool_name, parameters)

@router.get("/resources/{resource_uri}")
async def get_mcp_resource(resource_uri: str):
    """Récupérer une ressource MCP"""
    return await mcp_manager.get_resource(resource_uri)
```

#### **MCP Manager** (`fastapi/services/mcp_manager.py`)
```python
import asyncio
import json
from typing import Dict, List, Any
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client

class MCPManager:
    def __init__(self):
        self.core_servers = {}
        self.extension_servers = {}
        self.active_sessions = {}
        
    async def initialize(self):
        """Initialiser les serveurs MCP core"""
        await self.start_core_servers()
        
    async def start_core_servers(self):
        """Démarrer les serveurs MCP essentiels"""
        core_config = self.load_core_config()
        
        for server_name, config in core_config["mcp_core_servers"].items():
            try:
                server_params = StdioServerParameters(
                    command=config["command"],
                    env=config.get("env", {})
                )
                
                session = await stdio_client(server_params)
                await session.initialize()
                
                self.active_sessions[server_name] = session
                self.core_servers[server_name] = config
                
                print(f"[MCP] Serveur {server_name} démarré")
            except Exception as e:
                print(f"[MCP] Erreur démarrage {server_name}: {e}")
    
    async def analyze_query_sources(self, query: str) -> List[str]:
        """Analyser la requête pour identifier les sources MCP nécessaires"""
        sources = []
        
        # Mots-clés pour identifier les sources nécessaires
        if any(keyword in query.lower() for keyword in ["database", "table", "sql"]):
            sources.append("database")
        if any(keyword in query.lower() for keyword in ["file", "fichier", "log"]):
            sources.append("filesystem")
        if any(keyword in query.lower() for keyword in ["service", "pod", "status"]):
            sources.append("dagda")
        if any(keyword in query.lower() for keyword in ["search", "web", "internet"]):
            sources.append("web-search")
            
        return sources
    
    async def gather_context(self, sources: List[str], query: str) -> Dict[str, Any]:
        """Rassembler le contexte depuis les sources MCP"""
        context = {}
        
        for source in sources:
            if source in self.active_sessions:
                try:
                    # Récupérer les ressources disponibles
                    resources = await self.active_sessions[source].list_resources()
                    context[source] = {
                        "resources": resources,
                        "available_tools": await self.active_sessions[source].list_tools()
                    }
                except Exception as e:
                    context[source] = {"error": str(e)}
        
        return context
    
    async def execute_tool(self, server_name: str, tool_name: str, parameters: Dict[str, Any]):
        """Exécuter un outil MCP"""
        if server_name not in self.active_sessions:
            raise ValueError(f"Serveur MCP {server_name} non disponible")
        
        session = self.active_sessions[server_name]
        return await session.call_tool(tool_name, parameters)
    
    def load_core_config(self) -> Dict:
        """Charger la configuration des serveurs core"""
        with open("/app/config/core_servers.yml", "r") as f:
            import yaml
            return yaml.safe_load(f)
```

---

## 🔧 SERVEURS MCP CORE

### Serveur Database MCP

#### **Database Server** (`mcp-core/servers/database_server.py`)
```python
import asyncio
import json
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Resource, Tool, TextContent
import aiomysql
import os

# Configuration base de données depuis variables d'environnement
DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", "8901")),
    "user": os.getenv("DB_USER", "root"),
    "password": os.getenv("DB_PASSWORD"),
    "db": os.getenv("DB_NAME", "dagda")
}

app = Server("dagda-database")

@app.list_resources()
async def list_resources() -> list[Resource]:
    """Lister les ressources de base de données disponibles"""
    return [
        Resource(
            uri="database://tables",
            name="Tables de la base de données",
            mimeType="application/json"
        ),
        Resource(
            uri="database://schema",
            name="Schéma de la base de données", 
            mimeType="application/json"
        )
    ]

@app.read_resource()
async def read_resource(uri: str) -> str:
    """Lire une ressource de base de données"""
    if uri == "database://tables":
        async with aiomysql.connect(**DB_CONFIG) as conn:
            async with conn.cursor() as cursor:
                await cursor.execute("SHOW TABLES")
                tables = await cursor.fetchall()
                return json.dumps({"tables": [table[0] for table in tables]})
    
    elif uri == "database://schema":
        async with aiomysql.connect(**DB_CONFIG) as conn:
            async with conn.cursor() as cursor:
                schema = {}
                await cursor.execute("SHOW TABLES")
                tables = await cursor.fetchall()
                
                for table in tables:
                    table_name = table[0]
                    await cursor.execute(f"DESCRIBE {table_name}")
                    columns = await cursor.fetchall()
                    schema[table_name] = [
                        {"name": col[0], "type": col[1], "null": col[2], "key": col[3]}
                        for col in columns
                    ]
                
                return json.dumps(schema)
    
    raise ValueError(f"Ressource inconnue: {uri}")

@app.list_tools()
async def list_tools() -> list[Tool]:
    """Lister les outils disponibles"""
    return [
        Tool(
            name="execute_query",
            description="Exécuter une requête SQL",
            inputSchema={
                "type": "object",
                "properties": {
                    "query": {"type": "string", "description": "Requête SQL à exécuter"},
                    "params": {"type": "array", "description": "Paramètres de la requête"}
                },
                "required": ["query"]
            }
        ),
        Tool(
            name="get_table_info",
            description="Obtenir des informations sur une table",
            inputSchema={
                "type": "object", 
                "properties": {
                    "table_name": {"type": "string", "description": "Nom de la table"}
                },
                "required": ["table_name"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    """Exécuter un outil"""
    if name == "execute_query":
        query = arguments["query"]
        params = arguments.get("params", [])
        
        async with aiomysql.connect(**DB_CONFIG) as conn:
            async with conn.cursor() as cursor:
                await cursor.execute(query, params)
                if query.strip().upper().startswith("SELECT"):
                    results = await cursor.fetchall()
                    return [TextContent(type="text", text=json.dumps({"results": results}))]
                else:
                    await conn.commit()
                    return [TextContent(type="text", text=json.dumps({"affected_rows": cursor.rowcount}))]
    
    elif name == "get_table_info":
        table_name = arguments["table_name"]
        
        async with aiomysql.connect(**DB_CONFIG) as conn:
            async with conn.cursor() as cursor:
                # Informations sur la table
                await cursor.execute(f"DESCRIBE {table_name}")
                columns = await cursor.fetchall()
                
                await cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
                row_count = (await cursor.fetchone())[0]
                
                info = {
                    "table_name": table_name,
                    "columns": [
                        {"name": col[0], "type": col[1], "null": col[2], "key": col[3]}
                        for col in columns
                    ],
                    "row_count": row_count
                }
                
                return [TextContent(type="text", text=json.dumps(info))]
    
    raise ValueError(f"Outil inconnu: {name}")

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream, app.create_initialization_options())

if __name__ == "__main__":
    asyncio.run(main())
```

### Serveur Dagda System MCP

#### **Dagda System Server** (`mcp-core/servers/dagda_server.py`)
```python
import asyncio
import json
import subprocess
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Resource, Tool, TextContent
import os

app = Server("dagda-system")

# Chemin vers le script taranis
TARANIS_SCRIPT = os.getenv("TARANIS_SCRIPT", "/app/dagda/eveil/taranis.sh")

@app.list_resources()
async def list_resources() -> list[Resource]:
    """Ressources système Dagda disponibles"""
    return [
        Resource(
            uri="services://status",
            name="État des services Dagda",
            mimeType="application/json"
        ),
        Resource(
            uri="services://logs",
            name="Logs des services",
            mimeType="text/plain"
        )
    ]

@app.read_resource()
async def read_resource(uri: str) -> str:
    """Lire une ressource système"""
    if uri == "services://status":
        # Exécuter taranis.sh status all
        result = subprocess.run(
            [TARANIS_SCRIPT, "status", "all"],
            capture_output=True,
            text=True
        )
        return result.stdout
    
    elif uri == "services://logs":
        # Lire le fichier de logs système
        try:
            with open("/app/logs/system.log", "r") as f:
                return f.read()
        except FileNotFoundError:
            return "Aucun log système trouvé"
    
    raise ValueError(f"Ressource inconnue: {uri}")

@app.list_tools()
async def list_tools() -> list[Tool]:
    """Outils de gestion système disponibles"""
    return [
        Tool(
            name="start_service",
            description="Démarrer un service Dagda",
            inputSchema={
                "type": "object",
                "properties": {
                    "service_name": {"type": "string", "description": "Nom du service à démarrer"}
                },
                "required": ["service_name"]
            }
        ),
        Tool(
            name="stop_service", 
            description="Arrêter un service Dagda",
            inputSchema={
                "type": "object",
                "properties": {
                    "service_name": {"type": "string", "description": "Nom du service à arrêter"}
                },
                "required": ["service_name"]
            }
        ),
        Tool(
            name="get_service_status",
            description="Obtenir le statut d'un service",
            inputSchema={
                "type": "object",
                "properties": {
                    "service_name": {"type": "string", "description": "Nom du service"}
                },
                "required": ["service_name"]
            }
        ),
        Tool(
            name="get_service_logs",
            description="Obtenir les logs d'un service",
            inputSchema={
                "type": "object",
                "properties": {
                    "service_name": {"type": "string", "description": "Nom du service"}
                },
                "required": ["service_name"]
            }
        )
    ]

@app.call_tool()
async def call_tool(name: str, arguments: dict) -> list[TextContent]:
    """Exécuter un outil système"""
    service_name = arguments.get("service_name")
    
    if name == "start_service":
        result = subprocess.run(
            [TARANIS_SCRIPT, service_name],
            capture_output=True,
            text=True
        )
        return [TextContent(
            type="text", 
            text=json.dumps({
                "status": "success" if result.returncode == 0 else "error",
                "output": result.stdout,
                "error": result.stderr
            })
        )]
    
    elif name == "stop_service":
        result = subprocess.run(
            [TARANIS_SCRIPT, "stop", service_name],
            capture_output=True,
            text=True
        )
        return [TextContent(
            type="text",
            text=json.dumps({
                "status": "success" if result.returncode == 0 else "error", 
                "output": result.stdout,
                "error": result.stderr
            })
        )]
    
    elif name == "get_service_status":
        result = subprocess.run(
            [TARANIS_SCRIPT, "status", service_name],
            capture_output=True,
            text=True
        )
        return [TextContent(
            type="text",
            text=result.stdout
        )]
    
    elif name == "get_service_logs":
        result = subprocess.run(
            [TARANIS_SCRIPT, "logs", service_name],
            capture_output=True,
            text=True
        )
        return [TextContent(
            type="text",
            text=result.stdout
        )]
    
    raise ValueError(f"Outil inconnu: {name}")

async def main():
    async with stdio_server() as (read_stream, write_stream):
        await app.run(read_stream, write_stream, app.create_initialization_options())

if __name__ == "__main__":
    asyncio.run(main())
```

---

## 📊 GESTION REGISTRY MCP

### Scripts de gestion MCP

#### **MCP Registry Manager** (`dagda/mcp-manager/mcp-registry.sh`)
```bash
#!/bin/bash

SCRIPT_NAME="mcp-registry"
source "${DAGDA_ROOT}/.env"
source "${DAGDA_ROOT}/dagda/awens-utils/ollamh.sh"

MCP_REGISTRY_DIR="${DAGDA_ROOT}/registry"
MCP_CACHE_DIR="${MCP_REGISTRY_DIR}/cache/mcp"
MCP_CATALOG="${MCP_REGISTRY_DIR}/mcp-catalog.json"

# Fonctions principales
mcp_list() {
    echo "[$SCRIPT_NAME][info] Serveurs MCP disponibles:"
    if [[ -f "$MCP_CATALOG" ]]; then
        jq -r '.mcp_servers | to_entries[] | "\(.key): \(.value.description) (v\(.value.version))"' "$MCP_CATALOG"
    else
        echo "[$SCRIPT_NAME][error] Catalogue MCP non trouvé"
        return 1
    fi
}

mcp_info() {
    local server_name="$1"
    if [[ -z "$server_name" ]]; then
        echo "[$SCRIPT_NAME][error] Nom du serveur MCP requis"
        return 1
    fi
    
    echo "[$SCRIPT_NAME][info] Informations $server_name:"
    jq -r ".mcp_servers[\"$server_name\"]" "$MCP_CATALOG"
}

mcp_install() {
    local server_name="$1"
    if [[ -z "$server_name" ]]; then
        echo "[$SCRIPT_NAME][error] Nom du serveur MCP requis"
        return 1
    fi
    
    echo "[$SCRIPT_NAME][start] Installation serveur MCP $server_name"
    
    # Lire le manifest
    local manifest_file="${MCP_REGISTRY_DIR}/manifests/${server_name}-mcp.yml"
    if [[ ! -f "$manifest_file" ]]; then
        echo "[$SCRIPT_NAME][error] Manifest $server_name non trouvé"
        return 1
    fi
    
    # Créer le répertoire de cache
    local server_cache_dir="${MCP_CACHE_DIR}/${server_name}"
    mkdir -p "$server_cache_dir"
    
    # Télécharger les sources
    local download_url=$(yq eval '.downloads.source_code.url' "$manifest_file")
    local sha256=$(yq eval '.downloads.source_code.sha256' "$manifest_file")
    
    echo "[$SCRIPT_NAME][info] Téléchargement depuis $download_url"
    
    cd "$server_cache_dir"
    curl -L "$download_url" -o "source.tar.gz"
    
    # Vérifier l'intégrité
    if ! echo "$sha256 source.tar.gz" | sha256sum -c -; then
        echo "[$SCRIPT_NAME][error] Vérification SHA256 échouée"
        return 1
    fi
    
    # Extraire
    tar -xzf source.tar.gz --strip-components=1
    
    # Installer les dépendances
    if [[ -f "requirements.txt" ]]; then
        pip install -r requirements.txt
    fi
    
    # Copier vers le pod mcp-extensions
    local extensions_dir="${DAGDA_ROOT}/cauldron/muirdris/mcp-extensions/servers"
    cp -r . "${extensions_dir}/${server_name}/"
    
    # Mettre à jour la configuration
    echo "[$SCRIPT_NAME][success] Serveur MCP $server_name installé"
}

mcp_uninstall() {
    local server_name="$1"
    if [[ -z "$server_name" ]]; then
        echo "[$SCRIPT_NAME][error] Nom du serveur MCP requis"
        return 1
    fi
    
    echo "[$SCRIPT_NAME][start] Désinstallation $server_name"
    
    # Supprimer du cache
    rm -rf "${MCP_CACHE_DIR}/${server_name}"
    
    # Supprimer du pod extensions
    local extensions_dir="${DAGDA_ROOT}/cauldron/muirdris/mcp-extensions/servers"
    rm -rf "${extensions_dir}/${server_name}"
    
    echo "[$SCRIPT_NAME][success] Serveur MCP $server_name désinstallé"
}

mcp_update_catalog() {
    echo "[$SCRIPT_NAME][start] Mise à jour catalogue MCP"
    
    # URL du catalogue central (à adapter)
    local catalog_url="https://registry.dagda-lite.io/mcp-catalog.json"
    
    curl -L "$catalog_url" -o "${MCP_CATALOG
    