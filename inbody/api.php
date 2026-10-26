<?php
// api.php — يقرأ ويكتب ملف data.json بجانبه على نفس السيرفر
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

$file = __DIR__ . '/data.json';

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if (file_exists($file)) {
        echo file_get_contents($file);
    } else {
        echo '[]';
    }
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $input = file_get_contents('php://input');
    $decoded = json_decode($input, true);

    if (!is_array($decoded)) {
        http_response_code(400);
        echo json_encode(['error' => 'Invalid JSON body']);
        exit;
    }

    $ok = file_put_contents(
        $file,
        json_encode($decoded, JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT)
    );

    if ($ok === false) {
        http_response_code(500);
        echo json_encode(['error' => 'Could not write data.json — check folder write permissions (chmod 755 on the folder, 664 on data.json)']);
        exit;
    }

    echo json_encode(['status' => 'ok', 'count' => count($decoded)]);
    exit;
}

http_response_code(405);
echo json_encode(['error' => 'Method not allowed']);
