# Shawn — Next Manual Release Steps

**Phase 65** — App Store release gate prep after local multi-market arc (Phases 61–64).  
Agents must **not** mark any step below complete. You check boxes only after you do the work.

Baseline: `main` after Phase 65 · local product work through Phase 64 · version **1.0** · build **1** · bundle `com.shawnwright.yofai` · display **Yofai**  
Freemium Local Export · no Direct Upload · no AI · StoreKit 2 Pro already in code · Pro multi-market drafts/templates local-only.

**Build number:** still **1**. Bump before every App Store Connect upload (do not archive with build 1 if a prior binary used build 1). Phase 65 did **not** bump the build.

---

## A. Before You Start

- [ ] Working tree clean on latest `main` (`git pull` then `git status`)
- [ ] Apple Developer + App Store Connect access for this Apple ID
- [ ] Privacy URL opens: https://ketchupdrool.github.io/Yofai/privacy-policy.html
- [ ] Terms URL opens: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
- [ ] Support URL opens: https://ketchupdrool.github.io/Yofai/support.html
- [ ] Optional: local StoreKit smoke with scheme → `Yofai.storekit` (`STOREKIT_SANDBOX_TESTING.md`)

---

## B. Create Yofai Pro in App Store Connect

Full checklist: `APP_STORE_CONNECT_SUBSCRIPTIONS.md`  
Do **not** change product IDs. Intended prices are for Connect; the app shows StoreKit `displayPrice`.  
**Still manual unless you confirm Done by user.** Do not assume products are approved.

1. Open https://appstoreconnect.apple.com
2. **My Apps** → **Yofai** (bundle `com.shawnwright.yofai`)
3. **Monetization** → **Subscriptions** (or In-App Purchases → Subscriptions)
4. Create subscription group:
   - Name: **Yofai Pro**
5. Create **monthly** subscription:
   - Product ID: `com.shawnwright.yofai.pro.monthly` *(exact — cannot change later)*
   - Reference Name: Yofai Pro Monthly
   - Duration: 1 month
   - Display Name: Yofai Pro Monthly
   - Description: Unlocks Pro features in Yofai.
   - Price: **$4.99**/month (or your storefront equivalent)
6. Create **yearly** subscription:
   - Product ID: `com.shawnwright.yofai.pro.yearly`
   - Reference Name: Yofai Pro Yearly
   - Duration: 1 year
   - Display Name: Yofai Pro Yearly
   - Description: Unlocks Pro features in Yofai for one year.
   - Price: **$39.99**/year
7. Add localizations (at least English) for group + both products
8. Fill **subscription review information**
9. Attach a paywall screenshot if Connect requires it (Settings → Yofai Pro → Upgrade; real prices or honest unavailable state — **no fake success**)
10. Make products available / cleared for review with the app version you will submit
11. Optional: create a Sandbox tester (Users and Access → Sandbox)

When done, mark rows in `APP_STORE_CONNECT_SUBSCRIPTIONS.md` as **Done by user** yourself. Repo status stays **Needs user action** until you confirm.

---

## C. Screenshot Capture

Packet detail: `APP_STORE_PREP.md`  
Capture on required App Store sizes (e.g. 6.7" / 6.1"). Prefer a physical iPhone for Camera frames. Do **not** invent AI, Direct Upload, publish, compliance, or fake Pro purchase success.

**Still Needs user action** — no screenshot assets were generated in Phase 65.

Use one sample product with 1–3 clear photos.

| # | Screen | Path | Setup | Overlay / title | Avoid |
|---|---|---|---|---|---|
| 1 | Home / Start Product | Home → **New Product** (or empty Products) | Empty list or New Product sheet | “Start a product photo set on your iPhone” | Pro paywall, AI badges |
| 2 | Capture & Check Photos | Open product → **Capture & Check Photos** | ≥1 photo; Photo Check facts visible | “Capture and check product photos” | “Etsy ready”, compliance |
| 3 | Edit / Fit / Reposition | Photo → **Edit** | Contain+Pad or Fill+Crop; reposition if useful | “Edit and fit for export” | AI / auto-crop labels |
| 4 | Marketplace + Export Size | Product → **Prepare Listing & Export** | Marketplace target set; export size shown separately | “Prepare for your marketplace” | Upload, Connect, publish |
| 5 | Export Readiness + Prep Tips | Same workspace → readiness / Prep Tips | Real checklist + tips | “Check readiness before export” | Marketplace approved |
| 6 | Export Local JPEGs | After successful local export | Summary with next step to View Exported Files | “Export local JPEGs for manual upload” | Published / Direct Upload |
| 7 | Export History / View Files | **History** → open batch → **View Exported Files** (or post-export viewer) | Files still on disk | “Review and share exported files” | Upload status |
| 8 | Yofai Pro | **Settings** → **Yofai Pro** → **Upgrade** | See Pro screenshot rules below | “Optional Yofai Pro” | Fake $, fake success, AI, Direct Upload available |

### Pro screenshot rules
- **If Connect products exist and load:** show real monthly/yearly StoreKit prices + Terms / Privacy / Restore.
- **If products do not load yet:** show honest “Purchases are not available right now.” (or Free plan) — still OK for marketing if accurate.
- **Never** fake a successful purchase or invent dollar amounts.

Store captures locally (e.g. Desktop or `AppStoreScreenshots/`). Upload to Connect when ready. Status remains **Needs user action** until you capture and upload.

---

## D. Build Number

| Field | Current | Action |
|---|---|---|
| Marketing version | **1.0** | Keep unless you intentionally ship a different marketing version |
| Build | **1** | **Bump before every App Store Connect upload** (e.g. to 2). Phase 65 left build at **1** on purpose. |
| Bundle ID | `com.shawnwright.yofai` | Do not change |
| Display name | Yofai | Do not change |

Bump in `project.yml` (`CURRENT_PROJECT_VERSION`) then regenerate the Xcode project, **or** set Build in Xcode target General — then keep `project.yml` in sync if you use XcodeGen. Ask the agent to bump only if you explicitly approve.

---

## E. Archive / Upload

Full steps: `APP_STORE_ARCHIVE_RUNBOOK.md`

1. Clean `main`, Connect IAP ready (or knowingly blocked), build bumped  
2. Xcode → scheme **Yofai** → **Any iOS Device** → **Product → Archive**  
3. Organizer → **Distribute App** → App Store Connect → Upload  
4. Wait for processing → attach build to version / TestFlight  

Archive / upload / App Review: still **Not started** in the gate table until you do them. Agents must not archive/upload/submit without your explicit approval.

---

## F. TestFlight Purchase Verification

Template: `TESTFLIGHT_PURCHASE_VERIFICATION.md`  
**Overall result still Not run** unless you fill Pass with evidence.

Must pass before App Review submit:
- [ ] Monthly + yearly products load from Connect (real prices)
- [ ] Monthly purchase unlocks Pro
- [ ] Restore Purchases works
- [ ] Reinstall + restore if practical
- [ ] Free fallback when products unavailable / cancelled (no data deletion)
- [ ] Free local JPEG export still works **without** purchase
- [ ] Terms of Use + Privacy Statement open
- [ ] No Direct Upload / AI buttons

Fill the verification doc with **Pass** only for checks you actually ran.

---

## G. Submit Only After Gates Pass

Master table: `APP_STORE_SUBMIT_GATES.md`

Do **not** submit for App Review until these are **Passed** with evidence:
1. Connect IAP group + monthly + yearly (A)
2. TestFlight purchase verification (C) — products load, buy, restore, Free export
3. Screenshots captured, reviewed, uploaded (D)
4. Metadata + privacy answers + App Review notes + live Support/Privacy URLs (E)
5. Archive created + build uploaded (F)

Recommended first: local StoreKit smoke (B in gates) → Connect products → screenshots → bump build → archive/upload → TestFlight purchase → metadata → submit.

---

## Do not
- Mark Connect / screenshots / TestFlight / archive **Passed** without doing them  
- Show fake StoreKit prices or Pro success in screenshots  
- Lock Free core local export behind purchase  
- Add Direct Upload / AI / backend / marketplace API for launch  
- Ask the agent to archive/upload/submit unless you explicitly approve that step  
