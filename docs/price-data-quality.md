# PRICE RADAR — Price data quality and source policy

## Purpose

PRICE RADAR must help people compare offers without presenting guesses, stale records or community reports as confirmed merchant prices.

## Required fields for a published offer

Every offer shown as current must have:
- Product identity (GTIN when available, otherwise brand + model + matching attributes).
- Seller identity and destination country/market.
- Price amount and ISO 4217 currency code.
- Product page URL or documented source.
- Observation timestamp and, where known, expiry timestamp.
- Availability state.
- Source type and verification state.

## Source classes

| Source class | Meaning | Public display |
|---|---|---|
| Official retailer API/feed | Data supplied through a retailer-approved integration | Show as retailer-sourced; label last check |
| Official product page | Public product listing checked by an approved process | Show only while fresh; link to seller |
| Seller submitted | Seller-provided offer awaiting review | Pending until approved |
| Community submitted | User-reported price | Pending until moderated; then label community-reported |
| Editorial / estimate | Research estimate, not a live merchant offer | Never display as a current offer |

## Freshness rules

Initial product rules (to be tuned after observing provider update frequency):
- Up to 24 hours since check: current.
- 24 hours to 7 days: show as recently checked with a timestamp.
- 7 to 30 days: stale; exclude from default current-price comparisons.
- More than 30 days: expired from current comparison; retain only in historical records if useful.

The database's public offer policy currently uses a 30-day maximum age as a coarse safety boundary. The application should apply stricter display labels and default filters.

## Verification workflow

1. Ingest or receive a price observation.
2. Validate currency, amount, product match, URL and seller.
3. Detect suspicious duplicates, implausible prices and conflicting product variants.
4. Keep user-submitted observations pending.
5. Review and approve/reject through a moderator-only workflow (not implemented yet).
6. Store immutable observation history; do not silently overwrite old prices.
7. Expire offers when they pass their freshness window or seller availability changes.

## Product matching

Prefer exact GTIN/EAN/UPC matches. If unavailable, compare brand, model, capacity, size, color, region and other variant-defining attributes. Never merge distinct variants only because their product names look similar.

## Currency and international display

Store original seller price and ISO currency code. Do not compare raw amounts across currencies. Any converted display must include the conversion rate source and timestamp. Taxes, shipping, import duties and regional pricing must be stated separately when known.

## Legal and operational constraints

- Use retailer APIs, affiliate feeds, licensed datasets or integrations explicitly permitted by the provider.
- Respect website terms, robots rules, rate limits and applicable law; do not bypass access controls.
- Do not promise worldwide coverage until each country/category has reliable sources.
- Keep provider credentials server-side. Never ship secret keys or Supabase service-role keys in the PWA.
- Provide a correction/report mechanism and remove inaccurate or disputed listings promptly.

## Not yet implemented

This policy is a product and engineering standard. It does not mean that source integrations, moderation, fraud detection, currency conversion or live data refresh are already operational.
