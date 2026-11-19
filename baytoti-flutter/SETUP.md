# بيتي — Flutter (iOS + macOS) setup

Port of the web `baytoti/bayti.html` tracker to Flutter, backed by Firebase Firestore for real-time shared lists.

## 1. Install the FlutterFire CLI (one-time)

```bash
dart pub global activate flutterfire_cli
# then make sure ~/.pub-cache/bin is on your PATH
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

You also need the Firebase CLI (`npm i -g firebase-tools` → `firebase login`) because `flutterfire configure` calls it under the hood.

## 2. Create / link the Firebase project

From this project folder:

```bash
cd "$HOME/Downloads/web projects/projects/baytoti-flutter"
flutterfire configure \
  --project=<your-firebase-project-id-or-create-new> \
  --platforms=ios,macos \
  --ios-bundle-id=com.maizer.baytoti \
  --macos-bundle-id=com.maizer.baytoti
```

That will:

- create/link the Firebase project,
- register iOS + macOS apps,
- download `GoogleService-Info.plist` into `ios/Runner/` and `macos/Runner/`,
- overwrite `lib/firebase_options.dart` with real values.

## 3. Enable Firestore in the Firebase console

- Open https://console.firebase.google.com/project/_/firestore
- Click **Create database** → start in **test mode** for now.
- Pick a region close to you (e.g. `europe-west1`).

Lock down later with these rules (anyone with the `listId` can read/write that list only):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /lists/{listId} {
      allow read, write: if true;
      match /{sub=**} {
        allow read, write: if true;
      }
    }
  }
}
```

## 4. Install iOS pods

```bash
cd ios && pod install && cd ..
```

(Pods run automatically on first `flutter run` too, but installing manually surfaces errors faster.)

## 5. Run

```bash
flutter run -d macos     # macOS desktop
flutter run -d <iphone>  # see `flutter devices` for simulators / connected phones
```

## Data model (Firestore)

```
lists/{listId}                          { name, createdAt }
lists/{listId}/purchases/{id}           { itemName, price, category, addedByName, date }
lists/{listId}/wishlist/{id}            { itemName, addedByName, createdAt }
```

`listId` is a 10-char random string generated client-side — same shape as the web app's URL param. A link like `https://maizer999.github.io/projects/baytoti/bayti.html?list=<listId>` opens the same shared list on web.

## What's wired up

- Landing: create a new list, or paste a shared link / id to join.
- Needs tab (النواقص): add items, convert to purchase, delete.
- Purchases tab (المشتريات): add/edit/delete with name, price, category, auto-filled "added by".
- History tab (السجل): read-only full log.
- Weekly filter (هذا الأسبوع / الكل) on purchases + history.
- Share button copies/shares the web URL for that `listId`.
- Arabic RTL throughout; cream/teal theme.
- iOS 15+, macOS 10.15+ (both have network-client entitlement set).

## Not ported (yet)

- Product autocomplete + price autofill from the Google Sheet.
- `syncPurchase()` writes to the Apps Script endpoint — Firestore is now the source of truth, so that sync becomes redundant if everyone switches to the app. If you want web ⇆ Flutter cross-sync, migrate the web page to Firestore too.
