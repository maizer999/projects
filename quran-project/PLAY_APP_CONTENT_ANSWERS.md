# Play Console — App Content Form Answers

For package `com.maizer.quranalsabea`. Each section matches a Play Console sidebar item under **App content**.

---

## 1. Privacy policy
- **URL:** `https://maizer999.github.io/projects/quran-project/privacy.html` *(must be hosted before you can save this field)*

## 2. App access
- **Is all functionality available without special access?** → **Yes, all functionality is available without special access**
  - No login, no subscription, no gated features.

## 3. Ads
- **Does your app contain ads?** → **No, my app does not contain ads**

## 4. Content rating (IARC questionnaire)
Email for IARC certificate: `maizer99@gmail.com`
Category: **Reference, News, or Educational** → Reference

Expected answers (all **No**):
- Violence (cartoon, fantasy, realistic, sexual) → No
- Sexual content / nudity → No
- Profanity / crude humor → No
- Controlled substances → No
- User-to-user interaction / UGC / sharing location → No
- Digital purchases → No
- Gambling / contests → No
- Enables unrestricted internet browsing → No *(audio streams are from a fixed CDN only)*
- Horror / fear → No
- Collects personal info → No

**Expected rating:** Everyone (IARC 3+).

## 5. Target audience and content
- **Target age groups:** **13+** (allows adult reciters' audio, Arabic literacy expectation). Pick 18+ if you want to avoid the stricter "Designed for Families" rules — 13+ is fine.
- **Does your app unintentionally appeal to children?** → **No**
- **Google Play Families Policy applies?** → **No**

## 6. News app
- **Is this a news app?** → **No**

## 7. COVID-19 contact tracing and status apps
- **Is this a public health app / COVID-19 contact tracing?** → **No**

## 8. Data safety

### Section A — Data collection and security
- **Does your app collect or share any of the required user data types?** → **No**
  - All user preferences (reciter, theme, bookmarks, mistakes, last page) are stored **on-device** via SharedPreferences.
  - The app has **no account system**, **no analytics SDK**, **no crash reporting**, **no ads SDK**.

- **Is all of the user data collected by your app encrypted in transit?** → **Yes**
  *(Audio requests use HTTPS to `cdn.islamic.network` — technically the app doesn't collect data, so this field may be skipped.)*

- **Do you provide a way for users to request that their data is deleted?** → **Not applicable / No data collected**

### Section B — Third-party SDKs and network calls (for the "data not collected" declaration, still disclose network dependencies in the policy)
Audio recitations are streamed from a **public third-party CDN** (`cdn.islamic.network`). The request contains no personal identifiers — only the reciter ID and ayah number embedded in the URL. The CDN may log standard HTTP access logs (IP address, timestamp, user-agent) as any web server does; these are not accessible to this app.

**In the Data safety form:** keep "No data collected or shared". Mention the CDN only in your privacy policy.

## 9. Government apps
- **Is this app developed by or on behalf of a government?** → **No**

## 10. Financial features
- **Does your app provide financial features?** → **No**

## 11. Health
- **Does your app provide health features?** → **No**

## 12. Advertising ID
- **Does your app use advertising ID?** → **No**

---

## Summary of forms (what to click in Play Console)
| Section | Status to aim for |
|---|---|
| Privacy policy | ✅ URL entered |
| App access | ✅ All free, no login |
| Ads | ✅ No ads |
| Content rating | ✅ Everyone (after questionnaire) |
| Target audience | ✅ 13+, not designed for kids |
| News app | ✅ No |
| COVID-19 | ✅ No |
| Data safety | ✅ No data collected, no data shared |
| Government | ✅ No |
| Financial | ✅ No |
| Health | ✅ No |
| Advertising ID | ✅ No |
