import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/tracking_remote_datasource.dart';
import '../datasources/tracking_local_datasource.dart';
import '../models/driver_model.dart';
import '../../../../core/services/connectivity_service.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  final TrackingRemoteDataSource remoteDataSource;
  final TrackingLocalDataSource localDataSource;
  final ConnectivityService connectivityService;

  TrackingRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.connectivityService,
  });

  @override
  Future<Either<String, List<DriverModel>>> getDrivers() async {
    try {
      if (connectivityService.isOnline) {
        final drivers = await remoteDataSource.getDrivers();
        // Cache for offline use
        await localDataSource.cacheDrivers(drivers);
        return Right(drivers);
      } else {
        // Return cached data when offline
        final cachedDrivers = await localDataSource.getCachedDrivers();
        if (cachedDrivers.isNotEmpty) {
          return Right(cachedDrivers);
        }
        return const Left('No internet connection and no cached data');
      }
    } catch (e) {
      debugPrint('🚗 TrackingRepo: Error getting drivers: $e');
      // Try to return cached data on error
      final cachedDrivers = await localDataSource.getCachedDrivers();
      if (cachedDrivers.isNotEmpty) {
        return Right(cachedDrivers);
      }
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, DriverModel>> getDriverById(String driverId) async {
    try {
      if (connectivityService.isOnline) {
        final driver = await remoteDataSource.getDriverById(driverId);
        await localDataSource.cacheDriver(driver);
        return Right(driver);
      } else {
        final cachedDriver = await localDataSource.getCachedDriver(driverId);
        if (cachedDriver != null) {
          return Right(cachedDriver);
        }
        return const Left('No internet connection and driver not cached');
      }
    } catch (e) {
      debugPrint('🚗 TrackingRepo: Error getting driver: $e');
      final cachedDriver = await localDataSource.getCachedDriver(driverId);
      if (cachedDriver != null) {
        return Right(cachedDriver);
      }
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<DriverModel>>> getAvailableDrivers() async {
    try {
      if (connectivityService.isOnline) {
        final drivers = await remoteDataSource.getAvailableDrivers();
        return Right(drivers);
      } else {
        final cachedDrivers = await localDataSource.getCachedDrivers();
        final availableDrivers = cachedDrivers
            .where((d) => d.status == 'available')
            .toList();
        return Right(availableDrivers);
      }
    } catch (e) {
      debugPrint('🚗 TrackingRepo: Error getting available drivers: $e');
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> updateDriverLocation({
    required String driverId,
    required double latitude,
    required double longitude,
    required double heading,
    required double speed,
  }) async {
    try {
      await remoteDataSource.updateDriverLocation(
        driverId: driverId,
        latitude: latitude,
        longitude: longitude,
        heading: heading,
        speed: speed,
      );
      return const Right(null);
    } catch (e) {
      debugPrint('🚗 TrackingRepo: Error updating location: $e');
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> updateDriverStatus({
    required String driverId,
    required String status,
  }) async {
    try {
      await remoteDataSource.updateDriverStatus(
        driverId: driverId,
        status: status,
      );
      return const Right(null);
    } catch (e) {
      debugPrint('🚗 TrackingRepo: Error updating status: $e');
      return Left(e.toString());
    }
  }

  @override
  Stream<List<DriverModel>> watchDrivers() {
    return remoteDataSource.watchDrivers();
  }

  @override
  Future<List<DriverModel>> getCachedDrivers() async {
    return localDataSource.getCachedDrivers();
  }

  @override
  Future<void> cacheDrivers(List<DriverModel> drivers) async {
    await localDataSource.cacheDrivers(drivers);
  }
}
