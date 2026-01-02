import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_remote_datasource.dart';
import '../datasources/orders_local_datasource.dart';
import '../models/order_model.dart';
import '../../../../core/services/connectivity_service.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDataSource remoteDataSource;
  final OrdersLocalDataSource localDataSource;
  final ConnectivityService connectivityService;

  OrdersRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.connectivityService,
  });

  @override
  Future<Either<String, List<OrderModel>>> getOrders() async {
    try {
      if (connectivityService.isOnline) {
        final orders = await remoteDataSource.getOrders();
        await localDataSource.cacheOrders(orders);
        return Right(orders);
      } else {
        final cachedOrders = await localDataSource.getCachedOrders();
        if (cachedOrders.isNotEmpty) {
          return Right(cachedOrders);
        }
        return const Left('No internet connection and no cached data');
      }
    } catch (e) {
      debugPrint('📦 OrdersRepo: Error getting orders: $e');
      final cachedOrders = await localDataSource.getCachedOrders();
      if (cachedOrders.isNotEmpty) {
        return Right(cachedOrders);
      }
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<OrderModel>>> getActiveOrders() async {
    try {
      if (connectivityService.isOnline) {
        final orders = await remoteDataSource.getActiveOrders();
        return Right(orders);
      } else {
        final cachedOrders = await localDataSource.getCachedOrders();
        final activeOrders = cachedOrders.where((o) => o.isActive).toList();
        return Right(activeOrders);
      }
    } catch (e) {
      debugPrint('📦 OrdersRepo: Error getting active orders: $e');
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, OrderModel>> getOrderById(String orderId) async {
    try {
      if (connectivityService.isOnline) {
        final order = await remoteDataSource.getOrderById(orderId);
        await localDataSource.cacheOrder(order);
        return Right(order);
      } else {
        final cachedOrder = await localDataSource.getCachedOrder(orderId);
        if (cachedOrder != null) {
          return Right(cachedOrder);
        }
        return const Left('No internet connection and order not cached');
      }
    } catch (e) {
      debugPrint('📦 OrdersRepo: Error getting order: $e');
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, OrderModel>> createOrder(OrderModel order) async {
    try {
      final newOrder = await remoteDataSource.createOrder(order);
      await localDataSource.cacheOrder(newOrder);
      return Right(newOrder);
    } catch (e) {
      debugPrint('📦 OrdersRepo: Error creating order: $e');
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> updateOrderStatus(String orderId, String status) async {
    try {
      await remoteDataSource.updateOrderStatus(orderId, status);
      return const Right(null);
    } catch (e) {
      debugPrint('📦 OrdersRepo: Error updating order status: $e');
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> assignDriver(String orderId, String driverId) async {
    try {
      await remoteDataSource.assignDriver(orderId, driverId);
      return const Right(null);
    } catch (e) {
      debugPrint('📦 OrdersRepo: Error assigning driver: $e');
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> cancelOrder(String orderId) async {
    try {
      await remoteDataSource.cancelOrder(orderId);
      return const Right(null);
    } catch (e) {
      debugPrint('📦 OrdersRepo: Error cancelling order: $e');
      return Left(e.toString());
    }
  }

  @override
  Stream<List<OrderModel>> watchOrders() {
    return remoteDataSource.watchOrders();
  }

  @override
  Future<List<OrderModel>> getCachedOrders() async {
    return localDataSource.getCachedOrders();
  }

  @override
  Future<void> cacheOrders(List<OrderModel> orders) async {
    await localDataSource.cacheOrders(orders);
  }
}
