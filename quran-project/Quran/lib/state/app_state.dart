import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/juz.dart';
import '../models/surah.dart';
import '../services/prefs.dart';
import '../services/quran_api.dart';
import '../theme.dart';

class Reciter {
  final String id;
  final String name;
  const Reciter(this.id, this.name);
}

class AppState extends ChangeNotifier {
  AppState(this._prefs) {
    // Apply the saved accent preset immediately so the very first frame
    // (built from AppColors.accent/accent2) already matches it.
    AppColors.applyPreset(presetById(accentPresetId));
  }

  final Prefs _prefs;
  final QuranApi api = QuranApi();

  static const reciters = <Reciter>[
    Reciter('ar.alafasy', 'مشاري راشد العفاسي'),
    Reciter('ar.husary', 'محمود خليل الحصري'),
    Reciter('ar.husarymujawwad', 'محمود خليل الحصري (مجوّد)'),
    Reciter('ar.minshawi', 'محمد صديق المنشاوي'),
    Reciter('ar.minshawimujawwad', 'محمد صديق المنشاوي (مجوّد)'),
    Reciter('ar.abdulbasitmurattal', 'عبد الباسط عبد الصمد (مرتل)'),
    Reciter('ar.abdulsamad', 'عبد الباسط عبد الصمد (مجوّد)'),
    Reciter('ar.hudhaify', 'علي بن عبد الرحمن الحذيفي'),
    Reciter('ar.saoodshuraym', 'سعود الشريم'),
    Reciter('ar.abdurrahmaansudais', 'عبد الرحمن السديس'),
    Reciter('ar.mahermuaiqly', 'ماهر المعيقلي'),
    Reciter('ar.shaatree', 'أبو بكر الشاطري'),
    Reciter('ar.ahmedajamy', 'أحمد بن علي العجمي'),
    Reciter('ar.hanirifai', 'هاني الرفاعي'),
    Reciter('ar.muhammadayyoub', 'محمد أيوب'),
    Reciter('ar.muhammadjibreel', 'محمد جبريل'),
    Reciter('ar.abdullahbasfar', 'عبد الله بصفر'),
    Reciter('ar.ibrahimakhbar', 'إبراهيم الأخضر'),
    Reciter('ar.aymanswoaid', 'أيمن سويد'),
    Reciter('ar.parhizgar', 'شهريار پرهيزگار'),
  ];

  // Preferences
  late String reciterId = _prefs.getString('reciter', 'ar.alafasy');
  late double arSize = _prefs.getInt('arSize', 22).toDouble();
  late bool darkMode = _prefs.getBool('dark', true);
  late int lastSurah = _prefs.getInt('lastSurah', 0);
  late String accentPresetId = _prefs.getString('accentPreset', 'green');
  late bool ornateFrame = _prefs.getBool('ornateFrame', true);

  // Collections
  late Map<int, Set<int>> surahMistakeAyahs = _loadSurahMistakeAyahs();

  // Session
  List<Surah> surahs = [];
  bool loadingList = false;
  String? listError;

  SurahDetail? arabic;
  bool loadingSurah = false;
  String? surahError;

  int currentAyahIdx = -1;
  bool playing = false;

  // Derived
  Reciter get currentReciter =>
      reciters.firstWhere((r) => r.id == reciterId, orElse: () => reciters[0]);

  // Loaders
  Future<void> loadSurahs() async {
    loadingList = true;
    listError = null;
    notifyListeners();
    try {
      surahs = await api.listSurahs();
      listError = null;
      if (lastSurah > 0) {
        unawaited(loadSurah(lastSurah));
      }
    } catch (e) {
      listError = e.toString();
    } finally {
      loadingList = false;
      notifyListeners();
    }
  }

  Future<void> loadSurah(int number) async {
    loadingSurah = true;
    surahError = null;
    currentAyahIdx = -1;
    notifyListeners();
    try {
      arabic = await api.getSurah(number, 'quran-uthmani');
      lastSurah = number;
      await _prefs.setInt('lastSurah', number);
    } catch (e) {
      surahError = e.toString();
    } finally {
      loadingSurah = false;
      notifyListeners();
    }
  }

  // Settings mutators
  Future<void> setReciter(String id) async {
    reciterId = id;
    await _prefs.setString('reciter', id);
    notifyListeners();
  }

  static const double arSizeMin = 14;
  static const double arSizeMax = 60;
  static const double arSizeStep = 2;

  Future<void> setArSize(double size) async {
    arSize = size.clamp(arSizeMin, arSizeMax);
    await _prefs.setInt('arSize', arSize.round());
    notifyListeners();
  }

  Future<void> bumpArSize(double delta) => setArSize(arSize + delta);

  Future<void> toggleTheme() async {
    darkMode = !darkMode;
    await _prefs.setBool('dark', darkMode);
    notifyListeners();
  }

  Future<void> setAccentPreset(String id) async {
    accentPresetId = id;
    AppColors.applyPreset(presetById(id));
    await _prefs.setString('accentPreset', id);
    notifyListeners();
  }

  Future<void> setOrnateFrame(bool value) async {
    ornateFrame = value;
    await _prefs.setBool('ornateFrame', value);
    notifyListeners();
  }

  // Per-surah mistake marks (for the Memorize flow).
  // For each surah, we keep the SET of ayah numbers currently marked as a
  // mistake (not a blind running total) — so when you come back to a surah,
  // you see exactly which ayahs you had trouble with, and tapping an
  // already-marked ayah again un-marks it (fixes an accidental tap, or
  // "I got this one right now"). The counter shown in the surah list is
  // just the size of that set: how many ayahs still need work.
  Map<int, Set<int>> _loadSurahMistakeAyahs() {
    final raw = _prefs.getString('surahMistakeAyahs', '');
    if (raw.isEmpty) return <int, Set<int>>{};
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return decoded.map(
      (k, v) => MapEntry(
        int.parse(k),
        (v as List).map((e) => e as int).toSet(),
      ),
    );
  }

  Future<void> _saveSurahMistakeAyahs() => _prefs.setString(
        'surahMistakeAyahs',
        json.encode(
          surahMistakeAyahs.map(
            (k, v) => MapEntry(k.toString(), v.toList()),
          ),
        ),
      );

  int mistakeCountForSurah(int surahNumber) =>
      surahMistakeAyahs[surahNumber]?.length ?? 0;

  bool isSurahAyahMistake(int surahNumber, int ayahNumber) =>
      surahMistakeAyahs[surahNumber]?.contains(ayahNumber) ?? false;

  /// Marks or unmarks one ayah as a mistake for this surah. Returns the
  /// new state (true = now marked) so callers can show feedback.
  Future<bool> toggleSurahAyahMistake(int surahNumber, int ayahNumber) async {
    final set = surahMistakeAyahs.putIfAbsent(surahNumber, () => <int>{});
    final nowMarked = !set.contains(ayahNumber);
    if (nowMarked) {
      set.add(ayahNumber);
    } else {
      set.remove(ayahNumber);
    }
    await _saveSurahMistakeAyahs();
    notifyListeners();
    return nowMarked;
  }

  Future<void> resetSurahMistakeCount(int surahNumber) async {
    if (!surahMistakeAyahs.containsKey(surahNumber)) return;
    surahMistakeAyahs.remove(surahNumber);
    await _saveSurahMistakeAyahs();
    notifyListeners();
  }

  // Juz <-> Surah
  List<Surah> surahsInJuz(int juzNumber) {
    final juz = quranJuzs.firstWhere((j) => j.number == juzNumber);
    return surahs.where((s) => juz.containsSurah(s.number)).toList();
  }

  // Playback state (set from PlayerController)
  void setPlaybackState({required int ayahIdx, required bool playing}) {
    currentAyahIdx = ayahIdx;
    this.playing = playing;
    notifyListeners();
  }
}
