class CreditPack {
  final int id;
  final String name;
  final int credits;
  final double price;
  final String currency;
  final String storeProductIdIos;
  final String storeProductIdAndroid;
  final bool isActive;

  const CreditPack({
    required this.id,
    required this.name,
    required this.credits,
    required this.price,
    required this.currency,
    required this.storeProductIdIos,
    required this.storeProductIdAndroid,
    required this.isActive,
  });

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  factory CreditPack.fromJson(Map<String, dynamic> json) {
    return CreditPack(
      id: _toInt(json['id']),
      name: json['name'] as String? ?? '',
      credits: _toInt(json['credits']),
      price: _toDouble(json['price']),
      currency: json['currency'] as String? ?? 'EUR',
      storeProductIdIos: json['store_product_id_ios'] as String? ?? '',
      storeProductIdAndroid: json['store_product_id_android'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
