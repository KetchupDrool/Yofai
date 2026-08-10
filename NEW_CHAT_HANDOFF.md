# New Chat Handoff — Yofai

## App
Yofai · `com.shawnwright.yofai` · iPhone · `/Volumes/CombatMedic/Yofai` · `main`  
Date: 2026-08-10 · after Phase 61 + API-later decision docs

## Baseline
- Phase 61: local `MarketplaceListingDraft`; Free primary intact; Pro multi-draft gated
- **APIs not in progress** — local marketplace prep first (`DECISIONS.md`)
- 320 tests Passed on iPhone 16e · Version **1.0 (1)**
- Manual App Store gates still open

## Start here
1. `DECISIONS.md` — Phase 60–61 + **Why marketplace APIs are not being done yet**  
2. `SESSION_HANDOFF.md`  
3. `TASKS.md` / `SHAWN_NEXT_RELEASE_STEPS.md`

## First prompt

```text
Continue Yofai iOS work.

Read DECISIONS.md (Phase 61 + “Why marketplace APIs are not being done yet”) and SESSION_HANDOFF.md first.

Status: Phase 61 done. Local Export Mode only. No Direct Upload / OAuth / marketplace API work.
Next local candidate when approved: Phase 62 draft-aware packages and copy tools.
Work in /Volumes/CombatMedic/Yofai on main. Unit tests on iPhone 16e only.

Do not start marketplace API integration unless the exact marketplace is approved and official access is verified.
Do not use scraping, browser automation, password storage, or unofficial APIs.
```
