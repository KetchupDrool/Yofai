# Yofai

## App
- Name: Yofai
- Bundle ID: com.shawnwright.yofai
- SKU: yofai-ios
- Type: Mosaic
- Platform: iPhone, SwiftUI, SwiftData

## Product purpose (locked 2026-08-09)
Local-first marketplace product photo preparation for online sellers.

Core functionality is **local-first/on-device**.

## What sellers do in Yofai
- Photograph products
- Organize product photo sets
- Check photo quality
- Edit photos
- Resize/crop for marketplaces
- Prepare listing-ready exports
- Export locally for Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, and similar marketplaces

Those marketplaces are **export targets only** — not live integrations or publishing destinations.

## Priority
Keep the product focused on local seller photo preparation. Do not start new feature coding until an explicit next phase is approved.

## Constraints (active)
- Core photo preparation remains local-first/on-device
- No paid/live AI APIs on the active roadmap
- No OAuth marketplace publishing on the active roadmap
- No direct Etsy publishing or direct publishing to any marketplace on the active roadmap

## Future capabilities (approved direction, not next work)
These may be added later where they support the product:
- Backend services
- User accounts
- Cloud sync
- Subscriptions
- Ads

They are not immediate implementation tasks. Core photo preparation stays local-first/on-device even if some of these arrive later.

## Primary workflow
Home → Start / Continue Product → Item Project → Capture & Check Photos → Prepare Listing & Export → local export.
Import, Originals, and History remain available as secondary tools.

## Status
- Phases 1–37 technical history complete (see `DECISIONS.md`)
- Export fit modes: Contain + Pad (default) and Fill + Crop (center); Phase 37 supersedes Phase 20 contain+pad-only
- Verified local export canvases include Etsy sizes, eBay 1600×1600, Poshmark 1000×1000 (recommended; not compliance claims)
- Facebook Marketplace and Mercari named pixel presets deferred until verified
- App Store upload remains paused
- Old framing (“general photo editor MVP within 6 days”) is no longer the main goal

## Rules
- Keep changes small. Do not refactor unrelated files.
- Inspect files before editing.
- Do not implement abandoned-roadmap items unless explicitly re-approved.
