import 'arabic_text.dart';
import 'models.dart';

class Product {
  const Product({
    required this.name,
    required this.price,
    required this.category,
  });

  final String name;
  final double price;
  final PurchaseCategory category;
}

const List<Product> kProductCatalog = [
  Product(name: 'خبز عربي', price: 0.250, category: PurchaseCategory.food),
  Product(name: 'حليب (1 لتر)', price: 1.100, category: PurchaseCategory.food),
  Product(name: 'بيض (30 حبة)', price: 3.500, category: PurchaseCategory.food),
  Product(name: 'جبنة بيضاء', price: 2.500, category: PurchaseCategory.food),
  Product(name: 'زيت زيتون (لتر)', price: 7.000, category: PurchaseCategory.food),
  Product(name: 'زيت نباتي (لتر)', price: 2.500, category: PurchaseCategory.food),
  Product(name: 'سكر (كيلو)', price: 0.800, category: PurchaseCategory.food),
  Product(name: 'أرز بسمتي (كيلو)', price: 2.200, category: PurchaseCategory.food),
  Product(name: 'دقيق أبيض (كيلو)', price: 0.700, category: PurchaseCategory.food),
  Product(name: 'شاي', price: 2.500, category: PurchaseCategory.food),
  Product(name: 'قهوة', price: 5.000, category: PurchaseCategory.food),
  Product(name: 'طماطم (كيلو)', price: 1.000, category: PurchaseCategory.food),
  Product(name: 'بطاطا (كيلو)', price: 0.700, category: PurchaseCategory.food),
  Product(name: 'بصل (كيلو)', price: 0.600, category: PurchaseCategory.food),
  Product(name: 'تفاح (كيلو)', price: 1.500, category: PurchaseCategory.food),
  Product(name: 'موز (كيلو)', price: 1.200, category: PurchaseCategory.food),
  Product(name: 'دجاج (كيلو)', price: 3.500, category: PurchaseCategory.food),
  Product(name: 'لحم بقري (كيلو)', price: 10.000, category: PurchaseCategory.food),
  Product(name: 'منظف أرضيات', price: 3.000, category: PurchaseCategory.cleaning),
  Product(name: 'صابون غسيل', price: 4.500, category: PurchaseCategory.cleaning),
  Product(name: 'ورق مطبخ', price: 2.000, category: PurchaseCategory.other),
];

Iterable<Product> searchCatalog(String query) {
  final q = normalizeAr(query);
  if (q.isEmpty) return const Iterable.empty();
  return kProductCatalog.where((p) => normalizeAr(p.name).contains(q));
}

Product? findProductByName(String name) {
  final q = normalizeAr(name);
  for (final p in kProductCatalog) {
    if (normalizeAr(p.name) == q) return p;
  }
  return null;
}

int categoryOrder(PurchaseCategory c) {
  switch (c) {
    case PurchaseCategory.food:
      return 0;
    case PurchaseCategory.cleaning:
      return 1;
    case PurchaseCategory.other:
      return 2;
  }
}

List<Product> searchCatalogGrouped(String query) {
  final results = searchCatalog(query).toList();
  results.sort((a, b) {
    final c = categoryOrder(a.category).compareTo(categoryOrder(b.category));
    if (c != 0) return c;
    return a.name.compareTo(b.name);
  });
  return results;
}
