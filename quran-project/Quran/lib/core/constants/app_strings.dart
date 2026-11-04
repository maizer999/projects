/// User-facing Arabic text, in one place.
class AppStrings {
  AppStrings._();

  // ---- General ----
  static const String appSubtitle = 'القرآن الكريم · الأجزاء الثلاثون';
  static const String retry = 'إعادة المحاولة';
  static const String cancel = 'إلغاء';
  static const String noResults = 'لا توجد نتائج.';
  static const String searchHint = 'ابحث عن سورة...';
  static String juzTitle(String n) => 'الجزء $n';
  static String pageLabel(String n) => 'صفحة $n';

  // ---- Reader modes ----
  static const String modeListen = 'استماع';
  static const String modeMemorize = 'تسميع';
  static const String listenHint = 'اضغط على أي آية لتسمعها من عندها';
  static const String memorizeHint = 'اضغط على الآية لتعليمها كخطأ، واضغط مرة ثانية لإلغائها';

  // ---- Mistakes ----
  static String resetMistakes(String n) => 'تصفير ($n)';
  static const String resetMistakesTitle = 'تصفير الأخطاء؟';
  static String resetMistakesBody(int n) => 'رح يتم حذف علامات الأخطاء الـ$n لهاي السورة.';
  static const String reset = 'تصفير';
  static const String markedAsMistake = 'تم تعليم الآية كخطأ';
  static const String unmarkedMistake = 'تم إلغاء علامة الخطأ';

  // ---- Settings ----
  static const String settingsTitle = 'إعدادات القراءة';
  static const String reciter = 'القارئ';
  static const String fontSize = 'حجم الخط';
  static const String arabicFont = 'نوع الخط';
  static const String appColor = 'لون التطبيق';
  static const String tajweed = 'ألوان التجويد';
  static const String tajweedSubtitle = 'تلوين أحكام التجويد في صفحة المصحف';
  static const String ornateFrame = 'إطار المصحف المزخرف';
  static const String ornateFrameSubtitle = 'إطار ذهبي مزخرف حول الصفحة، أو تصميم بسيط';

  // ---- Player ----
  static const String play = 'تشغيل';
  static const String pause = 'إيقاف مؤقت';
  static const String stop = 'إيقاف';
  static const String nowPlaying = 'يتم التشغيل';
  static const String previousAyah = 'الآية السابقة';
  static const String nextAyah = 'الآية التالية';
  static const String speed = 'السرعة';
  static const String hidePlayer = 'إخفاء المشغّل';
  static String ayahLabel(String n) => 'آية $n';

  // ---- Contact ----
  static const String contactUs = 'تواصل معنا';
  static const String contactIntroTitle = 'نسعد بسماع رأيك';
  static const String contactIntroBody = 'فريق الدعم جاهز لمساعدتك، اختر الطريقة الأنسب لك.';
  static const String email = 'البريد الإلكتروني';
  static const String phone = 'الهاتف';
  static const String whatsapp = 'واتساب';
  static const String whatsappSubtitle = 'راسلنا مباشرة';
  static const String copy = 'نسخ';
  static String copied(String what) => 'تم نسخ $what';
  static const String emailNoun = 'البريد';
  static const String phoneNoun = 'الرقم';
  static const String sendMessage = 'أرسل رسالة';
  static const String nameHint = 'اسمك (اختياري)';
  static const String messageHint = 'اكتب رسالتك أو اقتراحك هنا';
  static const String messageRequired = 'اكتب رسالتك أولاً';
  static const String send = 'إرسال';
  static const String cannotOpenApp = 'ما قدرنا نفتح التطبيق المناسب على جهازك';
}
