import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/driver_model.dart';

abstract class TrackingLocalDataSource {
  Future<List<DriverModel>> getCachedDrivers();
  Future<void> cacheDrivers(List<DriverModel> drivers);
  Future<DriverModel?> getCachedDriver(String driverId);
  Future<void> cacheDriver(DriverModel driver);
  Future<void> clearCache();
}

class TrackingLocalDataSourceImpl implements TrackingLocalDataSource {
  static const String _driversBoxName = 'drivers_cache';
  Box<DriverModel>? _driversBox;

  Future<Box<DriverModel>> get driversBox async {
    if (_driversBox == null || !_driversBox!.isOpen) {
      // Register adapter if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(DriverModelAdapter());
      }
      _driversBox = await Hive.openBox<DriverModel>(_driversBoxName);
    }
    return _driversBox!;
  }

  @override
  Future<List<DriverModel>> getCachedDrivers() async {
    try {
      final box = await driversBox;
      return box.values.toList();
    } catch (e) {
      debugPrint('💾 TrackingLocal: Error getting cached drivers: $e');
      return [];
    }
  }

  @override
  Future<void> cacheDrivers(List<DriverModel> drivers) async {
    try {
      final box = await driversBox;
      await box.clear();
      
      final Map<String, DriverModel> driversMap = {
        for (final driver in drivers) driver.id: driver
      };
      
      await box.putAll(driversMap);
      debugPrint('💾 TrackingLocal: Cached ${drivers.length} drivers');
    } catch (e) {
      debugPrint('💾 TrackingLocal: Error caching drivers: $e');
    }
  }

  @override
  Future<DriverModel?> getCachedDriver(String driverId) async {
    try {
      final box = await driversBox;
      return box.get(driverId);
    } catch (e) {
      debugPrint('💾 TrackingLocal: Error getting cached driver: $e');
      return null;
    }
  }

  @override
  Future<void> cacheDriver(DriverModel driver) async {
    try {
      final box = await driversBox;
      await box.put(driver.id, driver);
    } catch (e) {
      debugPrint('💾 TrackingLocal: Error caching driver: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final box = await driversBox;
      await box.clear();
      debugPrint('💾 TrackingLocal: Cache cleared');
    } catch (e) {
      debugPrint('💾 TrackingLocal: Error clearing cache: $e');
    }
  }
}
