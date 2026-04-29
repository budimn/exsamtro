
import 'package:flutter/material.dart';
import 'package:exsamtro/webview_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pindai Kode QR Ujian'),
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white), // Ikon statis
            tooltip: 'Nyalakan Senter',
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white), // Ikon statis
            tooltip: 'Ganti Kamera',
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(
        controller: _scannerController,
        onDetect: (capture) {
          if (_isProcessing) return;
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? rawUrl = barcodes.first.rawValue;
            if (rawUrl != null && rawUrl.length > 4) {
              // Membuang 4 karakter terakhir dari URL
              final String finalUrl = rawUrl.substring(0, rawUrl.length - 4);

              if (finalUrl.startsWith('http://') || finalUrl.startsWith('https://')) {
                setState(() {
                  _isProcessing = true;
                });
                _scannerController.stop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WebViewScreen(url: finalUrl),
                  ),
                ).then((_) => setState(() => _isProcessing = false));
              }
            }
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }
}
