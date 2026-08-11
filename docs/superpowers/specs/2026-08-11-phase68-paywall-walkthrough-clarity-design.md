# Phase 68 — Pre-Archive Paywall & Walkthrough Clarity

**Date:** 2026-08-11  
**Approach:** Shared copy + targeted UI (no full rebuild)  
**Note:** Handoff number is Phase 68 (Phase 67 already = post-readability UI QA).

## Goal
Clarify Yofai Pro pricing/benefits and upgrade the first-run guide into a slower, readable animated mini tutorial before archive. No archive/upload/submit. No Direct Upload / OAuth / API / AI.

## Paywall
- Live StoreKit `displayPrice` when products load: `Monthly — …`, `Yearly — …`, **Best value** on yearly.
- When StoreKit unavailable: show intended/fallback `Monthly — $4.99` / `Yearly — $39.99` (not fake purchase success); keep purchases-unavailable honesty.
- Free includes: Create products, Edit photos, Photo Check, Export JPEGs.
- Pro adds: Unlimited products, Advanced export history, Marketplace Drafts, Marketplace templates.
- Remove Cloud backup + Direct Upload Mode from main paywall marketing (enum/policy cases may remain).
- Keep: Keep using Free, Restore, Terms, Privacy. Product IDs unchanged.

## Walkthrough
Title + short bullets. Pages (after Welcome):

1. Start with a Product  
2. Add Photos  
3. Check Your Photos (Photo Check)  
4. Crop and Focus  
5. Fit Your Photo (Contain + Pad / Fill + Crop)  
6. Reposition the Crop  
7. Pick Export Size  
8. Choose Marketplace Target (no upload/publish)  
9. Export JPEGs  
10. Use Export History  
11. Yofai Pro (brief, honest)

Slower premium motion; Reduce Motion → nil/instant. VoiceOver + Dynamic Type preserved.

## Seller wording (focused)
Primary CTAs / guide / paywall: Product, Photos, Listing Info, Photo Check, Export JPEGs, Marketplace Drafts, Copy Listing Text. Avoid marketing “Advanced multi-market export tools” / “Manual listing package” / “Marketplace workspace” on these surfaces.

## Out of scope
Archive, upload, submit, build bump, Direct Upload, OAuth, API, AI, invented FB/Mercari sizes.
