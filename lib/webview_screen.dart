
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import untuk SystemNavigator
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:provider/provider.dart';
import 'package:exsamtro/app_state.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late InAppWebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    // Mengaktifkan mode kiosk/penguncian saat layar ini dimuat
    _enableKioskMode();
  }

  Future<void> _enableKioskMode() async {
    // Mencegah tangkapan layar dan mengunci aplikasi
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    // Menandai status kiosk di AppState jika diperlukan
    Provider.of<AppState>(context, listen: false).setKioskMode(true);
  }

  Future<void> _showExitDialog() async {
    bool? shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Pengguna harus memilih salah satu opsi
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Ujian?'),
        content: const Text('Aplikasi akan ditutup. Apakah Anda yakin ingin keluar dari sesi ujian ini?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Batal, tetap di aplikasi
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              // Saat "Keluar" ditekan, tutup aplikasi sepenuhnya
              SystemNavigator.pop();
            },
            child: const Text('Keluar & Tutup'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Mencegah pengguna menekan tombol kembali fisik di Android
      onWillPop: () async {
        if (await _webViewController.canGoBack()) {
          _webViewController.goBack();
          return false; // Tetap di dalam WebView
        }
        // Jika tidak ada halaman untuk kembali, tampilkan dialog keluar
        _showExitDialog();
        return false; // Jangan keluar secara otomatis
      },
      child: Scaffold(
        body: SafeArea(
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialOptions: InAppWebViewGroupOptions(
              crossPlatform: InAppWebViewOptions(
                useShouldOverrideUrlLoading: true,
                mediaPlaybackRequiresUserGesture: false,
              ),
              android: AndroidInAppWebViewOptions(
                useHybridComposition: true,
              ),
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            // Menambahkan deteksi URL untuk logout
            onLoadStop: (controller, url) {
              // Ganti 'url_logout_anda' dengan URL spesifik yang menandakan logout
              if (url.toString().contains('logout')) {
                  _showExitDialog();
              }
            },
            androidOnPermissionRequest: (controller, origin, resources) async {
              return PermissionRequestResponse(
                resources: resources,
                action: PermissionRequestResponseAction.GRANT,
              );
            },
          ),
        ),
      ),
    );
  }
}
