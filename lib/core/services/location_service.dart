import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:rxdart/rxdart.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final double heading;
  final double speed;
  final double accuracy;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.heading = 0,
    this.speed = 0,
    this.accuracy = 0,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory LocationData.fromPosition(Position position) {
    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      heading: position.heading,
      speed: position.speed,
      accuracy: position.accuracy,
      timestamp: position.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading,
        'speed': speed,
        'accuracy': accuracy,
        'timestamp': timestamp.toIso8601String(),
      };
}

class AddressData {
  final String street;
  final String locality;
  final String city;
  final String country;
  final String postalCode;
  final String fullAddress;

  AddressData({
    this.street = '',
    this.locality = '',
    this.city = '',
    this.country = '',
    this.postalCode = '',
    this.fullAddress = '',
  });

  factory AddressData.fromPlacemark(Placemark placemark) {
    final parts = <String>[];
    if (placemark.street?.isNotEmpty ?? false) parts.add(placemark.street!);
    if (placemark.locality?.isNotEmpty ?? false) parts.add(placemark.locality!);
    if (placemark.administrativeArea?.isNotEmpty ?? false) {
      parts.add(placemark.administrativeArea!);
    }
    if (placemark.country?.isNotEmpty ?? false) parts.add(placemark.country!);

    return AddressData(
      street: placemark.street ?? '',
      locality: placemark.locality ?? '',
      city: placemark.administrativeArea ?? '',
      country: placemark.country ?? '',
      postalCode: placemark.postalCode ?? '',
      fullAddress: parts.join(', '),
    );
  }

  @override
  String toString() => fullAddress.isNotEmpty ? fullAddress : 'Unknown Location';
}

class LocationService {
  StreamSubscription<LocationData>? _positionSubscription;
  final _locationController = BehaviorSubject<LocationData?>();
  final _permissionController = BehaviorSubject<LocationPermission>.seeded(LocationPermission.denied);

  Stream<LocationData?> get locationStream => _locationController.stream;
  Stream<LocationPermission> get permissionStream => _permissionController.stream;
  LocationData? get currentLocation => _locationController.valueOrNull;

  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Update every 10 meters
  );

  static const LocationSettings _highPrecisionSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 5, // Update every 5 meters
  );

  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('📍 Location: Service disabled');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    _permissionController.add(permission);

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      _permissionController.add(permission);
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('📍 Location: Permission denied forever');
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<LocationData?> getCurrentLocation() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );

      final locationData = LocationData.fromPosition(position);
      _locationController.add(locationData);

      debugPrint('📍 Location: ${locationData.latitude}, ${locationData.longitude}');
      return locationData;
    } catch (e) {
      debugPrint('📍 Location Error: $e');
      return null;
    }
  }

  Future<LocationData?> getLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        return LocationData.fromPosition(position);
      }
      return null;
    } catch (e) {
      debugPrint('📍 Location Error: $e');
      return null;
    }
  }

  Stream<LocationData> startTracking({bool highPrecision = false}) {
    return Geolocator.getPositionStream(
      locationSettings: highPrecision ? _highPrecisionSettings : _locationSettings,
    ).map((position) {
      final locationData = LocationData.fromPosition(position);
      _locationController.add(locationData);
      return locationData;
    });
  }

  void startContinuousTracking({
    bool highPrecision = false,
    void Function(LocationData)? onLocation,
  }) {
    stopTracking();

    _positionSubscription = startTracking(highPrecision: highPrecision).listen(
      (location) {
        onLocation?.call(location);
      },
      onError: (error) {
        debugPrint('📍 Location Stream Error: $error');
      },
    );
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<AddressData?> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        return AddressData.fromPlacemark(placemarks.first);
      }
      return null;
    } catch (e) {
      debugPrint('📍 Geocoding Error: $e');
      return null;
    }
  }

  Future<LocationData?> getCoordinatesFromAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LocationData(
          latitude: locations.first.latitude,
          longitude: locations.first.longitude,
        );
      }
      return null;
    } catch (e) {
      debugPrint('📍 Geocoding Error: $e');
      return null;
    }
  }

  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  double calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.bearingBetween(startLat, startLng, endLat, endLng);
  }

  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  String formatDuration(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    } else if (seconds < 3600) {
      return '${(seconds / 60).toStringAsFixed(0)} min';
    } else {
      final hours = seconds ~/ 3600;
      final mins = (seconds % 3600) ~/ 60;
      return '${hours}h ${mins}m';
    }
  }

  int estimateArrivalTime(double distanceMeters, {double avgSpeedKmh = 30}) {
    // Returns seconds
    return ((distanceMeters / 1000) / avgSpeedKmh * 3600).round();
  }

  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  void dispose() {
    stopTracking();
    _locationController.close();
    _permissionController.close();
  }
}
