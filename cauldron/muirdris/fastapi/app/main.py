# Nemeton/cromlech/fastapi/app/main.py
import os
import httpx
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from .models import LLMRequest, LLMResponse

# Configuration depuis variables d'environnement
app = FastAPI(
    title="Dagda-Lite API", 
    version="1.0.0",
    description="API pour orchestration des services LLM"
)

# CORS pour SolidJS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # À restreindre en production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration des endpoints LLM depuis .env
LLAMA_URL = f"http://{os.getenv('HOST')}:{os.getenv('LLAMA_PORT')}"
QWEN_URL = f"http://{os.getenv('HOST')}:{os.getenv('QWEN25_05_PORT')}"

# Endpoints de santé
@app.get("/health")
def health_check():
    return {"status": "healthy", "service": "fastapi"}

@app.get("/api/status")
def api_status():
    return {
        "api": "running",
        "version": "1.0.0",
        "llm_services": {
            "llama": LLAMA_URL,
            "qwen": QWEN_URL
        }
    }

# Endpoints LLM génériques
@app.post("/api/llm/generate", response_model=LLMResponse)
async def llm_generate(request: LLMRequest, model: str = "llama"):
    """
    Génère du texte avec le modèle spécifié
    """
    # Déterminer l'URL selon le modèle
    if model == "llama":
        url = f"{LLAMA_URL}/completion"
    elif model == "qwen":
        url = f"{QWEN_URL}/completion"
    else:
        raise HTTPException(status_code=400, detail=f"Modèle {model} non supporté")
    
    # Préparer la requête pour llama.cpp
    llama_request = {
        "prompt": request.prompt,
        "n_predict": request.max_tokens,
        "temperature": request.temperature,
        "stop": ["\n\n"]
    }
    
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(url, json=llama_request)
            response.raise_for_status()
            
            llama_response = response.json()
            
            return LLMResponse(
                content=llama_response.get("content", ""),
                model=model,
                tokens_used=llama_response.get("tokens_predicted", 0)
            )
            
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail=f"Timeout lors de l'appel à {model}")
    except httpx.RequestError as e:
        raise HTTPException(status_code=503, detail=f"Erreur de connexion à {model}: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erreur interne: {str(e)}")

# Endpoints spécifiques par modèle
@app.post("/api/llama/generate", response_model=LLMResponse)
async def llama_generate(request: LLMRequest):
    """
    Génère du texte avec Llama
    """
    return await llm_generate(request, model="llama")

@app.post("/api/qwen/generate", response_model=LLMResponse)
async def qwen_generate(request: LLMRequest):
    """
    Génère du texte avec Qwen
    """
    return await llm_generate(request, model="qwen")

# Endpoints de statut des modèles
@app.get("/api/llm/status")
async def llm_status():
    """
    Vérifie le statut des services LLM
    """
    status = {}
    
    # Vérifier Llama
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{LLAMA_URL}/health")
            status["llama"] = "running" if response.status_code == 200 else "error"
    except:
        status["llama"] = "stopped"
    
    # Vérifier Qwen
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{QWEN_URL}/health")
            status["qwen"] = "running" if response.status_code == 200 else "error"
    except:
        status["qwen"] = "stopped"
    
    return {"models": status}

# Endpoint pour lister les modèles disponibles
@app.get("/api/llm/models")
def list_models():
    """
    Liste les modèles LLM disponibles
    """
    return {
        "models": [
            {
                "name": "llama",
                "description": "Llama model via llama.cpp",
                "endpoint": "/api/llama/generate",
                "status_url": f"{LLAMA_URL}"
            },
            {
                "name": "qwen",
                "description": "Qwen 2.5-0.5b model via llama.cpp",
                "endpoint": "/api/qwen/generate", 
                "status_url": f"{QWEN_URL}"
            }
        ]
    }
