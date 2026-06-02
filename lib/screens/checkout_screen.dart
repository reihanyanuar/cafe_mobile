import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/cart_controller.dart';
import '../services/database_helper.dart';
import '../models/order_model.dart';

class CheckoutScreen extends StatefulWidget {
  final Function(String orderId) onOrderCompleted;

  const CheckoutScreen({super.key, required this.onOrderCompleted});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartController _cartController = CartController();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _selectedTable = '';
  String _selectedPayment = 'Digital'; // Digital or Kasir

  final List<String> _tableList = List.generate(10, (index) => "Meja ${index + 1}");

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submitOrder() {
    if (_cartController.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            'Keranjang belanja Anda kosong!',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate() && _selectedTable.isNotEmpty) {
      final cartItems = List<CartItem>.from(_cartController.items);
      final totalPrice = _cartController.totalPrice;

      final orderId = _cartController.submitOrder(
        name: _nameController.text,
        phone: _phoneController.text,
        note: _noteController.text,
        tableNumber: _selectedTable,
        paymentMethod: _selectedPayment,
      );

      // Save to local SQLite
      final newOrder = OrderModel(
        id: orderId,
        date: DateTime.now(),
        name: _nameController.text,
        phone: _phoneController.text,
        note: _noteController.text,
        tableNumber: _selectedTable,
        paymentMethod: _selectedPayment,
        items: cartItems,
        total: totalPrice,
        status: 'Pending',
      );
      DatabaseHelper().insertOrder(newOrder);

      // Show beautiful success dialog mimicking SweetAlert
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  // Green check circle
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Color(0x1AD4AF37),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFFD4AF37),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Pesanan Dibuat!',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF5F5F7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pesanan Anda berhasil dikirim.\nID Pesanan: $orderId',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFA0A0A0),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      widget.onOrderCompleted(orderId); // Navigate to Lacak screen
                    },
                    child: Text(
                      'Kembali ke Menu',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF121212),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else if (_selectedTable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            'Silakan pilih nomor meja Anda!',
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _cartController,
      builder: (context, _) {
        final items = _cartController.items;
        final total = _cartController.totalPrice;

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Checkout Pesanan',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF5F5F7),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 1. Cart Listing Section
                    if (items.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.04)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.shopping_cart_outlined, size: 50, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              'Keranjang belanja kosong',
                              style: GoogleFonts.inter(color: const Color(0xFFA0A0A0)),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white.withOpacity(0.04)),
                            ),
                            child: Row(
                              children: [
                                // Item Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.asset(
                                    item.image,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.restaurant,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Item Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFF5F5F7),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Rp ${(item.price).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]}.")}',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: const Color(0xFFD4AF37),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Quantity control
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 18, color: Color(0xFFD4AF37)),
                                      onPressed: () => _cartController.updateQty(item.id, -1),
                                    ),
                                    Text(
                                      item.qty.toString(),
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18, color: Color(0xFFD4AF37)),
                                      onPressed: () => _cartController.updateQty(item.id, 1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),

                    // 2. Personal Info Inputs
                    Text(
                      'Detail Pemesan',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF5F5F7),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Color(0xFFF5F5F7)),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nama wajib diisi';
                        }
                        return null;
                      },
                      decoration: _inputDecoration('Nama Lengkap', 'Masukkan nama Anda...'),
                    ),
                    const SizedBox(height: 16),

                    // WhatsApp
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Color(0xFFF5F5F7)),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nomor WhatsApp wajib diisi';
                        }
                        return null;
                      },
                      decoration: _inputDecoration('No. Telepon / WhatsApp', '08xxxxxxxxxx'),
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _noteController,
                      maxLines: 2,
                      style: const TextStyle(color: Color(0xFFF5F5F7)),
                      decoration: _inputDecoration('Catatan (Opsional)', 'Contoh: es sedikit, gula normal...'),
                    ),
                    const SizedBox(height: 16),

                    // Table Selector Dropdown
                    DropdownButtonFormField<String>(
                      dropdownColor: const Color(0xFF1E1E1E),
                      style: const TextStyle(color: Color(0xFFF5F5F7)),
                      value: _selectedTable.isEmpty ? null : _selectedTable,
                      decoration: _inputDecoration('Nomor Meja', '-- Pilih Meja --'),
                      items: _tableList.map((table) {
                        return DropdownMenuItem<String>(
                          value: table,
                          child: Text(table),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedTable = val ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // 3. Payment Method
                    Text(
                      'Metode Pembayaran',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF5F5F7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _paymentPill('Digital', Icons.qr_code_2, 'Bayar Sekarang'),
                        const SizedBox(width: 12),
                        _paymentPill('Kasir', Icons.payments, 'Bayar di Kasir'),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Total & Order Button
                    if (items.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Pembayaran',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFA0A0A0),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Rp ${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]}.")}',
                            style: GoogleFonts.inter(
                              color: const Color(0xFFD4AF37),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          onPressed: _submitOrder,
                          child: Text(
                            'Selesaikan Pesanan',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: const Color(0xFF121212),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String labelText, String hintText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: GoogleFonts.inter(color: const Color(0xFFD4AF37), fontSize: 13),
      hintText: hintText,
      hintStyle: GoogleFonts.inter(color: const Color(0xFFA0A0A0), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4AF37)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  Widget _paymentPill(String value, IconData icon, String label) {
    final isSelected = _selectedPayment == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPayment = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.1) : const Color(0xFF1E1E1E),
            border: Border.all(
              color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.05),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFFA0A0A0)),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFFA0A0A0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
