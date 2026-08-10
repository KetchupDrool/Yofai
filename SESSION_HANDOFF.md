# Session Handoff

## Status
Phase 48 complete — Final Local Export Mode Polish. Build + unit tests succeeded on iPhone 16e (270 tests; 6 Phase 48). Local Export Mode remains current. Direct Upload Mode not implemented. App Store upload paused.

## Product purpose
Local-first marketplace product photo preparation for online sellers.
Core photo prep is local-first/on-device.
**Local Export Mode** = current. **Direct Upload Mode** = future only (`MARKETPLACE_UPLOAD_ROADMAP.md`).

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Post-export next step opens View Exported Files for the just-created batch
- History: View + Share primary; More menu for note/settings/delete
- Does not upload/publish; no upload status
- Hard bans: browser automation, unofficial APIs, marketplace passwords, AI API for upload
- Git: `/Volumes/CombatMedic/Yofai` on `main`

## Last Completed
- Phase 48: `LocalExportPostExportSupport`, `LocalExportNextStepActions`, action-order/DT/a11y polish, Phase48 tests

## Abandoned from the active near-term roadmap
- Paid/live AI APIs
- Browser automation / unofficial APIs / marketplace password storage

## Future capability (approved direction — not next work)
Backend, accounts, cloud sync, subscriptions, ads, and verified Direct Upload Mode may be added later; core photo prep stays local-first/on-device.

## Next Recommended
App Store prep for Local Export Mode, or verified Etsy upload foundation after manual API/OAuth confirmation. Do not start the next phase unprompted.

## Rules
- Core photo preparation: local-first/on-device
- Do not invent marketplace sizes, category trees, IDs, scopes, or compliance limits
- Do not claim Direct Upload Mode exists
- Keep share architecture stable (optional caption only)
