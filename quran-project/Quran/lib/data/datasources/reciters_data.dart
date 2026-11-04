import '../../domain/entities/reciter.dart';

/// Reciters on the audio CDN (ApiConstants.audioCdnBase) with the quality
/// that exists for each. Verified against the CDN on 2026-11-04 by
/// requesting ayah 1, 255 and 6236 in every quality (192/128/64/48/40/32):
/// 128 kbps is used where it exists, otherwise 64, otherwise the only one.
const List<Reciter> recitersData = [
  Reciter('ar.alafasy', 'مشاري راشد العفاسي', 128),
  Reciter('ar.husary', 'محمود خليل الحصري', 128),
  Reciter('ar.husarymujawwad', 'محمود خليل الحصري (مجوّد)', 128),
  Reciter('ar.minshawi', 'محمد صديق المنشاوي', 128),
  Reciter('ar.minshawimujawwad', 'محمد صديق المنشاوي (مجوّد)', 64),
  Reciter('ar.abdulbasitmurattal', 'عبد الباسط عبد الصمد (مرتل)', 64),
  Reciter('ar.abdulsamad', 'عبد الباسط عبد الصمد (مجوّد)', 64),
  Reciter('ar.hudhaify', 'علي بن عبد الرحمن الحذيفي', 128),
  Reciter('ar.saoodshuraym', 'سعود الشريم', 64),
  Reciter('ar.abdurrahmaansudais', 'عبد الرحمن السديس', 64),
  Reciter('ar.mahermuaiqly', 'ماهر المعيقلي', 128),
  Reciter('ar.shaatree', 'أبو بكر الشاطري', 128),
  Reciter('ar.ahmedajamy', 'أحمد بن علي العجمي', 128),
  Reciter('ar.hanirifai', 'هاني الرفاعي', 64),
  Reciter('ar.muhammadayyoub', 'محمد أيوب', 128),
  Reciter('ar.muhammadjibreel', 'محمد جبريل', 128),
  Reciter('ar.abdullahbasfar', 'عبد الله بصفر', 64),
  Reciter('ar.ibrahimakhbar', 'إبراهيم الأخضر', 32),
  Reciter('ar.aymanswoaid', 'أيمن سويد', 64),
  Reciter('ar.parhizgar', 'شهريار پرهيزگار', 48),
];
