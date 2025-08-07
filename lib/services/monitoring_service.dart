import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'animal_service.dart';
import 'location_service.dart';
import 'alerts_service.dart';

class MonitoringService {
  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();

  final AnimalService _animalService = AnimalService();
  final LocationService _locationService = LocationService();
  final AlertsService _alertsService = AlertsService();

  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  // Monitoring interval (in seconds)
  static const int _monitoringInterval = 30; // Check every 30 seconds

  Future<void> initialize() async {
    await _animalService.initialize();
    await _locationService.initialize();
    await _alertsService.initialize();
  }

  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(
      Duration(seconds: _monitoringInterval),
      (_) => _performMonitoringCheck(),
    );

    print('Monitoring started - checking every $_monitoringInterval seconds');
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    print('Monitoring stopped');
  }

  bool get isMonitoring => _isMonitoring;

  Future<void> _performMonitoringCheck() async {
    try {
      // Check for new alerts
      await _alertsService.checkForAlerts();
      
      // Update animal statuses based on current locations
      await _updateAnimalStatuses();
      
      print('Monitoring check completed at ${DateTime.now()}');
    } catch (e) {
      print('Error during monitoring check: $e');
    }
  }

  Future<void> _updateAnimalStatuses() async {
    final animals = await _animalService.getAllAnimals();
    
    for (var animal in animals) {
      final location = _locationService.getAnimalLocation(animal.id);
      if (location != null) {
        // Update animal status if it has changed
        if (animal.status != location.status) {
          await _animalService.updateAnimalStatus(
            animal.id,
            location.status,
            _animalService.getTimeAgo(DateTime.now()),
          );
        }
      }
    }
  }

  // Manual trigger for monitoring check (useful for testing)
  Future<void> triggerMonitoringCheck() async {
    await _performMonitoringCheck();
  }

  // Get monitoring status
  Map<String, dynamic> getMonitoringStatus() {
    return {
      'isMonitoring': _isMonitoring,
      'interval': _monitoringInterval,
      'lastCheck': DateTime.now().toString(),
    };
  }

  // Update location from external source (e.g., GPS device)
  Future<void> updateAnimalLocationFromDevice(
    String animalId,
    double latitude,
    double longitude,
  ) async {
    final coordinates = LatLng(latitude, longitude);
    await _locationService.updateLocationFromDevice(animalId, coordinates);
    
    // Trigger immediate monitoring check
    await _performMonitoringCheck();
  }

  // Get alert statistics
  Map<String, int> getAlertStatistics() {
    return {
      'high': _alertsService.getAlertCountByPriority('high'),
      'medium': _alertsService.getAlertCountByPriority('medium'),
      'low': _alertsService.getAlertCountByPriority('low'),
      'total': _alertsService.getActiveAlertCount(),
    };
  }

  // Clear old alerts
  Future<void> clearOldAlerts() async {
    await _alertsService.clearOldAlerts();
  }

  void dispose() {
    stopMonitoring();
  }
} 