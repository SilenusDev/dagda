import { Component } from 'solid-js';
import { Router, Route } from '@solidjs/router';
import Home from './pages/Home';
import './App.css';

const App: Component = () => {
  return (
    <div class="app">
      <header class="app-header">
        <h1>DAGDA-LITE</h1>
        <nav>
          <a href="/">Accueil</a>
        </nav>
      </header>
      <main class="app-main">
        <Router>
          <Route path="/" component={Home} />
        </Router>
      </main>
      <footer class="app-footer">
        <p>© 2024 DAGDA-LITE - Interface utilisateur SolidJS</p>
      </footer>
    </div>
  );
};

export default App;
