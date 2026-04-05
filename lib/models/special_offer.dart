class SpecialOffer {
  final String id;
  final String titleEn;
  final String titleAr;
  final String imageUrl;
  final double price;
  final String? productId;
  final bool isActive;

  SpecialOffer({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.imageUrl,
    required this.price,
    this.productId,
    this.isActive = true,
  });

  factory SpecialOffer.fromJson(Map<String, dynamic> json) {
    return SpecialOffer(
      id: json['id']?.toString() ?? '',
      titleEn: json['title_en'] ?? '',
      titleAr: json['title_ar'] ?? '',
      imageUrl: json['image_url'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      productId: json['product_id']?.toString(),
      isActive: json['is_active'] ?? true,
    );
  }
}
