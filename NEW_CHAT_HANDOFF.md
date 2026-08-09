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
- Phases 1–31 complete
- Phase 31: AI Listing Assistant Foundation (disconnected)
- Last build/tests: succeeded on iPhone 16e (81 tests)
- App Store upload paused
- Primary local path: `/Volumes/CombatMedic/Yofai`
- GitHub Pages: https://ketchupdrool.github.io/Yofai/

## 5. Completed phases 1–31
1–30. Prior local listing prep features
31. AI Listing Assistant Foundation — local preparation + suggestion review; no live AI

## 6. Phase 31 result
**AI Listing Assistant foundation complete.** Listing Workspace opens AI Listing Assistant with clear disconnected status. Sellers create local AI Preparation records (photos, suggestion types, included/excluded context), review before save, edit/discard suggestions, and apply only approved changes to allowed draft fields. Photo-order suggestions require confirmation and keep alt text on each photo. Production uses `DisconnectedAIListingProvider`; deterministic `MockAIListingProvider` is for tests/previews only. Build + 81 unit tests passed on iPhone 16e.

## 7. Current models/files
**AI:** `AIListingProvider.swift`, `AIPreparationRecord.swift`, `AIListingAssistantView.swift`; `ItemProjectPhoto.stableID`; `ItemProject.aiPreparations`

**Tests:** Phase22–31

## 8. Working features
- AI preparation/review/apply (local), listing information + review, bulk edit/undo, packages, seller defaults, duplicate drafts, workspace, queue, batch export, Etsy foundation (no live OAuth)

## 9. Rules/constraints
- No live AI / Etsy HTTP / OAuth / backend / publishing / uploads
- Do not invent fake AI copy, Etsy IDs, category trees, scopes, or marketplace limits
- Keep share architecture stable
- Prefer `/Volumes/CombatMedic/Yofai` on main

## 10. Required before live AI / OAuth / upload
- Approved live-AI provider plan + credentials/policy
- Backend for Etsy token exchange; client secret server-side only
- Real Etsy credentials, scopes, approval (do not invent)

## 11. Exact first prompt for the next Cursor chat

```text
Continue Yofai iOS work.

Read NEW_CHAT_HANDOFF.md, PROJECT.md, DECISIONS.md, TASKS.md, and SESSION_HANDOFF.md first.

App: Yofai
Bundle ID: com.shawnwright.yofai
Status: Phases 1–31 done. Local AI Listing Assistant foundation (disconnected) + listing information/workspace/queue/export/packages. No live AI/OAuth/upload. Last build/tests succeeded on iPhone 16e (81 tests). App Store upload paused.
Work in /Volumes/CombatMedic/Yofai on main.

Do not guess. Inspect files before coding.
Do not add AI API keys or Etsy client secret to the iPhone app.
Do not make live AI or Etsy requests unless newly approved with real credentials + backend/provider plan.
Do not invent fake AI listing copy, Etsy category trees, IDs, scopes, or marketplace limits.
Do not change Share sheet architecture unless fixing a proven bug.
Build once on iPhone 16e when you change code.

Next: App Store upload prep, or approved live-AI / live-OAuth/backend/upload phase with credentials supplied.
If blocked, report why and the safest alternative.
```
