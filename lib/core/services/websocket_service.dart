import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ConnectionStatus { connected, connecting, disconnected, error }

class WebSocketMessage {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  WebSocketMessage({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
      };
}

class WebSocketService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  Timer? _simulationTimer;
  
  final _messageController = BehaviorSubject<WebSocketMessage>();
  final _statusController = BehaviorSubject<ConnectionStatus>.seeded(ConnectionStatus.disconnected);
  final _driverLocationsController = BehaviorSubject<List<Map<String, dynamic>>>.seeded([]);
  
  Stream<WebSocketMessage> get messages => _messageController.stream;
  Stream<ConnectionStatus> get status => _statusController.stream;
  Stream<List<Map<String, dynamic>>> get driverLocations => _driverLocationsController.stream;
  
  ConnectionStatus get currentStatus => _statusController.value;
  
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  // Supabase Realtime for production use
  RealtimeChannel? _supabaseChannel;

  void connect({String? wsUrl}) {
    _statusController.add(ConnectionStatus.connecting);
    
    // For demo purposes, we'll simulate WebSocket with local data
    // In production, uncomment the real WebSocket connection
    _simulateConnection();
    
    // Real WebSocket connection (uncomment for production)
    // _connectToWebSocket(wsUrl ?? 'wss://your-websocket-server.com');
  }

  void _simulateConnection() {
    _statusController.add(ConnectionStatus.connected);
    _startHeartbeat();
    _startSimulation();
    
    debugPrint('🔌 WebSocket: Simulated connection established');
  }

  void _connectToWebSocket(String url) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      
      _channel!.stream.listen(
        (message) => _handleMessage(message),
        onDone: () => _handleDisconnect(),
        onError: (error) => _handleError(error),
      );
      
      _statusController.add(ConnectionStatus.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();
      
      debugPrint('🔌 WebSocket: Connected to $url');
    } catch (e) {
      _handleError(e);
    }
  }

  void connectToSupabaseRealtime() {
    final supabase = Supabase.instance.client;
    
    _supabaseChannel = supabase.channel('drivers')
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'drivers',
        callback: (payload) {
          _messageController.add(WebSocketMessage(
            type: 'driver_location_update',
            data: payload.newRecord,
          ));
        },
      )
      ..subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _statusController.add(ConnectionStatus.connected);
          debugPrint('🔌 Supabase Realtime: Subscribed to drivers channel');
        } else if (status == RealtimeSubscribeStatus.closed) {
          _statusController.add(ConnectionStatus.disconnected);
        }
      });
  }

  void _startSimulation() {
    // Initialize simulated drivers around Tunis, Tunisia
    final simulatedDrivers = [
      {
        'id': 'driver_1',
        'name': 'Ahmed Ben Salem',
        'avatar': 'https://i.pravatar.cc/150?u=driver1',
        'phone': '+216 98 123 456',
        'vehicle': 'Toyota Hilux',
        'plate': '123 TN 4567',
        'status': 'available',
        'latitude': 36.8065,
        'longitude': 10.1815,
        'heading': 45.0,
        'speed': 0.0,
        'rating': 4.8,
        'completedOrders': 156,
      },
      {
        'id': 'driver_2',
        'name': 'Youssef Trabelsi',
        'avatar': 'https://i.pravatar.cc/150?u=driver2',
        'phone': '+216 97 234 567',
        'vehicle': 'Renault Kangoo',
        'plate': '456 TN 7890',
        'status': 'busy',
        'latitude': 36.8189,
        'longitude': 10.1657,
        'heading': 90.0,
        'speed': 35.0,
        'rating': 4.9,
        'completedOrders': 243,
      },
      {
        'id': 'driver_3',
        'name': 'Mohamed Gharbi',
        'avatar': 'https://i.pravatar.cc/150?u=driver3',
        'phone': '+216 96 345 678',
        'vehicle': 'Peugeot Partner',
        'plate': '789 TN 1234',
        'status': 'available',
        'latitude': 36.7955,
        'longitude': 10.1880,
        'heading': 180.0,
        'speed': 0.0,
        'rating': 4.7,
        'completedOrders': 89,
      },
      {
        'id': 'driver_4',
        'name': 'Karim Mansour',
        'avatar': 'https://i.pravatar.cc/150?u=driver4',
        'phone': '+216 95 456 789',
        'vehicle': 'Citroen Berlingo',
        'plate': '012 TN 3456',
        'status': 'busy',
        'latitude': 36.8120,
        'longitude': 10.1750,
        'heading': 270.0,
        'speed': 42.0,
        'rating': 4.6,
        'completedOrders': 178,
      },
      {
        'id': 'driver_5',
        'name': 'Slim Bouazizi',
        'avatar': 'https://i.pravatar.cc/150?u=driver5',
        'phone': '+216 94 567 890',
        'vehicle': 'Fiat Doblo',
        'plate': '345 TN 6789',
        'status': 'offline',
        'latitude': 36.7890,
        'longitude': 10.1920,
        'heading': 0.0,
        'speed': 0.0,
        'rating': 4.5,
        'completedOrders': 67,
      },
    ];

    _driverLocationsController.add(simulatedDrivers);
    
    // Simulate real-time movement for busy drivers
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final drivers = List<Map<String, dynamic>>.from(_driverLocationsController.value);
      
      for (int i = 0; i < drivers.length; i++) {
        if (drivers[i]['status'] == 'busy') {
          // Simulate movement
          final heading = (drivers[i]['heading'] as double) + (10 - 20 * (i % 2));
          final speed = 30 + (i * 5.0);
          
          // Move in the heading direction
          final distance = speed / 3600 / 111; // km to degrees approximately
          final radians = heading * 3.14159 / 180;
          
          drivers[i] = Map<String, dynamic>.from(drivers[i])
            ..['latitude'] = (drivers[i]['latitude'] as double) + distance * 0.5 * (i % 2 == 0 ? 1 : -1)
            ..['longitude'] = (drivers[i]['longitude'] as double) + distance * 0.3 * (i % 2 == 0 ? -1 : 1)
            ..['heading'] = heading % 360
            ..['speed'] = speed;
        }
      }
      
      _driverLocationsController.add(drivers);
      
      _messageController.add(WebSocketMessage(
        type: 'driver_locations_update',
        data: {'drivers': drivers},
      ));
    });
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final wsMessage = WebSocketMessage.fromJson(data);
      
      _messageController.add(wsMessage);
      
      // Handle specific message types
      switch (wsMessage.type) {
        case 'driver_location_update':
          _updateDriverLocation(wsMessage.data);
          break;
        case 'order_status_update':
          // Handle order status update
          break;
        case 'pong':
          // Heartbeat response received
          break;
      }
    } catch (e) {
      debugPrint('🔌 WebSocket: Error parsing message: $e');
    }
  }

  void _updateDriverLocation(Map<String, dynamic> data) {
    final drivers = List<Map<String, dynamic>>.from(_driverLocationsController.value);
    final index = drivers.indexWhere((d) => d['id'] == data['driver_id']);
    
    if (index != -1) {
      drivers[index] = {
        ...drivers[index],
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'heading': data['heading'],
        'speed': data['speed'],
      };
      _driverLocationsController.add(drivers);
    }
  }

  void _handleDisconnect() {
    _statusController.add(ConnectionStatus.disconnected);
    _stopHeartbeat();
    _scheduleReconnect();
    
    debugPrint('🔌 WebSocket: Disconnected');
  }

  void _handleError(dynamic error) {
    _statusController.add(ConnectionStatus.error);
    _stopHeartbeat();
    _scheduleReconnect();
    
    debugPrint('🔌 WebSocket: Error: $error');
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('🔌 WebSocket: Max reconnect attempts reached');
      return;
    }
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay * (_reconnectAttempts + 1), () {
      _reconnectAttempts++;
      debugPrint('🔌 WebSocket: Reconnecting... Attempt $_reconnectAttempts');
      connect();
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      send({'type': 'ping', 'timestamp': DateTime.now().toIso8601String()});
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void send(Map<String, dynamic> data) {
    if (_channel != null && currentStatus == ConnectionStatus.connected) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  void sendDriverLocation(String driverId, double lat, double lng, double heading) {
    send({
      'type': 'driver_location_update',
      'driver_id': driverId,
      'latitude': lat,
      'longitude': lng,
      'heading': heading,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void sendOrderStatusUpdate(String orderId, String status) {
    send({
      'type': 'order_status_update',
      'order_id': orderId,
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _simulationTimer?.cancel();
    _stopHeartbeat();
    _channel?.sink.close();
    _supabaseChannel?.unsubscribe();
    _statusController.add(ConnectionStatus.disconnected);
    
    debugPrint('🔌 WebSocket: Manually disconnected');
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
    _driverLocationsController.close();
  }
}
