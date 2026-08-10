# New Chat Handoff — Yofai

## 1. App name
Yofai

## 2. Bundle ID
`com.shawnwright.yofai`

## 3. Platform / stack
- iPhone
- SwiftUI + SwiftData
- Path: `/Volumes/CombatMedic/Yofai`
- Branch: `main`

## 4. Current date
2026-08-10

## 5. Verified baseline (repo history)
| Item | Value |
|---|---|
| HEAD | `e84b52b` — Phase 51 no-AI positioning cleanup |
| Phase 51 | complete @ `e84b52b` |
| Phase 50 | complete @ `f7223c3` |
| Phase 49 | complete @ `4aa6204` |
| Phase 48 | complete @ `febeb38` |
| Tests | **275** passed (Phase 51 suite) |
| Build | succeeded |
| Simulator | **iPhone 16e** only |
| Working tree | clean at last Phase 51 push |

**Note:** Phase 50 and Phase 51 were completed on `main` after `4aa6204`. Do not re-run them unless explicitly re-approved.

## 6. Product summary
Yofai is a **freemium-first**, **local-first**, **no-AI** marketplace product photo-prep app for sellers.

**Workflow:** Capture → Organize → Photo Check → Edit → Prepare → Local Export

**Current production behavior (Local Export Mode):**
- Prepares local JPEG exports for marketplace use
- Seller manually uploads exported JPEGs in marketplace apps/websites
- No marketplace upload / publish
- No Direct Upload Mode
- Marketplace target is separate from export canvas
- Export history + optional export notes are local
- Exported files can be viewed / re-shared from history
- Free users keep the core local export workflow

## 7. Monetization
- Freemium foundation exists (`EntitlementSupport.swift`)
- StoreKit **not** implemented
- Current plan: Free
- Free active product create limit: **12** (over-limit products remain viewable/editable; no auto-delete)
- Pro planned / additive only
- Settings → Yofai Pro placeholder: “not available yet / **no purchase is charged**”
- No fake pricing, Subscribe, Buy Pro, or Restore Purchases UI

## 8. Upload / backend
- No backend vendor
- No account system
- No Direct Upload Mode
- No marketplace OAuth upload
- No upload/publish status
- Etsy is only a possible future Direct Upload target after manual API/OAuth confirmation (`MARKETPLACE_UPLOAD_ROADMAP.md`)
- App remains Local Export Mode only

## 9. No-AI (hard constraint — Phase 51)
- Yofai **does not use AI**
- No OpenAI API, AI listing assistant, AI photo analysis, prompt flows, or AI provider abstractions
- Photo Check, Export Readiness, and Prep Tips are **deterministic/local**
- Listing Assistant UI + providers removed
- Dormant `AIPreparationRecord` SwiftData shell retained **only** for existing store compatibility (no UI)
- Do not add “future AI” roadmap language

## 10. Presets
- **7** preset cases remain unchanged — do not change raw values/dimensions
- Facebook Marketplace and Mercari have **no** fixed named presets — do not invent dimensions
- Marketplace destination (target) ≠ export pixel canvas

## 11. Core rules
- Freemium-first if monetized; Free keeps core local export; Pro additive
- Do not launch fully free and later lock existing core Free features
- Preserve existing user data
- No Direct Upload / OAuth upload / browser automation / marketplace passwords / guessed APIs unless explicitly approved
- No compliance / partnership / AI claims
- No invented marketplace dimensions
- Keep changes small; no unrelated refactors
- One simulator only: **iPhone 16e**
- See `.cursor/rules/project.mdc`

## 12. Recent completed phases (37–51)

| Phase | Summary | Tests | Commit |
|---|---|---|---|
| 37 | Contain+Pad default; Fill+Crop added | 138 | `143fea3` |
| 38 | Per-photo Fill+Crop reposition; Reset to Center; batch honors position | 153 | `769e0cc` |
| 39 | Marketplace target ≠ canvas; FB Marketplace / Mercari guidance-only | 172 | `70f121f` |
| 40 | Per-product export history; “exported for” not published; restore settings | 185 | `635c864` |
| 41 | Marketplace filters; metadata-only compare; Export Again restores settings | 198 | `20c5fcd` |
| 42 | Computed Export Readiness checklist; no compliance claims | 213 | `b9237c5` |
| 43 | Computed Prep Tips (max 3); no auto-fixes | 228 | `370726a` |
| 44 | Optional local export-batch notes (`sellerNote`, 240 chars) | 240 | `69bed57` |
| 45 | Local Export confirmed; Direct Upload roadmap/feasibility only | 246 | `4c922b2` |
| 46 | Share polish: Share Exported Photos / Share with Note / Copy Export Note | 254 | `063a1a6` |
| 47 | View Exported Files; re-share; missing-file handling | 264 | `0e8b8d3` |
| 48 | Post-export View Exported Files next step; history action order; a11y/wording | *(Phase 48 suite)* | `febeb38` |
| 49 | Freemium foundation; Free limit 12; Pro placeholder; no StoreKit | 278 | `4aa6204` |
| 50 | App Store prep docs + review-safe copy; Etsy Connect hidden | 282 | `f7223c3` |
| 51 | No-AI cleanup; assistant UI/providers removed; docs/rules neutralized | **275** | `e84b52b` |

### Phase 48 (verified from `DECISIONS.md` + `febeb38`)
- Post-export next step: View Exported Files for the just-created batch
- History: View + Share primary; More = Share with Note → Copy Note → Add/Edit Note → Use These → Export Again → Delete
- Dynamic Type / accessibility pass; local JPEG / manual-upload wording only
- No upload, OAuth, backend, analytics, subscriptions, ads, or new presets

### Phase 50 (verified @ `f7223c3`)
- `APP_STORE_PREP.md`, `APP_STORE_METADATA.md`, `RELEASE_CHECKLIST.md`, privacy/support pages
- Etsy Connect button removed while OAuth incomplete
- No StoreKit; no Direct Upload; no compliance claims

### Phase 51 (verified @ `e84b52b`)
- Removed `AIListingAssistantView`, `AIListingProvider`, Phase 31 tests, Listing Workspace AI section
- Slim `AIPreparationRecord` shell kept for SwiftData compatibility
- App Store / privacy / rules / handoffs state: no AI

## 13. Important files
**Export / marketplace**
- `MarketplaceExportSupport.swift`, `ListingExport.swift`, `ProjectBatchExporter.swift`, `ProjectExportBatch.swift`
- `ExportHistorySection.swift`, `ExportBatchNoteSupport.swift`, `ExportBatchNoteEditor.swift`
- `ExportBatchFileAccessSupport.swift`, `ExportedFilesViewer.swift`
- `LocalExportShareSupport.swift`, `ActivityShareView.swift`
- `ExportReadinessChecklistSection.swift`, `ExportPrepTipSupport.swift`, `ExportPrepTipsSection.swift`, `ExportPreviewCard.swift`

**Freemium / settings**
- `EntitlementSupport.swift`, `YofaiProPlaceholderView.swift`, `ProjectsView.swift`, `SettingsView.swift`

**Core project / UI**
- `ItemProject.swift`, `SellerDefaults.swift`, `ProjectDetailView.swift`, `ListingWorkspaceView.swift`
- `ProductIntakeView.swift`, `PhotoPlanSupport.swift`, `PhotoEditState.swift`, `ImageEditing.swift`
- `AIPreparationRecord.swift` (dormant store shell only)

**Docs / rules**
- `MARKETPLACE_UPLOAD_ROADMAP.md`, `APP_STORE_PREP.md`, `APP_STORE_METADATA.md`, `RELEASE_CHECKLIST.md`
- `PROJECT.md`, `DECISIONS.md`, `TASKS.md`, `SESSION_HANDOFF.md`, `NEW_CHAT_HANDOFF.md`
- `.cursor/rules/project.mdc`

## 14. Recommended next work
Do **not** start Phase 50 or 51 again.

Next only when explicitly approved:
1. **App Store submit path** — follow `RELEASE_CHECKLIST.md` (screenshots, App Store Connect metadata, TestFlight smoke, submit)
2. **StoreKit / Yofai Pro payments** — real purchases only; no fake success
3. **Verified Direct Upload foundation** — only after manual official API/OAuth confirmation (Etsy first candidate)

## 15. Exact first prompt for the next Cursor chat

```text
Continue Yofai iOS work.

Read NEW_CHAT_HANDOFF.md, SESSION_HANDOFF.md, APP_STORE_PREP.md, RELEASE_CHECKLIST.md, PROJECT.md, DECISIONS.md, TASKS.md, and .cursor/rules/project.mdc first.

Verified baseline:
- main @ e84b52b (Phase 51 complete)
- Phases 48–51 complete (48=febeb38, 49=4aa6204, 50=f7223c3, 51=e84b52b)
- 275 tests passed; build succeeded on iPhone 16e
- Yofai is no-AI, freemium-first, Local Export Mode only
- StoreKit not implemented; Direct Upload not implemented
Work in /Volumes/CombatMedic/Yofai on main.
Build/test on iPhone 16e only when changing code.

Do not re-run Phase 50 or Phase 51.
Next: only an explicitly approved phase (App Store screenshots/submit help, StoreKit payments, or verified upload foundation).
```
