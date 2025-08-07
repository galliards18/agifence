import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum EventType {
  geofenceBreach,
  deterrentActivation,
  animalReturned,
  deviceOffline,
  deviceOnline,
  lowBattery,
  animalAdded,
  animalRemoved,
  systemAlert,
}

enum EventSeverity { low, medium, high, critical }

class FarmEvent {
  final String id;
  final String title;
  final String description;
  final EventType type;
  final EventSeverity severity;
  final String? animalId;
  final String? animalName;
  final String? deviceId;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;
  final bool isResolved;

  FarmEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
    this.animalId,
    this.animalName,
    this.deviceId,
    this.metadata,
    required this.timestamp,
    this.isResolved = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString(),
      'severity': severity.toString(),
      'animalId': animalId,
      'animalName': animalName,
      'deviceId': deviceId,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'isResolved': isResolved,
    };
  }

  factory FarmEvent.fromJson(Map<String, dynamic> json) {
    try {
      return FarmEvent(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        type: EventType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => EventType.systemAlert,
        ),
        severity: EventSeverity.values.firstWhere(
          (e) => e.toString() == json['severity'],
          orElse: () => EventSeverity.medium,
        ),
        animalId: json['animalId'],
        animalName: json['animalName'],
        deviceId: json['deviceId'],
        metadata: json['metadata'] != null
            ? Map<String, dynamic>.from(json['metadata'])
            : null,
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
        isResolved: json['isResolved'] ?? false,
      );
    } catch (e) {
      print('Error parsing FarmEvent from JSON: $e');
      // Return a default event if parsing fails
      return FarmEvent(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] ?? 'Unknown Event',
        description: json['description'] ?? 'Event parsing failed',
        type: EventType.systemAlert,
        severity: EventSeverity.medium,
        timestamp: DateTime.now(),
      );
    }
  }

  Color getSeverityColor() {
    switch (severity) {
      case EventSeverity.low:
        return Colors.green;
      case EventSeverity.medium:
        return Colors.orange;
      case EventSeverity.high:
        return Colors.red;
      case EventSeverity.critical:
        return Colors.purple;
    }
  }

  IconData getEventIcon() {
    switch (type) {
      case EventType.geofenceBreach:
        return Icons.warning;
      case EventType.deterrentActivation:
        return Icons.electric_bolt;
      case EventType.animalReturned:
        return Icons.check_circle;
      case EventType.deviceOffline:
        return Icons.signal_wifi_off;
      case EventType.deviceOnline:
        return Icons.signal_wifi_4_bar;
      case EventType.lowBattery:
        return Icons.battery_alert;
      case EventType.animalAdded:
        return Icons.add_circle;
      case EventType.animalRemoved:
        return Icons.remove_circle;
      case EventType.systemAlert:
        return Icons.info;
    }
  }

  String getTimeAgo() {
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
}

class EventsService {
  static const String _storageKey = 'farm_events';
  static final EventsService _instance = EventsService._internal();
  factory EventsService() => _instance;
  EventsService._internal();

  List<FarmEvent> _events = [];

  Future<void> initialize() async {
    await _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(_storageKey);

      if (eventsJson != null) {
        final List<dynamic> eventsList = json.decode(eventsJson);
        _events = eventsList.map((json) => FarmEvent.fromJson(json)).toList();
      } else {
        _events = [];
      }
    } catch (e) {
      print('Error loading events: $e');
      _events = [];
    }
  }

  Future<void> _saveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = json.encode(_events.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, eventsJson);
    } catch (e) {
      print('Error saving events: $e');
    }
  }

  Future<void> addEvent(FarmEvent event) async {
    _events.insert(0, event);
    await _saveEvents();
  }

  Future<void> logGeofenceBreach({
    required String animalId,
    required String animalName,
    required String deviceId,
  }) async {
    final event = FarmEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Geofence Breach Detected',
      description: '$animalName has breached the geofence boundary',
      type: EventType.geofenceBreach,
      severity: EventSeverity.high,
      animalId: animalId,
      animalName: animalName,
      deviceId: deviceId,
      timestamp: DateTime.now(),
    );

    await addEvent(event);
  }

  Future<void> logDeterrentActivation({
    required String animalId,
    required String animalName,
    required String deviceId,
  }) async {
    final event = FarmEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Deterrent Activated',
      description: 'Deterrent system activated for $animalName',
      type: EventType.deterrentActivation,
      severity: EventSeverity.medium,
      animalId: animalId,
      animalName: animalName,
      deviceId: deviceId,
      timestamp: DateTime.now(),
    );

    await addEvent(event);
  }

  Future<void> logAnimalReturned({
    required String animalId,
    required String animalName,
    required String deviceId,
  }) async {
    final event = FarmEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Animal Returned to Safe Zone',
      description: '$animalName has returned to the safe zone',
      type: EventType.animalReturned,
      severity: EventSeverity.low,
      animalId: animalId,
      animalName: animalName,
      deviceId: deviceId,
      timestamp: DateTime.now(),
    );

    await addEvent(event);
  }

  List<FarmEvent> getAllEvents() {
    return List.from(_events);
  }

  List<FarmEvent> getActiveEvents() {
    return _events.where((event) => !event.isResolved).toList();
  }

  Map<String, int> getEventStatistics() {
    final activeEvents = getActiveEvents();
    return {
      'total': _events.length,
      'active': activeEvents.length,
      'geofenceBreaches': _events
          .where((e) => e.type == EventType.geofenceBreach)
          .length,
      'deterrentActivations': _events
          .where((e) => e.type == EventType.deterrentActivation)
          .length,
    };
  }
}
