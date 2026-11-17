# Prompt: Prepare Quran App for Google Play Console Upload

**App context (give this to the AI verbatim):**
- Flutter app: Al-Quran Mushaf reader with audio recitation
- Package ID: `com.quranapp.quran_app`
- Version: `1.0.1+2` (versionName 1.0.1, versionCode 2)
- Platforms shipping: Android (this upload)
- Content: Offline KFGQPC Hafs Quran text, streams recitation audio from `cdn.islamic.network`
- Features: 20 reciters, memorization mode, bookmarks, favorites, local notifications, dark-only RTL Arabic UI
- Dependencies that affect disclosures: `audioplayers`, `flutter_local_notifications`, `url_launcher`, `shared_preferences`
- No ads, no in-app purchases, no user accounts, no analytics, no user-generated content
- Audio is public CDN (Islamic Network) — no personal data collected

**Tasks for you (the AI) to walk me through step-by-step:**

## 1. Pre-upload code fixes (BLOCKERS)
- [ ] Replace **debug signing** in `android/app/build.gradle.kts` with a real release signing config (keystore, key.properties, gitignored)
- [ ] Confirm `minSdk`, `targetSdk`, `compileSdk` meet current Play requirements (targetSdk 34+ for new apps in 2024/2025)
- [ ] Review `AndroidManifest.xml` permissions — justify every one (INTERNET, POST_NOTIFICATIONS, WAKE_LOCK, FOREGROUND_SERVICE if any)
- [ ] Build an **AAB** (`flutter build appbundle --release`), not APK
- [ ] Verify app doesn't crash in release mode on a real device

## 2. Google Play Console account setup
- [ ] Developer account ($25 one-time) — needs ID verification (D-U-N-S or personal, takes days)
- [ ] Choose developer type: Personal vs Organization
- [ ] Payment profile if monetizing later

## 3. Store listing assets to prepare
- [ ] **App icon**: 512×512 PNG, 32-bit
- [ ] **Feature graphic**: 1024×500 PNG/JPG (no transparency)
- [ ] **Phone screenshots**: 2–8 images, 16:9 or 9:16, min 320px
- [ ] **7-inch tablet** and **10-inch tablet** screenshots (optional but recommended)
- [ ] **Short description**: ≤80 chars (Arabic + English)
- [ ] **Full description**: ≤4000 chars (mention: offline Mushaf, 20 reciters, bookmarks, memorization)
- [ ] **App title**: ≤30 chars
- [ ] **Promo video** (optional, YouTube link)

## 4. Policy/declaration forms to fill
- [ ] **Content rating questionnaire** (IARC) — religious content, no violence
- [ ] **Target audience & content** — ages 13+ likely
- [ ] **Data safety form**: declare no data collection; audio URLs hit third-party CDN (disclose `cdn.islamic.network`)
- [ ] **Ads declaration**: No
- [ ] **Government app**: No
- [ ] **COVID-19 contact tracing**: No
- [ ] **News app**: No
- [ ] **Financial features**: No
- [ ] **Health**: No

## 5. App category & tags
- [ ] Category: **Books & Reference** (or Lifestyle)
- [ ] Tags: Islam, Quran, Religion
- [ ] Contact email, website, privacy policy URL (REQUIRED — I need to host one)

## 6. Privacy policy content (draft one for me)
Should cover: no personal data collected, local storage only (SharedPreferences), third-party audio CDN requests, no analytics/ads/trackers.

## 7. Release track strategy
- [ ] Start with **Internal testing** → Closed testing → Open testing → Production
- [ ] Google now requires **12 testers for 14 days** for new personal developer accounts before Production

## 8. Final upload checklist
- [ ] Upload signed AAB to Internal testing
- [ ] Attach release notes (Arabic + English)
- [ ] Review all green checkmarks on "Dashboard"
- [ ] Submit for review (24h–7 days)

---

**Please walk me through each section one at a time, asking what I've prepared and what I still need. Flag anything unusual about distributing a Quran app (content sensitivity, trademark on KFGQPC font, etc.).**

---

## Known blocker on this repo
The Android release currently signs with **debug keys** (`Quran/android/app/build.gradle.kts:32`) — fix that first or Play will reject the upload.
