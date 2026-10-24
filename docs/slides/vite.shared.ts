// Shared Vite config for all decks. Slidev serves `public/` next to the entry file,
// so each deck re-exports this from its own vite.config.ts to share docs/slides/public/.
import { fileURLToPath } from 'node:url'

export default {
  publicDir: fileURLToPath(new URL('./public', import.meta.url)),
  server: {
    // The repo is bind-mounted from the Windows host over 9p, which raises no inotify events.
    watch: { usePolling: true, interval: 300 },
  },
}
