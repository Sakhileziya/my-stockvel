import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          green: "#00A86B",
          gold: "#FFB800",
          dark: "#1A1A2E",
          light: "#F8FAF9",
        },
      },
    },
  },
  plugins: [],
};

export default config;
