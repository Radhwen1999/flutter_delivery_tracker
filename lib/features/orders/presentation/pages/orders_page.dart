import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/order_model.dart';
import '../bloc/orders_bloc.dart';
import '../widgets/order_card.dart';
import '../widgets/create_order_sheet.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders, int tabIndex) {
    switch (tabIndex) {
      case 1:
        return orders.where((o) => o.orderStatus == OrderStatus.pending).toList();
      case 2:
        return orders.where((o) => o.orderStatus == OrderStatus.assigned || o.orderStatus == OrderStatus.pickedUp).toList();
      case 3:
        return orders.where((o) => o.orderStatus == OrderStatus.inTransit).toList();
      case 4:
        return orders.where((o) => o.orderStatus == OrderStatus.delivered).toList();
      default:
        return orders;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersBloc, OrdersState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: CustomScrollView(
            slivers: [
              _buildAppBar(state),
              if (state is OrdersLoaded) ...[
                SliverToBoxAdapter(child: _buildStats(state)),
                SliverToBoxAdapter(child: _buildTabBar(state)),
                _buildOrdersList(state),
              ] else if (state is OrdersLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state is OrdersError)
                SliverFillRemaining(
                  child: _buildError(state.message),
                ),
            ],
          ),
          floatingActionButton: _buildFAB(),
        );
      },
    );
  }

  Widget _buildAppBar(OrdersState state) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.background,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'Orders',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.secondary.withOpacity(0.08),
                AppColors.background,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => context.read<OrdersBloc>().add(RefreshOrdersEvent()),
          icon: const Icon(Iconsax.refresh),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStats(OrdersLoaded state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.colored,
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              icon: Iconsax.timer_1,
              value: '${state.activeCount}',
              label: 'Active',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Iconsax.tick_circle,
              value: '${state.deliveredCount}',
              label: 'Delivered',
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withOpacity(0.2),
          ),
          Expanded(
            child: _buildStatItem(
              icon: Iconsax.chart,
              value: '${((state.deliveredCount / (state.orders.isEmpty ? 1 : state.orders.length)) * 100).toStringAsFixed(0)}%',
              label: 'Success',
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.8), size: 18),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(OrdersLoaded state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', state.orders.length, 0),
            const SizedBox(width: 8),
            _buildFilterChip('Pending', state.pendingCount, 1),
            const SizedBox(width: 8),
            _buildFilterChip('Assigned', state.assignedCount, 2),
            const SizedBox(width: 8),
            _buildFilterChip('In Transit', state.inTransitCount, 3),
            const SizedBox(width: 8),
            _buildFilterChip('Delivered', state.deliveredCount, 4),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildFilterChip(String label, int count, int index) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tabController.animateTo(index);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          boxShadow: isSelected ? AppShadows.colored : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(OrdersLoaded state) {
    final filteredOrders = _filterOrders(state.orders, _tabController.index);
    
    if (filteredOrders.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(),
      );
    }
    
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final order = filteredOrders[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OrderCard(
                order: order,
                onTap: () => _showOrderDetails(order),
                onStatusUpdate: (status) {
                  context.read<OrdersBloc>().add(UpdateOrderStatusEvent(order.id, status));
                },
              ).animate(delay: Duration(milliseconds: 50 * index))
                  .fadeIn()
                  .slideX(begin: 0.05),
            );
          },
          childCount: filteredOrders.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.box,
              size: 48,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No orders found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new order to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.warning_2, size: 48, color: AppColors.error),
          ),
          const SizedBox(height: 24),
          Text('Something went wrong', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<OrdersBloc>().add(LoadOrdersEvent()),
            icon: const Icon(Iconsax.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showCreateOrderSheet,
      icon: const Icon(Iconsax.add),
      label: const Text('New Order'),
    ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8));
  }

  void _showCreateOrderSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateOrderSheet(),
    );
  }

  void _showOrderDetails(OrderModel order) {
    // Show order details bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOrderDetailsSheet(order),
    );
  }

  Widget _buildOrderDetailsSheet(OrderModel order) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.orderStatus).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(order.orderStatus.icon, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              order.orderStatus.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(order.orderStatus),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '#${order.id.substring(0, 8).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Customer', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(Iconsax.user, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.customerName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            Text(order.customerPhone, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Iconsax.call, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLocationSection('Pickup', order.pickupAddress, Iconsax.location),
                  const SizedBox(height: 16),
                  _buildLocationSection('Dropoff', order.dropoffAddress, Iconsax.location_tick),
                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Notes', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        children: [
                          Icon(Iconsax.note_text, size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(child: Text(order.notes!, style: TextStyle(color: AppColors.textSecondary))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(Iconsax.money, '${order.amount?.toStringAsFixed(2) ?? '0.00'} TND', 'Amount'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(Iconsax.timer_1, '${order.estimatedMinutes ?? 0} min', 'ETA'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(Iconsax.routing_2, '${order.distanceKm?.toStringAsFixed(1) ?? '0'} km', 'Distance'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (order.isActive) ...[
                    Row(
                      children: [
                        if (order.orderStatus == OrderStatus.pending)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                context.read<OrdersBloc>().add(CancelOrderEvent(order.id));
                              },
                              icon: const Icon(Iconsax.close_circle),
                              label: const Text('Cancel'),
                              style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: BorderSide(color: AppColors.error)),
                            ),
                          ),
                        if (order.orderStatus == OrderStatus.pending) const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              final nextStatus = _getNextStatus(order.orderStatus);
                              if (nextStatus != null) {
                                context.read<OrdersBloc>().add(UpdateOrderStatusEvent(order.id, nextStatus));
                              }
                            },
                            icon: Icon(_getNextStatusIcon(order.orderStatus)),
                            label: Text(_getNextStatusLabel(order.orderStatus)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationSection(String label, String address, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, size: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(address, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          Text(label, style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.assigned:
        return AppColors.info;
      case OrderStatus.pickedUp:
      case OrderStatus.inTransit:
        return AppColors.primary;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  String? _getNextStatus(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'assigned';
      case OrderStatus.assigned:
        return 'picked_up';
      case OrderStatus.pickedUp:
        return 'in_transit';
      case OrderStatus.inTransit:
        return 'delivered';
      default:
        return null;
    }
  }

  String _getNextStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Assign Driver';
      case OrderStatus.assigned:
        return 'Mark Picked Up';
      case OrderStatus.pickedUp:
        return 'Start Delivery';
      case OrderStatus.inTransit:
        return 'Mark Delivered';
      default:
        return 'Complete';
    }
  }

  IconData _getNextStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Iconsax.user_add;
      case OrderStatus.assigned:
        return Iconsax.box;
      case OrderStatus.pickedUp:
        return Iconsax.truck_fast;
      case OrderStatus.inTransit:
        return Iconsax.tick_circle;
      default:
        return Iconsax.tick_circle;
    }
  }
}
