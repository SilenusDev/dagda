import { defineConfig } from 'vite';
import solid from 'vite-plugin-solid';

export default defineConfig({
  plugins: [solid()],
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: false,
    minify: 'esbuild',
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['solid-js', '@solidjs/router']
        }
      }
    }
  },
  server: {
    host: '0.0.0.0',
    port: parseInt(process.env.VITE_PORT || '8900'),
    strictPort: true,
    watch: {
      usePolling: true,
      interval: 1000,
      ignored: ['**/node_modules/**', '**/.git/**']
    },
    hmr: {
      host: process.env.HOST || process.env.VITE_HOST || 'localhost',
      port: parseInt(process.env.VITE_PORT || '8900')
    }
  },
  preview: {
    host: '0.0.0.0',
    port: parseInt(process.env.VITE_PORT || '8900'),
    strictPort: true
  }
});
