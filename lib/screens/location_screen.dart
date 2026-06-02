import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lokasi Star Coffee',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFF5F5F7),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Kunjungi kami dan nikmati suasana premium bersama teman atau keluarga.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFFA0A0A0),
                ),
              ),
              const SizedBox(height: 24),

              // 1. Mock Stylized Dark Mode Map Widget
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                  image: const DecorationImage(
                    image: AssetImage(
                      'assets/images/tempat.png',
                    ),
                    fit: BoxFit.cover,
                    opacity: 0.25,
                  ),
                ),
                child: Stack(
                  children: [
                    // Grid pattern overlay lines (simulating map grid)
                    Positioned.fill(
                      child: GridPaper(
                        color: Colors.white.withOpacity(0.01),
                        divisions: 1,
                        subdivisions: 1,
                        interval: 100,
                      ),
                    ),
                    // Centered Gold Marker with Pulse Ring
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFFD4AF37),
                              size: 36,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121212),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                            ),
                            child: Text(
                              'Star Coffee Lumajang',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF5F5F7),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    // Map controls mockup
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF121212),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.navigation_outlined, size: 12, color: Color(0xFFD4AF37)),
                                const SizedBox(width: 4),
                                Text(
                                  'Petunjuk Arah',
                                  style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Info Boxes
              // Box A: Detail Alamat
              _buildInfoCard(
                icon: Icons.map_outlined,
                title: 'Detail Alamat',
                lines: [
                  'Alun Alun, Lumajang Kota',
                  'Jawa Timur, Indonesia',
                ],
              ),
              const SizedBox(height: 16),

              // Box B: Jam Operasional
              _buildInfoCard(
                icon: Icons.access_time,
                title: 'Jam Operasional',
                lines: [
                  'Senin - Jumat:  08.00 - 22.00',
                  'Sabtu - Minggu: 09.00 - 23.00',
                ],
              ),
              const SizedBox(height: 16),

              // Box C: Layanan Reservasi
              _buildInfoCard(
                icon: Icons.phone_android_outlined,
                title: 'Layanan Reservasi',
                lines: [
                  'WhatsApp: 0812-3456-7890',
                  'Email: hello@starcoffee.id',
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<String> lines,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFFD4AF37),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF5F5F7),
                  ),
                ),
                const SizedBox(height: 8),
                ...lines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      line,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFFA0A0A0),
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
