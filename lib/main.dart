import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Channel untuk komunikasi dengan Android native (lock task)
const MethodChannel _channel = MethodChannel('exambro/lock');

void main() {
  // Pastikan binding Flutter sudah siap sebelum menjalankan kode async di main
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ExamBroApp());
}

class ExamBroApp extends StatelessWidget {
  const ExamBroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ExamBro',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

// -----------------------------
// Halaman Awal – Input URL / Scan QR
// -----------------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController urlController = TextEditingController();
  bool isPenaltyActive = false;
  int penaltySeconds = 0;

  @override
  void initState() {
    super.initState();
    _checkPenalty();
  }

  Future<void> _checkPenalty() async {
    // Panggil Navigator.of(context) di dalam try-catch atau setelah frame pertama
    // untuk menghindari error "Looking up a deactivated widget's ancestor".
    // Menggunakan addPostFrameCallback adalah solusi yang aman.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      int penaltyUntil = prefs.getInt('penalty_until') ?? 0;
      int now = DateTime.now().millisecondsSinceEpoch;

      if (now < penaltyUntil) {
        setState(() {
          isPenaltyActive = true;
          penaltySeconds = ((penaltyUntil - now) / 1000).ceil();
        });
        // Pastikan context masih valid sebelum navigasi
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => PenaltyPage(secondsRemaining: penaltySeconds),
            ),
          );
        }
      }
    });
  }

  void _startExam(String url) {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL tidak boleh kosong')),
      );
      return;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExamPage(examUrl: url)),
    );
  }

  Future<void> _scanQR() async {
    // Hasil dari QRScannerPage adalah sebuah String.
    // Jadi, kita harus mengharapkan `String?` dari Navigator.push.
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const QRScannerPage(),
      ),
    );
    // Jika result tidak null (user tidak membatalkan), isi controllernya.
    if (result != null) {
      urlController.text = result;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ExamBro - Mulai Ujian')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'URL Google Form',
                hintText: 'https://forms.gle/...',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _startExam(urlController.text.trim()),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('Buka Ujian'),
                ),
                ElevatedButton.icon(
                  onPressed: _scanQR,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan QR'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// -----------------------------
// Scanner QR sederhana
// -----------------------------
class QRScannerPage extends StatelessWidget {
  const QRScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arahkan ke QR Code')),
      body: MobileScanner(
        onDetect: (capture) {
          if (capture.barcodes.isNotEmpty) {
            final value = capture.barcodes.first.rawValue;
            if (value != null && value.isNotEmpty) {
              // Kembali dengan hasil scan (String)
              Navigator.of(context).pop(value);
            }
          }
        },
      ),
    );
  }
}

// -----------------------------
// Halaman Ujian – WebView + Lock Task
// -----------------------------
class ExamPage extends StatefulWidget {
  final String examUrl;
  const ExamPage({super.key, required this.examUrl});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

// Gunakan WidgetsBindingObserver untuk mendeteksi siklus hidup aplikasi
class _ExamPageState extends State<ExamPage> with WidgetsBindingObserver {
  late final WebViewController controller;
  bool isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    // Tambahkan observer siklus hidup
    WidgetsBinding.instance.addObserver(this);

    // Tandai sesi ujian aktif
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('session_active', true);
    });

    // Minta kunci perangkat
    _lockDevice();

    // Setup WebView
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            // Injeksi JS setelah halaman selesai dimuat jika perlu
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.examUrl));
  }

  @override
  void dispose() {
    // Hapus observer saat widget dibuang
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Deteksi jika pengguna mencoba meninggalkan aplikasi (misal, buka notifikasi)
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _handleAppExit();
    }
  }

  Future<void> _handleAppExit() async {
    final prefs = await SharedPreferences.getInstance();
    // Hanya terapkan penalti jika bukan karena logout sah
    if (prefs.getBool('session_active') == true) {
      // Atur penalti: waktu sekarang + 1 menit
      int penaltyUntil = DateTime.now().add(const Duration(minutes: 1)).millisecondsSinceEpoch;
      await prefs.setInt('penalty_until', penaltyUntil);
    }
  }

  Future<void> _lockDevice() async {
    try {
      if (mounted) await _channel.invokeMethod('startLockTask');
    } catch (e) {
      debugPrint('Lock task error: $e');
    }
  }

  Future<void> _logoutSah() async {
    if (isLoggingOut) return;
    setState(() => isLoggingOut = true);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('session_active', false); // Tandai logout sah

    try {
      if (mounted) await _channel.invokeMethod('stopLockTask');
    } catch (_) {}

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // PopScope digantikan oleh canPop (di Flutter versi baru) dan onPopInvoked
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        // Jika didPop true, artinya ada upaya pop yang tidak terduga.
        // Bisa terapkan penalti di sini jika perlu.
        if (didPop) return;
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: controller),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton.extended(
                  onPressed: _logoutSah,
                  label: const Text('Serahkan & Keluar'),
                  icon: const Icon(Icons.exit_to_app),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------
// Halaman Penalti
// -----------------------------
class PenaltyPage extends StatefulWidget {
  final int secondsRemaining;
  const PenaltyPage({super.key, required this.secondsRemaining});

  @override
  State<PenaltyPage> createState() => _PenaltyPageState();
}

class _PenaltyPageState extends State<PenaltyPage> {
  late int _seconds;
  bool _canProceed = false;

  @override
  void initState() {
    super.initState();
    _seconds = widget.secondsRemaining;
    _startCountdown();
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else {
          _canProceed = true;
        }
      });
      return _seconds > 0 && mounted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Penalti'), automaticallyImplyLeading: false),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, size: 80, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'Anda terdeteksi keluar tanpa menyelesaikan sesi dengan benar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sisa waktu tunggu: $_seconds detik',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                if (_canProceed)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const HomePage()),
                      );
                    },
                    child: const Text('Kembali ke Halaman Utama'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
