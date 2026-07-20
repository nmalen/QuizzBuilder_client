import 'dart:async';

import 'package:flutter/material.dart';

import '../services/connectivity_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _service;
  StreamSubscription<bool>? _subscription;
  bool _isOnline = true;

  ConnectivityProvider({ConnectivityService? service})
      : _service = service ?? ConnectivityService() {
    _init();
  }

  bool get isOnline => _isOnline;

  Future<void> _init() async {
    _isOnline = await _service.isOnline();
    notifyListeners();
    _subscription = _service.onStatusChange.listen((online) {
      if (_isOnline == online) return;
      _isOnline = online;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
