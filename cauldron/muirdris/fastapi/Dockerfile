# Nemeton/cromlech/fastapi/Dockerfile
FROM python:3.11-slim

# Métadonnées
LABEL maintainer="Dagda-Lite"
LABEL description="FastAPI with httpx for LLM integration"
LABEL version="1.0.0"

# Arguments de construction
ARG APP_HOME=/home/app

# Variables d'environnement
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV APP_HOME=${APP_HOME}

# Installer les dépendances système
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Installer les dépendances Python
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
    fastapi==0.104.1 \
    uvicorn[standard]==0.24.0 \
    httpx==0.25.0 \
    pydantic==2.4.2

# Créer utilisateur non-root
RUN useradd --create-home --shell /bin/bash app
USER app
WORKDIR ${APP_HOME}

# Copier le code de l'application
COPY --chown=app:app . ${APP_HOME}/

# Exposer le port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Commande de démarrage
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
