import 'dart:async';
import 'package:flutter/material.dart';
import '../models/animal.dart';
import 'animal_service.dart';
import 'location_service.dart';
import 'alerts_service.dart';
import 'events_service.dart';

class TestService {
  static final TestService _instance = TestService._internal();
  factory TestService() => _instance;
  TestService._internal();

  final AnimalService _animalService = AnimalService();
  final LocationService _locationService = LocationService();
  final AlertsService _alertsService = AlertsService();
  final EventsService _eventsService = EventsService();

  Timer? _testTimer;
  bool _isRunning = false;

  // Simulate realistic farm scenarios
  Future<void> startTestScenario() async {
    if (_isRunning) return;

    _isRunning = true;
    print('Starting AgriFence test scenario...');

    // Initialize all services
    await _animalService.initialize();
    await _locationService.initialize();
    await _alertsService.initialize();
    await _eventsService.initialize();

    // Add some test animals
    await _addTestAnimals();

    // Start periodic testing
    _testTimer = Timer.periodic(Duration(seconds: 10), (_) {
      _simulateRandomEvents();
    });

    print('Test scenario started - events will occur every 10 seconds');
  }

  void stopTestScenario() {
    _isRunning = false;
    _testTimer?.cancel();
    _testTimer = null;
    print('Test scenario stopped');
  }

  bool get isRunning => _isRunning;

  Future<void> _addTestAnimals() async {
    final testAnimals = [
      {
        'name': 'Bella',
        'type': 'Cow',
        'breed': 'Angus',
        'deviceId': 'ESP32-AGRI-001',
      },
      {
        'name': 'Max',
        'type': 'Goat',
        'breed': 'Boer',
        'deviceId': 'ESP32-AGRI-002',
      },
      {
        'name': 'Luna',
        'type': 'Sheep',
        'breed': 'Merino',
        'deviceId': 'ESP32-AGRI-003',
      },
    ];

    for (var animalData in testAnimals) {
      final animal = Animal(
        id: _animalService.generateId(),
        name: animalData['name']!,
        type: animalData['type']!,
        breed: animalData['breed']!,
        deviceId: animalData['deviceId']!,
        status: 'Inside Fence',
        lastSeen: 'Just now',
        createdAt: DateTime.now(),
        age: '3',
        weight: '450',
        gender: 'Female',
      );

      await _animalService.addAnimal(animal);
      print('Added test animal: ${animal.name}');
    }
  }

  Future<void> _simulateRandomEvents() async {
    if (!_isRunning) return;

    final animals = await _animalService.getAllAnimals();
    if (animals.isEmpty) return;

    // Randomly select an animal
    final randomAnimal = animals[DateTime.now().millisecond % animals.length];

    // Simulate different types of events
    final eventTypes = [
      'geofence_breach',
      'deterrent_activation',
      'animal_returned',
      'device_offline',
      'low_battery',
    ];

    final randomEvent =
        eventTypes[DateTime.now().millisecond % eventTypes.length];

    switch (randomEvent) {
      case 'geofence_breach':
        await _simulateGeofenceBreach(randomAnimal);
        break;
      case 'deterrent_activation':
        await _simulateDeterrentActivation(randomAnimal);
        break;
      case 'animal_returned':
        await _simulateAnimalReturned(randomAnimal);
        break;
      case 'device_offline':
        await _simulateDeviceOffline(randomAnimal);
        break;
      case 'low_battery':
        await _simulateLowBattery(randomAnimal);
        break;
    }
  }

  Future<void> _simulateGeofenceBreach(Animal animal) async {
    print('Simulating geofence breach for ${animal.name}');

    // Update animal status to outside fence
    await _animalService.updateAnimalStatus(
      animal.id,
      'Outside Fence',
      'Just now',
    );

    // Log the event
    await _eventsService.logGeofenceBreach(
      animalId: animal.id,
      animalName: animal.name,
      deviceId: animal.deviceId,
    );

    // Generate alert
    await _alertsService.checkForAlerts();
  }

  Future<void> _simulateDeterrentActivation(Animal animal) async {
    print('Simulating deterrent activation for ${animal.name}');

    await _eventsService.logDeterrentActivation(
      animalId: animal.id,
      animalName: animal.name,
      deviceId: animal.deviceId,
    );
  }

  Future<void> _simulateAnimalReturned(Animal animal) async {
    print('Simulating animal returned for ${animal.name}');

    // Update animal status to inside fence
    await _animalService.updateAnimalStatus(
      animal.id,
      'Inside Fence',
      'Just now',
    );

    // Log the event
    await _eventsService.logAnimalReturned(
      animalId: animal.id,
      animalName: animal.name,
      deviceId: animal.deviceId,
    );
  }

  Future<void> _simulateDeviceOffline(Animal animal) async {
    print('Simulating device offline for ${animal.deviceId}');

    await _eventsService.addEvent(
      FarmEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Device Offline',
        description: 'GPS collar ${animal.deviceId} is offline',
        type: EventType.deviceOffline,
        severity: EventSeverity.high,
        deviceId: animal.deviceId,
        animalName: animal.name,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _simulateLowBattery(Animal animal) async {
    print('Simulating low battery for ${animal.deviceId}');

    await _eventsService.addEvent(
      FarmEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Low Battery Alert',
        description: 'GPS collar ${animal.deviceId} battery is low (15%)',
        type: EventType.lowBattery,
        severity: EventSeverity.medium,
        deviceId: animal.deviceId,
        animalName: animal.name,
        metadata: {'batteryLevel': 15},
        timestamp: DateTime.now(),
      ),
    );
  }

  // Get test statistics
  Map<String, dynamic> getTestStatistics() {
    return {
      'isRunning': _isRunning,
      'testInterval': '10 seconds',
      'lastEvent': DateTime.now().toString(),
    };
  }

  void dispose() {
    stopTestScenario();
    _testTimer?.cancel();
    _testTimer = null;
  }
}
