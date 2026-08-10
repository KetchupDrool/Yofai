# Decisions

## Locked
- Final app name: Yofai
- Bundle ID: com.shawnwright.yofai
- Platform: iOS first
- UI framework: SwiftUI
- Local storage: SwiftData
- Build tool: Xcode
- Coding assistant: Cursor

## Product Pivot (2026-08-09) — Locked (modes clarified Phase 45)
- Primary purpose: local-first marketplace product photo preparation for online sellers
- Core functionality is local-first/on-device
- Seller jobs: photograph → organize photo sets → quality check → edit → resize/crop → listing-ready local exports
- Marketplace targets for **Local Export Mode**: Etsy, eBay, Facebook Marketplace, Poshmark, Mercari, and similar
- **Local Export Mode** is current production behavior and remains permanent fallback
- **Direct Upload Mode** is future-only: official API/OAuth per marketplace after verification + explicit approval; not implemented
- Abandoned from the active near-term roadmap (inactive unless explicitly re-approved later):
  - Browser automation / unofficial marketplace APIs / marketplace password storage
- **Hard product constraint:** Yofai does not use AI (no OpenAI, no AI listing assistant, no AI photo analysis, no AI roadmap)
- Future-capability / approved-direction (not immediate tasks; may be added later where they support the product):
  - Backend services
  - User accounts
  - Cloud sync
  - Subscriptions
  - Ads
  - Direct Upload Mode for verified marketplaces only (see `MARKETPLACE_UPLOAD_ROADMAP.md`)
- Core photo preparation remains local-first/on-device even if future capabilities are added later
- Old primary goal (“general photo editor MVP”) is superseded; App Store upload remains paused

## Phase 20 — Listing export (locked; fit mode superseded by Phase 37)
- Product direction: listing / photo-prep for sellers (local-only)
- ~~Fit mode: contain + pad only~~ → **superseded by Phase 37** (Contain + Pad and Fill + Crop)
- Backgrounds: white, black, soft gray only (no transparent)
- Export presets (pixels):
  - Etsy square: 2000 × 2000
  - Etsy listing: 3000 × 2400
  - Instagram square: 1080 × 1080
  - Facebook post: 1200 × 630
  - Marketplace: 1600 × 1600
- Defaults: Etsy square + white
- Deferred: transparent export, border/shadow frames

## Phase 21 — Watermark (locked)
- Simple text watermark on listing exports only
- State: watermarkEnabled (default false), watermarkText (default "", max 32)
- Draw after listing frame (contain+pad or fill+crop); bottom-trailing; font scales with canvas
- Text color follows background (light on black, dark on white/soft gray)
- History stores optional didWatermark Bool? (Yes/No); nil = older rows
- Share architecture unchanged (ShareFileItem + temp JPEG + .sheet(item:))
- Deferred: logo watermark, opacity/position pickers, multi-line

## Phase 22 — Item Projects (locked)
- Local Item Projects: name, multiple photos, created/modified dates
- Files under Application Support/ItemProjects
- Projects tab; open existing Edit from a project photo
- Delete project confirms and removes project files only
- List rows use thumbnails only; full image loads on Edit navigate

## Phase 23 — Local listing drafts (locked)
- Per-project listing fields: title, description, price text, quantity, category, tags (≤13), materials, shipping profile, processing time
- SwiftData on `ItemProject`; edit/save in Project Detail Listing Details section
- Validation on save: title required, price valid nonnegative, quantity ≥ 1, max 13 tags, blank tags removed
- Completeness summary from persisted values

## Phase 24 — Etsy connection foundation (locked; live path abandoned from active roadmap)
- Settings Etsy Shop section: Not connected / Connecting / Connected / Connection expired / Error
- `EtsyConnecting` protocol; `MockEtsyConnectionService` for tests/previews; `StubEtsyConnectionService` for app (no network)
- Tokens + connection payload in Keychain only; Disconnect deletes all Etsy Keychain items
- Development placeholder redirect: `yofai://etsy-oauth-callback` via URL Types; `isConfigurationComplete = false`
- No Associated Domains; no client secret on device; no live Etsy HTTP in this foundation
- Completed local stub/history preserved
- **Abandoned from the active roadmap:** live OAuth, upload, and marketplace publishing (including direct Etsy publishing). Inactive unless explicitly re-approved later.

## Phase 25 — Local Listing Queue (locked)
- `ListingQueueEntry` in SwiftData: sort order + local status
- Statuses: Needs Details, Ready, Processing, Failed, Completed
- Readiness: ≥1 existing photo file, nonblank title, valid nonnegative price, quantity ≥ 1, ≤13 tags
- Prepare Queue validates locally only; Ready may enter Processing then return to Ready/Failed
- Completed only when tests/previews set it explicitly — never faked by Prepare Queue
- Projects toolbar → Listing Queue; Review Draft opens Project Detail; delete project cascades queue entry
- Abandoned from the active roadmap: network upload, live Etsy publish

## Phase 26 — Batch listing image export (locked)
- Project Detail: Listing Export settings + Export Listing Images
- Export all project photos in sort order to Application Support/ExportBatches as `01.jpg`, `02.jpg`, …
- Per-photo saved `PhotoEditState` when available; else original + project preset/background/fit mode/watermark
- Export fit uses project fit mode (Phase 37); source project files never modified
- Share Export Batch shares real JPEG file URLs; Delete Batch removes only that batch folder
- Abandoned from the active roadmap: Etsy upload of batches

## Phase 27 — Listing Workspace + bulk queue actions (locked)
- `ListingWorkspaceView` entry from Project Detail and Listing Queue
- Shows cover, title, completeness, missing info, queue status, photo order, latest export batch
- Reuses ItemProject / ListingQueueEntry / ProjectExportBatch — no second draft model
- Actions: edit details/photos via existing Project Detail, export/share batch, add/remove queue, validate readiness
- `prepareReadyListings`: validate all, process Ready only, skip Needs Details, summary counts; never Completed/upload
- Readiness remains Phase 25 rules only

## Phase 28 — Seller Defaults + Duplicate Listing Draft (locked)
- Settings Seller Defaults: category, materials, shipping, processing time, export preset/background/fit mode, watermark text
- Stored in UserDefaults via `SellerDefaultsStore`; never Etsy credentials; clear requires confirmation
- Apply only when creating a new Item Project with Use Seller Defaults; Start Blank applies nothing
- Existing projects never overwritten by defaults changes
- Duplicate Listing Draft copies listing details + export settings only; requires new item name; no photos/files/edits/batches/queue/History/Originals; starts outside queue

## Phase 29 — Bulk Photo Editing + Listing Package (locked)
- Bulk Edit Photos: copy selectable edit recipe from one project photo to targets; never overwrite source image files; no History rows
- Exclude any setting before apply; fit mode is a selectable recipe field (Phase 37)
- Per-project undo restores previous edit settings for the most recent bulk op only
- Listing Package: local folder with `listing-details.txt` + ordered JPEGs from newest successful export batch
- Requires export batch first; packages separate from photos/Originals/History/export batches; share/delete package files only

## Phase 30 — Complete Local Listing Information (locked)
- Listing Workspace → Listing Information grouped editors; reuses Phase 23 core draft fields (no duplicate title/price/etc. editors)
- New local SwiftData fields: item type, condition, who/when made, SKU, personalization, variations, category attributes, return policy, per-photo alt text
- Optional fields support explicit Not Applicable
- Listing Information Review: filled / missing / N/A / needs review — local only; never labels a draft Etsy-ready
- Phase 25 queue readiness rules unchanged
- Validation: enabled variation name/options/SKU; personalization character limit positive when enabled; blank attributes/options/alt text removed on sanitize
- Alt text stored on `ItemProjectPhoto` so reorder/delete keep matching text
- Duplicate Listing Draft copies all new listing-information fields; still no photos/files/edits/batches/packages/queue/History/Originals
- Seller Defaults may prefill only item type, condition, who made, when made, return policy (plus prior defaults) on new-project create; never overwrite existing projects
- Do not invent marketplace limits/IDs; Etsy API/OAuth/upload remain out of scope here

## Phase 31 — Listing prep foundation history (superseded by Phase 51)
- Historical: disconnected listing-prep assistant UI + provider stubs existed in earlier builds
- **Phase 51:** AI Listing Assistant UI, providers, and Phase 31 tests removed
- `AIPreparationRecord` SwiftData shell retained only so existing on-device stores continue to load; no UI; no provider; no AI product roadmap
- Duplicate draft still does not copy dormant listing-prep records; Seller Defaults store none of that data
- Listing Information Review and Phase 25 readiness unchanged

## Phase 32 — Product Intake + Guided Photo Capture (locked)
- Entry from Project Detail and Listing Workspace → Product Intake / Capture Photos
- Reuses existing project-photo storage/order/edit/alt-text/export/delete paths — no second photo library
- Editable local photo plan with optional starter goals; not Etsy requirements
- Goals: add/rename/reorder/delete/complete; attach at most one project photo; clear attachment without deleting photo
- Photo delete clears matching goal attachment; reorder keeps attachment + alt text on the photo
- System camera capture via UIImagePickerController; permission denial messaging; rear camera; flash when supported; confirm/retake; optional goal attach; append-only via `LocalEditStore.saveProjectImage`
- Simulator/unavailable camera fails safely; production never fakes capture; tests use `InjectedTestCaptureSource` only
- Photo Check reports measurable local facts only; seller review checkboxes never affect Phase 25 readiness
- Duplicate draft copies goal names/order only; cascade-delete goals with project; Seller Defaults store no photo-plan/camera/review data
- Etsy API/OAuth/upload out of scope; do not claim marketplace compliance

## Phase 33 — Seller Export Preset Clarity (locked)
- Seller-facing display metadata on `ListingExportPreset` only; stored `rawValue` and pixel sizes unchanged
- Display: Marketplace → “Square 1600”; groups Listing vs Other canvas; picker labels include W×H
- Facebook post subtitle clarifies social post canvas, not Marketplace product
- Local export disclaimer on Edit, Project Detail export, Seller Defaults
- Home + Projects empty copy aligned to marketplace product photo-prep north star
- Fit mode later unlocked in Phase 37; no new marketplace sizes invented in Phase 33
- Out of scope at the time: cover/crop fit, eBay/Poshmark/Mercari/FB Marketplace sized presets, OAuth/AI/upload, nav merge

## Phase 34 — Local Export Canvas Check (locked; framing facts extended by Phase 37)
- Photo Check compares source file pixels to the project’s listing export preset canvas (batch-export canvas)
- Facts: canvas picker label/size, source smaller than canvas, aspect differs; Phase 37 adds fit mode + framing expectation (pad vs crop)
- Product Intake progress + Export Canvas Notes section; Listing Workspace intake summary line
- Local facts only — not marketplace compliance; never changes Phase 25 queue readiness
- Out of scope at the time: nav merge, inventing marketplace sizes, OAuth/AI/upload

## Phase 35 — Seller-First Navigation Simplification (locked)
- Primary path: Home → Start/Continue Product → Item Project → Capture & Check → Prepare Listing & Export
- Tab labels: Projects → Products; Home primary CTA Start Product (switches to Products + new-product sheet)
- Continue Product shows recent Item Projects; Import / Originals / History remain secondary under More Tools
- Project Detail: Capture & Check Photos before Prepare Listing & Export; no data deletion; no SwiftData migration
- Out of scope: deleting features, new marketplace sizes, OAuth/AI/upload, backend/accounts

## Phase 36 — Verified Marketplace Local Export Presets (locked)
- Added ListingExportPreset cases: eBay (`"eBay"`, 1600×1600) and Poshmark (`"Poshmark"`, 1000×1000) in Listing group
- Existing five Phase 33 raw values and pixel sizes unchanged; old stored selections still decode
- Square 1600 / Instagram / Facebook post remain; not relabeled as Facebook Marketplace or Mercari
- Recommended local canvases only — not marketplace compliance guarantees
- Photo Check / batch export / Seller Defaults / Edit pickers use CaseIterable (includes new presets)
- Deferred named presets: Facebook Marketplace, Mercari (pending verified specific canvas)

## Phase 37 — Cover/Crop Export Fit Mode (locked)
- **Supersedes the Phase 20 contain+pad-only export-fit restriction.**
- Current locked export-fit decision (seller-selectable):
  - **Contain + Pad** — keeps the whole photo; may add borders (selected export background)
  - **Fill + Crop** — fills the canvas; may crop edges (Phase 37 defaulted to center; Phase 38 adds manual reposition)
- Default / backward-compatible behavior: **Contain + Pad**
- Missing/unknown stored fit-mode values resolve to Contain + Pad (PhotoEditState, Seller Defaults, project raw string)
- Stable raw values: `"Contain + Pad"`, `"Fill + Crop"`
- Exact canvas dimensions for all 7 current export presets unchanged; no stretch/distort
- Honored by single/project/batch/package export paths via existing `PhotoEditState` + `ImageEditing.applyListingFrame`
- Photo Check: aspect mismatch → padding expected (Contain + Pad) or cropping expected (Fill + Crop); matching aspect → no meaningful pad/crop warning; Phase 25 readiness unchanged
- Watermark unchanged (drawn after framing); background still stored; Fill + Crop fully filled canvases show no visible pad
- Out of scope at Phase 37: drag/focal-point/face/AI crop, new marketplace sizes, FB Marketplace/Mercari named presets, compliance claims, OAuth/AI/upload/backend

## Phase 38 — Fill + Crop Reposition (locked)
- **Extends Phase 37 Fill + Crop from center-only cropping to seller-controlled manual repositioning.**
- Locked behavior:
  - Fill + Crop keeps the required fill scale (no pinch-zoom beyond fill)
  - Seller can drag to reposition within valid bounds (canvas never shows empty background)
  - Default remains centered (`fillCropOffsetX` / `fillCropOffsetY` = 0)
  - Positioning is persisted per photo on `PhotoEditState` (not project-global / not Seller Defaults)
  - No AI / focal-point automation
- Normalized offsets in **-1.0 … 1.0** (screen-independent); missing keys decode to centered
- Contain + Pad ignores offsets and remains unchanged
- Edit UI: Reposition + Reset to Center when Fill + Crop is selected (`FillCropRepositionView`)
- Same offsets used by preview, single export, batch export, and listing package paths
- Bulk Edit may optionally copy “Fill crop position”; fit mode copy does not force positions
- All 7 preset sizes/raw values unchanged

## Phase 39 — Marketplace Export Expansion (locked)
- Separates **Marketplace target** (where the listing is headed) from **Export size** (pixel canvas authority)
- Marketplace targets: Etsy, eBay, Poshmark, Facebook Marketplace, Mercari, Other / General
- Verified targets may recommend existing canvases only: Etsy → Etsy square; eBay → eBay 1600×1600; Poshmark → Poshmark 1000×1000
- **No new named pixel presets added in Phase 39**
- Research (checked 2026-08-09):
  - **Facebook Marketplace:** Meta Ads Guide Marketplace image placement recommends ratio 1:1 and resolution “at least 1080 × 1080” for **ads** — a minimum, not an exact organic listing export canvas. No first-party exact seller-listing pixel canvas found → **no named FB Marketplace preset**
  - **Mercari:** Mercari US Help does not publish an exact listing pixel size; third-party/community sizes conflict; JP Mercari column soft-suggests ~720×720 (“程度”) — not treated as a defensible US exact canvas → **no named Mercari preset**
- Guidance layer explains when no fixed verified Yofai canvas exists; sellers choose general canvases (e.g. Square 1600 / Instagram square)
- Persistence: `listingMarketplaceTargetRaw` on `ItemProject`; `marketplaceTargetRaw` on Seller Defaults; missing → Other / General; never stores Phase 38 offsets globally
- Export readiness summary (Ready / Review / Needs Attention): deterministic local facts only; never blocks export; never claims compliance
- Seller workspace: Marketplace → Export size → Fit → Photo check → Export readiness → Preview (`ImageEditing.renderPreview`) → Export Photos
- Marketplace quick switch changes export-level settings only; preserves per-photo edits and Fill + Crop offsets
- All existing 7 preset raw values and dimensions unchanged; Phase 37/38 behavior preserved

## Phase 40 — Local Export Batch History & Marketplace Labeling (locked)
- Extends existing `ProjectExportBatch` with export-history metadata (no second history model)
- Metadata stored per successful export: marketplace target, preset raw, canvas W×H, fit mode, photo count, watermark enabled, date/time, local batch folder reference
- Seller labels keep destination and canvas separate (e.g. “eBay • 1600×1600 • 6 photos”, “Facebook Marketplace • 1600×1600 • 6 photos”)
- Language: **exported for** — never “published to”; no upload/publish status tracking
- Only `successCount > 0` creates a history row; failed/empty exports do not create false completed entries
- Pre-Phase-40 rows load with empty metadata → “Earlier export” / Other fallback
- “Use These Export Settings” restores marketplace/preset/fit/watermark only — never per-photo edits or Phase 38 offsets
- Deleting a history row removes that ExportBatches folder only — not product photos, Originals, or edit History
- Intentionally NOT tracked: marketplace upload status, compliance, cloud sync, accounts

## Phase 41 — Export History Filters & Compare Polish (locked)
- Local marketplace filters on export history: All + chips for targets present in that project’s history (+ Earlier export for empty `marketplaceTargetRaw`)
- Selected filter is **transient UI state only** — not persisted; filtering does not mutate history
- Filter matches stored `marketplaceTargetRaw` only — never infers marketplace from canvas size, folder name, or JPEG name
- Legacy empty-target rows appear only under All / Earlier export — not guessed into named markets
- Newest-first order preserved after filtering; empty filter copy e.g. “No eBay exports yet.”
- Metadata-only compare of the two newest completed exports (marketplace, canvas, fit, photo count, watermark, date); changed fields only
- Compare does **not** decode JPEG pixels, run AI, or claim quality/compliance differences
- One export → “No previous export to compare.”
- Row polish: primary marketplace + canvas; secondary date · count · fit (± watermark)
- “Export Again” applies export-level settings and leaves the seller in the normal flow (must tap Export Photos); does not auto-export; does not change per-photo edits or Phase 38 offsets
- Intentionally NOT added: pixel comparison, upload/publish status, new persistence for filters, new marketplace dimensions

## Phase 42 — Seller Export Readiness Checklist (locked)
- Expands Phase 39 `ExportReadiness` into a computed checklist: Photos, Marketplace, Export size, Fit, Photo Check, Watermark
- Overall: Ready to export / Review before export / Needs attention — from local deterministic state only
- Needs Attention: no photos, missing/unreadable files, invalid export size raw
- Review: low source resolution, expected pad/crop, adjusted Fill + Crop position (informational — not an error), incomplete listing details (Phase 25)
- Ready: photos present with readable files + valid canvas; guidance-only FB Marketplace / Mercari + valid general canvas can be Ready
- Watermark is **Optional** and never reduces overall readiness
- Reuses `PhotoTechnicalCheck` — no duplicate pixel-evaluation logic; readiness is **not persisted**
- UI: compact checklist on Project Detail; full checklist on Listing Workspace after Photo check, before Preview
- Language: local export readiness only — never compliant / approved / marketplace-ready / publish readiness
- Intentionally NOT added: compliance claims, upload status, new marketplace dimensions, readiness persistence

## Phase 43 — Seller One-Tap Prep Tips (locked)
- Computed `ExportPrepTip` rows from the same local readiness/Photo Check facts — **not persisted**
- Max 2–3 visible tips (priority: blocking → photo review → framing → optional); hide section when empty (Ready may show one Preview tip)
- Actions point at existing controls only: Capture & Check Photos, Photo Check, scroll to Export size/Fit/Preview, Reposition (Edit), Listing Workspace
- Manual only: never auto-switches fit, crop, size, or exports; never invents marketplace rules
- Guidance-only FB Marketplace / Mercari: no tip solely for guidance-only when a valid canvas is selected
- Adjusted Phase 38 crop is informational (“Check crop position”), not an error
- Watermark off creates no tip
- Project Detail: compact single top tip near readiness; Listing Workspace: Prep Tips after Export Readiness, before Preview
- Intentionally NOT added: AI, auto-fixes, face/object detection, tip persistence, new marketplace dimensions

## Phase 44 — Seller Export Batch Notes (locked)
- Optional local free-text `sellerNote` on existing `ProjectExportBatch` (default `""` for legacy rows)
- Max **240** characters; trim whitespace; blank/whitespace-only → no note
- Notes are seller memory only — not publish/upload status, not AI-generated, not marketplace claims
- Never required for export; editing a note does not change files, marketplace, preset, canvas, fit, watermark, photo count, date, or Phase 38 offsets
- UI: Add Note after successful export summary (optional); Add Note / Edit Note / Remove Note in Export History sheet
- History shows note only when present (secondary); Phase 41 filters/compare unchanged (notes not compared or used for filtering)
- Deleting a history row removes the note with the batch (Phase 40 deletion unchanged)
- Intentionally NOT added: note search/filter by text, sync, backend, separate note entity

## Phase 45 — Direct Marketplace Upload Feasibility & Roadmap Reset (locked)
- Audit confirmed: app prepares local JPEGs, stores export history/notes, does not authenticate live upload, does not call marketplace upload APIs, does not publish
- Formalizes **Local Export Mode** (current/permanent) vs **Direct Upload Mode** (future only)
- Feasibility matrix for Etsy, eBay, Poshmark, Facebook Marketplace, Mercari in `MARKETPLACE_UPLOAD_ROADMAP.md`
- Strongest verified official photo-upload path today: Etsy Open API v3 `uploadListingImage` (still requires OAuth/app registration before any implementation)
- Poshmark / consumer Facebook Marketplace / Mercari US: no suitable verified individual-seller binary upload path for first implementation
- Hard bans: browser automation, unofficial APIs, marketplace password storage, guessed endpoints
- No Direct Upload Mode code, OAuth secrets, backend vendors, or AI APIs added in this phase
- Minimal code: `YofaiProductMode.current == .localExport`; queue empty-state copy no longer implies “future Etsy upload”
- UI language remains “exported for” / local export — not publish/upload status

## Phase 46 — Local Export Share Polish (locked)
- Seller-facing share/package wording: local JPEGs, exported for, manual upload — never published/uploaded/Direct Upload claims
- Post-export summary: marketplace, canvas, fit, watermark, manual upload, optional note line
- History rows: marketplace • canvas • count; Exported date · fit · Local JPEGs; Note when present
- Optional Share with Note prepends note text to the system share sheet activity items (off by default); Copy Export Note for pasteboard
- Does not embed notes into JPEG pixels; does not mutate export settings when sharing/copying note
- ShareBatchItem gains optional `caption` only; sheet still uses ActivityShareView
- No marketplace upload, OAuth, publish status, or Direct Upload Mode

## Phase 47 — Local Export File Access & UX Polish (locked)
- View Exported Files sheet lists ordered local JPEGs for one history batch (filename + canvas label; no raw paths)
- Tap available file for read-only larger preview; unreadable/missing files show a short safe message
- Re-share from history uses existing on-disk JPEGs only — no re-render, no new history row, no settings/note mutation
- Missing folder / missing files / empty ordered names → hide share actions and show “Export files no longer available”
- History actions: View Exported Files + Share Exported Photos primary; Use These / Export Again / notes / delete under More
- Deleting a history row still removes only that ExportBatches folder — never product photos
- No Direct Upload Mode, OAuth upload, publish status, or file-manager features

## Phase 48 — Final Local Export Mode Polish (locked)
- Post-export next step: View Exported Files for the just-created batch (plus Share / note actions when valid)
- History action order: View + Share primary; More = Share with Note → Copy Note → Add/Edit Note → Use These → Export Again → Delete
- Dynamic Type / accessibility pass on export summary, history, viewer, readiness (status not color-only)
- Wording cleanup remains local JPEGs / exported for / manual upload — no publish/Direct Upload claims
- No new product scope: no upload, OAuth, backend, analytics, subscriptions, ads, or new presets

## Phase 49 — Freemium Foundation & Entitlement Planning (locked)
- Freemium-first if monetized: Free keeps Capture → Organize → Photo Check → Edit → Prepare → Local Export
- Do not launch fully free and later lock existing core Free features behind payment
- Free limit (changeable in `FreemiumLimits`): **12 active products**; over-limit existing products stay fully usable; no auto-delete
- Core Free forever in this plan: local JPEG export, Photo Check, edit/fit, export notes, view/re-share exported files, export history
- Pro additive (planned): unlimited products, advanced history/multi-market tools, cloud backup/sync, Direct Upload Mode (still not implemented)
- Architecture: `EntitlementPlan`, `FreemiumFeature`, `EntitlementState`, `EntitlementPolicy`, `EntitlementStore` — testable, offline, default Free
- Settings: Yofai Pro section + factual placeholder sheet (“Pro is not available yet. No purchase is charged.”) — no fake pricing or StoreKit buy button
- StoreKit not implemented; future payments phase needs product IDs, StoreKit 2, restore, App Store Connect, legal/privacy, paywall copy, configuration tests

## Phase 50 — App Store Prep for Freemium Local Export Launch (locked)
- Launch positioning: marketplace product photo prep + local JPEG export for manual upload
- Docs: `APP_STORE_PREP.md`, updated `APP_STORE_METADATA.md`, `RELEASE_CHECKLIST.md`, privacy/support pages aligned to Local Export Mode
- Review mitigations: Etsy Connect button removed while OAuth incomplete
- Freemium copy remains Free-core + Pro planned / no purchase charged; no StoreKit
- No Direct Upload, no fake paywall, no compliance claims

## Phase 51 — Remove AI References & Final No-AI Positioning Cleanup (locked)
- **Yofai is a no-AI app** — hard product constraint, not a temporary deferral
- Removed user-facing Listing Assistant section, `AIListingAssistantView`, `AIListingProvider`, and Phase 31 tests
- Retained minimal `AIPreparationRecord` SwiftData shell (+ legacy status raw values) so existing stores load; no UI; no providers; no “future AI” roadmap
- Photo Check, Export Readiness, and Prep Tips remain deterministic/local
- App Store / privacy / handoff / Cursor rules updated: no AI-powered claims; no OpenAI; no AI roadmap
- Preferred privacy wording: no account, cloud, or AI service required for the core local export workflow

## Phase 52 — App Store Submit Path (locked)
- Submission preparation only — no new product features at the time; no Direct Upload, no AI, no phase renumbering
- Finalized metadata package: `APP_STORE_METADATA.md` (subtitle, descriptions, keywords, review notes, URL checklists)
- Privacy answers sheet: `APP_STORE_CONNECT_PRIVACY.md`
- Screenshot capture plan expanded in `APP_STORE_PREP.md` (8 screens; no fake screenshots)
- TestFlight smoke script: `TESTFLIGHT_SMOKE.md`
- Release checklist expanded for archive → upload → TestFlight → App Review (`RELEASE_CHECKLIST.md`)
- `AppStoreLaunchSupport` carries version/build, short description, review-note lines for tests
- Does **not** archive or upload to App Store Connect in this phase

## Phase 53 — StoreKit / Yofai Pro Payments (locked)
- Freemium-first: Free keeps core local export; Pro is additive via StoreKit 2 subscriptions
- Product IDs: `com.shawnwright.yofai.pro.monthly`, `com.shawnwright.yofai.pro.yearly`
- Intended Connect prices (docs only): $4.99/month, $39.99/year — live UI prices from StoreKit
- Architecture: `YofaiProductIDs`, `PurchaseServicing`, `StoreKitPurchaseService`, `MockPurchaseService`, `StoreEntitlementResolver`, `PurchaseManager`
- `EntitlementPolicy` remains Free vs Pro feature access; StoreKit only applies verified plan
- Paywall (`YofaiProPaywallView`): load products, purchase, restore; unavailable if products fail; no fake success
- Local config: `Yofai.storekit`; Connect checklist: `APP_STORE_CONNECT_SUBSCRIPTIONS.md` (manual; not claimed complete)
- No lifetime SKU this phase; no backend; no Direct Upload; no AI; no data deletion on Free demotion
- Over-limit Free products remain viewable/editable; create blocked until under limit or Pro restored

## Phase 54 — App Store Connect Subscriptions & Sandbox Purchase Verification (locked)
- Documentation + App Review readiness for real Connect subscriptions; **Connect setup not claimed complete**
- Expanded `APP_STORE_CONNECT_SUBSCRIPTIONS.md` (exact checkbox steps)
- Added `STOREKIT_SANDBOX_TESTING.md` (local StoreKit config + TestFlight sandbox scripts)
- Paywall always shows **Terms of Use** (Apple Standard EULA) + **Privacy Statement** (GitHub Pages privacy URL)
- Settings privacy copy updated (Pro is optional StoreKit subscription; Free keeps core export)
- No new product features; no Direct Upload; no AI; no backend

## Phase 55 — App Store Connect IAP Manual Sign-Off & TestFlight Purchase Verification (locked)
- Final Connect sign-off checklist with statuses: Not done / Done by user / Verified in TestFlight (defaults **Not done**)
- `TESTFLIGHT_PURCHASE_VERIFICATION.md` report template (Not run / Pass / Fail / Blocked — defaults **Not run**)
- `STOREKIT_SANDBOX_TESTING.md` + `RELEASE_CHECKLIST.md` A2 IAP gate before submit
- No claim that Connect products or TestFlight purchases were completed
- No new product features; no Direct Upload; no AI; no backend; product IDs unchanged

## Phase 56 — Screenshots, Archive & App Review Submit Path (locked)
- Submission-path package only — **no archive/upload/submit claimed**
- `APP_STORE_SUBMIT_GATES.md` — master gate table (Needs user action / Not started defaults)
- `APP_STORE_ARCHIVE_RUNBOOK.md` — version/build checklist + Xcode archive/upload steps
- Screenshot capture packet finalized in `APP_STORE_PREP.md` (8 screens; no generated fake assets)
- App Review notes finalized in `APP_STORE_METADATA.md`
- Verification order: local StoreKit → Connect IAP → archive/upload → TestFlight purchase → app smoke → gates Passed → App Review
- No new product features; no Direct Upload; no AI; no StoreKit ID/price changes

## Phase 57 — Release Gate Execution Support (locked)
- Local verification only: full suite **301 Passed** + build **Passed** on iPhone 16e (2026-08-10)
- Submission docs package verified present; no optimistic Connect/TestFlight/archive/screenshot Passes
- Screenshots: **Needs user action** (manual capture; not performed by agent)
- Added `SHAWN_NEXT_RELEASE_STEPS.md` owner checklist
- Version remains **1.0 (1)** — build bump before archive is **manual / not auto-changed**
- No new product features; no Direct Upload; no AI; no StoreKit ID/price changes

## Phase 58 — Connect IAP Setup & Screenshot Execution Guide (locked)
- Docs-only owner package: expanded sequential `SHAWN_NEXT_RELEASE_STEPS.md` (§A–G)
- Tightened `APP_STORE_PREP.md` paths/setup/Pro-screenshot rules; Connect checklist still all **Not done**
- Manual gates remain **Needs user action** / **Not started** — no fake Passes
- Version remains **1.0 (1)** — build bump still required before archive
- No new product features; no Direct Upload; no AI; no StoreKit ID/price changes; no archive/upload

## Phase 59 — First Launch Welcome & Walkthrough (locked)
- System launch screen stays simple (`UILaunchScreen` + LaunchMark)
- After open: branded welcome + short animation; Skip always; Get Started / Continue / Done
- 7 guided steps: Start Product → Add Photos → Photo Check → Edit/Fit → Export Local JPEGs → Export History → Yofai Pro
- First launch only (UserDefaults); replay from Settings → Help
- Offline; VoiceOver + Dynamic Type; no AI / Direct Upload / fake Pro success / publish claims
- Free core local export unchanged; StoreKit IDs / presets unchanged
- **Follow-up:** rich SwiftUI mini-scenes per step (`FirstLaunchGuideScenes.swift`) — multi-angle entrances + workflow acting beats; Reduce Motion shows static final frame; still no Lottie/Rive/video

## Phase 60 — Marketplace Workspace Planning & Freemium Mapping (locked, docs-only)
- **No Swift / SwiftData / UI / StoreKit / entitlement code in this phase** — decision lock only
- Yofai stays **freemium-first** and **Local Export Mode only** for this phase family
- Future marketplace workspaces = **manual listing package preparation** for Etsy, eBay, Facebook Marketplace, Mercari, Poshmark, Other — **not** upload/publish/login/OAuth
- **Free:** keep 12 active product limit; **one primary listing workflow per product** via existing `ItemProject` listing fields; full Capture → Organize → Photo Check → Edit/Fit → Prepare → Local JPEG export → notes → view/re-share → copy/share manual package → seller uploads outside the app
- **Pro (additive later):** unlimited products; multiple marketplace drafts per product; reuse product across drafts; marketplace templates; per-marketplace seller defaults; advanced copy/export packages; advanced multi-market checklists; future bulk prep — map multi-draft tools to existing `advancedMultiMarketTools`
- **Model (future impl):** do **not** replace `ItemProject` listing fields; keep them as Free primary draft; add local-only `MarketplaceListingDraft` owned by `ItemProject`; migration **additive only** — never delete/clear/overwrite existing listing text; export history stays valid; presets unchanged; FB/Mercari keep `recommendedExportPreset == nil` until officially verified
- **Copy:** allow “Prepare listing packages for Etsy, eBay, Facebook Marketplace, Mercari, Poshmark, and more,” Local JPEGs, Manual upload, Exported for…, Draft, Workspace, Manual listing package; ban upload-directly / publish / post-automatically / connect-account / automation / “* upload” / compliance / AI claims
- **Out of scope:** Direct Upload, publishing, login, OAuth, browser automation, passwords, scraping, unofficial APIs, backend, AI, ads, analytics SDK, invented dimensions, new fixed FB/Mercari sizes
- Next implementation (when approved): **Phase 61 — Marketplace Listing Drafts (additive model + Free primary / Pro multi-draft UI)**

## Phase 61 — Marketplace Listing Drafts (locked)
- Additive local SwiftData model `MarketplaceListingDraft` owned by `ItemProject` (cascade)
- Free primary listing workflow unchanged on `ItemProject.listing*` fields + Prepare Listing & Export
- Pro additional drafts gated by `advancedMultiMarketTools` — one draft per marketplace per product
- Create copies primary fields into new draft; never clears/overwrites existing project listing text
- UI: Marketplace Drafts section on Product Detail + Listing Workspace; basic Pro draft editor
- FB/Mercari `recommendedExportPreset` still nil; all 7 preset raw values/dimensions unchanged
- Manual listing packages only — no Direct Upload / login / OAuth / publish / API / AI
- Tests: Phase 61 suite + Phase 27 entry-point update for additive draft model

## Phase 62 — Draft-Aware Listing Packages & Copy Tools (locked)
- Draft-specific listing-details text from `MarketplaceListingDraft` fields via `MarketplaceDraftPackageSupport` / `ListingPackageSupport.listingDetailsText(for:)`
- Includes Prepared for / Draft label / listing fields / manual Local JPEGs upload note
- Field copy + Copy listing text + Share listing text in Pro draft editor
- Gated by `advancedMultiMarketTools` (`canUseDraftPackageTools`)
- Free primary `ItemProject` package/export/share unchanged; no Pro required for primary workflow
- No draft JPEG package-folder generation this phase (text copy/share only; file packages stay primary)
- Still Local Export Mode only — no Direct Upload / login / OAuth / publish / API / AI
- FB/Mercari recommended presets still nil; 7 preset raw values/dimensions unchanged
- Tests: Phase 62 suite

## Phase 63 — Marketplace Templates/Defaults (locked)
- Per-marketplace local templates in UserDefaults (`MarketplaceTemplateDefaultsStore`, key `…marketplaceTemplateDefaults.v1`) — separate from Free `SellerDefaults`
- Pro save / apply-to-blank-fields / clear from draft editor; Settings shows status + Free lock
- New Pro draft create prefills blank fields + preferred export/fit from that marketplace template when present
- Apply never overwrites nonblank draft fields (no replace mode this phase)
- Gated by `advancedMultiMarketTools`
- Existing SellerDefaults key/behavior unchanged
- Still Local Export Mode only — no Direct Upload / login / OAuth / publish / API / AI
- FB/Mercari `recommendedExportPreset` still nil; 7 preset raw values/dimensions unchanged
- Tests: Phase 63 suite

## Phase 64 — Pro Multi-Market Workflow Polish (locked)
- Deterministic draft overview status (`MarketplaceDraftCompletionSupport`): Missing title/description, No price, Ready to copy, Draft basics complete, Review before manual upload
- Draft list shows Prepared for, title/placeholder, status, Template available / No saved template, updated date
- Editor shows completion hint + template availability; copy/share helper: “Use this text while manually creating your listing.”
- Free lock copy clarifies primary listing + local export stay available
- Apply-to-blank-fields unchanged; no data migration; no draft JPEG package folders
- Still Local Export Mode only — no Direct Upload / login / OAuth / publish / API / AI
- FB/Mercari recommended presets still nil; 7 preset raw values/dimensions unchanged
- Tests: Phase 64 suite

## Phase 65 — App Store Release Gate Prep (locked)
- Docs/checklist refresh after Phases 61–64; no product feature work; no archive/upload/submit
- Version **1.0** / build **1** left unchanged (bump still required before archive — manual)
- StoreKit IDs confirmed: `com.shawnwright.yofai.pro.monthly` / `.yearly` ($4.99 / $39.99 intended notes only)
- Manual gates remain open: Connect IAP, screenshots, bump+archive, TestFlight purchase Pass, metadata, App Review submit
- Local verification re-run: 354 tests Passed; build Passed on iPhone 16e
- No Direct Upload / login / OAuth / publish / API / AI; no marketplace dimension changes

## Why marketplace APIs are not being done yet (locked)
**Short answer:** APIs are not next because Yofai must first be a strong **local** marketplace listing prep app. Phase 61 only added local drafts. Direct Upload / OAuth / publish stay future work until the local workflow is finished and a specific official API is approved.

**Current state**
- Local Export Mode only
- Free: primary listing workflow on `ItemProject` + primary package/export + Seller Defaults for new products
- Pro: multiple local `MarketplaceListingDraft`s + draft-aware copy/share + per-marketplace templates/defaults + workflow polish via `advancedMultiMarketTools`
- No Direct Upload, login, OAuth, publish, or marketplace API code

**Why API work is later**
1. Local create → edit → copy → package → export → re-share must be reliable first
2. Each marketplace has its own API (or none) — not one shared integration
3. Official APIs need external setup (developer account, keys, OAuth redirects, privacy/terms, sandbox, review/partner approval)
4. Do not assume Facebook Marketplace, Mercari, or Poshmark third-party upload exists until verified
5. Wrong approaches (browser automation, scraping, password storage, unofficial APIs, fake upload) create App Store and account risk
6. When an API phase is approved, walk Shawn through that marketplace’s setup **one step at a time**

**Safe build order (local-first; each step needs approval)**
- Phase 61: Local marketplace drafts — **complete**
- Phase 62: Draft-aware listing packages and copy tools — **complete**
- Phase 63: Marketplace-specific templates/defaults — **complete**
- Phase 64: Pro multi-market workflow polish — **complete**
- Phase 65: App Store release gate prep — **complete** (manual Connect/TestFlight/screenshots/archive still open)
- Later API phase: pick **one** official marketplace (likely Etsy or eBay first), verify access, then implement only after approval

**Do not start API integration until**
- Exact marketplace is approved
- Official API access is verified
- Required external setup is done
- Local workflow is stable
- Integration needs no scraping, browser automation, password storage, or unofficial APIs

## Future StoreKit follow-ups (manual / not claimed done)
- Create/verify subscription group + products in App Store Connect (user sign-off)
- Fill `TESTFLIGHT_PURCHASE_VERIFICATION.md` with real Pass results
- Optional lifetime product if later approved
- Paid-apps privacy nutrition label updates when IAP goes live

## Future capability (approved direction — not next work)
May be added later where they support the product; core photo preparation remains local-first/on-device:
- Backend services
- User accounts
- Cloud sync
- Ads
- Direct Upload Mode for verified marketplaces only
- Yofai Pro StoreKit subscriptions are implemented in-app (Phase 53); Connect product creation still required before live charges

## Not on the product roadmap
- AI listing assistant / OpenAI / paid AI APIs / AI caption or photo evaluation / AI auto-crop

## Abandoned from the active near-term roadmap
Inactive unless explicitly re-approved later:
- Browser automation / unofficial marketplace APIs / marketplace password storage

## Still out of scope unless newly approved
- Social sharing beyond the system Share sheet (local export/share remains the path)
- Inventing marketplace category trees, IDs, scopes, or hard compliance limits
- Implementing Direct Upload Mode without verified official API/OAuth docs and explicit phase approval

## Naming
- Keep user-facing name as Yofai.
- Keep root folder as Yofai.
- Keep Xcode project as Yofai.xcodeproj.
