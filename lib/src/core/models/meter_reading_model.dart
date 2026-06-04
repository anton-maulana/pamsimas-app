// ─── Meter Reading Model ──────────────────────────────────────────────────

class MeterReading {
  final int id;
  final int customerId;
  final String readingDate;
  final double currentMeter;
  final double? previousMeter;
  final double? usage;
  final int? imageId;
  final double? latitude;
  final double? longitude;

  const MeterReading({
    required this.id,
    required this.customerId,
    required this.readingDate,
    required this.currentMeter,
    this.previousMeter,
    this.usage,
    this.imageId,
    this.latitude,
    this.longitude,
  });

  factory MeterReading.fromJson(Map<String, dynamic> json) => MeterReading(
        id: json['id'] as int,
        customerId: json['customer_id'] as int,
        readingDate: json['reading_date'] as String,
        currentMeter: (json['current_meter'] as num).toDouble(),
        previousMeter: (json['previous_meter'] as num?)?.toDouble(),
        usage: (json['usage'] as num?)?.toDouble(),
        imageId: json['image_id'] as int?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );
}

// ─── Meter Reading Request ──────────────────────────────────────────────────

class MeterReadingRequest {
  final int customerId;
  final String readingDate;
  final double currentMeter;
  final double? previousMeter;
  final int? imageId;
  final double? latitude;
  final double? longitude;

  const MeterReadingRequest({
    required this.customerId,
    required this.readingDate,
    required this.currentMeter,
    this.previousMeter,
    this.imageId,
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toJson() => {
        'customer_id': customerId,
        'reading_date': readingDate,
        'current_meter': currentMeter,
        if (previousMeter != null) 'previous_meter': previousMeter,
        if (imageId != null) 'image_id': imageId,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
}
