import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/cart_controller.dart';
import 'home_screen.dart';
import 'menu_screen.dart';
import 'checkout_screen.dart';
import 'about_screen.dart';
import 'location_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final CartController _cartController = CartController();
  int _currentIndex = 0;
  String? _trackerPrefilledId;

  // Waiter Modal Options
  void _openWaiterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Panggil Pelayan',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Pilih alasan Anda memanggil pelayan:',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFFA0A0A0),
                  ),
                ),
                const SizedBox(height: 24),
                // Options Grid
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  childAspectRatio: 1.6,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _waiterOptionButton(context, '🙋‍♂️ Bantuan'),
                    _waiterOptionButton(context, '🧹 Bersihkan Meja'),
                    _waiterOptionButton(context, '💵 Mau Bayar'),
                    _waiterOptionButton(context, '💬 Lainnya'),
                  ],
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _waiterOptionButton(BuildContext context, String title) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.04),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        padding: const EdgeInsets.all(8),
      ),
      onPressed: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFD4AF37),
            content: Text(
              'Panggilan terkirim: "$title". Pelayan akan segera datang!',
              style: GoogleFonts.inter(color: const Color(0xFF121212), fontWeight: FontWeight.w600),
            ),
          ),
        );
      },
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(onExploreMenu: () {
        setState(() {
          _currentIndex = 1; // Switch to Menu
        });
      }),
      const MenuScreen(),
      CheckoutScreen(onOrderCompleted: (orderId) {
        setState(() {
          _currentIndex = 1; // Switch to Menu Screen
        });
      }),
      const AboutScreen(),
      const LocationScreen(),
    ];

    return AnimatedBuilder(
      animation: _cartController,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xFFD4AF37),
            foregroundColor: const Color(0xFF121212),
            shape: const CircleBorder(),
            elevation: 8,
            onPressed: _openWaiterDialog,
            child: const Icon(Icons.notifications_active, size: 28),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.10),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home, 'Beranda'),
                  _buildNavItem(1, Icons.restaurant_menu, 'Menu'),
                  _buildNavItem(
                    2,
                    Icons.shopping_cart,
                    'Pesanan',
                    badgeCount: _cartController.totalCount,
                  ),
                  _buildNavItem(3, Icons.info_outline, 'Tentang'),
                  _buildNavItem(4, Icons.location_on, 'Alamat'),
                ],
              ),
            ),
          ),
          body: screens[_currentIndex],
        );
      },
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {int badgeCount = 0}) {
    final isActive = _currentIndex == index;
    final color = isActive ? const Color(0xFFD4AF37) : const Color(0xFFA0A0A0);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Icon translation on active (simulate translateY in CSS)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.translationValues(0, isActive ? -2 : 0, 0),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                // Badge count for Cart
                if (badgeCount > 0)
                  Positioned(
                    top: -6,
                    right: -10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD4AF37),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Center(
                        child: Text(
                          badgeCount.toString(),
                          style: const TextStyle(
                            color: Color(0xFF121212),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            // active indicator line (simulate active::after in CSS)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isActive ? 12 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37),
                borderRadius: BorderRadius.circular(2),
                boxShadow: isActive
                    ? [
                        const BoxShadow(
                          color: Color(0xFFD4AF37),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ]
                    : [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
