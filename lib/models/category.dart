class Category {
  final String id;
  final String nameEn;
  final String nameAr;
  final String icon;
  final String image;
  final String colorHex;

  Category({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.icon,
    required this.image,
    required this.colorHex,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      nameEn: json['name_en'] ?? '',
      nameAr: json['name_ar'] ?? '',
      icon: json['icon'] ?? '',
      image: json['image'] ?? json['image_url'] ?? '',
      colorHex: json['color_hex'] ?? '#000000',
    );
  }
}
