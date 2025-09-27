import { Component } from 'solid-js';
import './Home.css';

const Home: Component = () => {
  return (
    <div class="home">
      <section class="hero">
        <h1>Bienvenue dans DAGDA-LITE</h1>
        <p class="hero-subtitle">
          Plateforme d'orchestration et d'automatisation moderne
        </p>
      </section>

      <section class="features">
        <div class="feature-grid">
          <div class="feature-card">
            <h3>🗄️ Base de Données</h3>
            <p>MariaDB avec base dagda_db opérationnelle</p>
            <a href="http://192.168.1.43:8903" target="_blank" class="btn">
              Accéder à Adminer
            </a>
          </div>

          <div class="feature-card">
            <h3>🔧 Services</h3>
            <p>Orchestration des conteneurs Podman</p>
            <div class="status-indicator">
              <span class="status-dot active"></span>
              MariaDB: Actif
            </div>
          </div>

          <div class="feature-card">
            <h3>🚀 API</h3>
            <p>Interface FastAPI pour les services</p>
            <a href="http://192.168.1.43:8902" target="_blank" class="btn">
              Documentation API
            </a>
          </div>

          <div class="feature-card">
            <h3>🔄 Workflows</h3>
            <p>Automatisation avec N8N</p>
            <a href="http://192.168.1.43:8904" target="_blank" class="btn">
              Interface N8N
            </a>
          </div>
        </div>
      </section>

      <section class="system-info">
        <h2>État du Système</h2>
        <div class="info-grid">
          <div class="info-item">
            <strong>Host:</strong> 192.168.1.43
          </div>
          <div class="info-item">
            <strong>Base DAGDA:</strong> dagda_db
          </div>
          <div class="info-item">
            <strong>Version:</strong> 1.0.0
          </div>
        </div>
      </section>
    </div>
  );
};

export default Home;
