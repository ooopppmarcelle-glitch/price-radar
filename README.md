<!-- PHARELL STUDIOS brand header -->
<p align="center">
  <img src="public/pharell-studios-logo.jpg" alt="PHARELL STUDIOS — App Development Studio" width="100%" />
</p>

<p align="center">
  <strong>Created by PHARELL STUDIOS</strong><br />
  <sub>Powered by ChatGPT</sub>
</p>

# PRICE RADAR

**Global Smart Price Intelligence** — Le vrai prix. Au bon endroit. Au bon moment.

PRICE RADAR is an international, free-first product price discovery and comparison PWA. It is designed to help people identify products, compare available offers, track price history and make better-informed purchases.

## Current status

This repository contains the initial React + TypeScript + Vite PWA foundation and a responsive visual prototype. The displayed product cards and prices are **demo data**, not live merchant offers. No real price provider, scanner backend, authentication or alert delivery is connected yet.

## Stack

- React + TypeScript
- Vite
- vite-plugin-pwa
- Lucide icons
- Planned backend: Supabase (to be configured after schema and free-tier limits are reviewed)

## Requirements

- Node.js 20.19+ or 22.12+
- npm

## Run locally

```bash
npm install
npm run dev
```

## Validate and build

```bash
npm run typecheck
npm run build
```

## Project structure

```text
src/
  App.tsx          Main responsive prototype
  main.tsx         Application entry point
  styles.css       Design system and responsive styles
public/
  manifest.webmanifest
```

## Product principles

1. Every price must carry a source and observation date when real data is integrated.
2. Demo, estimated, user-submitted and verified prices must be visibly distinguished.
3. Never invent live offers or imply universal global coverage without evidence.
4. Keep the core consumer experience free at launch.
5. Protect user data and keep secrets out of the browser bundle and Git history.

## Roadmap

- [x] Initial responsive application shell and design direction
- [x] Search/filter interaction over clearly labelled demo catalogue
- [x] PWA manifest and Vite PWA foundation
- [ ] Product and offer data model
- [ ] Supabase schema, access policies and authentication
- [ ] Real data-source integrations
- [ ] Product matching and barcode/image scanning
- [ ] Price history and alerts
- [ ] Community price submissions and moderation
- [ ] Automated tests, accessibility and deployment

## License

License to be selected before public distribution.


## Database foundation

The first relational data model is documented in [docs/price-radar-schema.sql](docs/price-radar-schema.sql). It covers product categories, products, sellers, current offers, verified price observations, community price submissions and private watchlists.

Important safeguards:
- Public offer listings expose only verified and sufficiently recent prices.
- Community submissions remain pending until reviewed.
- User submissions and watchlists are protected with Row Level Security (RLS).
- The SQL file is a reviewed starting schema only. It has **not** been applied to a Supabase project.
- Do not reuse another application's Supabase project. Create or select a dedicated PRICE RADAR project before applying it.


## Data quality policy

See [docs/price-data-quality.md](docs/price-data-quality.md) for source classifications, freshness windows, product matching, currency handling and verification requirements. This is a specification, not evidence that live data sources are connected.
