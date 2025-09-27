# Nemeton/cromlech/fastapi/app/models.py
from pydantic import BaseModel, Field
from typing import Optional

class LLMRequest(BaseModel):
    prompt: str = Field(..., description="Texte d'entrée pour le modèle")
    max_tokens: Optional[int] = Field(100, description="Nombre maximum de tokens à générer")
    temperature: Optional[float] = Field(0.7, description="Température de génération", ge=0.0, le=2.0)

class LLMResponse(BaseModel):
    content: str = Field(..., description="Texte généré par le modèle")
    model: str = Field(..., description="Nom du modèle utilisé")
    tokens_used: int = Field(..., description="Nombre de tokens utilisés")

class ServiceStatus(BaseModel):
    status: str = Field(..., description="État du service: running, stopped, error")
    url: Optional[str] = Field(None, description="URL du service")
