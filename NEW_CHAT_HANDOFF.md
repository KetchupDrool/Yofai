# New Chat Handoff — Yofai

## 1. App name
Yofai

## 2. Bundle ID
`com.shawnwright.yofai`

## 3. Platform / stack
iPhone · SwiftUI + SwiftData · `/Volumes/CombatMedic/Yofai` · `main`

## 4. Current date
2026-08-10

## 5. Verified baseline
- Phase 53 StoreKit / Yofai Pro payments complete (in-app)
- 295 tests passed · iPhone 16e
- Freemium-first · no-AI · Local Export Mode only
- Direct Upload not implemented
- App Store Connect Pro products **still required** before live charges
- Do not submit to App Store until Connect IAP + release checklist are done

## 6. StoreKit
- Monthly: `com.shawnwright.yofai.pro.monthly` (intended $4.99)
- Yearly: `com.shawnwright.yofai.pro.yearly` (intended $39.99)
- Docs: `APP_STORE_CONNECT_SUBSCRIPTIONS.md`, `Yofai/Yofai.storekit`

## 7. Rules
- Free keeps core local export; Pro additive; no fake purchase success; no data deletion
- No AI / Direct Upload / backend vendor unless newly approved
- Unit tests: iPhone 16e only

## 8. Exact first prompt for the next Cursor chat

```text
Continue Yofai iOS work.

Read NEW_CHAT_HANDOFF.md, SESSION_HANDOFF.md, APP_STORE_CONNECT_SUBSCRIPTIONS.md, RELEASE_CHECKLIST.md, PROJECT.md, DECISIONS.md, and TASKS.md first.

Status: Phase 53 StoreKit Pro foundation done (295 tests). Connect subscription products not claimed created. Freemium-first, no-AI, Local Export Mode only.
Work in /Volumes/CombatMedic/Yofai on main. Unit tests on iPhone 16e only.

Next: only an explicitly approved step (Connect IAP setup help, sandbox TestFlight purchase smoke, screenshot/archive/submit, or Direct Upload foundation).
Do not start Phase 54 unless approved.
```
