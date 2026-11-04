# Al-Quran (Flutter)

Mushaf reader with ayah-by-ayah recitation and a memorisation (تسميع) mode.

- **Text:** Madinah Mushaf, KFGQPC Hafs font, bundled offline via [`mushaf_text`](https://pub.dev/packages/mushaf_text) — page-for-page like the printed copy, optional tajweed colours.
- **Audio:** Islamic Network CDN (`cdn.islamic.network`), 20 reciters.
- **Architecture:** Clean Architecture (layer-first) + Riverpod (manual `Notifier` / `Provider`, no code generation).

## Structure

```
lib/
  main.dart                 bootstraps prefs + Quran text, ProviderScope overrides
  app.dart                  MaterialApp
  core/
    constants/              ALL constants live here
      api_constants.dart      audio CDN, WhatsApp base URL
      app_constants.dart      page/juz counts, font limits, speeds, defaults, layout
      storage_keys.dart       SharedPreferences keys
      contact_constants.dart  email / phone / WhatsApp for "تواصل معنا"
      app_strings.dart        user-facing Arabic text
    theme/                  colour presets + ThemeData
    utils/                  arabic numerals
  domain/                   pure Dart, no Flutter/plugins
    entities/               Surah, Ayah, Juz, Reciter, AppSettings
    repositories/           abstract interfaces
    usecases/               quran / settings / mistakes use cases
  data/
    datasources/            mushaf_text (offline text), SharedPreferences, audioplayers, reciters list
    models/                 mushaf_text → entity mappers
    repositories/           *_impl.dart
  presentation/
    providers/              Riverpod: DI, settings, reader, player, mistakes, highlight
    screens/                home, contact
    widgets/                toolbar, juz list, mushaf reader, player bar, settings sheet
```

## External APIs

| Use | URL |
|---|---|
| Ayah audio | `https://cdn.islamic.network/quran/audio/128/{reciterId}/{globalAyahId}.mp3` |
| WhatsApp | `https://wa.me/{number}` |

No API is needed for the Quran text — it ships inside the app.

## Run

```bash
flutter pub get
flutter run
flutter test
```

Set real contact details in `lib/core/constants/contact_constants.dart`.
