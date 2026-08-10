# App Store Prep — Yofai (Phase 50)

Freemium-first **Local Export Mode** launch readiness.  
**StoreKit is not implemented. Direct Upload Mode is not implemented.**

## Positioning
Yofai is a marketplace product photo prep app that helps sellers prepare **local JPEG exports for manual upload**.

One-line: *Marketplace product photo prep that exports local JPEGs for manual upload.*

## Freemium / Pro wording
- Free keeps Capture → Organize → Photo Check → Edit → Prepare → Local Export
- Pro is planned / additive only
- Settings → Yofai Pro: current plan Free; Pro not available yet; **no purchase is charged**
- No fake pricing, Subscribe, Buy Pro, or Restore Purchases UI

## Privacy / data (current)
- Photos, projects, edits, export batches, history, and notes stay on device
- No backend account, no AI API, no analytics SDK, no ads
- No marketplace upload / publish
- No live marketplace login
- Camera: capture product photos into a local Item Project
- Photos add: optional Save Listing Copy to the Photos library
- System photo picker: choose existing photos without claiming cloud backup

## App Review risks & mitigations

| Risk | Mitigation |
|---|---|
| Pro placeholder without purchases | Explicit “not available yet / no purchase is charged” |
| Marketplace names | Framed as local export targets + manual upload |
| Compliance / partnership claims | Forbidden in Local Export Mode helpers |
| Etsy OAuth stub | Connect button removed; status “not available” |
| AI Listing Assistant | Labeled Not Available / offline; no AI API |
| Photos permission | Usage strings describe seller photo prep / Save Listing Copy |

## Screenshot plan
Document only — do not generate fake screens here.

Capture on iPhone (6.7" required set + 6.1" as needed):

1. **Start a product** — Products empty or New Product sheet  
   Message: “Start a product photo set on your iPhone”
2. **Capture & check** — Product Intake / Photo Check  
   Message: “Capture and check product photos”
3. **Edit & fit** — Edit / Fill+Crop or Contain+Pad  
   Message: “Edit and fit for export”
4. **Prepare for marketplace** — Marketplace target + export size (destination ≠ canvas)  
   Message: “Prepare for your marketplace”
5. **Export local JPEGs** — Export success summary with View Exported Files  
   Message: “Export local JPEGs for manual upload”
6. **History view/share** — Export History + View Exported Files  
   Message: “Review and share exported files”

Avoid screenshots that imply live upload, Pro purchase, AI connected, or marketplace approval.

## Related docs
- `APP_STORE_METADATA.md` — subtitle, description, keywords, release notes  
- `RELEASE_CHECKLIST.md` — ship steps  
- `PRIVACY_NOTES.md` + `docs/privacy-policy.html` / `docs/support.html`
