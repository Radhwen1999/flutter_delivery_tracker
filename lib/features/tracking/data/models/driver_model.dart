import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'driver_model.g.dart';

enum DriverStatus { available, busy, offline }

extension DriverStatusX on DriverStatus {
  String get label {
    switch (this) {
      case DriverStatus.available:
        return 'Available';
      case DriverStatus.busy:
        return 'In Transit';
      case DriverStatus.offline:
        return 'Offline';
    }
  }
  
  static DriverStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return DriverStatus.available;
      case 'busy':
      case 'in_transit':
        return DriverStatus.busy;
      case 'offline':
      default:
        return DriverStatus.offline;
    }
  }
}

@HiveType(typeId: 0)
class DriverModel extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? avatar;
  
  @HiveField(3)
  final String phone;
  
  @HiveField(4)
  final String vehicle;
  
  @HiveField(5)
  final String plate;
  
  @HiveField(6)
  final String status;
  
  @HiveField(7)
  final double latitude;
  
  @HiveField(8)
  final double longitude;
  
  @HiveField(9)
  final double heading;
  
  @HiveField(10)
  final double speed;
  
  @HiveField(11)
  final double rating;
  
  @HiveField(12)
  final int completedOrders;
  
  @HiveField(13)
  final String? currentOrderId;
  
  @HiveField(14)
  final DateTime? lastUpdated;

  const DriverModel({
    required this.id,
    required this.name,
    this.avatar,
    required this.phone,
    required this.vehicle,
    required this.plate,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.heading = 0,
    this.speed = 0,
    this.rating = 5.0,
    this.completedOrders = 0,
    this.currentOrderId,
    this.lastUpdated,
  });

  DriverStatus get driverStatus => DriverStatusX.fromString(status);

  DriverModel copyWith({
    String? id,
    String? name,
    String? avatar,
    String? phone,
    String? vehicle,
    String? plate,
    String? status,
    double? latitude,
    double? longitude,
    double? heading,
    double? speed,
    double? rating,
    int? completedOrders,
    String? currentOrderId,
    DateTime? lastUpdated,
  }) {
    return DriverModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      vehicle: vehicle ?? this.vehicle,
      plate: plate ?? this.plate,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      rating: rating ?? this.rating,
      completedOrders: completedOrders ?? this.completedOrders,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    return DriverModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      phone: json['phone'] as String? ?? '',
      vehicle: json['vehicle'] as String? ?? '',
      plate: json['plate'] as String? ?? '',
      status: json['status'] as String? ?? 'offline',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      completedOrders: json['completedOrders'] as int? ?? json['completed_orders'] as int? ?? 0,
      currentOrderId: json['currentOrderId'] as String? ?? json['current_order_id'] as String?,
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'] as String)
          : json['last_updated'] != null 
              ? DateTime.parse(json['last_updated'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'phone': phone,
    'vehicle': vehicle,
    'plate': plate,
    'status': status,
    'latitude': latitude,
    'longitude': longitude,
    'heading': heading,
    'speed': speed,
    'rating': rating,
    'completed_orders': completedOrders,
    'current_order_id': currentOrderId,
    'last_updated': lastUpdated?.toIso8601String(),
  };

  @override
  List<Object?> get props => [
    id,
    name,
    avatar,
    phone,
    vehicle,
    plate,
    status,
    latitude,
    longitude,
    heading,
    speed,
    rating,
    completedOrders,
    currentOrderId,
    lastUpdated,
  ];
}

// Manual adapter since we can't run build_runner
class DriverModelAdapter extends TypeAdapter<DriverModel> {
  @override
  final int typeId = 0;

  @override
  DriverModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DriverModel(
      id: fields[0] as String,
      name: fields[1] as String,
      avatar: fields[2] as String?,
      phone: fields[3] as String,
      vehicle: fields[4] as String,
      plate: fields[5] as String,
      status: fields[6] as String,
      latitude: fields[7] as double,
      longitude: fields[8] as double,
      heading: fields[9] as double? ?? 0,
      speed: fields[10] as double? ?? 0,
      rating: fields[11] as double? ?? 5.0,
      completedOrders: fields[12] as int? ?? 0,
      currentOrderId: fields[13] as String?,
      lastUpdated: fields[14] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DriverModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.avatar)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.vehicle)
      ..writeByte(5)
      ..write(obj.plate)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.latitude)
      ..writeByte(8)
      ..write(obj.longitude)
      ..writeByte(9)
      ..write(obj.heading)
      ..writeByte(10)
      ..write(obj.speed)
      ..writeByte(11)
      ..write(obj.rating)
      ..writeByte(12)
      ..write(obj.completedOrders)
      ..writeByte(13)
      ..write(obj.currentOrderId)
      ..writeByte(14)
      ..write(obj.lastUpdated);
  }
}
