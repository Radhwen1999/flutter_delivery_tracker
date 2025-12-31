import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/websocket_service.dart';

class ConnectionIndicator extends StatelessWidget {
  final ConnectionStatus status;

  const ConnectionIndicator({
    super.key,
    required this.status,
  });

  Color get _color {
    switch (status) {
      case ConnectionStatus.connected:
        return AppColors.success;
      case ConnectionStatus.connecting:
        return AppColors.warning;
      case ConnectionStatus.disconnected:
      case ConnectionStatus.error:
        return AppColors.error;
    }
  }

  IconData get _icon {
    switch (status) {
      case ConnectionStatus.connected:
        return Iconsax.wifi;
      case ConnectionStatus.connecting:
        return Iconsax.refresh;
      case ConnectionStatus.disconnected:
        return Iconsax.wifi_square;
      case ConnectionStatus.error:
        return Iconsax.danger;
    }
  }

  String get _label {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Live';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.disconnected:
        return 'Offline';
      case ConnectionStatus.error:
        return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: AppShadows.small,
        border: Border.all(
          color: _color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == ConnectionStatus.connecting)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_color),
              ),
            )
          else if (status == ConnectionStatus.connected)
            _buildPulsingDot()
          else
            Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 8),
          Text(
            _label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildPulsingDot() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: _color.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(),
        ).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.5, 1.5),
          duration: 1000.ms,
        ).fadeOut(duration: 1000.ms),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _color,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
