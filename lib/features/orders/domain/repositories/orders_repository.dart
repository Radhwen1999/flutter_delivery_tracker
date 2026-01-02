import 'package:dartz/dartz.dart';
import '../../data/models/order_model.dart';

abstract class OrdersRepository {
  Future<Either<String, List<OrderModel>>> getOrders();
  Future<Either<String, List<OrderModel>>> getActiveOrders();
  Future<Either<String, OrderModel>> getOrderById(String orderId);
  Future<Either<String, OrderModel>> createOrder(OrderModel order);
  Future<Either<String, void>> updateOrderStatus(String orderId, String status);
  Future<Either<String, void>> assignDriver(String orderId, String driverId);
  Future<Either<String, void>> cancelOrder(String orderId);
  Stream<List<OrderModel>> watchOrders();
  Future<List<OrderModel>> getCachedOrders();
  Future<void> cacheOrders(List<OrderModel> orders);
}
