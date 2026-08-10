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
- Phases 1–43 technical history complete (see `DECISIONS.md`)
- Marketplace target (destination) is separate from export size (pixel canvas)
- Local export history records what was **exported for** a marketplace — never publish/upload status
- Export history supports transient marketplace filters and metadata-only compare of the two newest exports (no pixel compare)
- Export Readiness checklist and Prep Tips are computed from local state (not persisted); tips never auto-change fit/crop/size; watermark is optional; no compliance claims
- Export fit modes: Contain + Pad (default) and Fill + Crop with optional per-photo reposition
- Verified local export canvases include Etsy sizes, eBay 1600×1600, Poshmark 1000×1000 (recommended; not compliance claims)
- Facebook Marketplace and Mercari intentionally have no named Yofai pixel presets until an exact first-party canvas is verified
- App Store upload remains paused
- Old framing (“general photo editor MVP within 6 days”) is no longer the main goal

## Rules
- Keep changes small. Do not refactor unrelated files.
- Inspect files before editing.
- Do not implement abandoned-roadmap items unless explicitly re-approved.
