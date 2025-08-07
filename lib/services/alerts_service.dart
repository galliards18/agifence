import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/animal.dart';
import '../models/animal_location.dart';
import 'animal_service.dart';
import 'location_service.dart';
import 'events_service.dart';

class Alert {
  final String id;
  final String animalId;
  final String animalName;
  final String animalType;
  final String deviceId;
  final String event;
  final String status;
  final Map<String, double> coordinates;
  final DateTime timestamp;
  final String priority;
  final bool isDismissed;

  Alert({
    required this.id,
    required this.animalId,
    required this.animalName,
    required this.animalType,
    required this.deviceId,
    required this.event,
    required this.status,
    required this.coordinates,
    required this.timestamp,
    required this.priority,
    this.isDismissed = false,
  });

  Alert copyWith({
    String? id,
    String? animalId,
    String? animalName,
    String? animalType,
    String? deviceId,
    String? event,
    String? status,
    Map<String, double>? coordinates,
    DateTime? timestamp,
    String? priority,
    bool? isDismissed,
  }) {
    return Alert(
      id: id ?? this.id,
      animalId: animalId ?? this.animalId,
      animalName: animalName ?? this.animalName,
      animalType: animalType ?? this.animalType,
      deviceId: deviceId ?? this.deviceId,
      event: event ?? this.event,
      status: status ?? this.status,
      coordinates: coordinates ?? this.coordinates,
      timestamp: timestamp ?? this.timestamp,
      priority: priority ?? this.priority,
      isDismissed: isDismissed ?? this.isDismissed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'animalId': animalId,
      'animalName': animalName,
      'animalType': animalType,
      'deviceId': deviceId,
      'event': event,
      'status': status,
      'coordinates': coordinates,
      'timestamp': timestamp.toIso8601String(),
      'priority': priority,
      'isDismissed': isDismissed,
    };
  }

  factory Alert.fromJson(Map<String, dynamic> json) {
    try {
      return Alert(
        id: json['id'] ?? '',
        animalId: json['animalId'] ?? '',
        animalName: json['animalName'] ?? '',
        animalType: json['animalType'] ?? '',
        deviceId: json['deviceId'] ?? '',
        event: json['event'] ?? '',
        status: json['status'] ?? '',
        coordinates: json['coordinates'] != null
            ? Map<String, double>.from(json['coordinates'])
            : {'lat': 0.0, 'lng': 0.0},
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
        priority: json['priority'] ?? 'medium',
        isDismissed: json['isDismissed'] ?? false,
      );
    } catch (e) {
      print('Error parsing Alert from JSON: $e');
      // Return a default alert if parsing fails
      return Alert(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        animalId: json['animalId'] ?? '',
        animalName: json['animalName'] ?? 'Unknown Animal',
        animalType: json['animalType'] ?? 'Unknown',
        deviceId: json['deviceId'] ?? '',
        event: json['event'] ?? 'Unknown Event',
        status: json['status'] ?? 'Unknown',
        coordinates: {'lat': 0.0, 'lng': 0.0},
        timestamp: DateTime.now(),
        priority: 'medium',
      );
    }
  }
}

class AlertsService {
  static const String _storageKey = 'alerts_data';

  // Singleton pattern
  static final AlertsService _instance = AlertsService._internal();
  factory AlertsService() => _instance;
  AlertsService._internal();

  // In-memory cache
  List<Alert> _alerts = [];
  final AnimalService _animalService = AnimalService();
  final LocationService _locationService = LocationService();
  final EventsService _eventsService = EventsService();

  Future<void> initialize() async {
    await _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = prefs.getString(_storageKey);

      if (alertsJson != null) {
        final List<dynamic> alertsList = json.decode(alertsJson);
        _alerts = alertsList.map((json) => Alert.fromJson(json)).toList();
      } else {
        _alerts = [];
      }
    } catch (e) {
      print('Error loading alerts: $e');
      _alerts = [];
    }
  }

  Future<void> _saveAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alertsJson = json.encode(_alerts.map((a) => a.toJson()).toList());
      await prefs.setString(_storageKey, alertsJson);
    } catch (e) {
      print('Error saving alerts: $e');
    }
  }

  // Generate alerts based on animal status changes
  Future<void> checkForAlerts() async {
    final animals = await _animalService.getAllAnimals();

    for (var animal in animals) {
      final location = _locationService.getAnimalLocation(animal.id);
      if (location != null) {
        await _processAnimalStatus(animal, location);
      }
    }
  }

  Future<void> _processAnimalStatus(
    Animal animal,
    AnimalLocation location,
  ) async {
    final previousStatus = animal.status;
    final currentStatus = location.status;

    // Only generate alert if status has changed
    if (previousStatus != currentStatus) {
      String event;
      String priority;

      switch (currentStatus) {
        case 'Outside Fence':
          event = 'Geofence Breach';
          priority = 'high';
          break;
        case 'Near Boundary':
          event = 'Near Boundary';
          priority = 'medium';
          break;
        case 'Inside Fence':
          if (previousStatus == 'Outside Fence') {
            event = 'Returned to Safe Zone';
            priority = 'low';
          } else {
            return; // No alert for normal inside status
          }
          break;
        default:
          return;
      }

      final alert = Alert(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        animalId: animal.id,
        animalName: animal.name,
        animalType: animal.type,
        deviceId: animal.deviceId,
        event: event,
        status: currentStatus,
        coordinates: {
          'lat': location.coordinates.latitude,
          'lng': location.coordinates.longitude,
        },
        timestamp: DateTime.now(),
        priority: priority,
      );

      await addAlert(alert);

      // Log event based on alert type
      switch (event) {
        case 'Geofence Breach':
          await _eventsService.logGeofenceBreach(
            animalId: animal.id,
            animalName: animal.name,
            deviceId: animal.deviceId,
          );
          break;
        case 'Near Boundary':
          // Could log deterrent activation here if animal gets too close
          break;
        case 'Returned to Safe Zone':
          await _eventsService.logAnimalReturned(
            animalId: animal.id,
            animalName: animal.name,
            deviceId: animal.deviceId,
          );
          break;
      }

      // Update animal status
      await _animalService.updateAnimalStatus(
        animal.id,
        currentStatus,
        _animalService.getTimeAgo(DateTime.now()),
      );
    }
  }

  Future<void> addAlert(Alert alert) async {
    _alerts.insert(0, alert); // Add to beginning of list
    await _saveAlerts();
  }

  Future<void> dismissAlert(String alertId) async {
    final index = _alerts.indexWhere((alert) => alert.id == alertId);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(isDismissed: true);
      await _saveAlerts();
    }
  }

  Future<void> deleteAlert(String alertId) async {
    _alerts.removeWhere((alert) => alert.id == alertId);
    await _saveAlerts();
  }

  List<Alert> getActiveAlerts() {
    return _alerts.where((alert) => !alert.isDismissed).toList();
  }

  List<Alert> getAllAlerts() {
    return List.from(_alerts);
  }

  List<Alert> getAlertsByPriority(String priority) {
    return _alerts.where((alert) => alert.priority == priority).toList();
  }

  int getAlertCountByPriority(String priority) {
    return _alerts.where((alert) => alert.priority == priority).length;
  }

  int getActiveAlertCount() {
    return _alerts.where((alert) => !alert.isDismissed).length;
  }

  // Clear old alerts (older than 7 days)
  Future<void> clearOldAlerts() async {
    final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
    _alerts.removeWhere((alert) => alert.timestamp.isBefore(sevenDaysAgo));
    await _saveAlerts();
  }

  String getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Outside Fence':
        return Colors.red;
      case 'Near Boundary':
        return Colors.amber;
      case 'Inside Fence':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData getEventIcon(String event) {
    switch (event) {
      case 'Geofence Breach':
        return Icons.warning;
      case 'Near Boundary':
        return Icons.location_on;
      case 'Returned to Safe Zone':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }
}
