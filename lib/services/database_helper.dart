import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/menu_model.dart';
import '../models/order_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Web/In-memory fallback data
  static List<MenuModel>? _webMenus;
  static List<OrderModel> _webOrders = [];

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite tidak didukung di Web');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cafe_star.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create menus table
    await db.execute('''
      CREATE TABLE menus (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price INTEGER NOT NULL,
        category TEXT NOT NULL,
        image_url TEXT NOT NULL,
        label TEXT,
        is_available INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create orders table
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        note TEXT,
        table_number TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        items_json TEXT NOT NULL,
        total INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'Pending'
      )
    ''');

    // Seed default menus
    await _seedMenus(db);
  }

  Future<void> _seedMenus(Database db) async {
    final defaultMenus = _getDefaultMenus();

    for (var m in defaultMenus) {
      await db.insert('menus', m.toMap());
    }
  }

  List<MenuModel> _getDefaultMenus() {
    return [
      MenuModel(
        id: 1,
        name: 'Nasi Goreng',
        price: 15000,
        category: 'Makanan',
        imageUrl: 'assets/images/nasi_goreng.png',
        label: 'Recommended',
      ),
      MenuModel(
        id: 2,
        name: 'Roti Bakar',
        price: 12000,
        category: 'Makanan',
        imageUrl: 'assets/images/roti_bakar.png',
      ),
      MenuModel(
        id: 3,
        name: 'Es Kopi Susu',
        price: 18000,
        category: 'Minuman',
        imageUrl: 'assets/images/es_kopi_susu.png',
        label: 'Best Seller',
      ),
      MenuModel(
        id: 4,
        name: 'Cappuccino',
        price: 20000,
        category: 'Minuman',
        imageUrl: 'assets/images/cappuccino.png',
      ),
      MenuModel(
        id: 5,
        name: 'Brownies',
        price: 14000,
        category: 'Dessert',
        imageUrl: 'assets/images/brownies.png',
      ),
      MenuModel(
        id: 6,
        name: 'Pancake',
        price: 16000,
        category: 'Dessert',
        imageUrl: 'assets/images/pancake.png',
        label: 'New',
      ),
    ];
  }

  void _initWebData() {
    if (_webMenus == null) {
      _webMenus = _getDefaultMenus();
    }
  }

  // --- MENU CRUD ---
  Future<List<MenuModel>> getMenus() async {
    if (kIsWeb) {
      _initWebData();
      return List<MenuModel>.from(_webMenus!);
    }
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('menus');
      return List.generate(maps.length, (i) => MenuModel.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Database error, falling back to mock: $e');
      _initWebData();
      return List<MenuModel>.from(_webMenus!);
    }
  }

  Future<int> insertMenu(MenuModel menu) async {
    if (kIsWeb) {
      _initWebData();
      final newId = (_webMenus!.isEmpty) ? 1 : (_webMenus!.map((m) => m.id ?? 0).reduce((a, b) => a > b ? a : b) + 1);
      final newMenu = MenuModel(
        id: newId,
        name: menu.name,
        price: menu.price,
        category: menu.category,
        imageUrl: menu.imageUrl,
        label: menu.label,
        isAvailable: menu.isAvailable,
      );
      _webMenus!.add(newMenu);
      return newId;
    }
    final db = await database;
    return await db.insert('menus', menu.toMap());
  }

  Future<int> updateMenu(MenuModel menu) async {
    if (kIsWeb) {
      _initWebData();
      final index = _webMenus!.indexWhere((m) => m.id == menu.id);
      if (index != -1) {
        _webMenus![index] = menu;
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update(
      'menus',
      menu.toMap(),
      where: 'id = ?',
      whereArgs: [menu.id],
    );
  }

  Future<int> deleteMenu(int id) async {
    if (kIsWeb) {
      _initWebData();
      final lengthBefore = _webMenus!.length;
      _webMenus!.removeWhere((m) => m.id == id);
      return lengthBefore - _webMenus!.length;
    }
    final db = await database;
    return await db.delete(
      'menus',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- ORDER CRUD ---
  Future<int> insertOrder(OrderModel order) async {
    if (kIsWeb) {
      _webOrders.add(order);
      return 1;
    }
    final db = await database;
    return await db.insert('orders', order.toMap());
  }

  Future<List<OrderModel>> getOrders() async {
    if (kIsWeb) {
      final list = List<OrderModel>.from(_webOrders);
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('orders', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => OrderModel.fromMap(maps[i]));
  }

  Future<OrderModel?> getOrderById(String id) async {
    if (kIsWeb) {
      final index = _webOrders.indexWhere((o) => o.id == id);
      if (index != -1) return _webOrders[index];
      return null;
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return OrderModel.fromMap(maps.first);
  }

  Future<OrderModel?> findOrder(String query) async {
    if (kIsWeb) {
      final cleanQuery = query.trim().toLowerCase();
      final index = _webOrders.indexWhere((o) =>
          o.id.toLowerCase() == cleanQuery ||
          o.phone == cleanQuery ||
          o.id.toLowerCase().contains(cleanQuery));
      if (index != -1) return _webOrders[index];
      return null;
    }
    final db = await database;
    final cleanQuery = query.trim().toLowerCase();
    final List<Map<String, dynamic>> maps = await db.query(
      'orders',
      where: 'LOWER(id) = ? OR phone = ? OR LOWER(id) LIKE ?',
      whereArgs: [cleanQuery, cleanQuery, '%$cleanQuery%'],
    );
    if (maps.isEmpty) return null;
    return OrderModel.fromMap(maps.first);
  }

  Future<int> updateOrderStatus(String id, String status) async {
    if (kIsWeb) {
      final index = _webOrders.indexWhere((o) => o.id == id);
      if (index != -1) {
        final order = _webOrders[index];
        _webOrders[index] = OrderModel(
          id: order.id,
          date: order.date,
          name: order.name,
          phone: order.phone,
          note: order.note,
          tableNumber: order.tableNumber,
          paymentMethod: order.paymentMethod,
          items: order.items,
          total: order.total,
          status: status,
        );
        return 1;
      }
      return 0;
    }
    final db = await database;
    return await db.update(
      'orders',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
