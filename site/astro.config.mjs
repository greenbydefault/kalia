import { defineConfig } from 'astro/config';

export default defineConfig({
  output: 'static',
  trailingSlash: 'never',
  // Alles CSS inline: kein blockierender Stylesheet-Request im Head (eine Seite, ~40 KB)
  build: { format: 'file', inlineStylesheets: 'always' },
  devToolbar: { enabled: false },
});
