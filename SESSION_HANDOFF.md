# Session Handoff

## Status
Phase 47 complete — Local Export File Access & UX Polish. Build + unit tests succeeded on iPhone 16e (264 tests; 10 Phase 47). Local Export Mode remains current. Direct Upload Mode not implemented. App Store upload paused.

## Product purpose
Local-first marketplace product photo preparation for online sellers.
Core photo prep is local-first/on-device.
**Local Export Mode** = current. **Direct Upload Mode** = future only (`MARKETPLACE_UPLOAD_ROADMAP.md`).

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Export batches live under Application Support / ExportBatches; history can view/re-share when files remain
- Missing export files show a safe message; delete history removes export folder only
- Does not upload/publish; no upload status
- Hard bans: browser automation, unofficial APIs, marketplace passwords, AI API for upload
- Git: `/Volumes/CombatMedic/Yofai` on `main`

## Last Completed
- Phase 47: `ExportBatchFileAccessSupport`, `ExportedFilesViewer`, history View/Share/More actions, Phase47 tests

## Abandoned from the active near-term roadmap
- Paid/live AI APIs
- Browser automation / unofficial APIs / marketplace password storage

## Future capability (approved direction — not next work)
Backend, accounts, cloud sync, subscriptions, ads, and verified Direct Upload Mode may be added later; core photo prep stays local-first/on-device.

## Next Recommended
Phase 48 only when approved — further Local Export Mode polish, or verified Etsy upload foundation after manual API/OAuth confirmation. Do not start Phase 48 unprompted.

## Rules
- Core photo preparation: local-first/on-device
- Do not invent marketplace sizes, category trees, IDs, scopes, or compliance limits
- Do not claim Direct Upload Mode exists
- Keep share architecture stable (optional caption only)
