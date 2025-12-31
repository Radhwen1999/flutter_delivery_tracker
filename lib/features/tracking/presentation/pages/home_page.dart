import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/tracking_bloc.dart';
import 'map_view_page.dart';
import 'driver_list_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  
  final List<Widget> _pages = [
    const MapViewPage(),
    const DriverListPage(),
    const Scaffold(),
    const Scaffold(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrackingBloc, TrackingState>(
      builder: (context, state) {
        final isDriverMode = state is TrackingLoaded && state.isDriverMode;
        
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: _buildBottomNavBar(isDriverMode),
          extendBody: true,
        );
      },
    );
  }

  Widget _buildBottomNavBar(bool isDriverMode) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Iconsax.map,
                activeIcon: Iconsax.map_15,
                label: 'Map',
              ),
              _buildNavItem(
                index: 1,
                icon: Iconsax.people,
                activeIcon: Iconsax.people5,
                label: 'Drivers',
              ),
              _buildNavItem(
                index: 2,
                icon: Iconsax.box,
                activeIcon: Iconsax.box5,
                label: 'Orders',
              ),
              _buildDriverModeItem(isDriverMode),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3, curve: Curves.easeOutCubic);
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDriverModeItem(bool isDriverMode) {
    return GestureDetector(
      onTap: () {
        if (_currentIndex == 3) {
          context.read<TrackingBloc>().add(ToggleDriverModeEvent());
        }
        setState(() => _currentIndex = 3);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isDriverMode ? AppColors.primaryGradient : null,
          color: _currentIndex == 3 && !isDriverMode 
              ? AppColors.primary.withOpacity(0.1) 
              : null,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: isDriverMode ? AppShadows.colored : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDriverMode ? Iconsax.driver5 : Iconsax.driver,
              color: isDriverMode 
                  ? Colors.white 
                  : _currentIndex == 3 
                      ? AppColors.primary 
                      : AppColors.textTertiary,
              size: 24,
            ),
            if (_currentIndex == 3) ...[
              const SizedBox(width: 8),
              Text(
                'Driver',
                style: TextStyle(
                  color: isDriverMode ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
