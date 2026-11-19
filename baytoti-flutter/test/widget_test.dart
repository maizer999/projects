import 'package:flutter_test/flutter_test.dart';

import 'package:baytoti/data/arabic_text.dart';
import 'package:baytoti/data/models.dart';
import 'package:baytoti/data/product_catalog.dart';
import 'package:baytoti/data/repository.dart';

void main() {
  group('normalizeAr', () {
    test('folds alef variants', () {
      expect(normalizeAr('أحمد'), normalizeAr('احمد'));
      expect(normalizeAr('إبراهيم'), normalizeAr('ابراهيم'));
      expect(normalizeAr('آية'), 'ايه');
    });

    test('folds alef maqsura and taa marbuta', () {
      expect(normalizeAr('بنى'), normalizeAr('بني'));
      expect(normalizeAr('جبنة'), 'جبنه');
    });

    test('strips tashkeel and collapses whitespace', () {
      expect(normalizeAr('حَلِيبٌ  طَازَج'), 'حليب طازج');
    });
  });

  group('parseFlexibleDouble', () {
    test('parses ASCII digits', () {
      expect(parseFlexibleDouble('1.5'), 1.5);
      expect(parseFlexibleDouble('  12 '), 12);
    });
    test('parses Arabic-Indic digits', () {
      expect(parseFlexibleDouble('١٫٥'), 1.5);
      expect(parseFlexibleDouble('٠٫٧٥'), 0.75);
      expect(parseFlexibleDouble('١٢٣'), 123);
    });
    test('parses mixed and Persian digits', () {
      expect(parseFlexibleDouble('۲۵'), 25);
      expect(parseFlexibleDouble('1٫25'), 1.25);
    });
    test('returns null on garbage', () {
      expect(parseFlexibleDouble('abc'), isNull);
      expect(parseFlexibleDouble(''), isNull);
    });
  });

  group('catalog search', () {
    test('matches by normalized Arabic', () {
      final results = searchCatalog('بطاطا').toList();
      expect(results, isNotEmpty);
      expect(results.first.name, contains('بطاطا'));
    });

    test('finds product ignoring tashkeel', () {
      final p = findProductByName('شَاي');
      expect(p, isNotNull);
      expect(p!.name, 'شاي');
    });

    test('grouped search sorts food before cleaning before other', () {
      final results = searchCatalogGrouped('ا'); // broad match
      final orders = results.map((p) => categoryOrder(p.category)).toList();
      for (var i = 1; i < orders.length; i++) {
        expect(orders[i] >= orders[i - 1], isTrue,
            reason: 'order decreased at index $i: $orders');
      }
    });
  });

  group('invite code', () {
    test('is 6 chars from the restricted alphabet', () {
      for (var i = 0; i < 50; i++) {
        final code = ListRepository.generateInviteCode();
        expect(code.length, 6);
        expect(RegExp(r'^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]+$').hasMatch(code),
            isTrue,
            reason: 'bad chars in $code');
      }
    });
  });

  group('Purchase', () {
    test('toJson includes archived flag', () {
      final p = Purchase(
        id: 'x',
        itemName: 'خبز',
        price: 0.5,
        category: PurchaseCategory.food,
        addedByName: 'ضيف',
        date: DateTime(2026, 1, 1),
      );
      final m = p.toJson();
      expect(m['archived'], false);
    });

    test('note key omitted when empty', () {
      final p = Purchase(
        id: 'x',
        itemName: 'خبز',
        price: null,
        category: PurchaseCategory.food,
        addedByName: 'ضيف',
        date: DateTime(2026, 1, 1),
        note: null,
      );
      expect(p.toJson().containsKey('note'), isFalse);
    });
  });

  group('ShoppingList membership', () {
    test('owner is a member', () {
      final l = ShoppingList(
        id: 'x',
        name: 'بيت',
        createdAt: DateTime(2026, 1, 1),
        ownerName: 'محمد',
        members: const ['محمد', 'نجوى'],
      );
      expect(l.isOwner('محمد'), isTrue);
      expect(l.isMember('محمد'), isTrue);
      expect(l.isMember('نجوى'), isTrue);
      expect(l.isMember('سارة'), isFalse);
      expect(l.editors, const ['نجوى']);
    });
  });
}
