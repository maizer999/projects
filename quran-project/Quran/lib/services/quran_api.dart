import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/surah.dart';

class QuranApi {
  static const _base = 'https://api.alquran.cloud/v1';
  static const audioCdn = 'https://cdn.islamic.network/quran/audio/128';

  Future<List<Surah>> listSurahs() async {
    final r = await http.get(Uri.parse('$_base/surah'));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    final body = json.decode(r.body) as Map<String, dynamic>;
    final list = body['data'] as List;
    return list
        .map((e) => Surah.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SurahDetail> getSurah(int number, String edition) async {
    final r = await http.get(Uri.parse('$_base/surah/$number/$edition'));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    final body = json.decode(r.body) as Map<String, dynamic>;
    return SurahDetail.fromJson(body['data'] as Map<String, dynamic>);
  }

  Future<QuranPage> getPage(int page,
      {String edition = 'quran-uthmani'}) async {
    final r = await http.get(Uri.parse('$_base/page/$page/$edition'));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    final body = json.decode(r.body) as Map<String, dynamic>;
    return QuranPage.fromJson(body['data'] as Map<String, dynamic>);
  }

  static String ayahAudioUrl(String reciter, int globalAyahNumber) =>
      '$audioCdn/$reciter/$globalAyahNumber.mp3';
}
