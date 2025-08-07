import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/animal.dart';
import 'location_service.dart';
import 'events_service.dart';

class AnimalService {
  static const String _storageKey = 'animals_data';

  // Singleton pattern
  static final AnimalService _instance = AnimalService._internal();
  factory AnimalService() => _instance;
  AnimalService._internal();

  // In-memory cache
  List<Animal> _animals = [];
  final LocationService _locationService = LocationService();
  final EventsService _eventsService = EventsService();

  // Initialize the service
  Future<void> initialize() async {
    await _locationService.initialize();
    await _loadAnimals();
  }

  Future<List<Animal>> getAllAnimals() async {
    await _loadAnimals();
    return List.from(_animals);
  }

  Future<Animal?> getAnimalById(String id) async {
    await _loadAnimals();
    try {
      return _animals.firstWhere((animal) => animal.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addAnimal(Animal animal) async {
    _animals.add(animal);
    await _saveAnimals();

    // Generate location for the new animal
    await _locationService.generateLocationForAnimal(animal);

    // Log animal added event
    await _eventsService.addEvent(
      FarmEvent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Animal Added',
        description: '${animal.name} has been registered to the system',
        type: EventType.animalAdded,
        severity: EventSeverity.low,
        animalId: animal.id,
        animalName: animal.name,
        deviceId: animal.deviceId,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> updateAnimal(Animal animal) async {
    final index = _animals.indexWhere((a) => a.id == animal.id);
    if (index != -1) {
      _animals[index] = animal;
      await _saveAnimals();
    }
  }

  Future<void> deleteAnimal(String id) async {
    Animal? animal;
    for (final a in _animals) {
      if (a.id == id) {
        animal = a;
        break;
      }
    }
    if (animal != null) {
      await _eventsService.addEvent(
        FarmEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'Animal Deleted',
          description:
              ' [1m${animal.name} [0m has been deleted from the system',
          type: EventType.animalRemoved,
          severity: EventSeverity.medium,
          animalId: animal.id,
          animalName: animal.name,
          deviceId: animal.deviceId,
          timestamp: DateTime.now(),
        ),
      );
    }
    _animals.removeWhere((animal) => animal.id == id);
    await _saveAnimals();
  }

  Future<void> updateAnimalStatus(
    String id,
    String status,
    String lastSeen,
  ) async {
    final index = _animals.indexWhere((a) => a.id == id);
    if (index != -1) {
      final animal = _animals[index];
      _animals[index] = animal.copyWith(status: status, lastSeen: lastSeen);
      await _saveAnimals();
    }
  }

  Future<List<Animal>> getAnimalsByStatus(String status) async {
    await _loadAnimals();
    return _animals.where((animal) => animal.status == status).toList();
  }

  Future<int> getAnimalCountByStatus(String status) async {
    await _loadAnimals();
    return _animals.where((animal) => animal.status == status).length;
  }

  Future<void> _loadAnimals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final animalsJson = prefs.getString(_storageKey);

      if (animalsJson != null) {
        final List<dynamic> animalsList = json.decode(animalsJson);
        _animals = animalsList.map((json) => Animal.fromJson(json)).toList();
      } else {
        _animals = [];
      }
    } catch (e) {
      print('Error loading animals: $e');
      _animals = [];
    }
  }

  Future<void> _saveAnimals() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final animalsJson = json.encode(_animals.map((a) => a.toJson()).toList());
      await prefs.setString(_storageKey, animalsJson);
    } catch (e) {
      print('Error saving animals: $e');
    }
  }

  String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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
