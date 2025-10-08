import { Component } from 'solid-js';
import { Router, Route } from '@solidjs/router';
import { Server } from 'lucide-solid';
import Home from './pages/Home';

const App: Component = () => {
  return (
    <div style={{ "min-height": "100vh", display: "flex", "flex-direction": "column" }}>
      {/* Header */}
      <header>
        <div class="header-content">
          <div class="header-logo">
            <Server size={32} color="var(--color-primary)" />
            <h1>DAGDA-LITE</h1>
          </div>
          <nav class="header-nav">
            <a href="/">Accueil</a>
            <a href="/services">Services</a>
          </nav>
        </div>
      </header>

      {/* Main Content */}
      <main style={{ flex: "1" }}>
        <Router>
          <Route path="/" component={Home} />
        </Router>
      </main>

      {/* Footer */}
      <footer>
        <div class="footer-content">
          <p>© 2025 DAGDA-LITE - Interface utilisateur SolidJS</p>
        </div>
      </footer>
    </div>
  );
};

export default App;
