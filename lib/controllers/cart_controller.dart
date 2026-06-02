import 'package:flutter/foundation.dart';
import '../services/database_helper.dart';

class CartItem {
  final String id; // unique combination of product name + variants
  final String baseName; // just the product name (e.g. "Es Kopi Susu")
  final String name; // variant name (e.g. "Es Kopi Susu (Ice, Less Sugar)")
  final int price;
  final String image;
  int qty;
  final String? temp;
  final String? sugar;

  CartItem({
    required this.id,
    required this.baseName,
    required this.name,
    required this.price,
    required this.image,
    required this.qty,
    this.temp,
    this.sugar,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'baseName': baseName,
    'name': name,
    'price': price,
    'image': image,
    'qty': qty,
    'temp': temp,
    'sugar': sugar,
  };
}

class MockOrder {
  final String id;
  final DateTime date;
  final String name;
  final String phone;
  final String note;
  final String tableNumber;
  final String paymentMethod;
  final List<CartItem> items;
  final int total;
  String status; // "Pending", "Process", "Selesai"

  MockOrder({
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
}

class CartController extends ChangeNotifier {
  static final CartController _instance = CartController._internal();
  factory CartController() => _instance;
  CartController._internal();

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  // Mock order history and tracking
  final List<MockOrder> _orders = [];
  List<MockOrder> get orders => List.unmodifiable(_orders);
  String? activeOrderId;

  void addItem({
    required String baseName,
    required String image,
    required int price,
    required int qty,
    String? temp,
    String? sugar,
  }) {
    // Generate variant details for name
    List<String> details = [];
    if (temp != null && temp.isNotEmpty) details.add(temp);
    if (sugar != null && sugar.isNotEmpty) details.add(sugar);

    String displayName = baseName;
    if (details.isNotEmpty) {
      displayName += " (${details.join(', ')})";
    }

    // Generate unique ID based on name and options
    String itemId = "${baseName.replaceAll(' ', '_')}_${temp ?? ''}_${sugar ?? ''}";

    int existingIndex = _items.indexWhere((item) => item.id == itemId);
    if (existingIndex != -1) {
      _items[existingIndex].qty += qty;
    } else {
      _items.add(
        CartItem(
          id: itemId,
          baseName: baseName,
          name: displayName,
          price: price,
          image: image,
          qty: qty,
          temp: temp,
          sugar: sugar,
        ),
      );
    }
    notifyListeners();
  }

  void updateQty(String id, int change) {
    int index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index].qty += change;
      if (_items[index].qty <= 0) {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  int get totalCount {
    int total = 0;
    for (var item in _items) {
      total += item.qty;
    }
    return total;
  }

  int get totalPrice {
    int total = 0;
    for (var item in _items) {
      total += item.price * item.qty;
    }
    return total;
  }

  // Submit Order logic (mocks API checkout)
  String submitOrder({
    required String name,
    required String phone,
    required String note,
    required String tableNumber,
    required String paymentMethod,
  }) {
    if (_items.isEmpty) return '';

    // Generate unique order ID like ORD-123456
    String oId = "ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

    final newOrder = MockOrder(
      id: oId,
      date: DateTime.now(),
      name: name,
      phone: phone,
      note: note,
      tableNumber: tableNumber,
      paymentMethod: paymentMethod,
      items: List.from(_items),
      total: totalPrice,
      status: 'Pending',
    );

    _orders.add(newOrder);
    activeOrderId = oId;

    // Simulate order progress in background
    _startMockOrderProgress(newOrder);

    clear();
    return oId;
  }

  // Simulate updating status from Pending -> Process -> Selesai
  void _startMockOrderProgress(MockOrder order) {
    Future.delayed(const Duration(seconds: 15), () {
      order.status = 'Process';
      DatabaseHelper().updateOrderStatus(order.id, 'Process');
      notifyListeners();
    });

    Future.delayed(const Duration(seconds: 40), () {
      order.status = 'Selesai';
      DatabaseHelper().updateOrderStatus(order.id, 'Selesai');
      notifyListeners();
    });
  }

  MockOrder? findOrder(String query) {
    if (query.trim().isEmpty) return null;
    final lowerQuery = query.toLowerCase().trim();
    for (var o in _orders) {
      if (o.id.toLowerCase() == lowerQuery || o.phone == lowerQuery || o.id.toLowerCase().contains(lowerQuery)) {
        return o;
      }
    }
    return null;
  }

  MockOrder? get activeOrder {
    if (activeOrderId == null) return null;
    for (var o in _orders) {
      if (o.id == activeOrderId) {
        return o;
      }
    }
    return null;
  }
}
