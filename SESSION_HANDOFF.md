# Session Handoff

## Status
Phase 21 complete. **Save rotation bug fixed** (EXIF orientation normalize). Build succeeded on iPhone 16e. Share architecture unchanged. Local-only. App Store upload paused.

## Facts
- Yofai / `com.shawnwright.yofai` / iPhone-only
- Listing presets + watermark unchanged
- `ImageEditing.normalizedOrientation()` bakes EXIF into pixels before pipeline
- Share still uses ShareFileItem + temp JPEG + `.sheet(item:)`

## Last Completed
- Debugged Save vs Preview rotation mismatch
- Root cause: preview often downscaled (draw normalizes orientation); full Save used oriented UIImage with `rotate(0)` passthrough into CIImage
- Fix: `normalizedOrientation()` at start of `renderPipeline`, `downscaled`, and `imageForCropping`
- User quarter-turn rotate behavior unchanged

## Flow Verified (code paths + build)
Import → Edit preview → Save Listing Copy / Share use same normalized base orientation

## Remaining Rough Spots
- Manual retest with phone camera photos (EXIF .right / .left) still needed
- Edit panel may scroll with watermark field open
- Import re-picks still create another Original (no dedupe)

## Next Recommended
Manual Save orientation retest on iPhone 16e, then App Store prep when ready.

## Rules
- No backend/login/payments/ads/AI/subscriptions
- No transparent / frames / logo watermark unless approved
- Keep ShareFileItem path stable
- One simulator unless approved
