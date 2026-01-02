import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/order_model.dart';
import '../../domain/repositories/orders_repository.dart';
import '../../../../core/services/notification_service.dart';

// Events
abstract class OrdersEvent extends Equatable {
  const OrdersEvent();
  @override
  List<Object?> get props => [];
}

class LoadOrdersEvent extends OrdersEvent {}

class RefreshOrdersEvent extends OrdersEvent {}

class CreateOrderEvent extends OrdersEvent {
  final OrderModel order;
  const CreateOrderEvent(this.order);
  @override
  List<Object?> get props => [order];
}

class UpdateOrderStatusEvent extends OrdersEvent {
  final String orderId;
  final String status;
  const UpdateOrderStatusEvent(this.orderId, this.status);
  @override
  List<Object?> get props => [orderId, status];
}

class AssignDriverEvent extends OrdersEvent {
  final String orderId;
  final String driverId;
  const AssignDriverEvent(this.orderId, this.driverId);
  @override
  List<Object?> get props => [orderId, driverId];
}

class CancelOrderEvent extends OrdersEvent {
  final String orderId;
  const CancelOrderEvent(this.orderId);
  @override
  List<Object?> get props => [orderId];
}

class SelectOrderEvent extends OrdersEvent {
  final OrderModel order;
  const SelectOrderEvent(this.order);
  @override
  List<Object?> get props => [order];
}

class DeselectOrderEvent extends OrdersEvent {}

class FilterOrdersEvent extends OrdersEvent {
  final OrderStatus? statusFilter;
  const FilterOrdersEvent(this.statusFilter);
  @override
  List<Object?> get props => [statusFilter];
}

// States
abstract class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<OrderModel> orders;
  final List<OrderModel> filteredOrders;
  final OrderModel? selectedOrder;
  final OrderStatus? statusFilter;
  final bool isCreating;

  const OrdersLoaded({
    required this.orders,
    List<OrderModel>? filteredOrders,
    this.selectedOrder,
    this.statusFilter,
    this.isCreating = false,
  }) : filteredOrders = filteredOrders ?? orders;

  int get pendingCount => orders.where((o) => o.orderStatus == OrderStatus.pending).length;
  int get assignedCount => orders.where((o) => o.orderStatus == OrderStatus.assigned).length;
  int get inTransitCount => orders.where((o) => o.orderStatus == OrderStatus.pickedUp || o.orderStatus == OrderStatus.inTransit).length;
  int get deliveredCount => orders.where((o) => o.orderStatus == OrderStatus.delivered).length;
  int get activeCount => orders.where((o) => o.isActive).length;

  OrdersLoaded copyWith({
    List<OrderModel>? orders,
    List<OrderModel>? filteredOrders,
    OrderModel? selectedOrder,
    bool? clearSelectedOrder,
    OrderStatus? statusFilter,
    bool? clearStatusFilter,
    bool? isCreating,
  }) {
    return OrdersLoaded(
      orders: orders ?? this.orders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      selectedOrder: clearSelectedOrder == true ? null : selectedOrder ?? this.selectedOrder,
      statusFilter: clearStatusFilter == true ? null : statusFilter ?? this.statusFilter,
      isCreating: isCreating ?? this.isCreating,
    );
  }

  @override
  List<Object?> get props => [orders, filteredOrders, selectedOrder, statusFilter, isCreating];
}

class OrdersError extends OrdersState {
  final String message;
  const OrdersError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrdersRepository ordersRepository;
  final NotificationService notificationService;
  StreamSubscription? _ordersSubscription;

  OrdersBloc({
    required this.ordersRepository,
    required this.notificationService,
  }) : super(OrdersInitial()) {
    on<LoadOrdersEvent>(_onLoadOrders);
    on<RefreshOrdersEvent>(_onRefreshOrders);
    on<CreateOrderEvent>(_onCreateOrder);
    on<UpdateOrderStatusEvent>(_onUpdateOrderStatus);
    on<AssignDriverEvent>(_onAssignDriver);
    on<CancelOrderEvent>(_onCancelOrder);
    on<SelectOrderEvent>(_onSelectOrder);
    on<DeselectOrderEvent>(_onDeselectOrder);
    on<FilterOrdersEvent>(_onFilterOrders);
  }

  Future<void> _onLoadOrders(LoadOrdersEvent event, Emitter<OrdersState> emit) async {
    emit(OrdersLoading());
    
    final result = await ordersRepository.getOrders();
    result.fold(
      (error) => emit(OrdersError(error)),
      (orders) => emit(OrdersLoaded(orders: orders)),
    );
  }

  Future<void> _onRefreshOrders(RefreshOrdersEvent event, Emitter<OrdersState> emit) async {
    final result = await ordersRepository.getOrders();
    result.fold(
      (error) {
        if (state is OrdersLoaded) {
          debugPrint('📦 OrdersBloc: Error refreshing orders: $error');
        } else {
          emit(OrdersError(error));
        }
      },
      (orders) {
        if (state is OrdersLoaded) {
          final currentState = state as OrdersLoaded;
          List<OrderModel> filtered = orders;
          if (currentState.statusFilter != null) {
            filtered = orders.where((o) => o.orderStatus == currentState.statusFilter).toList();
          }
          emit(currentState.copyWith(orders: orders, filteredOrders: filtered));
        } else {
          emit(OrdersLoaded(orders: orders));
        }
      },
    );
  }

  Future<void> _onCreateOrder(CreateOrderEvent event, Emitter<OrdersState> emit) async {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      emit(currentState.copyWith(isCreating: true));
      
      final result = await ordersRepository.createOrder(event.order);
      result.fold(
        (error) {
          emit(currentState.copyWith(isCreating: false));
          debugPrint('📦 OrdersBloc: Error creating order: $error');
        },
        (newOrder) {
          final updatedOrders = [newOrder, ...currentState.orders];
          emit(currentState.copyWith(orders: updatedOrders, filteredOrders: updatedOrders, isCreating: false));
        },
      );
    }
  }

  Future<void> _onUpdateOrderStatus(UpdateOrderStatusEvent event, Emitter<OrdersState> emit) async {
    final result = await ordersRepository.updateOrderStatus(event.orderId, event.status);
    result.fold(
      (error) => debugPrint('📦 OrdersBloc: Error updating order status: $error'),
      (_) {
        if (state is OrdersLoaded) {
          final currentState = state as OrdersLoaded;
          final updatedOrders = currentState.orders.map((order) {
            if (order.id == event.orderId) {
              return order.copyWith(status: event.status);
            }
            return order;
          }).toList();
          emit(currentState.copyWith(orders: updatedOrders, filteredOrders: updatedOrders));
          
          // Show notification
          if (event.status == 'delivered') {
            notificationService.showOrderDeliveredNotification(orderId: event.orderId);
          }
        }
      },
    );
  }

  Future<void> _onAssignDriver(AssignDriverEvent event, Emitter<OrdersState> emit) async {
    final result = await ordersRepository.assignDriver(event.orderId, event.driverId);
    result.fold(
      (error) => debugPrint('📦 OrdersBloc: Error assigning driver: $error'),
      (_) {
        if (state is OrdersLoaded) {
          final currentState = state as OrdersLoaded;
          final updatedOrders = currentState.orders.map((order) {
            if (order.id == event.orderId) {
              return order.copyWith(driverId: event.driverId, status: 'assigned', assignedAt: DateTime.now());
            }
            return order;
          }).toList();
          emit(currentState.copyWith(orders: updatedOrders, filteredOrders: updatedOrders));
        }
        add(RefreshOrdersEvent());
      },
    );
  }

  Future<void> _onCancelOrder(CancelOrderEvent event, Emitter<OrdersState> emit) async {
    final result = await ordersRepository.cancelOrder(event.orderId);
    result.fold(
      (error) => debugPrint('📦 OrdersBloc: Error cancelling order: $error'),
      (_) {
        if (state is OrdersLoaded) {
          final currentState = state as OrdersLoaded;
          final updatedOrders = currentState.orders.map((order) {
            if (order.id == event.orderId) {
              return order.copyWith(status: 'cancelled');
            }
            return order;
          }).toList();
          emit(currentState.copyWith(orders: updatedOrders, filteredOrders: updatedOrders, clearSelectedOrder: true));
        }
      },
    );
  }

  void _onSelectOrder(SelectOrderEvent event, Emitter<OrdersState> emit) {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      emit(currentState.copyWith(selectedOrder: event.order));
    }
  }

  void _onDeselectOrder(DeselectOrderEvent event, Emitter<OrdersState> emit) {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      emit(currentState.copyWith(clearSelectedOrder: true));
    }
  }

  void _onFilterOrders(FilterOrdersEvent event, Emitter<OrdersState> emit) {
    if (state is OrdersLoaded) {
      final currentState = state as OrdersLoaded;
      List<OrderModel> filtered;
      if (event.statusFilter == null) {
        filtered = currentState.orders;
      } else {
        filtered = currentState.orders.where((o) => o.orderStatus == event.statusFilter).toList();
      }
      emit(currentState.copyWith(
        filteredOrders: filtered,
        statusFilter: event.statusFilter,
        clearStatusFilter: event.statusFilter == null,
      ));
    }
  }

  @override
  Future<void> close() {
    _ordersSubscription?.cancel();
    return super.close();
  }
}
