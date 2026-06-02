import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/menu_model.dart';
import '../../models/order_model.dart';
import '../../services/database_helper.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentTab = 0; // 0: Orders, 1: Menu Management

  // Menu tab state
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<MenuModel> _menus = [];
  bool _isMenuLoading = true;

  // Orders tab state
  List<OrderModel> _orders = [];
  bool _isOrdersLoading = true;
  int _ordersFilter = 0; // 0: Pesanan Baru (Pending), 1: Terselesaikan (Selesai)
  Timer? _pollingTimer;

  // Menu dropdown list options
  final List<String> _categories = ['Makanan', 'Minuman', 'Dessert'];
  final List<String> _labels = ['None', 'Recommended', 'Best Seller', 'New'];
  final List<String> _images = [
    'assets/images/nasi_goreng.png',
    'assets/images/roti_bakar.png',
    'assets/images/es_kopi_susu.png',
    'assets/images/cappuccino.png',
    'assets/images/brownies.png',
    'assets/images/pancake.png',
    'assets/images/food.png',
    'assets/images/menu.png',
    'assets/images/tempat.png',
  ];

  @override
  void initState() {
    super.initState();
    _refreshMenus();
    _refreshOrders();
    // Poll for new orders every 8 seconds for a real-time experience
    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted && _currentTab == 0) {
        _silentRefreshOrders();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // --- ORDER DB HELPER CALLS ---
  Future<void> _refreshOrders() async {
    setState(() => _isOrdersLoading = true);
    final data = await _dbHelper.getOrders();
    if (mounted) {
      setState(() {
        _orders = data;
        _isOrdersLoading = false;
      });
    }
  }

  Future<void> _silentRefreshOrders() async {
    final data = await _dbHelper.getOrders();
    if (mounted) {
      setState(() {
        _orders = data;
      });
    }
  }

  Future<void> _completeOrder(OrderModel order) async {
    // Show confirmation dialog before completing
    bool confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.white10),
            ),
            title: Text(
              'Selesaikan Pesanan?',
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD4AF37),
              ),
            ),
            content: Text(
              'Apakah Anda yakin ingin menandai pesanan "${order.name}" (Meja ${order.tableNumber}) sebagai selesai?',
              style: GoogleFonts.inter(color: const Color(0xFFA0A0A0)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Ya, Selesai',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF121212),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await _dbHelper.updateOrderStatus(order.id, 'Selesai');
      _refreshOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD4AF37),
            content: Text(
              'Pesanan ${order.id} berhasil diselesaikan!',
              style: GoogleFonts.inter(
                color: const Color(0xFF121212),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
    }
  }

  // --- MENU DB HELPER CALLS ---
  Future<void> _refreshMenus() async {
    setState(() => _isMenuLoading = true);
    final data = await _dbHelper.getMenus();
    if (mounted) {
      setState(() {
        _menus = data;
        _isMenuLoading = false;
      });
    }
  }

  void _showFormDialog({MenuModel? menu}) {
    final isEdit = menu != null;
    final nameController = TextEditingController(text: menu?.name ?? '');
    final priceController = TextEditingController(text: menu?.price.toString() ?? '');
    String selectedCategory = menu?.category ?? _categories[0];
    String selectedLabel = menu?.label ?? 'None';
    String selectedImage = menu?.imageUrl ?? _images[0];
    bool isAvailable = menu?.isAvailable ?? true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.white10),
              ),
              title: Text(
                isEdit ? 'Edit Menu Item' : 'Tambah Menu Baru',
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD4AF37),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview selected image
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.asset(
                            selectedImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.restaurant,
                              size: 50,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Image Dropdown Selector
                    Text('Pilih Gambar Aset', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: const Color(0xFF1E1E1E),
                          value: selectedImage,
                          isExpanded: true,
                          items: _images.map((img) {
                            String displayName = img.split('/').last.replaceAll('.png', '').replaceAll('_', ' ');
                            return DropdownMenuItem(
                              value: img,
                              child: Text(displayName, style: GoogleFonts.inter(color: const Color(0xFFF5F5F7))),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedImage = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Name Field
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Nama Menu',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white24),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Price Field
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.inter(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Harga (Rp)',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white24),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Category Dropdown
                    Text('Kategori', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: const Color(0xFF1E1E1E),
                          value: selectedCategory,
                          isExpanded: true,
                          items: _categories.map((cat) {
                            return DropdownMenuItem(
                              value: cat,
                              child: Text(cat, style: GoogleFonts.inter(color: const Color(0xFFF5F5F7))),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedCategory = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Label Dropdown
                    Text('Label Promo/Status', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: const Color(0xFF1E1E1E),
                          value: selectedLabel,
                          isExpanded: true,
                          items: _labels.map((lbl) {
                            return DropdownMenuItem(
                              value: lbl,
                              child: Text(lbl, style: GoogleFonts.inter(color: const Color(0xFFF5F5F7))),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedLabel = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Availability Switch
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tersedia / Stok Ada', style: GoogleFonts.inter(color: const Color(0xFFF5F5F7))),
                        Switch(
                          value: isAvailable,
                          activeColor: const Color(0xFFD4AF37),
                          onChanged: (val) {
                            setDialogState(() => isAvailable = val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty || priceController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Semua kolom wajib diisi')),
                      );
                      return;
                    }
                    final price = int.tryParse(priceController.text) ?? 0;
                    final newMenu = MenuModel(
                      id: menu?.id,
                      name: nameController.text.trim(),
                      price: price,
                      category: selectedCategory,
                      imageUrl: selectedImage,
                      label: selectedLabel == 'None' ? null : selectedLabel,
                      isAvailable: isAvailable,
                    );

                    if (isEdit) {
                      await _dbHelper.updateMenu(newMenu);
                    } else {
                      await _dbHelper.insertMenu(newMenu);
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      _refreshMenus();
                    }
                  },
                  child: Text(
                    isEdit ? 'Simpan' : 'Tambah',
                    style: GoogleFonts.inter(color: const Color(0xFF121212), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(MenuModel menu) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white10),
          ),
          title: Text(
            'Hapus Menu?',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus "${menu.name}"? Tindakan ini tidak dapat dibatalkan.',
            style: GoogleFonts.inter(color: const Color(0xFFA0A0A0)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: GoogleFonts.inter(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                if (menu.id != null) {
                  await _dbHelper.deleteMenu(menu.id!);
                  if (mounted) {
                    Navigator.pop(context);
                    _refreshMenus();
                  }
                }
              },
              child: Text('Hapus', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Helper to calculate time ago for orders
  String _getTimeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else {
      return '${difference.inDays} hari lalu';
    }
  }

  // Helper to format currency
  String _formatPrice(int price) {
    return 'Rp ${price.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}';
  }

  // --- WIDGET BUILDERS ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Text(
          _currentTab == 0 ? 'Pesanan Masuk' : 'Manajemen Menu',
          style: GoogleFonts.playfairDisplay(color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold),
        ),
        actions: [
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: _currentTab == 0 ? _refreshOrders : _refreshMenus,
            tooltip: 'Segarkan Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () {
              Navigator.pop(context); // Log out, returns to MainLayout
            },
            tooltip: 'Logout Admin',
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTab,
          onTap: (index) {
            setState(() {
              _currentTab = index;
            });
            if (index == 0) _refreshOrders();
            if (index == 1) _refreshMenus();
          },
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFFD4AF37),
          unselectedItemColor: const Color(0xFFA0A0A0),
          selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              label: 'Pesanan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: 'Kelola Menu',
            ),
          ],
        ),
      ),
      floatingActionButton: _currentTab == 1
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFD4AF37),
              onPressed: () => _showFormDialog(),
              child: const Icon(Icons.add, color: Color(0xFF121212)),
            )
          : null,
      body: _currentTab == 0 ? _buildOrdersView() : _buildMenuView(),
    );
  }

  // VIEW 1: ORDERS VIEW
  Widget _buildOrdersView() {
    // Filter orders based on status
    // 0: Pesanan Baru (Pending), 1: Terselesaikan (Selesai)
    final filteredOrders = _orders.where((order) {
      if (_ordersFilter == 0) {
        return order.status != 'Selesai';
      } else {
        return order.status == 'Selesai';
      }
    }).toList();

    return Column(
      children: [
        // Sub-filters for active orders and history
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          color: const Color(0xFF1A1A1A),
          child: Row(
            children: [
              Expanded(
                child: _buildFilterButton('Pesanan Baru', 0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterButton('Terselesaikan', 1),
              ),
            ],
          ),
        ),

        // List of filtered orders
        Expanded(
          child: _isOrdersLoading
              ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37))))
              : RefreshIndicator(
                  onRefresh: _refreshOrders,
                  color: const Color(0xFFD4AF37),
                  backgroundColor: const Color(0xFF1E1E1E),
                  child: filteredOrders.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _ordersFilter == 0 ? Icons.check_circle_outline : Icons.history,
                                    size: 60,
                                    color: Colors.grey.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _ordersFilter == 0 ? 'Semua pesanan sudah diselesaikan!' : 'Belum ada riwayat pesanan selesai.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(color: const Color(0xFFA0A0A0), fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = filteredOrders[index];
                            return _buildOrderCard(order);
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String label, int index) {
    final isActive = _ordersFilter == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _ordersFilter = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFD4AF37).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFFD4AF37) : const Color(0xFFA0A0A0),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header order card
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.id,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getTimeAgo(order.date),
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.status == 'Selesai'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: order.status == 'Selesai' ? Colors.green : Colors.amber,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    order.status == 'Selesai' ? 'Terselesaikan' : 'Pesanan Baru',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: order.status == 'Selesai' ? Colors.green : Colors.amber,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          // Customer details
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pelanggan:', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(
                            order.name,
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(order.phone, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0A0A0))),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Meja:', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            order.tableNumber,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xFFD4AF37),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pembayaran:', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(
                          order.paymentMethod == 'Digital' ? 'Digital (QRIS)' : 'Bayar di Kasir',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFF5F5F7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Note if present
                if (order.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.03)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Catatan:', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text(
                          '"${order.note}"',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFFE0E0E0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          // Items List
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daftar Pesanan:', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 8),
                ...order.items.map((item) {
                  // Custom variant details
                  List<String> options = [];
                  if (item.temp != null && item.temp!.isNotEmpty) options.add(item.temp!);
                  if (item.sugar != null && item.sugar!.isNotEmpty) options.add(item.sugar!);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.qty}x ',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37), fontSize: 13),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.baseName,
                                style: GoogleFonts.inter(color: const Color(0xFFF5F5F7), fontWeight: FontWeight.w500, fontSize: 13),
                              ),
                              if (options.isNotEmpty)
                                Text(
                                  '(${options.join(', ')})',
                                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          _formatPrice(item.price * item.qty),
                          style: GoogleFonts.inter(color: const Color(0xFFA0A0A0), fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          // Footer Total & Actions
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Pembayaran:', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      _formatPrice(order.total),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                  ],
                ),
                if (order.status != 'Selesai')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () => _completeOrder(order),
                    icon: const Icon(Icons.check, color: Color(0xFF121212), size: 18),
                    label: Text(
                      'Selesaikan',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF121212),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // VIEW 2: MENU VIEW
  Widget _buildMenuView() {
    return _isMenuLoading
        ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37))))
        : _menus.isEmpty
            ? Center(
                child: Text(
                  'Belum ada menu di database.\nKlik tombol + di bawah untuk menambahkan.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: const Color(0xFFA0A0A0)),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _menus.length,
                itemBuilder: (context, index) {
                  final item = _menus[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          item.imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.restaurant,
                            size: 50,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: GoogleFonts.playfairDisplay(
                                  fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFFF5F5F7)),
                            ),
                          ),
                          if (item.label != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: const Color(0xFFD4AF37), width: 0.5),
                              ),
                              child: Text(
                                item.label!,
                                style: GoogleFonts.inter(
                                    fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFD4AF37)),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            _formatPrice(item.price),
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFFD4AF37)),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                item.category,
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: item.isAvailable ? Colors.green : Colors.red,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.isAvailable ? 'Tersedia' : 'Habis',
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: item.isAvailable ? Colors.green : Colors.red),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Color(0xFFD4AF37)),
                            onPressed: () => _showFormDialog(menu: item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => _confirmDelete(item),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
  }
}
