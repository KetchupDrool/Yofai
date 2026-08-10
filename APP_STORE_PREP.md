# App Store Prep — Yofai

**Phases 50–56** — positioning, screenshots, and submit-path docs.  
Freemium-first **Local Export Mode**. StoreKit 2 Pro is implemented in-app. **Direct Upload is not implemented. No AI.**

Connect products + TestFlight purchases remain **manual** (`APP_STORE_SUBMIT_GATES.md`).

## Positioning
Yofai helps online sellers prepare marketplace product photos as **local JPEG exports for manual upload**.

One-line: *Marketplace product photo prep that exports local JPEGs for manual upload.*

## Freemium / Pro wording
- Free keeps Capture → Organize → Photo Check → Edit → Prepare → Local Export
- Pro is additive via StoreKit 2 (monthly/yearly) when App Store Connect products exist
- Settings → Yofai Pro: current plan, Upgrade/Manage, Restore Purchases
- If products cannot load: “Purchases are not available right now.” — Free stays usable
- Do not show fake prices when StoreKit products fail to load
- Legal: Terms of Use (Apple EULA) + Privacy Statement on paywall

## Privacy / data (current)
- Photos, projects, edits, export batches, history, and notes stay on device
- No account, cloud, or AI service is required for the core local export workflow
- Purchases (when live) are handled by Apple StoreKit — Yofai does not collect card numbers
- No analytics SDK, no ads
- No marketplace upload / publish; no live marketplace login
- Camera: capture into local Item Project
- Photos add: optional Save Listing Copy
- System photo picker: existing photos (no cloud-backup claim)

## App Review risks & mitigations

| Risk | Mitigation |
|---|---|
| IAP without Connect products | Create products before submit; review notes explain Free works without purchase |
| Marketplace names | Local export targets + manual upload |
| Compliance / partnership | Forbidden in Local Export Mode helpers |
| Etsy OAuth stub | Connect button removed; “not available” |
| AI claims | No AI UI |
| Pro screenshot | Only with real StoreKit prices, or show Free plan / unavailable — never fake purchase success |

---

## Screenshot capture packet (Phase 56)

**Do not generate fake screenshot image assets in-repo unless explicitly asked.**  
Capture on App Store required sizes (e.g. 6.7" + 6.1" as needed). Use one sample product with 1–3 clear product photos.

Device profile: physical iPhone preferred for Camera/Photos; simulator OK for non-camera frames. Unit-test simulator remains **iPhone 16e** only.

| # | Screen name | Setup / data | Exact path | Overlay / title | Do not show |
|---|---|---|---|---|---|
| 1 | Start Product | Empty Products or New Product sheet | Home / Products → New | “Start a product photo set on your iPhone” | Pro paywall, AI badges |
| 2 | Capture & Check Photos | Product with ≥1 photo; Photo Check facts visible | Product → Capture & Check / Photo Check | “Capture and check product photos” | “Etsy ready”, compliance |
| 3 | Edit / Fit / Reposition | Edit open; Contain+Pad or Fill+Crop (+ reposition if useful) | Photo → Edit | “Edit and fit for export” | AI / auto-crop labels |
| 4 | Marketplace + Export Size | Target set; canvas size clearly separate from destination | Prepare Listing & Export | “Prepare for your marketplace” | Upload, Connect, publish |
| 5 | Export Readiness + Prep Tips | Checklist + tips on real project | Listing Workspace readiness / tips | “Check readiness before export” | Marketplace approved |
| 6 | Export Local JPEGs | Successful export; View Exported Files next step | Post-export summary | “Export local JPEGs for manual upload” | Published / Direct Upload |
| 7 | Export History / View Files | History row + viewer with files on disk | History → View Exported Files | “Review and share exported files” | Upload status |
| 8 | Yofai Pro *(optional)* | Free plan; paywall with **real** StoreKit prices **or** unavailable copy | Settings → Yofai Pro → Upgrade | “Optional Yofai Pro” | Fake success, invented $, AI, Direct Upload available |

### Screenshot status (repo default)
Captured: **Needs user action**  
Reviewed: **Needs user action**  
Uploaded to Connect: **Needs user action**

## Related docs
- `APP_STORE_SUBMIT_GATES.md` — master gate table  
- `APP_STORE_ARCHIVE_RUNBOOK.md` — archive/upload steps  
- `APP_STORE_METADATA.md` — metadata + App Review notes  
- `APP_STORE_CONNECT_PRIVACY.md` — privacy answers  
- `APP_STORE_CONNECT_SUBSCRIPTIONS.md` — IAP sign-off  
- `TESTFLIGHT_PURCHASE_VERIFICATION.md` / `STOREKIT_SANDBOX_TESTING.md` / `TESTFLIGHT_SMOKE.md`  
- `RELEASE_CHECKLIST.md`
