import 'package:google_maps_flutter/google_maps_flutter.dart';

class AnimalLocation {
  final String animalId;
  final String deviceId;
  final LatLng coordinates;
  final DateTime lastUpdated;
  final String status;

  AnimalLocation({
    required this.animalId,
    required this.deviceId,
    required this.coordinates,
    required this.lastUpdated,
    required this.status,
  });

  AnimalLocation copyWith({
    String? animalId,
    String? deviceId,
    LatLng? coordinates,
    DateTime? lastUpdated,
    String? status,
  }) {
    return AnimalLocation(
      animalId: animalId ?? this.animalId,
      deviceId: deviceId ?? this.deviceId,
      coordinates: coordinates ?? this.coordinates,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animalId': animalId,
      'deviceId': deviceId,
      'coordinates': {
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
      },
      'lastUpdated': lastUpdated.toIso8601String(),
      'status': status,
    };
  }

  factory AnimalLocation.fromJson(Map<String, dynamic> json) {
    try {
      return AnimalLocation(
        animalId: json['animalId'] ?? '',
        deviceId: json['deviceId'] ?? '',
        coordinates: LatLng(
          json['coordinates']?['latitude']?.toDouble() ?? 0.0,
          json['coordinates']?['longitude']?.toDouble() ?? 0.0,
        ),
        lastUpdated:
            DateTime.tryParse(json['lastUpdated'] ?? '') ?? DateTime.now(),
        status: json['status'] ?? 'Unknown',
      );
    } catch (e) {
      print('Error parsing AnimalLocation from JSON: $e');
      // Return a default location if parsing fails
      return AnimalLocation(
        animalId: json['animalId'] ?? '',
        deviceId: json['deviceId'] ?? '',
        coordinates: LatLng(0.0, 0.0),
        lastUpdated: DateTime.now(),
        status: 'Unknown',
      );
    }
  }

  @override
  String toString() {
    return 'AnimalLocation(animalId: $animalId, status: $status, coordinates: $coordinates)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnimalLocation && other.animalId == animalId;
  }

  @override
  int get hashCode => animalId.hashCode;
}
