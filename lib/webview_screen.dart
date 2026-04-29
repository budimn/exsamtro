
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import untuk SystemNavigator
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:flutter_windowmanager/flutter_windowmanager.dart'; // Dinonaktifkan sementara
import 'package:provider/provider.dart';
import 'package:exsamtro/app_state.dart';

class WebViewScreen extends StatefulWidget {
  final String url;
  const WebViewScreen({super.key, required this.url});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

// Menambahkan WidgetsBindingObserver untuk mendeteksi siklus hidup aplikasi
class _WebViewScreenState extends State<WebViewScreen> with WidgetsBindingObserver {
  InAppWebViewController? _webViewController;
  bool _isDialogShowing = false; // Flag untuk mencegah dialog ganda

  @override
  void initState() {
    super.initState();
    // Menambahkan observer
    WidgetsBinding.instance.addObserver(this);
    // Mengaktifkan mode kiosk/penguncian saat layar ini dimuat
    _enableKioskMode();
  }

  @override
  void dispose() {
    // Menghapus observer untuk mencegah memory leak
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Metode ini dipanggil setiap kali status siklus hidup aplikasi berubah
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Jika pengguna keluar dari aplikasi (mis. menekan home)
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Tampilkan dialog hanya jika belum ada dialog yang tampil
      if (!_isDialogShowing) {
        _showExitDialog();
      }
    }
  }

  Future<void> _enableKioskMode() async {
    // Mencegah tangkapan layar dan mengunci aplikasi
    // await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE); // Dinonaktifkan sementara
    Provider.of<AppState>(context, listen: false).setKioskMode(true);
  }

  Future<void> _showExitDialog() async {
    setState(() {
      _isDialogShowing = true; // Tandai bahwa dialog sedang ditampilkan
    });
    
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Ujian?'),
        content: const Text('Aplikasi akan ditutup. Apakah Anda yakin ingin keluar dari sesi ujian ini?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Tutup dialog
              setState(() {
                _isDialogShowing = false; // Tandai dialog sudah ditutup
              });
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              // Tutup aplikasi sepenuhnya
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
    // Menggunakan PopScope sebagai pengganti WillPopScope yang deprecated
    return PopScope(
      canPop: false, // Mencegah pop default, kita akan menanganinya secara manual
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          return;
        }
        if (_webViewController != null && await _webViewController!.canGoBack()) {
          _webViewController!.goBack();
        } else if (!_isDialogShowing) {
          _showExitDialog();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            // Menggunakan initialSettings sebagai pengganti initialOptions
            initialSettings: InAppWebViewSettings(
              useShouldOverrideUrlLoading: true,
              mediaPlaybackRequiresUserGesture: false,
              useHybridComposition: true,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStop: (controller, url) {
              if (url != null && url.toString().contains('logout')) {
                if (!_isDialogShowing) {
                  _showExitDialog();
                }
              }
            },
            // Menggunakan onPermissionRequest sebagai pengganti androidOnPermissionRequest
            onPermissionRequest: (controller, request) async {
              // Menggunakan PermissionResponse dan PermissionResponseAction
              return PermissionResponse(
                resources: request.resources,
                action: PermissionResponseAction.GRANT,
              );
            },
          ),
        ),
      ),
    );
  }
}
