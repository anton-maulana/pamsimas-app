// ─── Customer Model ──────────────────────────────────────────────────────────

class Customer {
  final String id;
  final String name;
  final int rt;
  final int rw;
  final String address;
  final String phoneNumber;
  final double meterNumber;
  final int? meterImageId;
  final int? officerId;
  final String status;
  final double? latitude;
  final double? longitude;

  const Customer({
    required this.id,
    required this.name,
    required this.rt,
    required this.rw,
    required this.address,
    required this.phoneNumber,
    required this.meterNumber,
    this.meterImageId,
    this.officerId,
    required this.status,
    this.latitude,
    this.longitude,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'].toString(),
        name: json['name'] as String,
        rt: json['rt'] as int,
        rw: json['rw'] as int,
        address: json['address'] as String,
        phoneNumber: json['phoneNumber'] as String,
        meterNumber: (json['meterNumber'] as num).toDouble(),
        meterImageId: json['meterImageId'] as int?,
        officerId: json['officerId'] as int?,
        status: json['status'] as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}

// ─── Customer Request ────────────────────────────────────────────────────────

class CustomerRequest {
  final String name;
  final int rt;
  final int rw;
  final String address;
  final String phoneNumber;
  final double meterNumber;
  final int? meterImageId;
  final int? officerId;
  final String status;
  final double? latitude;
  final double? longitude;

  const CustomerRequest({
    required this.name,
    required this.rt,
    required this.rw,
    required this.address,
    required this.phoneNumber,
    required this.meterNumber,
    this.meterImageId,
    this.officerId,
    required this.status,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'rt': rt,
        'rw': rw,
        'address': address,
        'phoneNumber': phoneNumber,
        'meterNumber': meterNumber,
        if (meterImageId != null) 'meterImageId': meterImageId,
        if (officerId != null) 'officerId': officerId,
        'status': status,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
}
