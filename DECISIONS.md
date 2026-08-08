# Decisions

## Locked
- Final app name: Yofai
- Bundle ID: com.shawnwright.yofai
- Platform: iOS first
- UI framework: SwiftUI
- Local storage: SwiftData
- Build tool: Xcode
- Coding assistant: Cursor

## Phase 20 — Listing export (locked)
- Product direction: listing / photo-prep for sellers (local-only)
- Fit mode: contain + pad
- Backgrounds: white, black, soft gray only (no transparent)
- Export presets (pixels):
  - Etsy square: 2000 × 2000
  - Etsy listing: 3000 × 2400
  - Instagram square: 1080 × 1080
  - Facebook post: 1200 × 630
  - Marketplace: 1600 × 1600
- Defaults: Etsy square + white
- Deferred: transparent export, border/shadow frames

## Phase 21 — Watermark (locked)
- Simple text watermark on listing exports only
- State: watermarkEnabled (default false), watermarkText (default "", max 32)
- Draw after contain + pad; bottom-trailing; font scales with canvas
- Text color follows background (light on black, dark on white/soft gray)
- History stores optional didWatermark Bool? (Yes/No); nil = older rows
- Share architecture unchanged (ShareFileItem + temp JPEG + .sheet(item:))
- Deferred: logo watermark, opacity/position pickers, multi-line

## Not Approved Yet
- Backend
- User accounts
- Cloud sync
- AI API calls
- Subscriptions
- Ads
- Social sharing (beyond system Share sheet)

## Naming
- Keep user-facing name as Yofai.
- Keep root folder as Yofai.
- Keep Xcode project as Yofai.xcodeproj.
