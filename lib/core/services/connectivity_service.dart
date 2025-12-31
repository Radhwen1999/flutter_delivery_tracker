import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

enum NetworkStatus { online, offline, unknown }

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  final _statusController = BehaviorSubject<NetworkStatus>.seeded(NetworkStatus.unknown);
  
  Stream<NetworkStatus> get statusStream => _statusController.stream;
  NetworkStatus get currentStatus => _statusController.value;
  bool get isOnline => _statusController.value == NetworkStatus.online;

  ConnectivityService() {
    _initialize();
  }

  void _initialize() {
    _checkInitialConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
    } catch (e) {
      debugPrint('🌐 Connectivity: Error checking initial status: $e');
      _statusController.add(NetworkStatus.unknown);
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    NetworkStatus status;
    
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      status = NetworkStatus.offline;
    } else {
      status = NetworkStatus.online;
    }
    
    if (_statusController.value != status) {
      _statusController.add(status);
      debugPrint('🌐 Connectivity: ${status.name}');
    }
  }

  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return !results.contains(ConnectivityResult.none) && results.isNotEmpty;
    } catch (e) {
      debugPrint('🌐 Connectivity: Error: $e');
      return false;
    }
  }

  String getConnectionType(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) {
      return 'WiFi';
    } else if (results.contains(ConnectivityResult.mobile)) {
      return 'Mobile Data';
    } else if (results.contains(ConnectivityResult.ethernet)) {
      return 'Ethernet';
    } else if (results.contains(ConnectivityResult.vpn)) {
      return 'VPN';
    } else if (results.contains(ConnectivityResult.bluetooth)) {
      return 'Bluetooth';
    } else if (results.contains(ConnectivityResult.other)) {
      return 'Other';
    }
    return 'None';
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
