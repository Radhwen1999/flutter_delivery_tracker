import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/driver_model.dart';

class DriverBottomSheet extends StatelessWidget {
  final DriverModel driver;
  final VoidCallback onClose;
  final VoidCallback? onNavigate;
  final VoidCallback? onCall;

  const DriverBottomSheet({
    super.key,
    required this.driver,
    required this.onClose,
    this.onNavigate,
    this.onCall,
  });

  Color get _statusColor {
    switch (driver.driverStatus) {
      case DriverStatus.available:
        return AppColors.success;
      case DriverStatus.busy:
        return AppColors.warning;
      case DriverStatus.offline:
        return AppColors.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 100,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          boxShadow: AppShadows.large,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildAvatar(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    driver.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: onClose,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceVariant,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Iconsax.close_circle,
                                      size: 20,
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildStatusBadge(),
                                const SizedBox(width: 8),
                                Row(
                                  children: [
                                    Icon(Iconsax.star1, size: 14, color: AppColors.warning),
                                    const SizedBox(width: 4),
                                    Text(
                                      driver.rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Icon(Iconsax.car, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driver.vehicle,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                driver.plate,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (driver.driverStatus == DriverStatus.busy && driver.speed > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.speedometer, size: 14, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text(
                                  '${driver.speed.toStringAsFixed(0)} km/h',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildStatCard(Iconsax.box_tick, '${driver.completedOrders}', 'Completed', AppColors.success)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildStatCard(Iconsax.timer_1, '4.2', 'Avg. mins', AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onCall,
                          icon: const Icon(Iconsax.call),
                          label: const Text('Call'),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: onNavigate,
                          icon: const Icon(Iconsax.location),
                          label: const Text('Navigate'),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.3, curve: Curves.easeOutCubic),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient, boxShadow: AppShadows.colored),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ClipOval(
              child: driver.avatar != null
                  ? CachedNetworkImage(imageUrl: driver.avatar!, fit: BoxFit.cover, placeholder: (c, u) => _buildPlaceholder(), errorWidget: (c, u, e) => _buildPlaceholder())
                  : _buildPlaceholder(),
            ),
          ),
        ),
        Positioned(right: 2, bottom: 2, child: Container(width: 18, height: 18, decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle, border: Border.all(color: AppColors.surface, width: 3)))),
      ],
    );
  }

  Widget _buildPlaceholder() => Container(color: AppColors.surfaceVariant, child: Center(child: Text(driver.name.substring(0, 1).toUpperCase(), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary))));

  Widget _buildStatusBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: _statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(AppRadius.full)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle)), const SizedBox(width: 6), Text(driver.driverStatus.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor))]),
  );

  Widget _buildStatCard(IconData icon, String value, String label, Color color) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(AppRadius.lg)),
    child: Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)), Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary))])]),
  );
}
