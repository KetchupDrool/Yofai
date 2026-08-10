# TestFlight Smoke Test — Yofai

**Phase 52 — manual smoke before App Review.**  
Device: physical iPhone preferred for Camera / Photos / Share. Unit tests use **iPhone 16e** simulator.

Do not expect: login, Pro purchase, Direct Upload, AI assistant, marketplace Connect.

## Pass/fail
- [ ] App launches without crash
- [ ] Core Local Export path works end-to-end
- [ ] No AI or marketplace-upload UI presented as available
- [ ] Pro placeholder: not available / no purchase charged

## Script

### 1. Launch
1. Install TestFlight build.
2. Open Yofai.
3. Confirm home / products loads.

### 2. Create product
1. Start / create a new product.
2. Confirm Free create path works (under limit 12).

### 3. Add / import photo
1. Import an existing photo **or** capture with Camera (device).
2. Confirm photo appears in the product.

### 4. Photo Check
1. Open Capture & Check / Photo Check.
2. Confirm local facts (size, canvas notes) — no compliance claims.

### 5. Edit
1. Open Edit on a photo.
2. Apply a simple edit and save.
3. Confirm edit persists.

### 6. Fit mode
1. Set **Contain + Pad**.
2. Switch to **Fill + Crop**.
3. Confirm preview updates.

### 7. Fill + Crop reposition
1. With Fill + Crop, open reposition.
2. Move framing; use **Reset to Center**.
3. Confirm export later honors position (spot-check after export).

### 8. Listing Workspace
1. Open Prepare Listing & Export.
2. Set marketplace target (e.g. Etsy or eBay).
3. Confirm export size (canvas) is separate from marketplace target.
4. Confirm **no** Listing Assistant / AI section.

### 9. Export Readiness / Prep Tips
1. Confirm checklist and tips appear when applicable.
2. Confirm tips do not auto-change fit/crop/size without seller action.

### 10. Export local JPEGs
1. Tap Export Photos.
2. Confirm success summary uses local JPEG / manual upload wording.
3. Confirm **View Exported Files** next step appears.

### 11. Export note
1. Add an optional export note (≤240 chars).
2. Confirm note saves on the batch.

### 12. View Exported Files
1. Open View Exported Files.
2. Confirm ordered local JPEGs; tap one for preview.

### 13. Share Exported Photos
1. Share from history / post-export when files exist.
2. Confirm system share sheet (no marketplace publish claim).

### 14. Share with Note / Copy Export Note
1. If note exists: Share with Note and Copy Export Note.
2. Confirm note text is available; JPEGs unchanged.

### 15. Export Again
1. Use Export Again from history.
2. Confirm settings restore; photo edits unchanged; new export still local-only.

### 16. Yofai Pro placeholder
1. Settings → Yofai Pro.
2. Confirm Free plan.
3. Confirm “not available yet” / **no purchase is charged**.
4. Confirm no Buy / Subscribe / Restore Purchases.

### 17. Etsy Shop
1. Settings → Etsy Shop.
2. Confirm connection **not available**; no Connect button.

### 18. Over-Free-limit (optional)
1. If practical, create past Free limit (12).
2. Confirm over-limit existing products remain viewable/editable.
3. Confirm create is limited without deleting data.

### 19. Negative checks
- [ ] No AI assistant / Open AI / “smart AI” UI
- [ ] No Direct Upload / “publish to marketplace” action
- [ ] No fake Pro pricing
- [ ] No upload status treated as published

## Sign-off
- Build / version: __________  
- Device: __________  
- Tester: __________  
- Date: __________  
- Result: Pass / Fail (notes: __________)
