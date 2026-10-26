<?php
/**
 * update.php — بيسحب شيت جوجل، بينضّف البيانات، وبيكتب doctors.json جنبه.
 *
 * التشغيل:
 *   - من كرون:   php /home/USER/public_html/mednet/update.php
 *   - من المتصفح: https://example.com/mednet/update.php?key=SECRET
 *
 * الشيت لازم يكون: Share ← Anyone with the link ← Viewer
 */

// ————— الإعدادات —————
const SHEET_ID = '1quHK22ckCGiG5uYGWk6euius14AbOy_xeeE0zJVH6xQ';
const GID      = '';          // معرّف التبويب، اتركه فاضي للتبويب الأول
const SECRET   = 'change-me'; // غيّره، لازم يطابق ?key= بالرابط
const OUT_FILE = __DIR__ . '/doctors.json';
const LOG_FILE = __DIR__ . '/update.log';

$cli = (php_sapi_name() === 'cli');
if (!$cli && (($_GET['key'] ?? '') !== SECRET)) {
    http_response_code(403);
    exit('forbidden');
}

// مفاتيح المحافظات للأرقام الأرضية
const AREA_CODE = [
    'عمّان' => '06', 'عمان' => '06',
    'الزرقاء' => '05', 'البلقاء' => '05', 'مادبا' => '05',
    'إربد' => '02', 'اربد' => '02', 'المفرق' => '02', 'جرش' => '02', 'عجلون' => '02',
    'الكرك' => '03', 'الطفيلة' => '03', 'معان' => '03', 'العقبة' => '03',
];

const HEADERS = [
    'اسم مقدم الخدمة' => 'name', 'إسم مقدم الخدمة' => 'name', 'name' => 'name',
    'الطبيب' => 'doctor', 'doctor' => 'doctor',
    'النوع' => 'type', 'type' => 'type',
    'الاختصاص' => 'specialty', 'specialty' => 'specialty',
    'المحافظة' => 'city', 'city' => 'city',
    'المنطقة' => 'area', 'area' => 'area',
    'العنوان' => 'address', 'address' => 'address',
    'رقم الهاتف' => 'phone', 'phone' => 'phone',
    'رقم الاتصال الدولي' => 'phone_dial', 'phone_dial' => 'phone_dial',
    'الشبكة' => 'network', 'network' => 'network',
    'صفحة الدليل' => 'source_page', 'source_page' => 'source_page',
    'ملاحظات' => 'notes', 'notes' => 'notes',
];

function logline(string $msg): void {
    file_put_contents(LOG_FILE, date('Y-m-d H:i:s') . "  $msg\n", FILE_APPEND);
}

function fail(string $msg): void {
    logline("خطأ: $msg");
    http_response_code(500);
    exit("فشل: $msg\n");
}

// ————— تحميل الشيت —————
$url = 'https://docs.google.com/spreadsheets/d/' . SHEET_ID . '/export?format=csv';
if (GID !== '') $url .= '&gid=' . GID;

$ch = curl_init($url);
curl_setopt_array($ch, [
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_FOLLOWLOCATION => true,
    CURLOPT_TIMEOUT        => 60,
    CURLOPT_USERAGENT      => 'mednet-updater/1.0',
]);
$csv  = curl_exec($ch);
$code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($csv === false || $code !== 200) fail("تعذّر تحميل الشيت (HTTP $code)");
if (stripos(ltrim($csv), '<!doctype html') === 0) fail('الشيت مش مشارك للعامة');

// ————— قراءة الصفوف —————
$fh = fopen('php://memory', 'r+');
fwrite($fh, $csv);
rewind($fh);

$head = fgetcsv($fh);
if (!$head) fail('الشيت فاضي');
$head[0] = preg_replace('/^\xEF\xBB\xBF/', '', $head[0]);   // BOM
$map = [];
foreach ($head as $i => $h) {
    $key = HEADERS[trim($h)] ?? null;
    if ($key) $map[$i] = $key;
}
if (!in_array('name', $map, true)) fail('ما لقيت عمود اسم مقدم الخدمة');

$rows = [];
while (($cells = fgetcsv($fh)) !== false) {
    $row = [];
    foreach ($map as $i => $key) $row[$key] = trim($cells[$i] ?? '');
    if (($row['name'] ?? '') !== '') $rows[] = $row;
}
fclose($fh);

// ————— التنظيف —————
$clean = [];
$seen  = [];
$dups  = 0;

foreach ($rows as $r) {
    $city = $r['city'] ?? '';
    if ($city === 'عمان') $city = 'عمّان';

    $digits = preg_replace('/\D/', '', $r['phone'] ?? '');
    $note   = $r['notes'] ?? '';

    if ($digits === '') {
        $phone = '';
    } elseif (strlen($digits) === 9 && $digits[0] === '7') {
        $phone = '0' . $digits;                       // موبايل ضايع منه الصفر
    } elseif (strlen($digits) === 10 && substr($digits, 0, 2) === '07') {
        $phone = $digits;
    } elseif (strlen($digits) === 7) {
        $phone = (AREA_CODE[$city] ?? '06') . $digits; // أرضي بدون مفتاح
    } elseif (strlen($digits) === 8 && $digits[0] === '6') {
        $phone = '0' . $digits;                        // أرضي ضايع منه الصفر
    } elseif (strlen($digits) === 9 && $digits[0] === '0') {
        $phone = $digits;
    } else {
        $phone = $digits;
        $note  = trim($note . ' | ⚠ رقم غير صالح (' . strlen($digits) . ' خانة)', ' |');
    }

    $dial = '';
    if ($phone !== '' && $phone[0] === '0' && in_array(strlen($phone), [9, 10], true)) {
        $dial = '+962' . substr($phone, 1);
    }

    $type = $r['type'] ?? '';
    if (!in_array($type, ['طبيب', 'عيادة/مركز', 'doctor', 'clinic'], true)) {
        $type = preg_match('/عياد|مركز|مجمع|كلينك/u', $r['name']) ? 'clinic' : 'doctor';
    }
    $type = ['طبيب' => 'doctor', 'عيادة/مركز' => 'clinic'][$type] ?? $type;

    $area    = $r['area'] ?? '';
    $address = ($r['address'] ?? '') !== '' ? $r['address'] : $area;

    $key = $r['name'] . '|' . preg_replace('/\D/', '', $phone) . '|' . $address;
    if (isset($seen[$key])) { $dups++; continue; }
    $seen[$key] = true;

    $clean[] = [
        'id'          => count($clean) + 1,
        'name'        => $r['name'],
        'doctor'      => $r['doctor'] ?? '',
        'type'        => $type,
        'specialty'   => $r['specialty'] ?? '',
        'city'        => $city,
        'area'        => $area,
        'address'     => $address,
        'phone'       => $phone,
        'phone_dial'  => ($r['phone_dial'] ?? '') !== '' ? $r['phone_dial'] : $dial,
        'network'     => ($r['network'] ?? '') !== '' ? $r['network'] : 'MedNet',
        'source_page' => $r['source_page'] ?? '',
        'notes'       => $note,
    ];
}

if (count($clean) < 50) fail('عدد الصفوف قليل (' . count($clean) . ') — ما رح أستبدل الملف الحالي');

// ————— الإخراج —————
$cityCount = [];
$specs = [];
$areas = [];
foreach ($clean as $r) {
    if ($r['city'])      $cityCount[$r['city']] = ($cityCount[$r['city']] ?? 0) + 1;
    if ($r['specialty']) $specs[$r['specialty']] = true;
    if ($r['area'])      $areas[$r['area']] = true;
}
uksort($cityCount, function ($a, $b) use ($cityCount) {
    if ($a === 'عمّان') return -1;
    if ($b === 'عمّان') return 1;
    return $cityCount[$b] <=> $cityCount[$a];
});

$out = [
    'meta' => [
        'source'      => 'شيت جوجل — دليل شبكة MedNet',
        'updated'     => date('c'),
        'count'       => count($clean),
        'specialties' => array_keys($specs),
        'cities'      => array_keys($cityCount),
        'areas'       => array_keys($areas),
    ],
    'providers' => $clean,
];

$tmp = OUT_FILE . '.tmp';
file_put_contents($tmp, json_encode($out, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT));
rename($tmp, OUT_FILE);   // استبدال ذرّي، الزوار ما بيشوفوا ملف نص جاهز

$msg = 'تم التحديث: ' . count($clean) . ' مقدم خدمة، وانحذف ' . $dups . ' مكرر';
logline($msg);
echo $msg . "\n";
