// Configuration centralisée pour Sidhe
// Utilise les variables d'environnement Vite

const HOST = import.meta.env.VITE_HOST || 'localhost';
const API_PORT = import.meta.env.VITE_API_PORT || '8902';
const ADMIN_PORT = import.meta.env.VITE_ADMIN_PORT || '8903';
const WORKFLOW_PORT = import.meta.env.VITE_WORKFLOW_PORT || '8904';

export const config = {
  apiUrl: `http://${HOST}:${API_PORT}`,
  adminerUrl: `http://${HOST}:${ADMIN_PORT}`,
  n8nUrl: `http://${HOST}:${WORKFLOW_PORT}`,
  host: HOST,
};
