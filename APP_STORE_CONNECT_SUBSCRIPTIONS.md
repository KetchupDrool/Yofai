# App Store Connect — Yofai Pro Subscriptions (Manual Sign-Off)

**Phases 55–58** — manual Connect setup checklist.  
Step-by-step owner guide: `SHAWN_NEXT_RELEASE_STEPS.md` §B.  
**Agents must not mark Connect items Done or Verified.** Only you can, after completing each step in App Store Connect / TestFlight.

Status values (use exactly one per row):
- **Not done** — default / Needs user action
- **Done by user** — you created/configured it in Connect
- **Verified in TestFlight** — you confirmed it works on a TestFlight/sandbox build (separate from Connect creation)

Overall Connect IAP status for this repo: **Not done** (no proof of Connect completion was provided).  
TestFlight purchase verification is **separate** — use `TESTFLIGHT_PURCHASE_VERIFICATION.md`; do not treat Connect “created” as purchase Verified.

## Product IDs (must match app — do not change without approval)
| Item | Value |
|---|---|
| Monthly product ID | `com.shawnwright.yofai.pro.monthly` |
| Yearly product ID | `com.shawnwright.yofai.pro.yearly` |
| Intended monthly price | $4.99/month |
| Intended yearly price | $39.99/year |
| Subscription group | **Yofai Pro** |

Local StoreKit config: `Yofai/Yofai.storekit`  
Scheme → Run → Options → StoreKit Configuration → `Yofai.storekit`

## Legal (in-app + Connect)
| Item | Value | Status |
|---|---|---|
| Terms of Use (Apple Standard EULA) | https://www.apple.com/legal/internet-services/itunes/dev/stdeula/ | Visible in app (Phase 54) |
| Privacy Statement | https://ketchupdrool.github.io/Yofai/privacy-policy.html | Visible in app (Phase 54) |
| Privacy URL opens in Safari | Confirm before submit | **Not done** |
| Connect privacy / Purchases nutrition labels updated for IAP | When products go live | **Not done** |

---

## Sign-off table

| # | Step | Details | Status |
|---|---|---|---|
| 1 | Open App Store Connect | https://appstoreconnect.apple.com | **Not done** |
| 2 | Select Yofai app | Bundle ID `com.shawnwright.yofai` | **Not done** |
| 3 | Open Subscriptions | Monetization → Subscriptions | **Not done** |
| 4 | Create subscription group | Name: **Yofai Pro** | **Not done** |
| 5 | Group localization | Display name for group if required | **Not done** |
| 6 | Create monthly subscription | See Monthly block below | **Not done** |
| 7 | Monthly localization | Display name + description | **Not done** |
| 8 | Create yearly subscription | See Yearly block below | **Not done** |
| 9 | Yearly localization | Display name + description | **Not done** |
| 10 | Subscription review information | Fill Connect review fields | **Not done** |
| 11 | Paywall screenshot | Attach if Connect requires for review | **Not done** |
| 12 | Clear products for review | Attach to the app version you will submit | **Not done** |
| 13 | Sandbox tester | Users and Access → Sandbox → create tester | **Not done** |
| 14 | Products load in TestFlight | Monthly + yearly appear with StoreKit prices | **Not done** |
| 15 | Purchase + restore verified | Fill `TESTFLIGHT_PURCHASE_VERIFICATION.md` | **Not done** |

---

## Monthly subscription (create exactly)

| Field | Value |
|---|---|
| Product ID | `com.shawnwright.yofai.pro.monthly` |
| Reference name | Yofai Pro Monthly |
| Duration | 1 month |
| Intended price | **$4.99**/month |
| Display name | Yofai Pro Monthly |
| Description | Unlocks Pro features in Yofai. |

Status: **Not done**

## Yearly subscription (create exactly)

| Field | Value |
|---|---|
| Product ID | `com.shawnwright.yofai.pro.yearly` |
| Reference name | Yofai Pro Yearly |
| Duration | 1 year |
| Intended price | **$39.99**/year |
| Display name | Yofai Pro Yearly |
| Description | Unlocks Pro features in Yofai for one year. |

Status: **Not done**

### Optional longer description (localization notes)
Free keeps Capture → Organize → Photo Check → Edit → Prepare → Local Export. Pro is additive (unlimited products and planned extras). Direct Upload and cloud backup are not included. No AI features.

---

## App behavior already in code (not Connect)
- Free keeps core local export without purchase
- UI prices from StoreKit `displayPrice` when products load
- Unavailable: “Purchases are not available right now.” — no fake price buttons; legal links + Restore still visible
- Pro unlock only after verified StoreKit entitlement
- No Direct Upload / AI / backend for Free workflow

## Related docs
- `STOREKIT_SANDBOX_TESTING.md` — how to test
- `TESTFLIGHT_PURCHASE_VERIFICATION.md` — Pass/Fail report template
- `RELEASE_CHECKLIST.md` — submit gate
