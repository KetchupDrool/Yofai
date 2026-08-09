# Session Handoff

## Status
Phase 30 complete — Complete Local Listing Information. Build + unit tests succeeded on iPhone 16e (70 tests). App Store upload paused.

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Listing Information lives in Listing Workspace; core Phase 23 fields remain in Project Detail
- Alt text is per `ItemProjectPhoto` (survives reorder/delete)
- Listing Information Review is separate from Phase 25 queue readiness
- Git: local tree at `/Volumes/CombatMedic/Yofai` on `main` (Phases 22–29 pushed as `dac0a93`)

## Last Completed
- Phase 30 models, validation, UI, Seller Defaults extensions, duplicate copy
- Phase30ListingInformationTests; Phases 22–29 still pass

## Remaining Before Live Upload
- Backend + real Etsy OAuth credentials
- Actual Etsy publish/upload pipeline

## Next Recommended
App Store upload prep, or approved AI-suggestions / backend/live-OAuth/upload phase with credentials supplied.

## Rules
- No client secret on iPhone
- No live Etsy HTTP until approved
- No AI / publishing / uploads unless newly approved
- Do not invent Etsy category trees, IDs, scopes, or marketplace limits
- Keep share architecture stable
