import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';
import tailwindcss from 'tailwindcss';
import autoprefixer from 'autoprefixer';

export default defineConfig({
  plugins: [react()],
  css: {
    postcss: {
      plugins: [
        tailwindcss({
          config: path.resolve(__dirname, 'tailwind.config.js'),
        }),
        autoprefixer(),
      ],
    },
  },
  resolve: {
    alias: {
      '@shared': path.resolve(__dirname, '../../shared'),
      '@assets': path.resolve(__dirname, '../../shared-assets'),
    },
  },
  server: {
    port: 3000,
    host: true,
  },
});
