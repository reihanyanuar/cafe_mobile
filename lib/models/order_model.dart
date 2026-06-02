import 'dart:convert';
import '../controllers/cart_controller.dart';

class OrderModel {
  final String id;
  final DateTime date;
  final String name;
  final String phone;
  final String note;
  final String tableNumber;
  final String paymentMethod;
  final List<CartItem> items;
  final int total;
  final String status;

  OrderModel({
    required this.id,
    required this.date,
    required this.name,
    required this.phone,
    required this.note,
    required this.tableNumber,
    required this.paymentMethod,
    required this.items,
    required this.total,
    this.status = 'Pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'name': name,
      'phone': phone,
      'note': note,
      'table_number': tableNumber,
      'payment_method': paymentMethod,
      'items_json': jsonEncode(items.map((e) => e.toJson()).toList()),
      'total': total,
      'status': status,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final decodedItems = jsonDecode(map['items_json'] as String) as List<dynamic>;
    final parsedItems = decodedItems.map((item) {
      final m = item as Map<String, dynamic>;
      return CartItem(
        id: m['id'] as String? ?? '',
        baseName: m['baseName'] as String? ?? m['name'] as String? ?? '',
        name: m['name'] as String? ?? '',
        price: m['price'] as int? ?? 0,
        image: m['image'] as String? ?? '',
        qty: m['qty'] as int? ?? 1,
        temp: m['temp'] as String?,
        sugar: m['sugar'] as String?,
      );
    }).toList();

    return OrderModel(
      id: map['id'] as String,
      date: DateTime.parse(map['date'] as String),
      name: map['name'] as String,
      phone: map['phone'] as String,
      note: map['note'] as String? ?? '',
      tableNumber: map['table_number'] as String? ?? '',
      paymentMethod: map['payment_method'] as String? ?? '',
      items: parsedItems,
      total: map['total'] as int,
      status: map['status'] as String? ?? 'Pending',
    );
  }
}
