# Session Handoff

## Status
Phase 46 complete — Local Export Share Polish. Build + unit tests succeeded on iPhone 16e (254 tests; 8 Phase 46). Local Export Mode remains current. Direct Upload Mode not implemented. App Store upload paused.

## Product purpose
Local-first marketplace product photo preparation for online sellers.
Core photo prep is local-first/on-device.
**Local Export Mode** = current. **Direct Upload Mode** = future only (`MARKETPLACE_UPLOAD_ROADMAP.md`).

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Code prepares local JPEGs + export history/notes; shares via system sheet; optional note as share caption / Copy Export Note
- Does not upload/publish; no upload status
- Hard bans: browser automation, unofficial APIs, marketplace passwords, AI API for upload
- Git: `/Volumes/CombatMedic/Yofai` on `main`

## Last Completed
- Phase 46: `LocalExportShareSupport`, summary/history/share wording, optional note caption + copy, Phase46 tests

## Abandoned from the active near-term roadmap
- Paid/live AI APIs
- Browser automation / unofficial APIs / marketplace password storage

## Future capability (approved direction — not next work)
Backend, accounts, cloud sync, subscriptions, ads, and verified Direct Upload Mode may be added later; core photo prep stays local-first/on-device.

## Next Recommended
Phase 47 only when approved — further Local Export Mode polish, or verified Etsy upload foundation after manual API/OAuth confirmation. Do not start Phase 47 unprompted.

## Rules
- Core photo preparation: local-first/on-device
- Do not invent marketplace sizes, category trees, IDs, scopes, or compliance limits
- Do not claim Direct Upload Mode exists
- Keep share architecture stable (optional caption only)
