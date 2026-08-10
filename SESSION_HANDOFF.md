# Session Handoff

## Status
Phase 64 complete — Pro multi-market workflow polish.  
**Full suite Passed; build Passed on iPhone 16e.**  
**Marketplace APIs are not next** unless explicitly approved (see `DECISIONS.md`).

## Behavior
- Free: Primary Draft + Prepare Listing & Export + primary package/share + Seller Defaults; Pro lock explains multi-market without blocking local export
- Pro: drafts + status overview + template available/no saved template + copy/share helpers + apply blank fields only
- Still Local Export Mode only — seller uploads manually outside the app
- No Direct Upload / login / OAuth / publish / API

## Why no APIs yet (short)
Local listing prep must be stable first. APIs are marketplace-specific, need external setup and official access, and some markets may not offer third-party upload. Wrong shortcuts (automation/scraping/passwords) are banned.

## Suggested next (approval required)
Later: one official API (likely Etsy or eBay) · or App Store release gates

## Version / build (do not auto-bump)
- Marketing: **1.0** · Build: **1** · Bundle: `com.shawnwright.yofai`

## Owner next steps
Release: **`SHAWN_NEXT_RELEASE_STEPS.md`**.  
Do not start API work without explicit approval.

## Rules
- Freemium-first; Free keeps core local export; no AI / Direct Upload  
- Unit tests: iPhone 16e  
