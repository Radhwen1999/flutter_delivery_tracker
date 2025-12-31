import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/driver_model.dart';
import '../../../../core/services/websocket_service.dart';

abstract class TrackingRemoteDataSource {
  Future<List<DriverModel>> getDrivers();
  Future<DriverModel> getDriverById(String driverId);
  Future<List<DriverModel>> getAvailableDrivers();
  Future<void> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    required double heading,
    required double speed,
  });
  Future<void> updateDriverStatus({
    required String driverId,
    required String status,
  });
  Stream<List<DriverModel>> watchDrivers();
}

class TrackingRemoteDataSourceImpl implements TrackingRemoteDataSource {
  final SupabaseClient supabaseClient;
  final WebSocketService webSocketService;

  TrackingRemoteDataSourceImpl({
    required this.supabaseClient,
    required this.webSocketService,
  });

  @override
  Future<List<DriverModel>> getDrivers() async {
    try {
      final response = await supabaseClient
          .from('drivers')
          .select()
          .order('name');
      
      return (response as List)
          .map((json) => DriverModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('🚗 TrackingRemote: Error getting drivers: $e');
      // Return simulated data for demo
      return _getSimulatedDrivers();
    }
  }

  @override
  Future<DriverModel> getDriverById(String driverId) async {
    try {
      final response = await supabaseClient
          .from('drivers')
          .select()
          .eq('id', driverId)
          .single();
      
      return DriverModel.fromJson(response);
    } catch (e) {
      debugPrint('🚗 TrackingRemote: Error getting driver: $e');
      final drivers = await _getSimulatedDrivers();
      return drivers.firstWhere(
        (d) => d.id == driverId,
        orElse: () => drivers.first,
      );
    }
  }

  @override
  Future<List<DriverModel>> getAvailableDrivers() async {
    try {
      final response = await supabaseClient
          .from('drivers')
          .select()
          .eq('status', 'available')
          .order('rating', ascending: false);
      
      return (response as List)
          .map((json) => DriverModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('🚗 TrackingRemote: Error getting available drivers: $e');
      final drivers = await _getSimulatedDrivers();
      return drivers.where((d) => d.status == 'available').toList();
    }
  }

  @override
  Future<void> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    required double heading,
    required double speed,
  }) async {
    try {
      await supabaseClient
          .from('drivers')
          .update({
            'latitude': latitude,
            'longitude': longitude,
            'heading': heading,
            'speed': speed,
            'last_updated': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);
      
      // Also send via WebSocket for real-time updates
      webSocketService.sendDriverLocation(driverId, latitude, longitude, heading);
    } catch (e) {
      debugPrint('🚗 TrackingRemote: Error updating location: $e');
    }
  }

  @override
  Future<void> updateDriverStatus({
    required String driverId,
    required String status,
  }) async {
    try {
      await supabaseClient
          .from('drivers')
          .update({
            'status': status,
            'last_updated': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);
    } catch (e) {
      debugPrint('🚗 TrackingRemote: Error updating status: $e');
    }
  }

  @override
  Stream<List<DriverModel>> watchDrivers() {
    return webSocketService.driverLocations.map((driversList) {
      return driversList.map((json) => DriverModel.fromJson(json)).toList();
    });
  }

  List<DriverModel> _getSimulatedDrivers() {
    return [
      DriverModel(
        id: 'driver_1',
        name: 'Ahmed Ben Salem',
        avatar: 'https://i.pravatar.cc/150?u=driver1',
        phone: '+216 98 123 456',
        vehicle: 'Toyota Hilux',
        plate: '123 TN 4567',
        status: 'available',
        latitude: 36.8065,
        longitude: 10.1815,
        heading: 45.0,
        speed: 0.0,
        rating: 4.8,
        completedOrders: 156,
      ),
      DriverModel(
        id: 'driver_2',
        name: 'Youssef Trabelsi',
        avatar: 'https://i.pravatar.cc/150?u=driver2',
        phone: '+216 97 234 567',
        vehicle: 'Renault Kangoo',
        plate: '456 TN 7890',
        status: 'busy',
        latitude: 36.8189,
        longitude: 10.1657,
        heading: 90.0,
        speed: 35.0,
        rating: 4.9,
        completedOrders: 243,
      ),
      DriverModel(
        id: 'driver_3',
        name: 'Mohamed Gharbi',
        avatar: 'https://i.pravatar.cc/150?u=driver3',
        phone: '+216 96 345 678',
        vehicle: 'Peugeot Partner',
        plate: '789 TN 1234',
        status: 'available',
        latitude: 36.7955,
        longitude: 10.1880,
        heading: 180.0,
        speed: 0.0,
        rating: 4.7,
        completedOrders: 89,
      ),
      DriverModel(
        id: 'driver_4',
        name: 'Karim Mansour',
        avatar: 'https://i.pravatar.cc/150?u=driver4',
        phone: '+216 95 456 789',
        vehicle: 'Citroen Berlingo',
        plate: '012 TN 3456',
        status: 'busy',
        latitude: 36.8120,
        longitude: 10.1750,
        heading: 270.0,
        speed: 42.0,
        rating: 4.6,
        completedOrders: 178,
      ),
      DriverModel(
        id: 'driver_5',
        name: 'Slim Bouazizi',
        avatar: 'https://i.pravatar.cc/150?u=driver5',
        phone: '+216 94 567 890',
        vehicle: 'Fiat Doblo',
        plate: '345 TN 6789',
        status: 'offline',
        latitude: 36.7890,
        longitude: 10.1920,
        heading: 0.0,
        speed: 0.0,
        rating: 4.5,
        completedOrders: 67,
      ),
    ];
  }
}
