class OrderItem {
  final String id;
  final String orderId;
  final String? productId;
  final String nameAr;
  final int qty;
  final double unitPrice;
  final double subtotal;
  final Map<String, dynamic>? metadata;

  OrderItem({
    required this.id,
    required this.orderId,
    this.productId,
    required this.nameAr,
    required this.qty,
    required this.unitPrice,
    required this.subtotal,
    this.metadata,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      productId: json['product_id']?.toString(),
      nameAr: json['name_ar']?.toString() ?? '',
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      metadata: json['metadata'],
    );
  }
}

class Order {
  final String id;
  final String userId;
  final double totalAmount;
  final String paymentMethod;
  final String status;
  final String phone;
  final String city;
  final String address;
  final DateTime createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.userId,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required this.phone,
    required this.city,
    required this.address,
    required this.createdAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = <OrderItem>[];
    if (json['order_items'] != null) {
      itemsList = (json['order_items'] as List)
          .map((i) => OrderItem.fromJson(i))
          .toList();
    }

    return Order(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      phone: json['phone']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at']).toLocal()
          : DateTime.now(),
      items: itemsList,
    );
  }
}
