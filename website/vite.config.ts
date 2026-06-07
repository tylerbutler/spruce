import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

// Built as a static site. `base` is relative so it works on GitHub Pages
// project subpaths as well as a custom domain root.
export default defineConfig({
  base: "./",
  plugins: [react(), tailwindcss()],
});
