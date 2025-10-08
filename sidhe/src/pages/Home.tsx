import { Component } from 'solid-js';
import { Database, Server, Workflow, Activity } from 'lucide-solid';
import { config } from '../config';

const Home: Component = () => {
  return (
    <div class="container py-8">
      {/* Hero Section */}
      <section class="hero">
        <h1>Bienvenue dans DAGDA-LITE</h1>
        <p>Plateforme d'orchestration et d'automatisation moderne</p>
      </section>

      {/* Features Grid */}
      <section class="py-8">
        <div class="grid lg:grid-cols-4 md:grid-cols-2 grid-cols-1">
          {/* Base de données */}
          <div class="card">
            <div class="card-header">
              <Database size={32} color="var(--color-primary)" />
              <h3 class="card-title">Base de Données</h3>
            </div>
            <p class="card-content">
              MariaDB avec base dagda_db opérationnelle
            </p>
            <a href={config.adminerUrl} target="_blank" class="btn btn-primary">
              Accéder à Adminer
            </a>
          </div>

          {/* Services */}
          <div class="card">
            <div class="card-header">
              <Server size={32} color="var(--color-primary)" />
              <h3 class="card-title">Services</h3>
            </div>
            <p class="card-content">
              Orchestration des conteneurs Podman
            </p>
            <div class="status-indicator">
              <span class="status-dot"></span>
              <span>MariaDB: Actif</span>
            </div>
          </div>

          {/* API */}
          <div class="card">
            <div class="card-header">
              <Activity size={32} color="var(--color-primary)" />
              <h3 class="card-title">API</h3>
            </div>
            <p class="card-content">
              Interface FastAPI pour les services
            </p>
            <a href={`${config.apiUrl}/docs`} target="_blank" class="btn btn-primary">
              Documentation API
            </a>
          </div>

          {/* Workflows */}
          <div class="card">
            <div class="card-header">
              <Workflow size={32} color="var(--color-primary)" />
              <h3 class="card-title">Workflows</h3>
            </div>
            <p class="card-content">
              Automatisation avec N8N
            </p>
            <a href={config.n8nUrl} target="_blank" class="btn btn-primary">
              Interface N8N
            </a>
          </div>
        </div>
      </section>

      {/* System Info */}
      <section class="py-8">
        <div class="card">
          <h2 class="card-title mb-6">État du Système</h2>
          <div class="info-grid">
            <div class="info-item">
              <span class="info-label">Host</span>
              <span class="info-value">{config.host}</span>
            </div>
            <div class="info-item">
              <span class="info-label">Base DAGDA</span>
              <span class="info-value">dagda_db</span>
            </div>
            <div class="info-item">
              <span class="info-label">Version</span>
              <span class="info-value">1.0.0</span>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};

export default Home;
