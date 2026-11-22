import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/data/datasources/reciters_data.dart';
import 'package:quran_app/data/repositories/audio_repository_impl.dart';

void main() {
  test('every reciter uses a bitrate the CDN serves', () {
    const served = {192, 128, 64, 48, 40, 32};
    for (final r in recitersData) {
      expect(served, contains(r.bitrate), reason: r.id);
    }
  });

  test('audio URL uses the reciter\'s own bitrate', () {
    final sudais = recitersData.firstWhere((r) => r.id == 'ar.abdurrahmaansudais');
    expect(
      AudioRepositoryImpl.ayahUrl(sudais, 8),
      'https://cdn.islamic.network/quran/audio/64/ar.abdurrahmaansudais/8.mp3',
    );
  });

  test('reciter ids are unique', () {
    final ids = recitersData.map((r) => r.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });
}
