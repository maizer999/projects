import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../ui/name_prompt.dart';
import 'models.dart';

/// HTTP-backed list repository against the Baytoti PHP API.
///
/// Realtime is simulated by polling (every [_pollInterval]) plus a per-list
/// "poke" stream that each mutation fires to force an immediate refresh on
/// any active watcher.
///
/// Wishlist is intentionally local-only (SharedPreferences) — same model as
/// the web version.
class ListRepository {
  ListRepository({
    http.Client? client,
    this.baseUrl = 'https://mazier.website/api',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  static const Duration _pollInterval = Duration(seconds: 4);

  // Mutation poke bus — one per listId.
  final Map<String, StreamController<void>> _pokes = {};
  // Local wishlist broadcast — one per listId.
  final Map<String, StreamController<List<WishItem>>> _wishBroadcasts = {};

  StreamController<void> _pokeFor(String listId) => _pokes.putIfAbsent(
        listId,
        () => StreamController<void>.broadcast(),
      );

  StreamController<List<WishItem>> _wishBroadcastFor(String listId) =>
      _wishBroadcasts.putIfAbsent(
        listId,
        () => StreamController<List<WishItem>>.broadcast(),
      );

  void _poke(String listId) {
    final c = _pokes[listId];
    if (c != null && !c.isClosed) c.add(null);
  }

  static String generateId([int length = 10]) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }

  static String generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  // ─── HTTP helpers ─────────────────────────────────────────────────────────

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  static const _jsonHeaders = {'Content-Type': 'application/json'};

  Future<Map<String, dynamic>?> _get(String path) async {
    final r = await _client.get(_u(path));
    if (r.statusCode == 404) return null;
    _ensureOk(r);
    return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
  }

  Future<List<dynamic>> _getArray(String path) async {
    final r = await _client.get(_u(path));
    _ensureOk(r);
    return jsonDecode(utf8.decode(r.bodyBytes)) as List<dynamic>;
  }

  Future<Map<String, dynamic>> _post(
      String path, Map<String, dynamic> body) async {
    final r = await _client.post(_u(path),
        headers: _jsonHeaders, body: jsonEncode(body));
    _ensureOk(r);
    if (r.bodyBytes.isEmpty) return const {};
    return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _put(
      String path, Map<String, dynamic> body) async {
    final r = await _client.put(_u(path),
        headers: _jsonHeaders, body: jsonEncode(body));
    _ensureOk(r);
    if (r.bodyBytes.isEmpty) return const {};
    return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
  }

  Future<void> _delete(String path) async {
    final r = await _client.delete(_u(path));
    _ensureOk(r);
  }

  void _ensureOk(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) return;
    throw ApiException(r.statusCode, utf8.decode(r.bodyBytes));
  }

  // ─── Lists ────────────────────────────────────────────────────────────────

  Future<ShoppingList> createList({String? name, String? ownerName}) async {
    final owner = ownerName ?? await DisplayName.get();
    final j = await _post('/lists', {
      if (name != null && name.isNotEmpty) 'name': name,
      'ownerName': owner,
    });
    return ShoppingList.fromJson(j);
  }

  Future<ShoppingList?> getList(String listId) async {
    final j = await _get('/lists/$listId');
    return j == null ? null : ShoppingList.fromJson(j);
  }

  /// Legacy convenience used by [LandingScreen] — tries to fetch, creates
  /// if missing. Note: the server generates its own id, so a newly-created
  /// list will not have [listId] as its id.
  Future<ShoppingList> getOrCreate(String listId, {String? defaultName}) async {
    final existing = await getList(listId);
    if (existing != null) return existing;
    return createList(name: defaultName);
  }

  Future<ShoppingList?> findByInviteCode(String code) async {
    final j = await _get('/lists/by-invite/${code.toUpperCase()}');
    return j == null ? null : ShoppingList.fromJson(j);
  }

  Future<ShoppingList?> joinViaCode(String code) async {
    final list = await findByInviteCode(code);
    if (list == null) return null;
    final name = await DisplayName.get();
    final j = await _post('/lists/${list.id}/join', {'name': name});
    _poke(list.id);
    return ShoppingList.fromJson(j);
  }

  Future<void> removeMember(String listId, String memberName) async {
    await _delete(
        '/lists/$listId/members/${Uri.encodeComponent(memberName)}');
    _poke(listId);
  }

  Future<void> renameList(String listId, String name) async {
    await _put('/lists/$listId', {'name': name});
    _poke(listId);
  }

  // ─── Polling watchers ─────────────────────────────────────────────────────

  Stream<T> _poll<T>(String listId, Future<T> Function() fetch) {
    late StreamController<T> ctl;
    Timer? timer;
    StreamSubscription<void>? pokeSub;
    var inflight = false;

    Future<void> tick() async {
      if (inflight || ctl.isClosed) return;
      inflight = true;
      try {
        final v = await fetch();
        if (!ctl.isClosed) ctl.add(v);
      } catch (e, s) {
        if (!ctl.isClosed) ctl.addError(e, s);
      } finally {
        inflight = false;
      }
    }

    ctl = StreamController<T>(
      onListen: () {
        tick();
        timer = Timer.periodic(_pollInterval, (_) => tick());
        pokeSub = _pokeFor(listId).stream.listen((_) => tick());
      },
      onCancel: () async {
        timer?.cancel();
        await pokeSub?.cancel();
      },
    );
    return ctl.stream;
  }

  Stream<ShoppingList?> watchList(String listId) {
    return _poll(listId, () => getList(listId));
  }

  Stream<List<Purchase>> watchPurchases(
    String listId, {
    bool includeArchived = false,
  }) {
    return _poll(listId, () async {
      final arr = await _getArray(
          '/lists/$listId/purchases${includeArchived ? '?includeArchived=1' : ''}');
      final items = arr
          .map((e) => Purchase.fromJson(e as Map<String, dynamic>))
          .toList();
      if (includeArchived) return items;
      return items.where((p) => !p.archived).toList();
    });
  }

  Stream<List<Purchase>> watchArchive(String listId) {
    return _poll(listId, () async {
      final arr =
          await _getArray('/lists/$listId/purchases?includeArchived=1');
      return arr
          .map((e) => Purchase.fromJson(e as Map<String, dynamic>))
          .where((p) => p.archived)
          .toList();
    });
  }

  Stream<List<ProductStat>> watchTopStats(String listId, {int limit = 10}) {
    return _poll(listId, () async {
      final arr = await _getArray('/lists/$listId/stats?limit=$limit');
      return arr
          .map((e) => ProductStat.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  // ─── Purchases ────────────────────────────────────────────────────────────

  Future<void> addPurchase(String listId, Purchase p) async {
    await _post('/lists/$listId/purchases', p.toJson());
    _poke(listId);
  }

  Future<void> updatePurchase(String listId, Purchase p) async {
    await _put('/lists/$listId/purchases/${p.id}', p.toJson());
    _poke(listId);
  }

  Future<void> archivePurchase(String listId, String id, bool archived) async {
    await _put('/lists/$listId/purchases/$id', {'archived': archived});
    _poke(listId);
  }

  Future<void> archiveOlderThan(String listId, DateTime cutoff) async {
    await _post('/lists/$listId/purchases/archive-older', {
      'cutoff': cutoff.toUtc().toIso8601String(),
    });
    _poke(listId);
  }

  Future<void> deletePurchase(String listId, String id) async {
    await _delete('/lists/$listId/purchases/$id');
    _poke(listId);
  }

  // ─── Wishlist (local, SharedPreferences) ──────────────────────────────────

  String _wishKey(String listId) => 'bayti_wishlist_$listId';

  Future<List<WishItem>> _loadWish(String listId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_wishKey(listId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final arr = jsonDecode(raw) as List<dynamic>;
      return arr
          .map((e) => WishItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveWish(String listId, List<WishItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _wishKey(listId),
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
    final b = _wishBroadcasts[listId];
    if (b != null && !b.isClosed) b.add(items);
  }

  Stream<List<WishItem>> watchWishlist(String listId) {
    late StreamController<List<WishItem>> out;
    StreamSubscription<List<WishItem>>? sub;
    out = StreamController<List<WishItem>>(
      onListen: () async {
        try {
          out.add(await _loadWish(listId));
        } catch (e, s) {
          if (!out.isClosed) out.addError(e, s);
        }
        sub = _wishBroadcastFor(listId).stream.listen((v) {
          if (!out.isClosed) out.add(v);
        });
      },
      onCancel: () async => sub?.cancel(),
    );
    return out.stream;
  }

  Future<void> addWish(String listId, WishItem w) async {
    final items = await _loadWish(listId);
    items.removeWhere((e) => e.id == w.id);
    items.insert(0, w);
    await _saveWish(listId, items);
  }

  Future<void> deleteWish(String listId, String id) async {
    final items = await _loadWish(listId);
    items.removeWhere((e) => e.id == id);
    await _saveWish(listId, items);
  }
}

class ApiException implements Exception {
  ApiException(this.statusCode, this.body);
  final int statusCode;
  final String body;
  @override
  String toString() => 'ApiException($statusCode): $body';
}
