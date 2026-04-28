
import 'package:flutter/material.dart';
import 'package:exsamtro/home_page.dart';
import 'package:exsamtro/qr_scanner_screen.dart';

class ChoiceScreen extends StatelessWidget {
  const ChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade800, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Menggunakan logo header baru
                Image.asset(
                  'assets/images/header_logo.png',
                  // Mengatur lebar agar pas dan tidak terlalu besar
                  width: MediaQuery.of(context).size.width * 0.9,
                ),
                const SizedBox(height: 80),
                _buildChoiceButton(
                  context,
                  icon: Icons.text_fields_rounded,
                  label: 'Input URL Ujian',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MyHomePage()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildChoiceButton(
                  context,
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Pindai Kode QR',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceButton(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onPressed}) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 24),
      label: Text(label),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.blue.shade800,
        backgroundColor: Colors.white,
        minimumSize: const Size(280, 60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        elevation: 5,
      ),
    );
  }
}
