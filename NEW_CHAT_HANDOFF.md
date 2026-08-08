# New Chat Handoff — Yofai

## 1. App name
Yofai

## 2. Bundle ID
`com.shawnwright.yofai`

## 3. Current date
2026-08-08

## 4. Current app status
- iPhone-only SwiftUI + SwiftData
- Local-only listing / photo-prep tool
- Phases 1–21 complete
- Phase 20: listing export presets + solid backgrounds
- Phase 21: simple seller watermark text on listing exports
- Share uses stable temp JPEG + `.sheet(item:)`
- Last build: succeeded on iPhone 16e
- App Store upload paused
- GitHub Pages: https://ketchupdrool.github.io/Yofai/

## 5. Completed phases 1–21
1–19. MVP editor + Premium Glass UI + icon/launch + compact Edit
20. Listing export presets (contain + pad; white/black/soft gray)
21. Listing watermark text (toggle + field; History Yes/No)

## 6. Phase 21 result
**Watermark complete.** Optional text drawn after listing pad. Save/Share include watermark when enabled with non-empty text. History stores optional didWatermark. Share architecture unchanged. Build succeeded on iPhone 16e.

## 7. Current models/files
**Models / storage:** `SavedEdit.swift`, `ImportedOriginal.swift`, `LocalEditStore.swift`, `PhotoEditState.swift`, `ImageEditing.swift`, `ListingExport.swift`

**Theme / UI helpers:** `DarkroomTheme.swift`

**Views:** `YofaiApp.swift`, `ContentView.swift`, `HomeView.swift`, `ImportView.swift`, `EditView.swift`, `FreeformCropView.swift`, `HistoryView.swift`, `HistoryDetailView.swift`, `OriginalsView.swift`, `OriginalDetailView.swift`, `SettingsView.swift`, `ActivityShareView.swift`

**Assets:** AppIcon, LaunchMark, LaunchBackground; `Info.plist`

**Project:** `Yofai.xcodeproj`, `project.yml`

## 8. Current working features
- Import → Edit → listing Export (preset + background + optional watermark)
- Save Listing Copy → Photos + History (framed, watermark baked in when on)
- Share → framed JPEG via ShareFileItem
- History/Home show listing summary + Watermark Yes/No when set
- Originals library; Settings; Premium Glass UI

## 9. Current rules/constraints
- Local-only; free
- No backend, login, payments, ads, AI API, subscription, one-time payment
- No transparent export / frames / logo watermark unless approved
- Keep ShareFileItem architecture stable
- No unrelated refactors
- One iPhone simulator unless approved

## 10. Known risks/limits
- Edit tools may scroll more with Export + watermark field
- Full export canvases cost more on Save/Share
- Manual Share retest with watermark still needed
- Import re-picks create another Original (no dedupe)
- Preview uses capped listing canvas; Save/Share full locked pixels

## 11. Exact first prompt for the next Cursor chat

```text
Continue Yofai iOS work.

Read NEW_CHAT_HANDOFF.md, PROJECT.md, DECISIONS.md, TASKS.md, and SESSION_HANDOFF.md first.

App: Yofai
Bundle ID: com.shawnwright.yofai
Status: Phases 1–21 done. Listing export + watermark live. Share uses ShareFileItem temp JPEG. Local-only. Last build succeeded on iPhone 16e. App Store upload paused.

Do not guess. Inspect files before coding.
Do not add backend, login, payments, ads, AI API, subscription, or one-time payment.
Do not change Share sheet architecture unless fixing a proven bug.
Do not add transparent export, frames, or logo watermarks unless newly approved.
Do not refactor unrelated files.
Build once on iPhone 16e when you change code.

Next: visual smoke-test of Share + watermark, or App Store upload prep.
If that is blocked, report why and recommend the safest alternative.
```
