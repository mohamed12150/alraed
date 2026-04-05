class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final List<String> images;
  final List<String> weights;
  final List<String> options;
  final String category;
  final double rating;
  final int reviewCount;
  final int salesCount;
  final double? discountPrice;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.images = const [],
    required this.weights,
    required this.options,
    required this.category,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.salesCount = 0,
    this.discountPrice,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle Supabase schema field names (name_ar, name_en)
    final String title =
        json['name_ar'] ?? json['name_en'] ?? json['title'] ?? '';
    final String description =
        json['description_ar'] ??
        json['description_en'] ??
        json['description'] ??
        '';

    // Handle image_url priority:
    // 1. product_images (is_primary = true)
    // 2. product_images (first item)
    // 3. products.image_url

    String imageUrl = '';

    final productImages = json['product_images'] as List?;
    if (productImages != null && productImages.isNotEmpty) {
      // Try to find primary image
      final primaryImage = productImages.firstWhere(
        (img) => img['is_primary'] == true,
        orElse: () => null,
      );

      if (primaryImage != null) {
        imageUrl = primaryImage['url'] ?? '';
      } else {
        imageUrl = productImages[0]['url'] ?? '';
      }
    }

    if (imageUrl.isEmpty) {
      imageUrl = json['image_url'] ?? '';
    }

    // Populate images list
    List<String> imagesList = [];
    if (productImages != null) {
      for (var img in productImages) {
        if (img['url'] != null && img['url'].toString().isNotEmpty) {
          imagesList.add(img['url'].toString());
        }
      }
    }

    // Ensure we have at least the main image
    if (imagesList.isEmpty && imageUrl.isNotEmpty) {
      imagesList.add(imageUrl);
    }

    // Handle category name from joined table
    String categoryName = '';
    if (json['categories'] != null) {
      categoryName =
          json['categories']['name_ar'] ?? json['categories']['name_en'] ?? '';
    }

    return Product(
      id: json['id'].toString(),
      title: title,
      description: description,
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: imageUrl,
      images: imagesList,
      weights: List<String>.from(
        json['weights'] ?? json['attributes']?['weights'] ?? [],
      ),
      options: List<String>.from(json['options'] ?? []),
      category: categoryName.isNotEmpty
          ? categoryName
          : (json['category_id']?.toString() ?? ''),
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      salesCount: json['sales_count'] ?? 0,
      discountPrice: json['stock'] != null
          ? (json['stock'] as num).toDouble()
          : null,
    );
  }
}
