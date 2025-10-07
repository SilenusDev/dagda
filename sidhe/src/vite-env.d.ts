/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_HOST: string;
  readonly VITE_API_PORT: string;
  readonly VITE_ADMIN_PORT: string;
  readonly VITE_WORKFLOW_PORT: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
