class Banner {
  final String id;
  final String titleEn;
  final String titleAr;
  final String image;
  final String? link;

  Banner({
    required this.id,
    required this.titleEn,
    required this.titleAr,
    required this.image,
    this.link,
  });

  factory Banner.fromJson(Map<String, dynamic> json) {
    return Banner(
      id: json['id']?.toString() ?? '',
      titleEn: json['title_en'] ?? '',
      titleAr: json['title_ar'] ?? '',
      image: json['image_url'] ?? '',
      link: json['link'],
    );
  }
}
