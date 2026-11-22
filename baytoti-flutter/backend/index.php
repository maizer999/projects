<?php
// Baytoti API — single-file router, PHP 8.1+, PDO/MySQL.
// Deployed at /var/www/baytoti-api/index.php, served by Nginx at api.mazier.website.
// Config lives next to this file in config.php (gitignored).

declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

set_exception_handler(function (Throwable $e) {
    error_log('[baytoti-api] ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(['error' => 'server_error', 'message' => $e->getMessage()]);
});

require __DIR__ . '/config.php';

function db(): PDO {
    static $pdo = null;
    if ($pdo !== null) return $pdo;
    $pdo = new PDO(
        'mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4',
        DB_USER,
        DB_PASS,
        [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
        ]
    );
    return $pdo;
}

function body(): array {
    $raw = file_get_contents('php://input') ?: '';
    if ($raw === '') return [];
    $json = json_decode($raw, true);
    if (!is_array($json)) bad('invalid JSON body');
    return $json;
}

function send(int $status, $payload = null): void {
    http_response_code($status);
    if ($payload !== null) echo json_encode($payload, JSON_UNESCAPED_UNICODE);
    exit;
}

function bad(string $message): void {
    send(400, ['error' => 'bad_request', 'message' => $message]);
}

function notFound(): void {
    send(404, ['error' => 'not_found']);
}

function iso(string $sqlDatetime): string {
    return gmdate('Y-m-d\TH:i:s\Z', strtotime($sqlDatetime . ' UTC'));
}

function fromIso(?string $s): string {
    if (!$s) return gmdate('Y-m-d H:i:s');
    $ts = strtotime($s);
    if ($ts === false) bad('invalid datetime: ' . $s);
    return gmdate('Y-m-d H:i:s', $ts);
}

function genId(int $len): string {
    $chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    $out = '';
    for ($i = 0; $i < $len; $i++) $out .= $chars[random_int(0, strlen($chars) - 1)];
    return $out;
}

function genInviteCode(): string {
    $chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    $out = '';
    for ($i = 0; $i < 6; $i++) $out .= $chars[random_int(0, strlen($chars) - 1)];
    return $out;
}

// --- Router ---
$method = $_SERVER['REQUEST_METHOD'];
$path   = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH) ?: '/';
// Strip /api prefix if present (lets us mount under either api.mazier.website or mazier.website/api/).
$path = preg_replace('#^/api#', '', $path) ?: '/';
$path = rtrim($path, '/') ?: '/';
$seg  = $path === '/' ? [] : explode('/', ltrim($path, '/'));

try {
    match (true) {
        // GET /health
        $method === 'GET' && $path === '/health'
            => send(200, ['ok' => true, 'time' => gmdate('Y-m-d\TH:i:s\Z')]),

        // POST /lists
        $method === 'POST' && $path === '/lists'
            => createList(body()),

        // GET /lists/{id}
        $method === 'GET' && count($seg) === 2 && $seg[0] === 'lists'
            => getList($seg[1]),

        // PUT /lists/{id}
        $method === 'PUT' && count($seg) === 2 && $seg[0] === 'lists'
            => renameList($seg[1], body()),

        // GET /lists/by-invite/{code}
        $method === 'GET' && count($seg) === 3 && $seg[0] === 'lists' && $seg[1] === 'by-invite'
            => getListByInvite($seg[2]),

        // POST /lists/{id}/join
        $method === 'POST' && count($seg) === 3 && $seg[0] === 'lists' && $seg[2] === 'join'
            => joinList($seg[1], body()),

        // DELETE /lists/{id}/members/{name}
        $method === 'DELETE' && count($seg) === 4 && $seg[0] === 'lists' && $seg[2] === 'members'
            => removeMember($seg[1], urldecode($seg[3])),

        // GET /lists/{id}/purchases
        $method === 'GET' && count($seg) === 3 && $seg[0] === 'lists' && $seg[2] === 'purchases'
            => listPurchases($seg[1], ($_GET['includeArchived'] ?? '0') === '1'),

        // POST /lists/{id}/purchases
        $method === 'POST' && count($seg) === 3 && $seg[0] === 'lists' && $seg[2] === 'purchases'
            => addPurchase($seg[1], body()),

        // POST /lists/{id}/purchases/archive-older
        $method === 'POST' && count($seg) === 4 && $seg[0] === 'lists' && $seg[2] === 'purchases' && $seg[3] === 'archive-older'
            => archiveOlder($seg[1], body()),

        // PUT /lists/{id}/purchases/{itemId}
        $method === 'PUT' && count($seg) === 4 && $seg[0] === 'lists' && $seg[2] === 'purchases'
            => updatePurchase($seg[1], $seg[3], body()),

        // DELETE /lists/{id}/purchases/{itemId}
        $method === 'DELETE' && count($seg) === 4 && $seg[0] === 'lists' && $seg[2] === 'purchases'
            => deletePurchase($seg[1], $seg[3]),

        // GET /lists/{id}/stats
        $method === 'GET' && count($seg) === 3 && $seg[0] === 'lists' && $seg[2] === 'stats'
            => listStats($seg[1], (int)($_GET['limit'] ?? 10)),

        // GET /lists/{id}/wishes
        $method === 'GET' && count($seg) === 3 && $seg[0] === 'lists' && $seg[2] === 'wishes'
            => listWishes($seg[1]),

        // POST /lists/{id}/wishes
        $method === 'POST' && count($seg) === 3 && $seg[0] === 'lists' && $seg[2] === 'wishes'
            => addWish($seg[1], body()),

        // DELETE /lists/{id}/wishes/{wishId}
        $method === 'DELETE' && count($seg) === 4 && $seg[0] === 'lists' && $seg[2] === 'wishes'
            => deleteWish($seg[1], $seg[3]),

        default => notFound(),
    };
} catch (PDOException $e) {
    throw new RuntimeException('database: ' . $e->getMessage(), 0, $e);
}

// --- Handlers ---

function createList(array $b): void {
    $name = trim((string)($b['name'] ?? 'بيت العائلة'));
    $owner = trim((string)($b['ownerName'] ?? ''));
    if ($name === '') bad('name required');

    $id         = genId(10);
    $inviteCode = genInviteCode();
    $createdAt  = gmdate('Y-m-d H:i:s');

    db()->prepare(
        'INSERT INTO lists (id, name, invite_code, owner_name, created_at)
         VALUES (?, ?, ?, ?, ?)'
    )->execute([$id, $name, $inviteCode, $owner ?: null, $createdAt]);

    if ($owner !== '') {
        db()->prepare('INSERT INTO members (list_id, name, joined_at) VALUES (?, ?, ?)')
            ->execute([$id, $owner, $createdAt]);
    }

    send(201, hydrateList($id));
}

function getList(string $id): void {
    $row = hydrateList($id);
    if ($row === null) notFound();
    send(200, $row);
}

function renameList(string $id, array $b): void {
    $name = trim((string)($b['name'] ?? ''));
    if ($name === '') bad('name required');
    $stmt = db()->prepare('UPDATE lists SET name = ? WHERE id = ?');
    $stmt->execute([$name, $id]);
    if ($stmt->rowCount() === 0 && !listExists($id)) notFound();
    send(200, hydrateList($id));
}

function getListByInvite(string $code): void {
    $code = strtoupper(trim($code));
    $stmt = db()->prepare('SELECT id FROM lists WHERE invite_code = ?');
    $stmt->execute([$code]);
    $id = $stmt->fetchColumn();
    if (!$id) notFound();
    send(200, hydrateList((string)$id));
}

function joinList(string $id, array $b): void {
    $name = trim((string)($b['name'] ?? ''));
    if ($name === '') bad('name required');
    if (!listExists($id)) notFound();

    db()->prepare(
        'INSERT IGNORE INTO members (list_id, name, joined_at) VALUES (?, ?, ?)'
    )->execute([$id, $name, gmdate('Y-m-d H:i:s')]);

    send(200, hydrateList($id));
}

function removeMember(string $id, string $name): void {
    $stmt = db()->prepare('DELETE FROM members WHERE list_id = ? AND name = ?');
    $stmt->execute([$id, $name]);
    send(204);
}

function listPurchases(string $id, bool $includeArchived): void {
    if (!listExists($id)) notFound();
    $sql = 'SELECT * FROM purchases WHERE list_id = ?';
    $args = [$id];
    if (!$includeArchived) { $sql .= ' AND archived = 0'; }
    $sql .= ' ORDER BY date DESC';
    $stmt = db()->prepare($sql);
    $stmt->execute($args);
    $out = array_map('purchaseRow', $stmt->fetchAll());
    send(200, $out);
}

function addPurchase(string $id, array $b): void {
    if (!listExists($id)) notFound();
    $itemId = (string)($b['id'] ?? genId(20));
    $name   = trim((string)($b['itemName'] ?? ''));
    if ($name === '') bad('itemName required');

    $cat = (string)($b['category'] ?? 'other');
    if (!in_array($cat, ['food', 'cleaning', 'other'], true)) $cat = 'other';

    $now = gmdate('Y-m-d H:i:s');
    db()->prepare(
        'INSERT INTO purchases
         (id, list_id, item_name, price, category, added_by_name, note, archived, date, updated_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)'
    )->execute([
        $itemId, $id, $name,
        isset($b['price']) && $b['price'] !== null ? (float)$b['price'] : null,
        $cat,
        (string)($b['addedByName'] ?? 'ضيف'),
        isset($b['note']) && $b['note'] !== '' ? (string)$b['note'] : null,
        !empty($b['archived']) ? 1 : 0,
        fromIso($b['date'] ?? null),
        $now,
    ]);

    bumpStat($id, $name);
    send(201, fetchPurchase($itemId));
}

function updatePurchase(string $listId, string $itemId, array $b): void {
    $fields = [];
    $args   = [];
    foreach (
        [
            'itemName'      => 'item_name',
            'price'         => 'price',
            'category'      => 'category',
            'addedByName'   => 'added_by_name',
            'note'          => 'note',
            'archived'      => 'archived',
            'date'          => 'date',
        ] as $json => $col
    ) {
        if (!array_key_exists($json, $b)) continue;
        $v = $b[$json];
        if ($col === 'date')     $v = fromIso((string)$v);
        if ($col === 'archived') $v = $v ? 1 : 0;
        if ($col === 'category' && !in_array($v, ['food','cleaning','other'], true)) continue;
        if ($col === 'price' && $v !== null) $v = (float)$v;
        if ($col === 'note' && $v === '') $v = null;
        $fields[] = "$col = ?";
        $args[]   = $v;
    }
    if (!$fields) bad('no updatable fields');
    $fields[] = 'updated_at = ?';
    $args[]   = gmdate('Y-m-d H:i:s');
    $args[]   = $listId;
    $args[]   = $itemId;

    $stmt = db()->prepare(
        'UPDATE purchases SET ' . implode(', ', $fields) .
        ' WHERE list_id = ? AND id = ?'
    );
    $stmt->execute($args);
    if ($stmt->rowCount() === 0 && !purchaseExists($listId, $itemId)) notFound();

    send(200, fetchPurchase($itemId));
}

function deletePurchase(string $listId, string $itemId): void {
    $stmt = db()->prepare('DELETE FROM purchases WHERE list_id = ? AND id = ?');
    $stmt->execute([$listId, $itemId]);
    send(204);
}

function archiveOlder(string $listId, array $b): void {
    $cutoff = fromIso($b['cutoff'] ?? null);
    $stmt = db()->prepare(
        'UPDATE purchases SET archived = 1, updated_at = ?
         WHERE list_id = ? AND archived = 0 AND date < ?'
    );
    $stmt->execute([gmdate('Y-m-d H:i:s'), $listId, $cutoff]);
    send(200, ['archived' => $stmt->rowCount()]);
}

function listWishes(string $listId): void {
    if (!listExists($listId)) notFound();
    $stmt = db()->prepare(
        'SELECT * FROM wishes WHERE list_id = ? ORDER BY created_at DESC'
    );
    $stmt->execute([$listId]);
    send(200, array_map('wishRow', $stmt->fetchAll()));
}

function addWish(string $listId, array $b): void {
    if (!listExists($listId)) notFound();
    $itemId = (string)($b['id'] ?? genId(20));
    $name   = trim((string)($b['itemName'] ?? ''));
    if ($name === '') bad('itemName required');

    db()->prepare(
        'INSERT INTO wishes (id, list_id, item_name, added_by_name, created_at)
         VALUES (?, ?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE
            item_name     = VALUES(item_name),
            added_by_name = VALUES(added_by_name),
            created_at    = VALUES(created_at)'
    )->execute([
        $itemId,
        $listId,
        $name,
        (string)($b['addedByName'] ?? 'ضيف'),
        fromIso($b['createdAt'] ?? null),
    ]);

    $stmt = db()->prepare('SELECT * FROM wishes WHERE id = ?');
    $stmt->execute([$itemId]);
    $row = $stmt->fetch();
    if (!$row) notFound();
    send(201, wishRow($row));
}

function deleteWish(string $listId, string $wishId): void {
    $stmt = db()->prepare('DELETE FROM wishes WHERE list_id = ? AND id = ?');
    $stmt->execute([$listId, $wishId]);
    send(204);
}

function wishRow(array $r): array {
    return [
        'id'          => $r['id'],
        'itemName'    => $r['item_name'],
        'addedByName' => $r['added_by_name'],
        'createdAt'   => iso($r['created_at']),
    ];
}

function listStats(string $id, int $limit): void {
    if (!listExists($id)) notFound();
    $limit = max(1, min($limit, 100));
    $stmt = db()->prepare(
        'SELECT normalized AS id, name, count, last_used
         FROM product_stats WHERE list_id = ?
         ORDER BY count DESC LIMIT ' . $limit
    );
    $stmt->execute([$id]);
    $out = array_map(function (array $r): array {
        return [
            'id'       => $r['id'],
            'name'     => $r['name'],
            'count'    => (int)$r['count'],
            'lastUsed' => iso($r['last_used']),
        ];
    }, $stmt->fetchAll());
    send(200, $out);
}

// --- Helpers ---

function listExists(string $id): bool {
    $stmt = db()->prepare('SELECT 1 FROM lists WHERE id = ?');
    $stmt->execute([$id]);
    return (bool)$stmt->fetchColumn();
}

function purchaseExists(string $listId, string $itemId): bool {
    $stmt = db()->prepare('SELECT 1 FROM purchases WHERE list_id = ? AND id = ?');
    $stmt->execute([$listId, $itemId]);
    return (bool)$stmt->fetchColumn();
}

function hydrateList(string $id): ?array {
    $stmt = db()->prepare('SELECT * FROM lists WHERE id = ?');
    $stmt->execute([$id]);
    $row = $stmt->fetch();
    if (!$row) return null;
    $m = db()->prepare('SELECT name FROM members WHERE list_id = ? ORDER BY joined_at');
    $m->execute([$id]);
    return [
        'id'         => $row['id'],
        'name'       => $row['name'],
        'inviteCode' => $row['invite_code'],
        'ownerName'  => $row['owner_name'],
        'createdAt'  => iso($row['created_at']),
        'members'    => array_column($m->fetchAll(), 'name'),
    ];
}

function fetchPurchase(string $itemId): array {
    $stmt = db()->prepare('SELECT * FROM purchases WHERE id = ?');
    $stmt->execute([$itemId]);
    $row = $stmt->fetch();
    if (!$row) notFound();
    return purchaseRow($row);
}

function purchaseRow(array $r): array {
    return [
        'id'          => $r['id'],
        'itemName'    => $r['item_name'],
        'price'       => $r['price'] === null ? null : (float)$r['price'],
        'category'    => $r['category'],
        'addedByName' => $r['added_by_name'],
        'note'        => $r['note'],
        'archived'    => (bool)$r['archived'],
        'date'        => iso($r['date']),
    ];
}

function bumpStat(string $listId, string $itemName): void {
    $key = mb_strtolower(trim($itemName));
    if ($key === '') return;
    // Arabic normalization: strip tashkeel, unify alif / yaa / taa marbuta.
    $key = preg_replace('/[\x{0610}-\x{061A}\x{064B}-\x{065F}\x{0670}]/u', '', $key);
    $key = strtr($key, ['أ' => 'ا', 'إ' => 'ا', 'آ' => 'ا', 'ى' => 'ي', 'ة' => 'ه']);
    $key = mb_substr($key, 0, 200);

    db()->prepare(
        'INSERT INTO product_stats (list_id, normalized, name, count, last_used)
         VALUES (?, ?, ?, 1, ?)
         ON DUPLICATE KEY UPDATE count = count + 1, last_used = VALUES(last_used), name = VALUES(name)'
    )->execute([$listId, $key, $itemName, gmdate('Y-m-d H:i:s')]);
}
