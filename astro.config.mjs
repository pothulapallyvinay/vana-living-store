import { defineConfig } from 'astro/config';
import cloudflare from '@astrojs/cloudflare';

export default defineConfig({
  output: 'server',
  build: {
    inlineStylesheets: 'always',
  },
  adapter: cloudflare({
    platformProxy: {
      enabled: true,
    },
  }),
});
