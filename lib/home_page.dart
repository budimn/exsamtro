
import 'package:flutter/material.dart';
import 'package:exsamtro/webview_screen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Input URL Ujian'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'Masukkan URL Ujian dengan Kode Unik',
                  hintText: 'https://.../ujianABCD',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.link),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  String url = _controller.text.trim();
                  if (url.length > 4) {
                    // Membuang 4 karakter terakhir dari URL
                    String finalUrl = url.substring(0, url.length - 4);

                    if (finalUrl.isNotEmpty && (finalUrl.startsWith('http://') || finalUrl.startsWith('https://'))) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WebViewScreen(url: finalUrl),
                        ),
                      );
                    } else {
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('URL setelah diproses tidak valid. Periksa kembali URL Anda.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('URL terlalu pendek. Harap masukkan URL yang benar.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Mulai Ujian',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
