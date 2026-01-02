import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/order_model.dart';
import '../bloc/orders_bloc.dart';

class CreateOrderSheet extends StatefulWidget {
  const CreateOrderSheet({super.key});

  @override
  State<CreateOrderSheet> createState() => _CreateOrderSheetState();
}

class _CreateOrderSheetState extends State<CreateOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _pickupAddressController = TextEditingController();
  final _dropoffAddressController = TextEditingController();
  final _notesController = TextEditingController();
  final _amountController = TextEditingController();
  
  String _paymentMethod = 'cash';

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _pickupAddressController.dispose();
    _dropoffAddressController.dispose();
    _notesController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
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
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: const Icon(Iconsax.box_add, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('New Order', style: Theme.of(context).textTheme.titleLarge),
                              Text('Fill in the delivery details', style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Iconsax.close_circle, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildSectionTitle('Customer Information'),
                    const SizedBox(height: 12),
                    _buildTextField(controller: _customerNameController, label: 'Customer Name', hint: 'Enter customer name', icon: Iconsax.user, validator: (v) => v?.isEmpty == true ? 'Required' : null),
                    const SizedBox(height: 12),
                    _buildTextField(controller: _customerPhoneController, label: 'Phone Number', hint: '+216 XX XXX XXX', icon: Iconsax.call, keyboardType: TextInputType.phone, validator: (v) => v?.isEmpty == true ? 'Required' : null),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Delivery Locations'),
                    const SizedBox(height: 12),
                    _buildTextField(controller: _pickupAddressController, label: 'Pickup Address', hint: 'Enter pickup location', icon: Iconsax.location, maxLines: 2, validator: (v) => v?.isEmpty == true ? 'Required' : null),
                    const SizedBox(height: 12),
                    _buildTextField(controller: _dropoffAddressController, label: 'Dropoff Address', hint: 'Enter delivery location', icon: Iconsax.location_tick, maxLines: 2, validator: (v) => v?.isEmpty == true ? 'Required' : null),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Order Details'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField(controller: _amountController, label: 'Amount (TND)', hint: '0.00', icon: Iconsax.money, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Payment', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              Row(children: [_buildPaymentChip('cash', 'Cash'), const SizedBox(width: 8), _buildPaymentChip('card', 'Card')]),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(controller: _notesController, label: 'Notes (Optional)', hint: 'Add any special instructions', icon: Iconsax.note_text, maxLines: 3),
                    const SizedBox(height: 32),
                    BlocBuilder<OrdersBloc, OrdersState>(
                      builder: (context, state) {
                        final isCreating = state is OrdersLoaded && state.isCreating;
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isCreating ? null : _submitOrder,
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                            child: isCreating
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Iconsax.add_circle), SizedBox(width: 8), Text('Create Order')]),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary));

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, required IconData icon, int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        TextFormField(controller: controller, maxLines: maxLines, keyboardType: keyboardType, validator: validator, decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, size: 20))),
      ],
    );
  }

  Widget _buildPaymentChip(String value, String label) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: isSelected ? AppColors.primary : AppColors.surfaceVariant, borderRadius: BorderRadius.circular(AppRadius.md)),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textSecondary)),
      ),
    );
  }

  void _submitOrder() {
    if (_formKey.currentState?.validate() != true) return;
    final order = OrderModel(
      id: _uuid.v4(), customerId: _uuid.v4(), customerName: _customerNameController.text, customerPhone: _customerPhoneController.text,
      status: 'pending', pickupLat: 36.8065, pickupLng: 10.1815, pickupAddress: _pickupAddressController.text,
      dropoffLat: 36.8100, dropoffLng: 10.1900, dropoffAddress: _dropoffAddressController.text,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null, amount: double.tryParse(_amountController.text),
      paymentMethod: _paymentMethod, createdAt: DateTime.now(), estimatedMinutes: 15, distanceKm: 3.5,
    );
    context.read<OrdersBloc>().add(CreateOrderEvent(order));
    Navigator.pop(context);
  }
}
