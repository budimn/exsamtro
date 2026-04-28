import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:exsamtro/app_state.dart';
import 'package:exsamtro/choice_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'EXSAMTro',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const ChoiceScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
