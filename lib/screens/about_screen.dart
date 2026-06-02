import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Logo Icon
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E1E1E),
                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.05),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_cafe,
                      size: 75,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Main Heading
                Text(
                  'STAR COFFEE',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: const Color(0xFFF5F5F7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Premium Coffee Experience',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.0,
                    color: const Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(height: 32),

                // Description Paragraphs
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.04)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Star Coffee hadir sebagai ruang premium bagi para penikmat kopi yang mencari kualitas, kenyamanan, dan elegansi. Kami menyajikan racikan biji kopi pilihan terbaik, diroasting dengan cermat oleh para ahli untuk menghasilkan profil rasa yang sempurna.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.6,
                          color: const Color(0xFFF5F5F7),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Dengan interior bergaya modern eksklusif, musik ambient yang menenangkan, serta pelayanan bertaraf internasional, kami berdedikasi untuk memberikan momen bersantai dan bekerja yang tak terlupakan bagi setiap tamu kami.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.6,
                          color: const Color(0xFFA0A0A0),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Bottom footer branding details
                Text(
                  '© 2026 Star Coffee. All Rights Reserved.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white24,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
