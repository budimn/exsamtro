
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
            icon: ValueListenableBuilder(
              valueListenable: _scannerController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => _scannerController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _scannerController.cameraFacingState,
              builder: (context, state, child) {
                return state == CameraFacing.front
                    ? const Icon(Icons.camera_front)
                    : const Icon(Icons.camera_rear);
              },
            ),
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
                Navigator.pop(context); // Kembali dari scanner
                Navigator.pushReplacement( // Ganti ke halaman webview
                  context,
                  MaterialPageRoute(
                    builder: (context) => WebViewScreen(url: finalUrl),
                  ),
                );
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
