enum OrderStatus {
  pending('Ожидает подтверждения'),
  confirmed('Подтверждён'),
  shipped('В пути'),
  delivered('Доставлен'),
  cancelled('Отменён');

  const OrderStatus(this.label);
  final String label;

  static OrderStatus parse(String v) => OrderStatus.values
      .firstWhere((s) => s.name == v, orElse: () => OrderStatus.pending);
}

class OrderLine {
  const OrderLine({
    required this.title,
    required this.size,
    required this.quantity,
    required this.unitPrice,
  });

  final String title;
  final String size;
  final int quantity;
  final int unitPrice;

  factory OrderLine.fromJson(Map<String, dynamic> json) => OrderLine(
        title: (json['title'] as String?) ?? '',
        size: (json['size'] as String?) ?? '',
        quantity: (json['quantity'] as num).toInt(),
        unitPrice: (json['unit_price'] as num).toInt(),
      );
}

class Order {
  const Order({
    required this.id,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.address,
    required this.phone,
    this.comment = '',
    this.lines = const [],
  });

  final String id;
  final OrderStatus status;
  final int total;
  final DateTime createdAt;
  final String address;
  final String phone;
  final String comment;
  final List<OrderLine> lines;

  String get shortId => id.length > 6 ? id.substring(0, 6).toUpperCase() : id;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        status: OrderStatus.parse(json['status'] as String),
        total: (json['total'] as num).toInt(),
        createdAt: DateTime.parse(json['created_at'] as String),
        address: (json['address'] as String?) ?? '',
        phone: (json['phone'] as String?) ?? '',
        comment: (json['comment'] as String?) ?? '',
        lines: [
          for (final l in (json['order_items'] as List? ?? const []))
            OrderLine.fromJson(l as Map<String, dynamic>),
        ],
      );
}

/// Contact & delivery details captured at checkout.
class CheckoutDetails {
  const CheckoutDetails({
    required this.name,
    required this.phone,
    required this.address,
    this.comment = '',
  });

  final String name;
  final String phone;
  final String address;
  final String comment;
}
