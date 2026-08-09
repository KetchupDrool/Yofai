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
- Phases 1–30 complete
- Phase 30: Complete Local Listing Information
- Last build/tests: succeeded on iPhone 16e (70 tests)
- App Store upload paused
- Primary local path: `/Volumes/CombatMedic/Yofai`
- GitHub Pages: https://ketchupdrool.github.io/Yofai/

## 5. Completed phases 1–30
1–29. Prior local listing prep features
30. Complete Local Listing Information + Listing Information Review

## 6. Phase 30 result
**Listing Information complete.** Listing Workspace opens grouped Listing Information for item type, condition, who/when made, SKU, personalization, variations, category attributes, return policy, and per-photo alt text. Optional fields support Not Applicable. Review reports filled / missing / N/A / needs review without inventing Etsy-ready status. Phase 25 readiness unchanged. Duplicate draft copies new listing-info fields; Seller Defaults extended for safe reusable fields only. Build + 70 unit tests passed on iPhone 16e.

## 7. Current models/files
**Listing info:** `ListingInformationSupport.swift`, `ListingInformationView.swift`; fields on `ItemProject` / `ItemProjectPhoto.altText`

**Defaults/duplicate:** `SellerDefaults.swift` (+ item type, condition, who/when, return policy)

**Tests:** Phase22–30

## 8. Working features
- Listing Information + review, bulk edit/undo, packages, seller defaults, duplicate drafts, workspace, queue, batch export, Etsy foundation (no live OAuth)

## 9. Rules/constraints
- No live Etsy HTTP / OAuth / backend / AI / publishing / uploads
- Do not invent Etsy IDs, category trees, scopes, or marketplace limits
- Keep share architecture stable
- Prefer local Mac path `/Volumes/CombatMedic/Yofai` over cloud clones missing Phases 22+

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
Status: Phases 1–30 done. Local listing information + workspace/queue/export/packages. No live OAuth/upload. Last build/tests succeeded on iPhone 16e (70 tests). App Store upload paused.
Work in /Volumes/CombatMedic/Yofai on main (not a Phase-21-only cloud clone).

Do not guess. Inspect files before coding.
Do not add Etsy client secret to the iPhone app.
Do not make live Etsy requests unless newly approved with real credentials + backend plan.
Do not invent Etsy category trees, IDs, scopes, or marketplace limits.
Do not change Share sheet architecture unless fixing a proven bug.
Build once on iPhone 16e when you change code.

Next: App Store upload prep, or approved AI-suggestions / live-OAuth/backend/upload phase with credentials supplied.
If blocked, report why and the safest alternative.
```
