import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'order_model.g.dart';

enum OrderStatus {
  pending,
  assigned,
  pickedUp,
  inTransit,
  delivered,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.assigned:
        return 'Assigned';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.inTransit:
        return 'In Transit';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get icon {
    switch (this) {
      case OrderStatus.pending:
        return '⏳';
      case OrderStatus.assigned:
        return '👤';
      case OrderStatus.pickedUp:
        return '📦';
      case OrderStatus.inTransit:
        return '🚚';
      case OrderStatus.delivered:
        return '✅';
      case OrderStatus.cancelled:
        return '❌';
    }
  }

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'assigned':
        return OrderStatus.assigned;
      case 'picked_up':
      case 'pickedup':
        return OrderStatus.pickedUp;
      case 'in_transit':
      case 'intransit':
        return OrderStatus.inTransit;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  String toJsonString() {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.assigned:
        return 'assigned';
      case OrderStatus.pickedUp:
        return 'picked_up';
      case OrderStatus.inTransit:
        return 'in_transit';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }
}

@HiveType(typeId: 1)
class LocationPoint {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final String address;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      address: json['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
  };
}

@HiveType(typeId: 2)
class OrderModel extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String customerId;

  @HiveField(2)
  final String customerName;

  @HiveField(3)
  final String customerPhone;

  @HiveField(4)
  final String? driverId;

  @HiveField(5)
  final String status;

  @HiveField(6)
  final double pickupLat;

  @HiveField(7)
  final double pickupLng;

  @HiveField(8)
  final String pickupAddress;

  @HiveField(9)
  final double dropoffLat;

  @HiveField(10)
  final double dropoffLng;

  @HiveField(11)
  final String dropoffAddress;

  @HiveField(12)
  final String? notes;

  @HiveField(13)
  final double? amount;

  @HiveField(14)
  final String? paymentMethod;

  @HiveField(15)
  final DateTime createdAt;

  @HiveField(16)
  final DateTime? assignedAt;

  @HiveField(17)
  final DateTime? pickedUpAt;

  @HiveField(18)
  final DateTime? deliveredAt;

  @HiveField(19)
  final int? estimatedMinutes;

  @HiveField(20)
  final double? distanceKm;

  const OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.driverId,
    required this.status,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    required this.dropoffLat,
    required this.dropoffLng,
    required this.dropoffAddress,
    this.notes,
    this.amount,
    this.paymentMethod,
    required this.createdAt,
    this.assignedAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.estimatedMinutes,
    this.distanceKm,
  });

  OrderStatus get orderStatus => OrderStatusX.fromString(status);

  LocationPoint get pickupLocation => LocationPoint(
    latitude: pickupLat,
    longitude: pickupLng,
    address: pickupAddress,
  );

  LocationPoint get dropoffLocation => LocationPoint(
    latitude: dropoffLat,
    longitude: dropoffLng,
    address: dropoffAddress,
  );

  bool get isActive =>
      orderStatus != OrderStatus.delivered &&
          orderStatus != OrderStatus.cancelled;

  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? driverId,
    String? status,
    double? pickupLat,
    double? pickupLng,
    String? pickupAddress,
    double? dropoffLat,
    double? dropoffLng,
    String? dropoffAddress,
    String? notes,
    double? amount,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? assignedAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
    int? estimatedMinutes,
    double? distanceKm,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      notes: notes ?? this.notes,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      assignedAt: assignedAt ?? this.assignedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String? ?? json['customerId'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? json['customerName'] as String? ?? '',
      customerPhone: json['customer_phone'] as String? ?? json['customerPhone'] as String? ?? '',
      driverId: json['driver_id'] as String? ?? json['driverId'] as String?,
      status: json['status'] as String? ?? 'pending',
      pickupLat: (json['pickup_lat'] as num?)?.toDouble() ?? (json['pickupLat'] as num?)?.toDouble() ?? 0,
      pickupLng: (json['pickup_lng'] as num?)?.toDouble() ?? (json['pickupLng'] as num?)?.toDouble() ?? 0,
      pickupAddress: json['pickup_address'] as String? ?? json['pickupAddress'] as String? ?? '',
      dropoffLat: (json['dropoff_lat'] as num?)?.toDouble() ?? (json['dropoffLat'] as num?)?.toDouble() ?? 0,
      dropoffLng: (json['dropoff_lng'] as num?)?.toDouble() ?? (json['dropoffLng'] as num?)?.toDouble() ?? 0,
      dropoffAddress: json['dropoff_address'] as String? ?? json['dropoffAddress'] as String? ?? '',
      notes: json['notes'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      paymentMethod: json['payment_method'] as String? ?? json['paymentMethod'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      assignedAt: json['assigned_at'] != null
          ? DateTime.parse(json['assigned_at'] as String)
          : json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'] as String)
          : null,
      pickedUpAt: json['picked_up_at'] != null
          ? DateTime.parse(json['picked_up_at'] as String)
          : json['pickedUpAt'] != null
          ? DateTime.parse(json['pickedUpAt'] as String)
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      estimatedMinutes: json['estimated_minutes'] as int? ?? json['estimatedMinutes'] as int?,
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_id': customerId,
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'driver_id': driverId,
    'status': status,
    'pickup_lat': pickupLat,
    'pickup_lng': pickupLng,
    'pickup_address': pickupAddress,
    'dropoff_lat': dropoffLat,
    'dropoff_lng': dropoffLng,
    'dropoff_address': dropoffAddress,
    'notes': notes,
    'amount': amount,
    'payment_method': paymentMethod,
    'created_at': createdAt.toIso8601String(),
    'assigned_at': assignedAt?.toIso8601String(),
    'picked_up_at': pickedUpAt?.toIso8601String(),
    'delivered_at': deliveredAt?.toIso8601String(),
    'estimated_minutes': estimatedMinutes,
    'distance_km': distanceKm,
  };

  @override
  List<Object?> get props => [
    id,
    customerId,
    customerName,
    customerPhone,
    driverId,
    status,
    pickupLat,
    pickupLng,
    pickupAddress,
    dropoffLat,
    dropoffLng,
    dropoffAddress,
    notes,
    amount,
    paymentMethod,
    createdAt,
    assignedAt,
    pickedUpAt,
    deliveredAt,
    estimatedMinutes,
    distanceKm,
  ];
}

// Manual Hive adapters
class LocationPointAdapter extends TypeAdapter<LocationPoint> {
  @override
  final int typeId = 1;

  @override
  LocationPoint read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocationPoint(
      latitude: fields[0] as double,
      longitude: fields[1] as double,
      address: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LocationPoint obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.address);
  }
}

class OrderModelAdapter extends TypeAdapter<OrderModel> {
  @override
  final int typeId = 2;

  @override
  OrderModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrderModel(
      id: fields[0] as String,
      customerId: fields[1] as String,
      customerName: fields[2] as String,
      customerPhone: fields[3] as String,
      driverId: fields[4] as String?,
      status: fields[5] as String,
      pickupLat: fields[6] as double,
      pickupLng: fields[7] as double,
      pickupAddress: fields[8] as String,
      dropoffLat: fields[9] as double,
      dropoffLng: fields[10] as double,
      dropoffAddress: fields[11] as String,
      notes: fields[12] as String?,
      amount: fields[13] as double?,
      paymentMethod: fields[14] as String?,
      createdAt: fields[15] as DateTime,
      assignedAt: fields[16] as DateTime?,
      pickedUpAt: fields[17] as DateTime?,
      deliveredAt: fields[18] as DateTime?,
      estimatedMinutes: fields[19] as int?,
      distanceKm: fields[20] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, OrderModel obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerId)
      ..writeByte(2)
      ..write(obj.customerName)
      ..writeByte(3)
      ..write(obj.customerPhone)
      ..writeByte(4)
      ..write(obj.driverId)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.pickupLat)
      ..writeByte(7)
      ..write(obj.pickupLng)
      ..writeByte(8)
      ..write(obj.pickupAddress)
      ..writeByte(9)
      ..write(obj.dropoffLat)
      ..writeByte(10)
      ..write(obj.dropoffLng)
      ..writeByte(11)
      ..write(obj.dropoffAddress)
      ..writeByte(12)
      ..write(obj.notes)
      ..writeByte(13)
      ..write(obj.amount)
      ..writeByte(14)
      ..write(obj.paymentMethod)
      ..writeByte(15)
      ..write(obj.createdAt)
      ..writeByte(16)
      ..write(obj.assignedAt)
      ..writeByte(17)
      ..write(obj.pickedUpAt)
      ..writeByte(18)
      ..write(obj.deliveredAt)
      ..writeByte(19)
      ..write(obj.estimatedMinutes)
      ..writeByte(20)
      ..write(obj.distanceKm);
  }
}