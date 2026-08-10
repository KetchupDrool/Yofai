# App Store Archive & Upload Runbook — Yofai

**Phase 56** — manual Xcode steps.  
**Do not claim archive/upload/submit happened unless you did them.**

Related: `APP_STORE_SUBMIT_GATES.md`, `RELEASE_CHECKLIST.md`, `APP_STORE_CONNECT_SUBSCRIPTIONS.md`.

## Before you archive
1. Working tree clean on the intended `main` commit  
2. Connect IAP products created / cleared for review (or knowingly blocked)  
3. Version / build checklist (below) reviewed — **bump build before each upload**  
4. Full unit suite passed on **iPhone 16e**  
5. Screenshots ready or planned  

### Version / build checklist (do not auto-change in-repo unless approved)
| Check | Current / note | Done? |
|---|---|---|
| Marketing version (`MARKETING_VERSION` / `CFBundleShortVersionString`) | **1.0** | [ ] |
| Build number (`CURRENT_PROJECT_VERSION` / `CFBundleVersion`) | **1** — increment before each Connect upload | [ ] |
| Bundle ID | `com.shawnwright.yofai` | [ ] |
| Display name | Yofai | [ ] |
| Device family | iPhone | [ ] |
| App icon (`AppIcon`) | Present | [ ] |
| Launch screen | Present | [ ] |
| Camera usage string | Product capture into local Item Project | [ ] |
| Photos Add usage string | Save Listing Copy only | [ ] |

## Archive / upload steps
1. Clean working tree (`git status` clean on intended commit)  
2. Open `Yofai.xcodeproj` in Xcode  
3. Select scheme **Yofai** → configuration **Release** for archive  
4. Destination: **Any iOS Device (arm64)** / Generic iOS Device (not a simulator)  
5. **Product → Archive**  
6. When Organizer opens: select the archive → **Distribute App**  
7. Choose **App Store Connect** → Upload  
8. Follow signing prompts (your Apple team)  
9. Wait for App Store Connect **processing** to finish  
10. Attach the build to the App Store / TestFlight version  
11. Run TestFlight smoke + purchase verification (`TESTFLIGHT_SMOKE.md`, `TESTFLIGHT_PURCHASE_VERIFICATION.md`)  
12. Submit for **App Review** only after purchase verification **Pass** and gates in `APP_STORE_SUBMIT_GATES.md` are Passed  

## After upload
- [ ] Build visible in TestFlight  
- [ ] Internal test installed on a physical iPhone  
- [ ] Purchase verification report filled  
- [ ] Metadata + screenshots attached  
- [ ] App Review notes pasted  

## Status for this phase (repo default)
Archive: **Not started**  
Upload: **Not started**  
App Review submit: **Not started**
