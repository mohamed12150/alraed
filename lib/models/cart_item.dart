class CartItem {
  final String id;
  final String productId;
  final String? variantId;
  final String title;
  final String image;
  final double price;
  int quantity;
  final String weight;
  final String? selectedOption;
  final int? cuttingMethodId;

  CartItem({
    required this.id,
    required this.productId,
    this.variantId,
    required this.title,
    required this.image,
    required this.price,
    this.quantity = 1,
    required this.weight,
    this.selectedOption,
    this.cuttingMethodId,
  });

  double get totalPrice => price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Helper to safely get single object from potential List or Map
    Map<String, dynamic>? getRelation(dynamic data) {
      if (data == null) return null;
      if (data is Map) return data as Map<String, dynamic>;
      if (data is List && data.isNotEmpty) return data.first as Map<String, dynamic>;
      return null;
    }

    final product = getRelation(json['products']);
    final variant = getRelation(json['product_variants']);
    // Handle both potential keys for cutting methods
    final cuttingMethod = getRelation(json['cutting_methods']) ?? getRelation(json['cutting_method']);
    
    // Extract title/image from product if available
    String title = '';
    String image = '';
    double price = 0.0;
    
    if (product != null) {
      title = product['name_ar'] ?? product['name_en'] ?? '';
      // Image handling logic similar to Product.fromJson
      image = product['image_url'] ?? '';
      
      final images = product['product_images'];
      if (image.isEmpty && images != null && images is List && images.isNotEmpty) {
         final firstImg = images.first;
         if (firstImg is Map) {
            image = firstImg['url'] ?? '';
         }
      }
      
      final pPrice = product['price'];
      if (pPrice != null) {
          price = (pPrice is num) ? pPrice.toDouble() : double.tryParse(pPrice.toString()) ?? 0.0;
      }
    }

    // Override price if variant has price
    if (variant != null && variant['price'] != null) {
       final vPrice = variant['price'];
       price = (vPrice is num) ? vPrice.toDouble() : double.tryParse(vPrice.toString()) ?? price;
    }
    
    // Fallback for weight if variant is null but logic requires it
    String weight = '';
    if (variant != null && variant['attributes'] != null) {
       final attrs = variant['attributes'];
       if (attrs is Map) {
          weight = attrs['weight'] ?? '';
       }
    }

    // Try to get cutting method name
    String? optionName;
    if (cuttingMethod != null) {
       optionName = cuttingMethod['name_ar'] ?? cuttingMethod['name_en'];
    }

    return CartItem(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      variantId: json['variant_id']?.toString(),
      title: title,
      image: image,
      price: price,
      quantity: (json['qty'] as num?)?.toInt() ?? 1,
      weight: weight,
      selectedOption: optionName, 
      cuttingMethodId: (json['cutting_method_id'] as num?)?.toInt(),
    );
  }
}
