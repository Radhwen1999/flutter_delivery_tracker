import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/driver_model.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../../../../core/services/websocket_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/notification_service.dart';

// Events
abstract class TrackingEvent extends Equatable {
  const TrackingEvent();
  
  @override
  List<Object?> get props => [];
}

class InitializeTrackingEvent extends TrackingEvent {}

class LoadDriversEvent extends TrackingEvent {}

class SelectDriverEvent extends TrackingEvent {
  final DriverModel driver;
  
  const SelectDriverEvent(this.driver);
  
  @override
  List<Object?> get props => [driver];
}

class DeselectDriverEvent extends TrackingEvent {}

class DriverLocationUpdatedEvent extends TrackingEvent {
  final String driverId;
  final double latitude;
  final double longitude;
  final double heading;
  final double speed;
  
  const DriverLocationUpdatedEvent({
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.speed,
  });
  
  @override
  List<Object?> get props => [driverId, latitude, longitude, heading, speed];
}

class DriversUpdatedEvent extends TrackingEvent {
  final List<DriverModel> drivers;
  
  const DriversUpdatedEvent(this.drivers);
  
  @override
  List<Object?> get props => [drivers];
}

class ToggleDriverModeEvent extends TrackingEvent {}

class UpdateMyLocationEvent extends TrackingEvent {
  final double latitude;
  final double longitude;
  
  const UpdateMyLocationEvent({
    required this.latitude,
    required this.longitude,
  });
  
  @override
  List<Object?> get props => [latitude, longitude];
}

class WebSocketStatusChangedEvent extends TrackingEvent {
  final ConnectionStatus status;
  
  const WebSocketStatusChangedEvent(this.status);
  
  @override
  List<Object?> get props => [status];
}

class FilterDriversEvent extends TrackingEvent {
  final DriverStatus? statusFilter;
  
  const FilterDriversEvent(this.statusFilter);
  
  @override
  List<Object?> get props => [statusFilter];
}

// States
abstract class TrackingState extends Equatable {
  const TrackingState();
  
  @override
  List<Object?> get props => [];
}

class TrackingInitial extends TrackingState {}

class TrackingLoading extends TrackingState {}

class TrackingLoaded extends TrackingState {
  final List<DriverModel> drivers;
  final List<DriverModel> filteredDrivers;
  final DriverModel? selectedDriver;
  final bool isDriverMode;
  final ConnectionStatus connectionStatus;
  final double? myLatitude;
  final double? myLongitude;
  final DriverStatus? statusFilter;
  
  const TrackingLoaded({
    required this.drivers,
    List<DriverModel>? filteredDrivers,
    this.selectedDriver,
    this.isDriverMode = false,
    this.connectionStatus = ConnectionStatus.disconnected,
    this.myLatitude,
    this.myLongitude,
    this.statusFilter,
  }) : filteredDrivers = filteredDrivers ?? drivers;
  
  int get availableCount => drivers.where((d) => d.driverStatus == DriverStatus.available).length;
  int get busyCount => drivers.where((d) => d.driverStatus == DriverStatus.busy).length;
  int get offlineCount => drivers.where((d) => d.driverStatus == DriverStatus.offline).length;
  
  TrackingLoaded copyWith({
    List<DriverModel>? drivers,
    List<DriverModel>? filteredDrivers,
    DriverModel? selectedDriver,
    bool? clearSelectedDriver,
    bool? isDriverMode,
    ConnectionStatus? connectionStatus,
    double? myLatitude,
    double? myLongitude,
    DriverStatus? statusFilter,
    bool? clearStatusFilter,
  }) {
    return TrackingLoaded(
      drivers: drivers ?? this.drivers,
      filteredDrivers: filteredDrivers ?? this.filteredDrivers,
      selectedDriver: clearSelectedDriver == true ? null : selectedDriver ?? this.selectedDriver,
      isDriverMode: isDriverMode ?? this.isDriverMode,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      myLatitude: myLatitude ?? this.myLatitude,
      myLongitude: myLongitude ?? this.myLongitude,
      statusFilter: clearStatusFilter == true ? null : statusFilter ?? this.statusFilter,
    );
  }
  
  @override
  List<Object?> get props => [
    drivers,
    filteredDrivers,
    selectedDriver,
    isDriverMode,
    connectionStatus,
    myLatitude,
    myLongitude,
    statusFilter,
  ];
}

class TrackingError extends TrackingState {
  final String message;
  
  const TrackingError(this.message);
  
  @override
  List<Object?> get props => [message];
}

// BLoC
class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final TrackingRepository trackingRepository;
  final WebSocketService webSocketService;
  final LocationService locationService;
  final NotificationService notificationService;
  
  StreamSubscription? _driversSubscription;
  StreamSubscription? _wsStatusSubscription;
  StreamSubscription? _locationSubscription;
  
  TrackingBloc({
    required this.trackingRepository,
    required this.webSocketService,
    required this.locationService,
    required this.notificationService,
  }) : super(TrackingInitial()) {
    on<InitializeTrackingEvent>(_onInitialize);
    on<LoadDriversEvent>(_onLoadDrivers);
    on<SelectDriverEvent>(_onSelectDriver);
    on<DeselectDriverEvent>(_onDeselectDriver);
    on<DriversUpdatedEvent>(_onDriversUpdated);
    on<ToggleDriverModeEvent>(_onToggleDriverMode);
    on<UpdateMyLocationEvent>(_onUpdateMyLocation);
    on<WebSocketStatusChangedEvent>(_onWebSocketStatusChanged);
    on<FilterDriversEvent>(_onFilterDrivers);
  }
  
  Future<void> _onInitialize(
    InitializeTrackingEvent event,
    Emitter<TrackingState> emit,
  ) async {
    emit(TrackingLoading());
    
    // Connect to WebSocket
    webSocketService.connect();
    
    // Subscribe to WebSocket status
    _wsStatusSubscription = webSocketService.status.listen((status) {
      add(WebSocketStatusChangedEvent(status));
    });
    
    // Subscribe to driver updates
    _driversSubscription = webSocketService.driverLocations.listen((driversJson) {
      final drivers = driversJson.map((json) => DriverModel.fromJson(json)).toList();
      add(DriversUpdatedEvent(drivers));
    });
    
    // Load initial drivers
    add(LoadDriversEvent());
    
    // Get current location
    final location = await locationService.getCurrentLocation();
    if (location != null) {
      add(UpdateMyLocationEvent(
        latitude: location.latitude,
        longitude: location.longitude,
      ));
    }
  }
  
  Future<void> _onLoadDrivers(
    LoadDriversEvent event,
    Emitter<TrackingState> emit,
  ) async {
    final result = await trackingRepository.getDrivers();
    
    result.fold(
      (error) {
        if (state is TrackingLoaded) {
          // Keep current state but show error
          debugPrint('🚗 TrackingBloc: Error loading drivers: $error');
        } else {
          emit(TrackingError(error));
        }
      },
      (drivers) {
        if (state is TrackingLoaded) {
          final currentState = state as TrackingLoaded;
          emit(currentState.copyWith(drivers: drivers, filteredDrivers: drivers));
        } else {
          emit(TrackingLoaded(
            drivers: drivers,
            connectionStatus: webSocketService.currentStatus,
          ));
        }
      },
    );
  }
  
  void _onSelectDriver(
    SelectDriverEvent event,
    Emitter<TrackingState> emit,
  ) {
    if (state is TrackingLoaded) {
      final currentState = state as TrackingLoaded;
      emit(currentState.copyWith(selectedDriver: event.driver));
    }
  }
  
  void _onDeselectDriver(
    DeselectDriverEvent event,
    Emitter<TrackingState> emit,
  ) {
    if (state is TrackingLoaded) {
      final currentState = state as TrackingLoaded;
      emit(currentState.copyWith(clearSelectedDriver: true));
    }
  }
  
  void _onDriversUpdated(
    DriversUpdatedEvent event,
    Emitter<TrackingState> emit,
  ) {
    if (state is TrackingLoaded) {
      final currentState = state as TrackingLoaded;
      
      // Apply current filter if any
      List<DriverModel> filtered = event.drivers;
      if (currentState.statusFilter != null) {
        filtered = event.drivers
            .where((d) => d.driverStatus == currentState.statusFilter)
            .toList();
      }
      
      // Update selected driver with new data
      DriverModel? updatedSelected;
      if (currentState.selectedDriver != null) {
        updatedSelected = event.drivers.firstWhere(
          (d) => d.id == currentState.selectedDriver!.id,
          orElse: () => currentState.selectedDriver!,
        );
      }
      
      emit(currentState.copyWith(
        drivers: event.drivers,
        filteredDrivers: filtered,
        selectedDriver: updatedSelected,
      ));
      
      // Cache drivers for offline use
      trackingRepository.cacheDrivers(event.drivers);
    } else if (state is TrackingLoading || state is TrackingInitial) {
      emit(TrackingLoaded(
        drivers: event.drivers,
        connectionStatus: webSocketService.currentStatus,
      ));
    }
  }
  
  void _onToggleDriverMode(
    ToggleDriverModeEvent event,
    Emitter<TrackingState> emit,
  ) {
    if (state is TrackingLoaded) {
      final currentState = state as TrackingLoaded;
      final newMode = !currentState.isDriverMode;
      
      if (newMode) {
        // Start tracking location when in driver mode
        locationService.startContinuousTracking(
          highPrecision: true,
          onLocation: (location) {
            add(UpdateMyLocationEvent(
              latitude: location.latitude,
              longitude: location.longitude,
            ));
          },
        );
      } else {
        locationService.stopTracking();
      }
      
      emit(currentState.copyWith(isDriverMode: newMode));
    }
  }
  
  void _onUpdateMyLocation(
    UpdateMyLocationEvent event,
    Emitter<TrackingState> emit,
  ) {
    if (state is TrackingLoaded) {
      final currentState = state as TrackingLoaded;
      emit(currentState.copyWith(
        myLatitude: event.latitude,
        myLongitude: event.longitude,
      ));
    }
  }
  
  void _onWebSocketStatusChanged(
    WebSocketStatusChangedEvent event,
    Emitter<TrackingState> emit,
  ) {
    if (state is TrackingLoaded) {
      final currentState = state as TrackingLoaded;
      emit(currentState.copyWith(connectionStatus: event.status));
    }
  }
  
  void _onFilterDrivers(
    FilterDriversEvent event,
    Emitter<TrackingState> emit,
  ) {
    if (state is TrackingLoaded) {
      final currentState = state as TrackingLoaded;
      
      List<DriverModel> filtered;
      if (event.statusFilter == null) {
        filtered = currentState.drivers;
      } else {
        filtered = currentState.drivers
            .where((d) => d.driverStatus == event.statusFilter)
            .toList();
      }
      
      emit(currentState.copyWith(
        filteredDrivers: filtered,
        statusFilter: event.statusFilter,
        clearStatusFilter: event.statusFilter == null,
      ));
    }
  }
  
  @override
  Future<void> close() {
    _driversSubscription?.cancel();
    _wsStatusSubscription?.cancel();
    _locationSubscription?.cancel();
    locationService.stopTracking();
    return super.close();
  }
}
