import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/order_model.dart';

abstract class OrdersRemoteDataSource {
  Future<List<OrderModel>> getOrders();
  Future<List<OrderModel>> getActiveOrders();
  Future<OrderModel> getOrderById(String orderId);
  Future<OrderModel> createOrder(OrderModel order);
  Future<void> updateOrderStatus(String orderId, String status);
  Future<void> assignDriver(String orderId, String driverId);
  Future<void> cancelOrder(String orderId);
  Stream<List<OrderModel>> watchOrders();
}

class OrdersRemoteDataSourceImpl implements OrdersRemoteDataSource {
  final SupabaseClient supabaseClient;
  final _uuid = const Uuid();

  OrdersRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<OrderModel>> getOrders() async {
    try {
      final response = await supabaseClient
          .from('orders')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List).map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('📦 OrdersRemote: Error getting orders: $e');
      return _getSimulatedOrders();
    }
  }

  @override
  Future<List<OrderModel>> getActiveOrders() async {
    try {
      final response = await supabaseClient
          .from('orders')
          .select()
          .not('status', 'in', '(delivered,cancelled)')
          .order('created_at', ascending: false);
      
      return (response as List).map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('📦 OrdersRemote: Error getting active orders: $e');
      return _getSimulatedOrders().where((o) => o.isActive).toList();
    }
  }

  @override
  Future<OrderModel> getOrderById(String orderId) async {
    try {
      final response = await supabaseClient
          .from('orders')
          .select()
          .eq('id', orderId)
          .single();
      
      return OrderModel.fromJson(response);
    } catch (e) {
      debugPrint('📦 OrdersRemote: Error getting order: $e');
      return _getSimulatedOrders().firstWhere((o) => o.id == orderId);
    }
  }

  @override
  Future<OrderModel> createOrder(OrderModel order) async {
    try {
      final newOrder = order.copyWith(
        id: _uuid.v4(),
        createdAt: DateTime.now(),
      );
      
      final response = await supabaseClient
          .from('orders')
          .insert(newOrder.toJson())
          .select()
          .single();
      
      return OrderModel.fromJson(response);
    } catch (e) {
      debugPrint('📦 OrdersRemote: Error creating order: $e');
      return order.copyWith(id: _uuid.v4(), createdAt: DateTime.now());
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final updates = <String, dynamic>{'status': status};
      
      if (status == 'picked_up') {
        updates['picked_up_at'] = DateTime.now().toIso8601String();
      } else if (status == 'delivered') {
        updates['delivered_at'] = DateTime.now().toIso8601String();
      }
      
      await supabaseClient
          .from('orders')
          .update(updates)
          .eq('id', orderId);
    } catch (e) {
      debugPrint('📦 OrdersRemote: Error updating order status: $e');
    }
  }

  @override
  Future<void> assignDriver(String orderId, String driverId) async {
    try {
      await supabaseClient.from('orders').update({
        'driver_id': driverId,
        'status': 'assigned',
        'assigned_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);
    } catch (e) {
      debugPrint('📦 OrdersRemote: Error assigning driver: $e');
    }
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    try {
      await supabaseClient.from('orders').update({
        'status': 'cancelled',
      }).eq('id', orderId);
    } catch (e) {
      debugPrint('📦 OrdersRemote: Error cancelling order: $e');
    }
  }

  @override
  Stream<List<OrderModel>> watchOrders() {
    return supabaseClient
        .from('orders')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => OrderModel.fromJson(json)).toList());
  }

  List<OrderModel> _getSimulatedOrders() {
    final now = DateTime.now();
    return [
      OrderModel(
        id: 'order_1',
        customerId: 'cust_1',
        customerName: 'Sami Belhadj',
        customerPhone: '+216 99 111 222',
        driverId: 'driver_2',
        status: 'in_transit',
        pickupLat: 36.8100,
        pickupLng: 10.1700,
        pickupAddress: '15 Avenue Habib Bourguiba, Tunis',
        dropoffLat: 36.8200,
        dropoffLng: 10.1800,
        dropoffAddress: '45 Rue de la Liberté, Tunis',
        notes: 'Ring doorbell twice',
        amount: 25.50,
        paymentMethod: 'card',
        createdAt: now.subtract(const Duration(minutes: 30)),
        assignedAt: now.subtract(const Duration(minutes: 25)),
        pickedUpAt: now.subtract(const Duration(minutes: 15)),
        estimatedMinutes: 8,
        distanceKm: 2.5,
      ),
      OrderModel(
        id: 'order_2',
        customerId: 'cust_2',
        customerName: 'Leila Mansouri',
        customerPhone: '+216 98 333 444',
        driverId: 'driver_4',
        status: 'picked_up',
        pickupLat: 36.7950,
        pickupLng: 10.1850,
        pickupAddress: '88 Avenue Mohamed V, La Marsa',
        dropoffLat: 36.8300,
        dropoffLng: 10.1600,
        dropoffAddress: '23 Rue de Carthage, Tunis',
        amount: 18.00,
        paymentMethod: 'cash',
        createdAt: now.subtract(const Duration(minutes: 45)),
        assignedAt: now.subtract(const Duration(minutes: 40)),
        pickedUpAt: now.subtract(const Duration(minutes: 20)),
        estimatedMinutes: 12,
        distanceKm: 4.2,
      ),
      OrderModel(
        id: 'order_3',
        customerId: 'cust_3',
        customerName: 'Omar Chaabane',
        customerPhone: '+216 97 555 666',
        status: 'pending',
        pickupLat: 36.8050,
        pickupLng: 10.1750,
        pickupAddress: '7 Place de la Victoire, Tunis',
        dropoffLat: 36.7800,
        dropoffLng: 10.2000,
        dropoffAddress: '56 Avenue Farhat Hached, Bardo',
        notes: 'Fragile items - handle with care',
        amount: 32.00,
        paymentMethod: 'card',
        createdAt: now.subtract(const Duration(minutes: 10)),
        estimatedMinutes: 15,
        distanceKm: 5.1,
      ),
      OrderModel(
        id: 'order_4',
        customerId: 'cust_4',
        customerName: 'Fatma Jebali',
        customerPhone: '+216 96 777 888',
        driverId: 'driver_1',
        status: 'assigned',
        pickupLat: 36.8150,
        pickupLng: 10.1650,
        pickupAddress: '12 Rue Ibn Khaldoun, Tunis',
        dropoffLat: 36.8250,
        dropoffLng: 10.1550,
        dropoffAddress: '34 Avenue de Paris, Tunis',
        amount: 15.00,
        paymentMethod: 'cash',
        createdAt: now.subtract(const Duration(minutes: 5)),
        assignedAt: now.subtract(const Duration(minutes: 2)),
        estimatedMinutes: 10,
        distanceKm: 1.8,
      ),
      OrderModel(
        id: 'order_5',
        customerId: 'cust_5',
        customerName: 'Nabil Saidi',
        customerPhone: '+216 95 999 000',
        driverId: 'driver_2',
        status: 'delivered',
        pickupLat: 36.8000,
        pickupLng: 10.1800,
        pickupAddress: '99 Avenue de la République, Tunis',
        dropoffLat: 36.7900,
        dropoffLng: 10.1900,
        dropoffAddress: '67 Rue de Marseille, Tunis',
        amount: 22.50,
        paymentMethod: 'card',
        createdAt: now.subtract(const Duration(hours: 2)),
        assignedAt: now.subtract(const Duration(hours: 2)),
        pickedUpAt: now.subtract(const Duration(hours: 1, minutes: 45)),
        deliveredAt: now.subtract(const Duration(hours: 1, minutes: 30)),
        estimatedMinutes: 18,
        distanceKm: 3.2,
      ),
    ];
  }
}
