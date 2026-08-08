# New Chat Handoff — Yofai

## 1. App name
Yofai

## 2. Bundle ID
`com.shawnwright.yofai`

## 3. Current date
2026-08-08

## 4. Current app status
- iPhone-only SwiftUI + SwiftData
- Local-only listing / photo-prep tool (seller-oriented export)
- Phases 1–20 complete
- Phase 20: listing-ready export presets + solid backgrounds
- Premium Glass UI + icon/launch
- Last build: succeeded on iPhone 16e
- App Store upload paused
- GitHub Pages: https://ketchupdrool.github.io/Yofai/

## 5. Completed phases 1–20
1–14. MVP editor + originals/history/crop/perf/polish
15–17. Darkroom → Premium Glass UI
18. App icon + launch screen
19. Edit compact tool layout
20. Listing export presets (contain + pad; white/black/soft gray)

## 6. Phase 20 result
**Listing-ready export complete.** Locked presets and solid backgrounds. Save Listing Copy + Share use framed export. History stores/shows preset · background. Old history rows still load. Build succeeded on iPhone 16e.

## 7. Current models/files
**Models / storage:** `SavedEdit.swift`, `ImportedOriginal.swift`, `LocalEditStore.swift`, `PhotoEditState.swift`, `ImageEditing.swift`, `ListingExport.swift`

**Theme / UI helpers:** `DarkroomTheme.swift`

**Views:** `YofaiApp.swift`, `ContentView.swift`, `HomeView.swift`, `ImportView.swift`, `EditView.swift`, `FreeformCropView.swift`, `HistoryView.swift`, `HistoryDetailView.swift`, `OriginalsView.swift`, `OriginalDetailView.swift`, `SettingsView.swift`, `ActivityShareView.swift`

**Assets:** AppIcon, LaunchMark, LaunchBackground; `Info.plist`

**Project:** `Yofai.xcodeproj`, `project.yml`

## 8. Current working features
- Import → Edit → listing Export (preset + background)
- Edit: rotate, filters, B/C/S, crop, Undo/Reset
- Save Listing Copy → Photos + History (framed)
- Share → framed export when editing with preset (always on; default Etsy square)
- History/Home show listing summary when present
- Originals library; Settings; Premium Glass UI

## 9. Current rules/constraints
- Local-only; free
- No backend, login, payments, ads, AI API, subscription, one-time payment
- No transparent export / watermark / frames unless approved
- No unrelated refactors
- One iPhone simulator unless approved

## 10. Known risks/limits
- Edit tools may scroll more with Export section
- Full export canvases (esp. 3000×2400) cost more on Save/Share
- Import re-picks create another Original (no dedupe)
- Freeform crop uses rotated image before filters/adjustments
- Preview uses capped listing canvas; Save/Share full locked pixels
- Visual smoke-test still needed

## 11. Exact first prompt for the next Cursor chat

```text
Continue Yofai iOS work.

Read NEW_CHAT_HANDOFF.md, PROJECT.md, DECISIONS.md, TASKS.md, and SESSION_HANDOFF.md first.

App: Yofai
Bundle ID: com.shawnwright.yofai
Status: Phases 1–20 done. Listing-ready export presets live (contain + pad; white/black/soft gray). Local-only. Last build succeeded on iPhone 16e. App Store upload paused.

Do not guess. Inspect files before coding.
Do not add backend, login, payments, ads, AI API, subscription, or one-time payment.
Do not add transparent export, watermark, or frames unless newly approved.
Do not refactor unrelated files.
Build once on iPhone 16e when you change code.

Next: visual smoke-test of listing export flow, or App Store upload prep.
If that is blocked, report why and recommend the safest alternative.
```
