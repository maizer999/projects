import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/surah.dart';
import '../services/prefs.dart';
import '../services/quran_api.dart';

class Reciter {
  final String id;
  final String name;
  const Reciter(this.id, this.name);
}

class Translation {
  final String id;
  final String name;
  const Translation(this.id, this.name);
}

class ArabicFont {
  final String key;
  final String label;
  final String family;
  const ArabicFont(this.key, this.label, this.family);
}

class AyahRef {
  final int surah;
  final int ayah;
  const AyahRef(this.surah, this.ayah);

  Map<String, dynamic> toJson() => {'surah': surah, 'ayah': ayah};
  factory AyahRef.fromJson(Map<String, dynamic> j) =>
      AyahRef(j['surah'] as int, j['ayah'] as int);
}

class PageMistakeMark {
  final double x;
  final double y;
  const PageMistakeMark(this.x, this.y);
  Map<String, dynamic> toJson() => {'x': x, 'y': y};
  factory PageMistakeMark.fromJson(Map<String, dynamic> j) =>
      PageMistakeMark((j['x'] as num).toDouble(), (j['y'] as num).toDouble());
}

class PageMemo {
  final int page;
  bool memorized;
  int percent;
  List<PageMistakeMark> mistakes;

  PageMemo({
    required this.page,
    this.memorized = false,
    this.percent = 0,
    List<PageMistakeMark>? mistakes,
  }) : mistakes = mistakes ?? <PageMistakeMark>[];

  Map<String, dynamic> toJson() => {
        'page': page,
        'memorized': memorized,
        'percent': percent,
        'mistakes': mistakes.map((m) => m.toJson()).toList(),
      };

  factory PageMemo.fromJson(Map<String, dynamic> j) => PageMemo(
        page: j['page'] as int,
        memorized: (j['memorized'] as bool?) ?? false,
        percent: (j['percent'] as int?) ?? 0,
        mistakes: ((j['mistakes'] as List?) ?? const [])
            .map((e) => PageMistakeMark.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

enum SurahFilter { all, meccan, medinan, bookmarks }

class AppState extends ChangeNotifier {
  AppState(this._prefs);

  final Prefs _prefs;
  final QuranApi api = QuranApi();

  static const reciters = <Reciter>[
    Reciter('ar.alafasy', 'Mishary Al-Afasy'),
    Reciter('ar.husary', 'Mahmoud Al-Husary'),
    Reciter('ar.husarymujawwad', 'Al-Husary (Mujawwad)'),
    Reciter('ar.minshawi', 'Muhammad Al-Minshawi'),
    Reciter('ar.minshawimujawwad', 'Al-Minshawi (Mujawwad)'),
    Reciter('ar.abdulbasitmurattal', 'AbdulBaset AbdulSamad (Murattal)'),
    Reciter('ar.abdulsamad', 'AbdulBaset AbdulSamad (Mujawwad)'),
    Reciter('ar.hudhaify', 'Ali Al-Hudhaify'),
    Reciter('ar.saoodshuraym', 'Saud Al-Shuraym'),
    Reciter('ar.abdurrahmaansudais', 'Abdur-Rahman As-Sudais'),
    Reciter('ar.mahermuaiqly', 'Maher Al Muaiqly'),
    Reciter('ar.shaatree', 'Abu Bakr Al-Shatri'),
    Reciter('ar.ahmedajamy', 'Ahmed Al-Ajamy'),
    Reciter('ar.hanirifai', 'Hani Ar-Rifai'),
    Reciter('ar.muhammadayyoub', 'Muhammad Ayyoub'),
    Reciter('ar.muhammadjibreel', 'Muhammad Jibreel'),
    Reciter('ar.abdullahbasfar', 'Abdullah Basfar'),
    Reciter('ar.ibrahimakhbar', 'Ibrahim Al-Akhdar'),
    Reciter('ar.aymanswoaid', 'Ayman Suwaid'),
    Reciter('ar.parhizgar', 'Shahriar Parhizgar'),
  ];

  static const translations = <Translation>[
    Translation('en.sahih', 'Saheeh International (EN)'),
    Translation('en.pickthall', 'Pickthall (EN)'),
    Translation('en.yusufali', 'Yusuf Ali (EN)'),
    Translation('ur.jalandhry', 'Urdu — Jalandhry'),
    Translation('fr.hamidullah', 'French — Hamidullah'),
    Translation('id.indonesian', 'Indonesian'),
    Translation('tr.diyanet', 'Turkish — Diyanet'),
    Translation('es.cortes', 'Spanish — Cortes'),
    Translation('de.aburida', 'German — Abu Rida'),
    Translation('none', 'No translation'),
  ];

  static const fonts = <ArabicFont>[
    ArabicFont('amiri-quran', 'Amiri Quran', 'Amiri Quran'),
    ArabicFont('amiri', 'Amiri', 'Amiri'),
    ArabicFont('scheherazade', 'Scheherazade New', 'Scheherazade New'),
    ArabicFont('noto', 'Noto Naskh Arabic', 'Noto Naskh Arabic'),
    ArabicFont('lateef', 'Lateef', 'Lateef'),
    ArabicFont('markazi', 'Markazi Text', 'Markazi Text'),
    ArabicFont('reem', 'Reem Kufi', 'Reem Kufi'),
  ];

  // Preferences
  late String reciterId = _prefs.getString('reciter', 'ar.alafasy');
  late String translationId = _prefs.getString('translation', 'en.sahih');
  late String fontKey = _prefs.getString('arFont', 'amiri-quran');
  late double arSize = _prefs.getInt('arSize', 22).toDouble();
  late bool darkMode = _prefs.getBool('dark', true);
  late int lastSurah = _prefs.getInt('lastSurah', 0);

  // Collections
  late List<AyahRef> bookmarks =
      _prefs.getJsonList('bookmarks', AyahRef.fromJson);
  late List<AyahRef> mistakes =
      _prefs.getJsonList('mistakes', AyahRef.fromJson);
  late List<int> savedSurahs = _prefs.getIntList('savedSurahs');
  late Map<int, PageMemo> pageMemos = _loadPageMemos();
  final Map<int, Future<QuranPage>> _pageCache = {};
  late String pageImageUrlTemplate = _prefs.getString(
    'pageImgTpl',
    'https://api.islamic.app/v1/mushaf/page/{N}.svg',
  );

  static const int quranPageCount = 604;

  Future<QuranPage> getQuranPage(int page) =>
      _pageCache.putIfAbsent(page, () => api.getPage(page));

  String pageImageUrl(int page) => pageImageUrlTemplate
      .replaceAll('{N}', page.toString())
      .replaceAll('{page}', page.toString())
      .replaceAll('{N3}', page.toString().padLeft(3, '0'));

  Future<void> setPageImageUrlTemplate(String tpl) async {
    pageImageUrlTemplate = tpl;
    await _prefs.setString('pageImgTpl', tpl);
    notifyListeners();
  }

  Map<int, PageMemo> _loadPageMemos() {
    final list = _prefs.getJsonList('pageMemos', PageMemo.fromJson);
    return {for (final m in list) m.page: m};
  }

  Future<void> _savePageMemos() async {
    await _prefs.setJsonList(
      'pageMemos',
      pageMemos.values.map((m) => m.toJson()).toList(),
    );
  }

  PageMemo getPageMemo(int page) =>
      pageMemos[page] ?? PageMemo(page: page);

  Future<void> setPageMemorized(int page, bool v) async {
    final m = pageMemos.putIfAbsent(page, () => PageMemo(page: page));
    m.memorized = v;
    if (v && m.percent < 100) m.percent = 100;
    await _savePageMemos();
    notifyListeners();
  }

  Future<void> setPagePercent(int page, int percent) async {
    final clamped = percent.clamp(0, 100);
    final m = pageMemos.putIfAbsent(page, () => PageMemo(page: page));
    m.percent = clamped;
    if (clamped == 100) m.memorized = true;
    if (clamped == 0) m.memorized = false;
    await _savePageMemos();
    notifyListeners();
  }

  Future<void> togglePageMistakeAt(int page, double x, double y,
      {double hitRadius = 0.03}) async {
    final m = pageMemos.putIfAbsent(page, () => PageMemo(page: page));
    final i = m.mistakes.indexWhere((mk) {
      final dx = mk.x - x;
      final dy = mk.y - y;
      return (dx * dx + dy * dy) <= hitRadius * hitRadius;
    });
    if (i >= 0) {
      m.mistakes.removeAt(i);
    } else {
      m.mistakes.add(PageMistakeMark(x, y));
    }
    await _savePageMemos();
    notifyListeners();
  }

  Future<void> clearPageMistakes(int page) async {
    final m = pageMemos[page];
    if (m == null || m.mistakes.isEmpty) return;
    m.mistakes.clear();
    await _savePageMemos();
    notifyListeners();
  }


  // Session
  List<Surah> surahs = [];
  bool loadingList = false;
  String? listError;

  SurahDetail? arabic;
  SurahDetail? translation;
  bool loadingSurah = false;
  String? surahError;

  String searchQuery = '';
  SurahFilter filter = SurahFilter.all;
  bool mistakeMode = false;

  int currentAyahIdx = -1;
  bool playing = false;

  // Derived
  Reciter get currentReciter =>
      reciters.firstWhere((r) => r.id == reciterId, orElse: () => reciters[0]);
  Translation get currentTranslation => translations
      .firstWhere((t) => t.id == translationId, orElse: () => translations[0]);
  ArabicFont get currentFont =>
      fonts.firstWhere((f) => f.key == fontKey, orElse: () => fonts[0]);

  List<Surah> get filteredSurahs {
    final q = searchQuery.trim().toLowerCase();
    return surahs.where((s) {
      if (filter == SurahFilter.meccan && s.revelationType != 'Meccan') {
        return false;
      }
      if (filter == SurahFilter.medinan && s.revelationType != 'Medinan') {
        return false;
      }
      if (filter == SurahFilter.bookmarks) {
        final has = bookmarks.any((b) => b.surah == s.number);
        if (!has) return false;
      }
      if (q.isEmpty) return true;
      return s.englishName.toLowerCase().contains(q) ||
          s.englishNameTranslation.toLowerCase().contains(q) ||
          s.name.contains(q) ||
          s.number.toString() == q;
    }).toList();
  }

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
      final futures = <Future>[
        api.getSurah(number, 'quran-uthmani'),
      ];
      if (translationId != 'none') {
        futures.add(api.getSurah(number, translationId));
      }
      final results = await Future.wait(futures);
      arabic = results[0] as SurahDetail;
      translation = results.length > 1 ? results[1] as SurahDetail : null;
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

  Future<void> setTranslation(String id) async {
    translationId = id;
    await _prefs.setString('translation', id);
    notifyListeners();
    if (arabic != null) {
      await loadSurah(arabic!.number);
    }
  }

  Future<void> setFont(String key) async {
    fontKey = key;
    await _prefs.setString('arFont', key);
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

  void setSearch(String q) {
    searchQuery = q;
    notifyListeners();
  }

  void setFilter(SurahFilter f) {
    filter = f;
    notifyListeners();
  }

  void toggleMistakeMode() {
    mistakeMode = !mistakeMode;
    notifyListeners();
  }

  // Bookmarks
  bool isBookmarked(int surah, int ayah) =>
      bookmarks.any((b) => b.surah == surah && b.ayah == ayah);

  Future<void> toggleBookmark(int surah, int ayah) async {
    final i =
        bookmarks.indexWhere((b) => b.surah == surah && b.ayah == ayah);
    if (i >= 0) {
      bookmarks.removeAt(i);
    } else {
      bookmarks.add(AyahRef(surah, ayah));
    }
    await _prefs.setJsonList(
      'bookmarks',
      bookmarks.map((b) => b.toJson()).toList(),
    );
    notifyListeners();
  }

  // Mistakes
  bool isMistake(int surah, int ayah) =>
      mistakes.any((m) => m.surah == surah && m.ayah == ayah);

  Future<void> toggleMistake(int surah, int ayah) async {
    final i = mistakes.indexWhere((m) => m.surah == surah && m.ayah == ayah);
    if (i >= 0) {
      mistakes.removeAt(i);
    } else {
      mistakes.add(AyahRef(surah, ayah));
    }
    await _prefs.setJsonList(
      'mistakes',
      mistakes.map((m) => m.toJson()).toList(),
    );
    notifyListeners();
  }

  // Saved surahs
  bool isSurahSaved(int number) => savedSurahs.contains(number);

  Future<void> toggleSavedSurah(int number) async {
    if (savedSurahs.contains(number)) {
      savedSurahs.remove(number);
    } else {
      savedSurahs.add(number);
    }
    await _prefs.setIntList('savedSurahs', savedSurahs);
    notifyListeners();
  }

  // Playback state (set from PlayerController)
  void setPlaybackState({required int ayahIdx, required bool playing}) {
    currentAyahIdx = ayahIdx;
    this.playing = playing;
    notifyListeners();
  }
}
