# New Chat Handoff — Yofai

## 1. App name
Yofai

## 2. Bundle ID
`com.shawnwright.yofai`

## 3. Current date
2026-08-10

## 4. Current app status
- Phases 1–51 complete
- Phase 51: no-AI positioning cleanup
- Yofai is a **no-AI** app (deterministic Photo Check / Readiness / Prep Tips only)
- Free core local export intact; Pro planned; no StoreKit charges
- Direct Upload Mode not implemented
- App Store upload paused until checklist + submit
- Path: `/Volumes/CombatMedic/Yofai`
- Prep docs: `APP_STORE_PREP.md`, `APP_STORE_METADATA.md`, `RELEASE_CHECKLIST.md`

## 5. Phase 51 result
Removed AI Listing Assistant UI and providers. Neutralized App Store / docs / rules AI language. Kept dormant `AIPreparationRecord` shell for existing SwiftData stores only. No OpenAI. No AI roadmap.

## 6. Rules
- Freemium-first; do not lock core Free features later
- No fake purchase UI
- Local Export Mode only
- No AI APIs / AI listing generation / AI photo analysis
- Prefer `/Volumes/CombatMedic/Yofai` on main

## 7. Exact first prompt for the next Cursor chat

```text
Continue Yofai iOS work.

Read NEW_CHAT_HANDOFF.md, APP_STORE_PREP.md, RELEASE_CHECKLIST.md, PROJECT.md, DECISIONS.md, TASKS.md, and SESSION_HANDOFF.md first.

Status: Phases 1–51 done. Yofai is no-AI. Freemium Local Export Mode ready for App Store prep/submit. StoreKit not implemented. Direct Upload not implemented.
Work in /Volumes/CombatMedic/Yofai on main.
Build on iPhone 16e when changing code.

Next: only an explicitly approved phase (screenshots/submit help, StoreKit, or verified upload foundation).
```
