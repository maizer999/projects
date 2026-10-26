<?php
/**
 * API لحفظ وقراءة بيانات "حاسبة رحلة الشباب" (trip.html)
 * يخزّن البيانات بملف trip_data.json بجانب هذا الملف.
 * ارفعه بنفس فولدر trip.html.
 *
 * مهم: عشان محدا يقدر يفتح ملف البيانات مباشرة من المتصفح،
 * أضف هذا السطر لملف .htaccess بنفس الفولدر:
 *   <FilesMatch "^(trip_data|expenses_data)\.json(\.bak)?$">
 *     Require all denied
 *   </FilesMatch>
 */

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');

$dataFile = __DIR__ . '/trip_data.json';
$secret   = '79347f421ecfbbd7e9fbf415'; // لازم يطابق APP_SECRET في trip.html

$provided = $_SERVER['HTTP_X_APP_SECRET'] ?? ($_GET['secret'] ?? '');
if (!hash_equals($secret, (string) $provided)) {
    http_response_code(403);
    echo json_encode(['error' => 'unauthorized']);
    exit;
}

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    echo file_exists($dataFile) ? file_get_contents($dataFile) : json_encode(new stdClass());
    exit;
}

if ($method === 'POST') {
    $body = json_decode(file_get_contents('php://input'), true);
    $data = $body['data'] ?? null;
    $base = (int) ($body['base'] ?? 0);

    if (!is_array($data) || !isset($data['people'], $data['items']) || !is_array($data['people']) || !is_array($data['items'])) {
        http_response_code(400);
        echo json_encode(['error' => 'invalid json']);
        exit;
    }

    $fp = fopen($dataFile, 'c+');
    if (!$fp) {
        http_response_code(500);
        echo json_encode(['error' => 'could not open file, check folder permissions']);
        exit;
    }
    flock($fp, LOCK_EX);

    $currentRaw = stream_get_contents($fp);
    $current = $currentRaw ? json_decode($currentRaw, true) : null;
    $currentVer = (int) ($current['updatedAt'] ?? 0);

    // لو حدا ثاني حفظ بعد آخر مرة حمّلنا فيها، نرجّع نسخته بدل ما نمسحها
    if ($current && $currentVer !== 0 && $base !== $currentVer) {
        flock($fp, LOCK_UN);
        fclose($fp);
        http_response_code(409);
        echo json_encode(['error' => 'conflict', 'data' => $current], JSON_UNESCAPED_UNICODE);
        exit;
    }

    if ($currentRaw) {
        @file_put_contents($dataFile . '.bak', $currentRaw);
    }

    $data['updatedAt'] = (int) round(microtime(true) * 1000);
    $json = json_encode($data, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);

    ftruncate($fp, 0);
    rewind($fp);
    fwrite($fp, $json);
    fflush($fp);
    flock($fp, LOCK_UN);
    fclose($fp);

    echo json_encode(['success' => true, 'updatedAt' => $data['updatedAt']]);
    exit;
}

http_response_code(405);
echo json_encode(['error' => 'method not allowed']);
