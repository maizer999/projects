enum PurchaseCategory { food, cleaning, other }

PurchaseCategory categoryFromString(String? v) {
  switch (v) {
    case 'food':
      return PurchaseCategory.food;
    case 'cleaning':
      return PurchaseCategory.cleaning;
    default:
      return PurchaseCategory.other;
  }
}

String categoryToString(PurchaseCategory c) {
  switch (c) {
    case PurchaseCategory.food:
      return 'food';
    case PurchaseCategory.cleaning:
      return 'cleaning';
    case PurchaseCategory.other:
      return 'other';
  }
}

String categoryLabelAr(PurchaseCategory c) {
  switch (c) {
    case PurchaseCategory.food:
      return 'طعام';
    case PurchaseCategory.cleaning:
      return 'منظفات';
    case PurchaseCategory.other:
      return 'أخرى';
  }
}

DateTime _parseIso(dynamic v) {
  if (v is String) {
    final t = DateTime.tryParse(v);
    if (t != null) return t.toLocal();
  }
  return DateTime.now();
}

String _toIso(DateTime d) => d.toUtc().toIso8601String();

class ShoppingList {
  final String id;
  final String name;
  final DateTime createdAt;
  final String? ownerName;
  final List<String> members;
  final String? inviteCode;

  ShoppingList({
    required this.id,
    required this.name,
    required this.createdAt,
    this.ownerName,
    this.members = const [],
    this.inviteCode,
  });

  factory ShoppingList.fromJson(Map<String, dynamic> j) => ShoppingList(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? 'بيت العائلة',
        createdAt: _parseIso(j['createdAt']),
        ownerName: j['ownerName'] as String?,
        members: ((j['members'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        inviteCode: j['inviteCode'] as String?,
      );

  bool isMember(String name) => members.contains(name) || ownerName == name;
  bool isOwner(String name) => ownerName == name;

  List<String> get editors =>
      members.where((m) => m != ownerName).toList();
}

class Purchase {
  final String id;
  final String itemName;
  final double? price;
  final PurchaseCategory category;
  final String addedByName;
  final DateTime date;
  final String? note;
  final bool archived;

  Purchase({
    required this.id,
    required this.itemName,
    required this.price,
    required this.category,
    required this.addedByName,
    required this.date,
    this.note,
    this.archived = false,
  });

  factory Purchase.fromJson(Map<String, dynamic> j) {
    final rawPrice = j['price'];
    final rawNote = j['note'] as String?;
    return Purchase(
      id: j['id'] as String,
      itemName: (j['itemName'] as String?) ?? '',
      price: rawPrice is num ? rawPrice.toDouble() : null,
      category: categoryFromString(j['category'] as String?),
      addedByName: (j['addedByName'] as String?) ?? 'ضيف',
      date: _parseIso(j['date']),
      note: (rawNote == null || rawNote.isEmpty) ? null : rawNote,
      archived: (j['archived'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemName': itemName,
        'price': price,
        'category': categoryToString(category),
        'addedByName': addedByName,
        'date': _toIso(date),
        if (note != null && note!.isNotEmpty) 'note': note,
        'archived': archived,
      };
}

class ProductStat {
  final String id;
  final String name;
  final int count;
  final DateTime? lastUsed;

  ProductStat({
    required this.id,
    required this.name,
    required this.count,
    this.lastUsed,
  });

  factory ProductStat.fromJson(Map<String, dynamic> j) => ProductStat(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        count: ((j['count'] as num?) ?? 0).toInt(),
        lastUsed: j['lastUsed'] == null ? null : _parseIso(j['lastUsed']),
      );
}

class WishItem {
  final String id;
  final String itemName;
  final String addedByName;
  final DateTime createdAt;

  WishItem({
    required this.id,
    required this.itemName,
    required this.addedByName,
    required this.createdAt,
  });

  factory WishItem.fromJson(Map<String, dynamic> j) => WishItem(
        id: j['id'] as String,
        itemName: (j['itemName'] as String?) ?? '',
        addedByName: (j['addedByName'] as String?) ?? 'ضيف',
        createdAt: _parseIso(j['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'itemName': itemName,
        'addedByName': addedByName,
        'createdAt': _toIso(createdAt),
      };
}
