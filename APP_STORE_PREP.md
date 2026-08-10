# App Store Prep — Yofai

**Phase 50** created initial prep. **Phase 52** finalizes the submit path (metadata package, privacy answers, screenshots, TestFlight smoke, release checklist).

Freemium-first **Local Export Mode**.  
**StoreKit is not implemented. Direct Upload Mode is not implemented. No AI.**

## Positioning
Yofai helps online sellers prepare marketplace product photos as **local JPEG exports for manual upload**.

One-line: *Marketplace product photo prep that exports local JPEGs for manual upload.*

## Freemium / Pro wording
- Free keeps Capture → Organize → Photo Check → Edit → Prepare → Local Export
- Pro is planned / additive only
- Settings → Yofai Pro: Free; Pro not available yet; **no purchase is charged**
- No fake pricing, Subscribe, Buy Pro, or Restore Purchases UI

## Privacy / data (current)
- Photos, projects, edits, export batches, history, and notes stay on device
- No account, cloud, or AI service is required for the core local export workflow
- Yofai uses deterministic local checks (Photo Check, Export Readiness, Prep Tips), not AI
- No analytics SDK, no ads
- No marketplace upload / publish
- No live marketplace login
- Camera: capture product photos into a local Item Project
- Photos add: optional Save Listing Copy
- System photo picker: choose existing photos (no cloud-backup claim)

## App Review risks & mitigations

| Risk | Mitigation |
|---|---|
| Pro placeholder without purchases | “Not available yet / no purchase is charged” |
| Marketplace names | Local export targets + manual upload |
| Compliance / partnership claims | Forbidden in Local Export Mode helpers |
| Etsy OAuth stub | Connect removed; “not available” |
| AI claims | No AI UI; docs state no AI |
| Photos permission | Usage strings for seller prep / Save Listing Copy |

## Screenshot capture plan
Document only — **do not generate fake screenshots.**

Capture on required App Store sizes (e.g. 6.7" + 6.1" as needed). Use a sample product with 1–3 clear product photos.

| # | Screen | State / data needed | Overlay / title suggestion | Avoid |
|---|---|---|---|---|
| 1 | Home / Start Product | Empty products or New Product sheet | “Start a product photo set on your iPhone” | Pro paywall, AI badges |
| 2 | Product Intake / Capture & Check | Product with photo; Photo Check visible | “Capture and check product photos” | Compliance / “Etsy ready” |
| 3 | Edit / Fit / Reposition | Edit open; Contain+Pad or Fill+Crop (+ reposition if useful) | “Edit and fit for export” | Auto-crop / AI labels |
| 4 | Listing Workspace — Marketplace + Export Size | Target set; canvas size visible and distinct | “Prepare for your marketplace” | Upload / Connect / publish |
| 5 | Export Readiness / Prep Tips | Checklist + tips on a real project | “Check readiness before export” | Marketplace approved |
| 6 | Export Summary | Successful local export; View Exported Files | “Export local JPEGs for manual upload” | “Published” / Direct Upload |
| 7 | Export History / View Exported Files | History row + viewer with files | “Review and share exported files” | Upload status |
| 8 | Settings / Yofai Pro *(optional)* | Free plan; placeholder sheet | Only if copy clearly says Pro not available / no purchase charged | Fake prices, Buy, Subscribe |

## Related docs
- `APP_STORE_METADATA.md` — metadata + App Review notes  
- `APP_STORE_CONNECT_PRIVACY.md` — privacy questionnaire answers  
- `TESTFLIGHT_SMOKE.md` — manual smoke script  
- `RELEASE_CHECKLIST.md` — archive / upload / submit  
- `PRIVACY_NOTES.md` + `docs/privacy-policy.html` / `docs/support.html`
