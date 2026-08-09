# Session Handoff

## Status
Phase 31 complete — AI Listing Assistant Foundation. Build + unit tests succeeded on iPhone 16e (81 tests). App Store upload paused.

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- AI assistant is local-only; production provider is disconnected
- `AIPreparationRecord` cascades with Item Project; duplicate draft does not copy it
- Apply path protects price/qty/shipping/processing/returns/variations/personalization/SKU/condition/item type/export/queue
- Git: `/Volumes/CombatMedic/Yofai` on `main`

## Last Completed
- AI Preparation create/review/save, placeholder + mock suggestion paths, apply + photo-order confirm
- Phase31AIListingAssistantTests; Phases 22–30 still pass

## Remaining Before Live AI / Upload
- Approved live-AI provider + policy/credentials
- Backend + real Etsy OAuth credentials for upload

## Next Recommended
App Store upload prep, or approved live-AI / live-OAuth/upload phase with credentials supplied.

## Rules
- No client secret on iPhone
- No live AI / Etsy HTTP until approved
- Do not invent fake AI listing copy in production
- Do not invent Etsy category trees, IDs, scopes, or marketplace limits
- Keep share architecture stable
