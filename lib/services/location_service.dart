import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/animal_location.dart';
import '../models/animal.dart';

class LocationService {
  static const String _storageKey = 'animal_locations';

  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // In-memory cache
  Map<String, AnimalLocation> _locations = {};

  // Farm center coordinates (you can adjust these)
  final LatLng _farmCenter = LatLng(12.345, 56.789);
  final double _geofenceRadius = 500.0; // meters

  Future<void> initialize() async {
    await _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = prefs.getString(_storageKey);

      if (locationsJson != null) {
        final Map<String, dynamic> locationsMap = json.decode(locationsJson);
        _locations = locationsMap.map(
          (key, value) => MapEntry(key, AnimalLocation.fromJson(value)),
        );
      } else {
        _locations = {};
      }
    } catch (e) {
      print('Error loading locations: $e');
      _locations = {};
    }
  }

  Future<void> _saveLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsMap = _locations.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      final locationsJson = json.encode(locationsMap);
      await prefs.setString(_storageKey, locationsJson);
    } catch (e) {
      print('Error saving locations: $e');
    }
  }

  // Generate location for a new animal based on device ID
  Future<AnimalLocation> generateLocationForAnimal(Animal animal) async {
    // Generate deterministic coordinates based on device ID
    final random = Random(animal.deviceId.hashCode);

    // Generate coordinates within the geofence area
    final angle = random.nextDouble() * 2 * pi;
    final distance =
        random.nextDouble() * _geofenceRadius * 0.8; // 80% of geofence radius

    final latOffset =
        distance * cos(angle) / 111000; // Convert meters to degrees
    final lngOffset =
        distance * sin(angle) / (111000 * cos(_farmCenter.latitude * pi / 180));

    final coordinates = LatLng(
      _farmCenter.latitude + latOffset,
      _farmCenter.longitude + lngOffset,
    );

    // Determine status based on distance from center
    final distanceFromCenter = _calculateDistance(_farmCenter, coordinates);
    String status;
    if (distanceFromCenter <= _geofenceRadius * 0.7) {
      status = 'Inside Fence';
    } else if (distanceFromCenter <= _geofenceRadius) {
      status = 'Near Boundary';
    } else {
      status = 'Outside Fence';
    }

    final location = AnimalLocation(
      animalId: animal.id,
      deviceId: animal.deviceId,
      coordinates: coordinates,
      lastUpdated: DateTime.now(),
      status: status,
    );

    _locations[animal.id] = location;
    await _saveLocations();

    return location;
  }

  // Update location for existing animal
  Future<void> updateAnimalLocation(
    String animalId,
    LatLng newCoordinates,
  ) async {
    if (_locations.containsKey(animalId)) {
      final currentLocation = _locations[animalId]!;
      final distanceFromCenter = _calculateDistance(
        _farmCenter,
        newCoordinates,
      );

      String status;
      if (distanceFromCenter <= _geofenceRadius * 0.7) {
        status = 'Inside Fence';
      } else if (distanceFromCenter <= _geofenceRadius) {
        status = 'Near Boundary';
      } else {
        status = 'Outside Fence';
      }

      _locations[animalId] = currentLocation.copyWith(
        coordinates: newCoordinates,
        lastUpdated: DateTime.now(),
        status: status,
      );

      await _saveLocations();
    }
  }

  // Get location for specific animal
  AnimalLocation? getAnimalLocation(String animalId) {
    return _locations[animalId];
  }

  // Get all animal locations
  List<AnimalLocation> getAllLocations() {
    return _locations.values.toList();
  }

  // Get locations by status
  List<AnimalLocation> getLocationsByStatus(String status) {
    return _locations.values
        .where((location) => location.status == status)
        .toList();
  }

  // Update location based on real GPS data (would be called by actual device)
  Future<void> updateLocationFromDevice(String animalId, LatLng newCoordinates) async {
    await updateAnimalLocation(animalId, newCoordinates);
  }

  // Calculate distance between two points
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters

    final lat1Rad = point1.latitude * pi / 180;
    final lat2Rad = point2.latitude * pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLng = (point2.longitude - point1.longitude) * pi / 180;

    final a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLng / 2) * sin(deltaLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // Get farm center and geofence info
  LatLng get farmCenter => _farmCenter;
  double get geofenceRadius => _geofenceRadius;

  // Check if coordinates are inside geofence
  bool isInsideGeofence(LatLng coordinates) {
    final distance = _calculateDistance(_farmCenter, coordinates);
    return distance <= _geofenceRadius;
  }

  // Get status color
  Color getStatusColor(String status) {
    switch (status) {
      case 'Inside Fence':
        return Colors.green;
      case 'Near Boundary':
        return Colors.amber;
      case 'Outside Fence':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get marker hue for Google Maps
  double getMarkerHue(String status) {
    switch (status) {
      case 'Inside Fence':
        return BitmapDescriptor.hueGreen;
      case 'Near Boundary':
        return BitmapDescriptor.hueYellow;
      case 'Outside Fence':
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueBlue;
    }
  }
}
