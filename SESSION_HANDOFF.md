# Session Handoff

## Status
Phase 45 complete — Direct Marketplace Upload Feasibility & Roadmap Reset. Build + unit tests succeeded on iPhone 16e (246 tests). Local Export Mode remains current. Direct Upload Mode not implemented. App Store upload paused.

## Product purpose
Local-first marketplace product photo preparation for online sellers.
Core photo prep is local-first/on-device.
**Local Export Mode** = current. **Direct Upload Mode** = future only (`MARKETPLACE_UPLOAD_ROADMAP.md`).

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Code prepares local JPEGs + export history/notes; does not upload/publish
- Feasibility: Etsy official `uploadListingImage` is the strongest documented path; Poshmark / consumer FB Marketplace / Mercari US not first targets
- Hard bans: browser automation, unofficial APIs, marketplace passwords, AI API for upload
- Git: `/Volumes/CombatMedic/Yofai` on `main`

## Last Completed
- Phase 45 docs + `YofaiProductMode` + queue wording cleanup + Phase45 tests

## Abandoned from the active near-term roadmap
- Paid/live AI APIs
- Browser automation / unofficial APIs / marketplace password storage

## Future capability (approved direction — not next work)
Backend, accounts, cloud sync, subscriptions, ads, and verified Direct Upload Mode may be added later; core photo prep stays local-first/on-device.

## Next Recommended
Continue Local Export Mode polish when approved, or a verified Etsy upload foundation only after manual API/OAuth confirmation. Do not default to live upload.

## Rules
- Core photo preparation: local-first/on-device
- Do not invent marketplace sizes, category trees, IDs, scopes, or compliance limits
- Do not claim Direct Upload Mode exists
- Keep share architecture stable
