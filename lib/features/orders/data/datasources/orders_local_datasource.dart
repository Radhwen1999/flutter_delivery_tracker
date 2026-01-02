import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/order_model.dart';

abstract class OrdersLocalDataSource {
  Future<List<OrderModel>> getCachedOrders();
  Future<void> cacheOrders(List<OrderModel> orders);
  Future<OrderModel?> getCachedOrder(String orderId);
  Future<void> cacheOrder(OrderModel order);
  Future<void> clearCache();
}

class OrdersLocalDataSourceImpl implements OrdersLocalDataSource {
  static const String _ordersBoxName = 'orders_cache';
  Box<OrderModel>? _ordersBox;

  Future<Box<OrderModel>> get ordersBox async {
    if (_ordersBox == null || !_ordersBox!.isOpen) {
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(LocationPointAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(OrderModelAdapter());
      }
      _ordersBox = await Hive.openBox<OrderModel>(_ordersBoxName);
    }
    return _ordersBox!;
  }

  @override
  Future<List<OrderModel>> getCachedOrders() async {
    try {
      final box = await ordersBox;
      return box.values.toList();
    } catch (e) {
      debugPrint('💾 OrdersLocal: Error getting cached orders: $e');
      return [];
    }
  }

  @override
  Future<void> cacheOrders(List<OrderModel> orders) async {
    try {
      final box = await ordersBox;
      await box.clear();
      
      final Map<String, OrderModel> ordersMap = {
        for (final order in orders) order.id: order
      };
      
      await box.putAll(ordersMap);
      debugPrint('💾 OrdersLocal: Cached ${orders.length} orders');
    } catch (e) {
      debugPrint('💾 OrdersLocal: Error caching orders: $e');
    }
  }

  @override
  Future<OrderModel?> getCachedOrder(String orderId) async {
    try {
      final box = await ordersBox;
      return box.get(orderId);
    } catch (e) {
      debugPrint('💾 OrdersLocal: Error getting cached order: $e');
      return null;
    }
  }

  @override
  Future<void> cacheOrder(OrderModel order) async {
    try {
      final box = await ordersBox;
      await box.put(order.id, order);
    } catch (e) {
      debugPrint('💾 OrdersLocal: Error caching order: $e');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final box = await ordersBox;
      await box.clear();
      debugPrint('💾 OrdersLocal: Cache cleared');
    } catch (e) {
      debugPrint('💾 OrdersLocal: Error clearing cache: $e');
    }
  }
}
