import 'package:dartz/dartz.dart';
import '../../data/models/driver_model.dart';

abstract class TrackingRepository {
  /// Get all drivers
  Future<Either<String, List<DriverModel>>> getDrivers();
  
  /// Get a specific driver by ID
  Future<Either<String, DriverModel>> getDriverById(String driverId);
  
  /// Get available drivers
  Future<Either<String, List<DriverModel>>> getAvailableDrivers();
  
  /// Update driver location
  Future<Either<String, void>> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    required double heading,
    required double speed,
  });
  
  /// Update driver status
  Future<Either<String, void>> updateDriverStatus({
    required String driverId,
    required String status,
  });
  
  /// Stream of driver updates
  Stream<List<DriverModel>> watchDrivers();
  
  /// Get cached drivers (offline mode)
  Future<List<DriverModel>> getCachedDrivers();
  
  /// Cache drivers locally
  Future<void> cacheDrivers(List<DriverModel> drivers);
}
