import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/websocket_service.dart';
import '../../data/models/driver_model.dart';
import '../bloc/tracking_bloc.dart';
import '../widgets/driver_bottom_sheet.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/map_controls.dart';
import '../widgets/driver_marker_info.dart';

class MapViewPage extends StatefulWidget {
  const MapViewPage({super.key});

  @override
  State<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // Tunis, Tunisia coordinates
  static const LatLng _defaultCenter = LatLng(36.8065, 10.1815);
  static const double _defaultZoom = 13.0;
  
  BitmapDescriptor? _availableMarker;
  BitmapDescriptor? _busyMarker;
  BitmapDescriptor? _offlineMarker;
  
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadCustomMarkers();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadCustomMarkers() async {
    // Using default markers with custom hue for now
    // In production, you'd load custom PNG markers
    _availableMarker = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    _busyMarker = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    _offlineMarker = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    setState(() {});
  }

  void _updateMarkers(List<DriverModel> drivers, DriverModel? selectedDriver) {
    _markers = drivers.map((driver) {
      BitmapDescriptor icon;
      switch (driver.driverStatus) {
        case DriverStatus.available:
          icon = _availableMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
          break;
        case DriverStatus.busy:
          icon = _busyMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
          break;
        case DriverStatus.offline:
          icon = _offlineMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
          break;
      }

      return Marker(
        markerId: MarkerId(driver.id),
        position: LatLng(driver.latitude, driver.longitude),
        icon: icon,
        rotation: driver.heading,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: driver.name,
          snippet: '${driver.driverStatus.label} • ${driver.vehicle}',
        ),
        onTap: () {
          context.read<TrackingBloc>().add(SelectDriverEvent(driver));
        },
      );
    }).toSet();
    
    setState(() {});
  }

  void _animateToDriver(DriverModel driver) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(driver.latitude, driver.longitude),
        16.0,
      ),
    );
  }

  void _fitAllDrivers(List<DriverModel> drivers) {
    if (drivers.isEmpty) return;
    
    double minLat = drivers.first.latitude;
    double maxLat = drivers.first.latitude;
    double minLng = drivers.first.longitude;
    double maxLng = drivers.first.longitude;
    
    for (final driver in drivers) {
      if (driver.latitude < minLat) minLat = driver.latitude;
      if (driver.latitude > maxLat) maxLat = driver.latitude;
      if (driver.longitude < minLng) minLng = driver.longitude;
      if (driver.longitude > maxLng) maxLng = driver.longitude;
    }
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat - 0.01, minLng - 0.01),
          northeast: LatLng(maxLat + 0.01, maxLng + 0.01),
        ),
        80,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrackingBloc, TrackingState>(
      listener: (context, state) {
        if (state is TrackingLoaded) {
          _updateMarkers(state.drivers, state.selectedDriver);
          
          if (state.selectedDriver != null) {
            _animateToDriver(state.selectedDriver!);
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              // Google Map
              _buildMap(state),
              
              // Top gradient overlay
              _buildTopOverlay(),
              
              // Header
              _buildHeader(state),
              
              // Stats cards
              if (state is TrackingLoaded) _buildStatsCards(state),
              
              // Map controls
              if (state is TrackingLoaded)
                Positioned(
                  right: 16,
                  bottom: 180,
                  child: MapControls(
                    onMyLocation: () async {
                      if (state.myLatitude != null && state.myLongitude != null) {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLng(
                            LatLng(state.myLatitude!, state.myLongitude!),
                          ),
                        );
                      }
                    },
                    onFitAll: () => _fitAllDrivers(state.drivers),
                    onZoomIn: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                    onZoomOut: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                  ),
                ),
              
              // Connection indicator
              if (state is TrackingLoaded)
                Positioned(
                  left: 16,
                  bottom: 140,
                  child: ConnectionIndicator(status: state.connectionStatus),
                ),
              
              // Driver bottom sheet
              if (state is TrackingLoaded && state.selectedDriver != null)
                DriverBottomSheet(
                  driver: state.selectedDriver!,
                  onClose: () {
                    context.read<TrackingBloc>().add(DeselectDriverEvent());
                  },
                  onNavigate: () {
                    // Open external navigation
                  },
                  onCall: () {
                    // Open phone dialer
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMap(TrackingState state) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: _defaultCenter,
        zoom: _defaultZoom,
      ),
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (controller) {
        _mapController = controller;
        _setMapStyle(controller);
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      buildingsEnabled: true,
      trafficEnabled: false,
      mapType: MapType.normal,
      onTap: (_) {
        if (state is TrackingLoaded && state.selectedDriver != null) {
          context.read<TrackingBloc>().add(DeselectDriverEvent());
        }
      },
    );
  }

  void _setMapStyle(GoogleMapController controller) async {
    // Custom map style for a cleaner look
    const String mapStyle = '''
    [
      {
        "featureType": "poi",
        "elementType": "labels",
        "stylers": [{ "visibility": "off" }]
      },
      {
        "featureType": "transit",
        "elementType": "labels",
        "stylers": [{ "visibility": "off" }]
      },
      {
        "featureType": "road",
        "elementType": "labels.icon",
        "stylers": [{ "visibility": "off" }]
      },
      {
        "featureType": "water",
        "elementType": "geometry.fill",
        "stylers": [{ "color": "#d4e4f7" }]
      },
      {
        "featureType": "landscape",
        "elementType": "geometry.fill",
        "stylers": [{ "color": "#f5f5f5" }]
      }
    ]
    ''';
    
    await controller.setMapStyle(mapStyle);
  }

  Widget _buildTopOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.white.withOpacity(0.9),
              Colors.white.withOpacity(0),
            ],
            stops: const [0, 0.6, 1],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(TrackingState state) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.small,
                  ),
                  child: const Icon(
                    Iconsax.location5,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Tracking',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (state is TrackingLoaded)
                        Text(
                          '${state.drivers.length} drivers on duty',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.small,
                  ),
                  child: const Icon(
                    Iconsax.notification,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(TrackingLoaded state) {
    return Positioned(
      top: 120,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 60,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            _buildStatCard(
              icon: Iconsax.tick_circle,
              label: 'Available',
              count: state.availableCount,
              color: AppColors.success,
              isSelected: state.statusFilter == DriverStatus.available,
              onTap: () {
                context.read<TrackingBloc>().add(
                  FilterDriversEvent(
                    state.statusFilter == DriverStatus.available 
                        ? null 
                        : DriverStatus.available,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Iconsax.truck_fast,
              label: 'In Transit',
              count: state.busyCount,
              color: AppColors.warning,
              isSelected: state.statusFilter == DriverStatus.busy,
              onTap: () {
                context.read<TrackingBloc>().add(
                  FilterDriversEvent(
                    state.statusFilter == DriverStatus.busy 
                        ? null 
                        : DriverStatus.busy,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              icon: Iconsax.moon,
              label: 'Offline',
              count: state.offlineCount,
              color: AppColors.textTertiary,
              isSelected: state.statusFilter == DriverStatus.offline,
              onTap: () {
                context.read<TrackingBloc>().add(
                  FilterDriversEvent(
                    state.statusFilter == DriverStatus.offline 
                        ? null 
                        : DriverStatus.offline,
                  ),
                );
              },
            ),
          ],
        ),
      ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
          boxShadow: AppShadows.small,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? color : AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? color : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
