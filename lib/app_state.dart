
import 'package:flutter/foundation.dart';

class AppState with ChangeNotifier {
  bool _isKioskMode = false;

  bool get isKioskMode => _isKioskMode;

  void setKioskMode(bool value) {
    _isKioskMode = value;
    notifyListeners();
  }
}
