# Session Handoff

## Status
Phase 32 complete — Product Intake + Guided Photo Capture. Build + unit tests succeeded on iPhone 16e (92 tests). App Store upload paused.

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Product Intake reuses Item Project photos; photo-plan goals are local guidance only
- System camera via UIImagePickerController; simulator unavailable is safe
- Seller review checkboxes do not affect Phase 25 readiness
- Git: `/Volumes/CombatMedic/Yofai` on `main`

## Last Completed
- Photo plan, capture flow, Photo Check, intake UI entry points
- Phase32ProductIntakeTests; Phases 22–31 still pass

## Remaining Before Live AI / Upload
- Approved live-AI provider + policy/credentials
- Backend + real Etsy OAuth credentials for upload

## Next Recommended
App Store upload prep, or approved live-AI / live-OAuth/upload phase with credentials supplied.

## Rules
- No client secret on iPhone
- No live AI / Etsy HTTP until approved
- Do not fake AI copy or camera captures in production
- Do not invent Etsy category trees, IDs, scopes, or marketplace limits
- Keep share architecture stable
