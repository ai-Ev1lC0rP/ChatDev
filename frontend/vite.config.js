import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const target = env.VITE_API_BASE_URL || 'http://localhost:6400'
  // Set VITE_HMR_CLIENT_PORT=443 when serving through an HTTPS reverse proxy
  // so the browser stays on wss://<public-host>:443 instead of localhost:5173.
  // TODO(proxy): document VITE_HMR_CLIENT_PORT (+ allowedHosts) in .env.example
  // and the user guide for *.casonclark.com reverse-proxy hosts.
  const hmrClientPort = env.VITE_HMR_CLIENT_PORT
    ? Number(env.VITE_HMR_CLIENT_PORT)
    : undefined

  return {
    plugins: [vue()],
    server: {
      host: true,
      // Allow chatdev/bit/chat-dev.casonclark.com (and any other reverse-proxy host)
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
          target: target,
          changeOrigin: true,
        },
        '/ws': {
          target: target,
          ws: true,
          changeOrigin: true,
        }
      }
    }
  }
})
