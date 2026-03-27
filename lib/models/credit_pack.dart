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

  factory CreditPack.fromJson(Map<String, dynamic> json) {
    return CreditPack(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      credits: (json['credits'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'EUR',
      storeProductIdIos: json['store_product_id_ios'] as String? ?? '',
      storeProductIdAndroid: json['store_product_id_android'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
