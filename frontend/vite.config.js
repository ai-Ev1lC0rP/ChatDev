import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'

/**
 * Dev server — localhost + reverse-proxy HMR
 *
 * Local: http://localhost:5173 — leave VITE_HMR_CLIENT_PORT unset.
 *
 * Behind HTTPS reverse proxies (*.casonclark.com — e.g. chatdev, chat-dev, bit):
 *   VITE_HMR_CLIENT_PORT=443  → browser HMR uses wss://<public-host>:443
 *   instead of ws://localhost:5173. Documented in .env.example.
 *
 * allowedHosts: true — accept Host headers from those proxies (and any other).
 */
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const apiTarget = env.VITE_API_BASE_URL || 'http://localhost:6400'

  const hmrClientPort = env.VITE_HMR_CLIENT_PORT
    ? Number(env.VITE_HMR_CLIENT_PORT)
    : undefined

  return {
    plugins: [vue()],
    server: {
      host: true,
      allowedHosts: true,
      ...(hmrClientPort
        ? {
            hmr: {
              protocol: 'wss',
              clientPort: hmrClientPort,
            },
          }
        : {}),
      proxy: {
        '/api': {
          target: apiTarget,
          changeOrigin: true,
        },
        '/ws': {
          target: apiTarget,
          ws: true,
          changeOrigin: true,
        },
      },
    },
  }
})
