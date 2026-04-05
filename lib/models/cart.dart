import 'cart_item.dart';

class Cart {
  final String id;
  final String userId;
  final List<CartItem> items;
  final Map<String, dynamic>? metadata;

  Cart({
    required this.id,
    required this.userId,
    required this.items,
    this.metadata,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'],
      userId: json['user_id'] ?? '',
      items: (json['cart_items'] as List<dynamic>?)
              ?.map((item) => CartItem.fromJson(item))
              .toList() ??
          [],
      metadata: json['metadata'],
    );
  }
}
