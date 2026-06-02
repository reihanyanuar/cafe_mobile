import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/cart_controller.dart';
import '../services/database_helper.dart';
import '../models/menu_model.dart';

class MenuItemModel {
  final String name;
  final int price;
  final String category;
  final String imageUrl;
  final String? label;
  final bool isAvailable;

  MenuItemModel({
    required this.name,
    required this.price,
    required this.category,
    required this.imageUrl,
    this.label,
    this.isAvailable = true,
  });
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final CartController _cartController = CartController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  void _openCustomization(BuildContext context, MenuItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DrinkCustomizerBottomSheet(
          item: item,
          onAddToCart: (temp, sugar, qty) {
            _cartController.addItem(
              baseName: item.name,
              image: item.imageUrl,
              price: item.price,
              qty: qty,
              temp: temp,
              sugar: sugar,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFFD4AF37),
                content: Text(
                  '${item.name} berhasil ditambahkan ke keranjang!',
                  style: GoogleFonts.inter(color: const Color(0xFF121212), fontWeight: FontWeight.w600),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }

  int _getItemCartCount(String baseName) {
    int total = 0;
    for (var item in _cartController.items) {
      if (item.baseName == baseName) {
        total += item.qty;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MenuModel>>(
      future: _dbHelper.getMenus(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF121212),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Gagal memuat menu: ${snapshot.error}',
                  style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
              ),
            ),
          );
        }

        final dbMenus = snapshot.data!;
        // Map database MenuModels to UI MenuItemModels (only available items)
        final menuItems = dbMenus
            .where((m) => m.isAvailable)
            .map((m) => MenuItemModel(
                  name: m.name,
                  price: m.price,
                  category: m.category,
                  imageUrl: m.imageUrl,
                  label: m.label,
                  isAvailable: m.isAvailable,
                ))
            .toList();

        // Perform filtering dynamically
        final filteredItems = menuItems.where((item) {
          final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
          final matchesSearch = item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              item.category.toLowerCase().contains(_searchQuery.toLowerCase());
          return matchesCategory && matchesSearch;
        }).toList();

        return AnimatedBuilder(
          animation: _cartController,
          builder: (context, _) {
            return Scaffold(
              backgroundColor: const Color(0xFF121212),
              body: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Our Premium Menu',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF5F5F7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: TextField(
                          style: const TextStyle(color: Color(0xFFF5F5F7)),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari menu favoritmu...',
                            hintStyle: GoogleFonts.inter(color: const Color(0xFFA0A0A0)),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Category Selectors
                SizedBox(
                  height: 55,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: ['All', 'Makanan', 'Minuman', 'Dessert'].map((cat) {
                      final isActive = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isActive,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                          labelStyle: GoogleFonts.inter(
                            color: isActive ? const Color(0xFF121212) : const Color(0xFFA0A0A0),
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          ),
                          selectedColor: const Color(0xFFD4AF37),
                          backgroundColor: const Color(0xFF1E1E1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Colors.transparent),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // 3. Grid View
                Expanded(
                  child: filteredItems.isEmpty
                      ? Center(
                          child: Text(
                            'Menu tidak ditemukan',
                            style: GoogleFonts.inter(color: const Color(0xFFA0A0A0)),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(20),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final cartQty = _getItemCartCount(item.name);
                            return GestureDetector(
                              onTap: () => _openCustomization(context, item),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E1E),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.04),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Product Image
                                          Expanded(
                                            child: Image.asset(
                                              item.imageUrl,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => const Center(
                                                child: Icon(Icons.restaurant, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                          // Details
                                          Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: GoogleFonts.playfairDisplay(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(0xFFF5F5F7),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Rp ${item.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]}.")}',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 14,
                                                    color: const Color(0xFFD4AF37),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Label Ribbon
                                      if (item.label != null)
                                        Positioned(
                                          top: 10,
                                          left: 10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD4AF37),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.label!,
                                              style: GoogleFonts.inter(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xFF121212),
                                              ),
                                            ),
                                          ),
                                        ),

                                      // Cart Count Badge
                                      if (cartQty > 0)
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: Container(
                                            width: 26,
                                            height: 26,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFD4AF37),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                cartQty.toString(),
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(0xFF121212),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
            );
          },
        );
      },
    );
  }
}

// Customization Bottom Sheet Widget
class DrinkCustomizerBottomSheet extends StatefulWidget {
  final MenuItemModel item;
  final Function(String? temp, String? sugar, int qty) onAddToCart;

  const DrinkCustomizerBottomSheet({
    super.key,
    required this.item,
    required this.onAddToCart,
  });

  @override
  State<DrinkCustomizerBottomSheet> createState() => _DrinkCustomizerBottomSheetState();
}

class _DrinkCustomizerBottomSheetState extends State<DrinkCustomizerBottomSheet> {
  String _selectedTemp = 'Ice';
  String _selectedSugar = 'Normal';
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final isDrink = widget.item.category == 'Minuman';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header Info
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  widget.item.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.restaurant,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF5F5F7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rp ${widget.item.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]}.")}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: const Color(0xFFD4AF37),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Variants Section (Only for drinks)
          if (isDrink) ...[
            // Temperature Selection
            Text(
              'Suhu',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF5F5F7),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['Ice', 'Hot'].map((temp) {
                final isSelected = _selectedTemp == temp;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.1),
                        ),
                        backgroundColor: isSelected
                            ? const Color(0xFFD4AF37).withOpacity(0.1)
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedTemp = temp;
                        });
                      },
                      child: Text(
                        temp,
                        style: GoogleFonts.inter(
                          color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFFA0A0A0),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Sugar Selection
            Text(
              'Tingkat Gula',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF5F5F7),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                'Normal',
                'Less Sugar',
                'No Sugar',
              ].map((sugar) {
                final isSelected = _selectedSugar == sugar;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.1),
                        ),
                        backgroundColor: isSelected
                            ? const Color(0xFFD4AF37).withOpacity(0.1)
                            : Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedSugar = sugar;
                        });
                      },
                      child: Text(
                        sugar,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFFA0A0A0),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            Center(
              child: Text(
                'Tidak ada kustomisasi untuk menu ini.',
                style: GoogleFonts.inter(
                  color: const Color(0xFFA0A0A0),
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
              ),
            ),
          ],
          const SizedBox(height: 30),

          // Footer Total & Add Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Quantity Controls
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, color: Color(0xFFD4AF37)),
                      onPressed: () {
                        if (_qty > 1) {
                          setState(() {
                            _qty--;
                          });
                        }
                      },
                    ),
                    Text(
                      _qty.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Color(0xFFD4AF37)),
                      onPressed: () {
                        setState(() {
                          _qty++;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Add Button
              GestureDetector(
                onTap: () {
                  widget.onAddToCart(
                    isDrink ? _selectedTemp : null,
                    isDrink ? _selectedSugar : null,
                    _qty,
                  );
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    'Tambah - Rp ${(widget.item.price * _qty).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]}.")}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF121212),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
