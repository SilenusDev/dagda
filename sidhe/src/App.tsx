import { Component } from 'solid-js';
import { Router, Route, Routes } from '@solidjs/router';
import Home from './pages/Home';
import './App.css';

const App: Component = () => {
  return (
    <Router>
      <div class="app">
        <header class="app-header">
          <h1>DAGDA-LITE</h1>
          <nav>
            <a href="/">Accueil</a>
          </nav>
        </header>
        <main class="app-main">
          <Routes>
            <Route path="/" component={Home} />
          </Routes>
        </main>
        <footer class="app-footer">
          <p>© 2024 DAGDA-LITE - Interface utilisateur SolidJS</p>
        </footer>
      </div>
    </Router>
  );
};

export default App;
