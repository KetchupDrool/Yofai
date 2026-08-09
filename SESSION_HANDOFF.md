# Session Handoff

## Status
Phase 29 complete — Bulk Photo Editing + Listing Package. Build + unit tests succeeded on iPhone 16e. App Store upload paused.

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Bulk edit copies `PhotoEditState` fields only; undo via `lastBulkEditUndoData`
- Packages: Application Support/ListingPackages; require newest successful export batch
- Fit mode remains locked contain + pad

## Last Completed
- Bulk Edit Photos UI + undo
- Create/Share/Delete Listing Package
- Phase 29 tests; Phases 22–28 still pass (60 total)

## Remaining Before Live Upload
- Backend + real Etsy OAuth credentials
- Actual Etsy publish/upload pipeline

## Next Recommended
App Store upload prep, or approved backend/live-OAuth/upload phase with credentials supplied.

## Rules
- No client secret on iPhone
- No live Etsy HTTP until approved
- No AI / publishing / uploads unless newly approved
- Keep share architecture stable
