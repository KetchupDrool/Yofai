# New Chat Handoff — Yofai

## 1. App name
Yofai

## 2. Bundle ID
`com.shawnwright.yofai`

## 3. Current date
2026-08-08

## 4. Current app status
- iPhone-only SwiftUI + SwiftData
- Local-first listing / photo-prep tool
- Phases 1–29 complete
- Phase 29: Bulk Photo Editing + Listing Package
- Last build/tests: succeeded on iPhone 16e
- App Store upload paused
- GitHub Pages: https://ketchupdrool.github.io/Yofai/

## 5. Completed phases 1–29
1–28. Prior local listing prep features
29. Bulk Edit Photos + Listing Package

## 6. Phase 29 result
**Bulk edit + Listing Package complete.** Bulk Edit Photos (Project Detail + Workspace) copies selectable edit recipe fields to targets without touching source image files or History; per-project undo restores prior edit settings. Create Listing Package builds a shareable folder with `listing-details.txt` + ordered JPEGs from the newest successful export batch (requires export first). Packages stored under Application Support/ListingPackages. Build + 60 unit tests passed on iPhone 16e.

## 7. Current models/files
**Bulk edit:** `BulkEditSupport.swift`, `BulkEditPhotosView.swift`; `ItemProject.lastBulkEditUndoData`

**Packages:** `ListingPackage.swift`; LocalEditStore ListingPackages folder

**Tests:** Phase22–29

## 8. Working features
- Bulk edit/undo, listing packages, seller defaults, duplicate drafts, workspace, queue, batch export, Etsy foundation (no live OAuth)

## 9. Rules/constraints
- No live Etsy HTTP / OAuth / backend / AI / publishing / uploads
- Keep share architecture stable

## 10. Required before live OAuth / upload
- Backend for token exchange; client secret server-side only
- Real Etsy credentials, scopes, approval (do not invent)
- Register redirect `yofai://etsy-oauth-callback` with Etsy

## 11. Exact first prompt for the next Cursor chat

```text
Continue Yofai iOS work.

Read NEW_CHAT_HANDOFF.md, PROJECT.md, DECISIONS.md, TASKS.md, and SESSION_HANDOFF.md first.

App: Yofai
Bundle ID: com.shawnwright.yofai
Status: Phases 1–29 done. Bulk edit + listing packages + local workspace/queue/export. No live OAuth/upload. Last build/tests succeeded on iPhone 16e. App Store upload paused.

Do not guess. Inspect files before coding.
Do not add Etsy client secret to the iPhone app.
Do not make live Etsy requests unless newly approved with real credentials + backend plan.
Do not change Share sheet architecture unless fixing a proven bug.
Build once on iPhone 16e when you change code.

Next: App Store upload prep, or approved live-OAuth/backend/upload phase with credentials supplied.
If blocked, report why and the safest alternative.
```
