# Dalely (دليلى) — Landing Page & Privacy Policy

Bilingual landing page and legal privacy disclosure for **Dalely (دليلى)**, built with React 19, TypeScript, and Vite.

## Features

- **Bilingual & RTL-Ready**: Instant switching between English (LTR) and Arabic (RTL) with localized typography (`Readex Pro` and `Outfit`).
- **Theme Modes**: Seamless Light and Dark mode toggle matching Dalely's brand palette (light blue `#1A93EA`, darker blue `#0B6FBF`, coral `#FF8A65`, deep navy `#12263F`).
- **Dedicated Privacy Policy Page**: Accessible via `#privacy` and navigation links, with legal disclosures for local-only Hive storage, foreground-only location, and zero analytics.
- **Interactive Demos**:
  - Live ticking walking distance counter to the parked car.
  - Interactive feature showcase tabs (Car live activity, unified persistent map, zero-cloud privacy matrix).
  - 12 Spot categories visual grid with custom badges.
  - Interactive FAQ accordion.
- **Modern Responsive Design**: Glassmorphic headers, responsive layouts, micro-animations, and thumb-friendly touch targets.

## Getting Started

### Prerequisites
- Node.js 18+ and npm

### Installation
```bash
cd landing
npm install
```

### Development
```bash
npm run dev
```
Runs the local dev server at `http://127.0.0.1:5173/`.

### Production Build
```bash
npm run build
```
Generates optimized static assets in `dist/`.

### Preview Production Build
```bash
npm run preview
```

## Deployment Options

### GitHub Pages / Static Hosting
Build with `npm run build` and deploy the `dist/` directory directly to GitHub Pages, Cloudflare Pages, or AWS S3.

### Vercel / Netlify
Connect the repository and set the root directory to `landing`.
- Build command: `npm run build`
- Output directory: `dist`

## Structure

```
landing/
├── public/assets/          # Brand logos, car artwork, app preview assets
├── src/
│   ├── components/
│   │   ├── Navbar.tsx             # Glassmorphic header with lang & theme toggles
│   │   ├── Hero.tsx               # Live distance mock & app store CTA
│   │   ├── ValuePillars.tsx       # 6 core architecture pillars
│   │   ├── InteractiveShowcase.tsx# Tabbed feature comparisons & architecture
│   │   ├── CategoriesGrid.tsx     # 12 spot categories visual grid
│   │   ├── FaqSection.tsx         # Expandable bilingual FAQ
│   │   ├── DownloadBanner.tsx     # App Store & Google Play conversion banner
│   │   ├── PrivacyPolicy.tsx      # Full privacy policy disclosure
│   │   └── Footer.tsx             # Footer links & copyright
│   ├── data/
│   │   └── translations.ts        # Complete English & Arabic translation dictionary
│   ├── App.tsx                    # Main app state (lang, theme, routing)
│   ├── index.css                  # Custom styling, design tokens, RTL & dark themes
│   └── main.tsx                   # React root entry
└── package.json
```
