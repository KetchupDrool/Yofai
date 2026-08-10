# App Store Prep — Yofai

**Phases 50–58** — positioning, screenshots, and submit-path docs.  
Freemium-first **Local Export Mode**. StoreKit 2 Pro is implemented in-app. **Direct Upload is not implemented. No AI.**

Connect products + TestFlight purchases remain **manual** (`APP_STORE_SUBMIT_GATES.md`).  
Owner sequence: `SHAWN_NEXT_RELEASE_STEPS.md`.

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

## Screenshot capture packet (Phase 58)

**Do not generate fake screenshot image assets in-repo.**  
Capture on App Store required sizes (e.g. 6.7" + 6.1"). Use **one** sample product with 1–3 clear product photos.

Device: physical iPhone preferred for Camera/Photos; simulator OK for non-camera frames. Unit-test simulator remains **iPhone 16e** only.

### Shared sample-data setup (do once)
1. Launch Yofai → create a product with a clear name  
2. Add 1–3 sharp product photos (Camera or Photos)  
3. Run Photo Check so facts/tips are visible  
4. Open Edit once (Contain+Pad or Fill+Crop) and save  
5. Set a marketplace destination on Prepare Listing & Export  
6. Run Local Export once so History / Exported Files have real files  

### Per-screen capture guide

| # | Screen name | Exact path | Required state | Overlay / title | Avoid |
|---|---|---|---|---|---|
| 1 | Home / Start Product | Tab/root **Home** → **New Product** (or empty Products list) | Empty home or New Product sheet open | “Start a product photo set on your iPhone” | Pro paywall, AI badges |
| 2 | Capture & Check Photos | Open product → **Capture & Check Photos** | ≥1 photo; Photo Check results visible | “Capture and check product photos” | “Etsy ready”, compliance, upload |
| 3 | Edit / Fit / Reposition | From a photo → **Edit** | Fit mode visible; optional reposition | “Edit and fit for export” | AI / auto-crop / enhance claims |
| 4 | Marketplace + Export Size | Product → **Prepare Listing & Export** | Destination + export size both visible and distinct | “Prepare for your marketplace” | Upload, Connect, publish |
| 5 | Export Readiness + Prep Tips | Same workspace → readiness checklist / Prep Tips | Real tips for this product | “Check readiness before export” | Marketplace approved / compliant |
| 6 | Export Local JPEGs | After **Export** succeeds → post-export summary | Local JPEG success + “View Exported Files” path | “Export local JPEGs for manual upload” | Published / Direct Upload |
| 7 | Export History / View Files | Tab **History** → open batch → viewer **Exported Files** (or post-export **View Exported Files**) | Files still on disk | “Review and share exported files” | Upload status / cloud sync |
| 8 | Yofai Pro *(optional but recommended)* | Tab **Settings** → **Yofai Pro** → **Upgrade** | See Pro rules below | “Optional Yofai Pro” | Fake success, invented $, AI, Direct Upload available |

### Pro screenshot (#8) — product-load rule
| Situation | What to capture |
|---|---|
| Connect products created **and** StoreKit loads them | Paywall with **real** monthly/yearly `displayPrice`, Terms, Privacy, Restore |
| Products not created yet, or load fails | Free plan and/or “Purchases are not available right now.” — accurate unavailable state only |
| Never | Fake purchase success, typed-in prices, “Pro unlocked” without a real entitlement |

Local StoreKit config (`Yofai.storekit`) can show real-looking prices for a **local** Pro shot if you attach the config in the scheme — still do not imply App Store Connect products exist until they do. Prefer Connect-backed prices for the final Connect upload set when possible.

### Screenshot status (repo default)
Captured: **Needs user action**  
Reviewed: **Needs user action**  
Uploaded to Connect: **Needs user action**

## Related docs
- `SHAWN_NEXT_RELEASE_STEPS.md` — owner sequence  
- `APP_STORE_SUBMIT_GATES.md` — master gate table  
- `APP_STORE_ARCHIVE_RUNBOOK.md` — archive/upload steps  
- `APP_STORE_METADATA.md` — metadata + App Review notes  
- `APP_STORE_CONNECT_PRIVACY.md` — privacy answers  
- `APP_STORE_CONNECT_SUBSCRIPTIONS.md` — IAP sign-off  
- `TESTFLIGHT_PURCHASE_VERIFICATION.md` / `STOREKIT_SANDBOX_TESTING.md` / `TESTFLIGHT_SMOKE.md`  
- `RELEASE_CHECKLIST.md`
