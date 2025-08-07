import 'package:flutter/material.dart';
import '../models/animal.dart';
import '../models/animal_location.dart';
import '../services/animal_service.dart';
import '../services/location_service.dart';
import 'animal_map_page.dart';

class AnimalDetailScreen extends StatefulWidget {
  final String animalId;

  AnimalDetailScreen({required this.animalId});

  @override
  _AnimalDetailScreenState createState() => _AnimalDetailScreenState();
}

class _AnimalDetailScreenState extends State<AnimalDetailScreen> {
  final AnimalService _animalService = AnimalService();
  final LocationService _locationService = LocationService();

  Animal? animal;
  AnimalLocation? location;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnimalData();
  }

  Future<void> _loadAnimalData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _animalService.initialize();
      await _locationService.initialize();

      final loadedAnimal = await _animalService.getAnimalById(widget.animalId);
      final loadedLocation = _locationService.getAnimalLocation(
        widget.animalId,
      );

      setState(() {
        animal = loadedAnimal;
        location = loadedLocation;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading animal data: $e');
    }
  }

  Color getStatusColor(String status) {
    return _locationService.getStatusColor(status);
  }

  String getStatusLabel(String status) {
    if (status == 'Inside Fence') return 'Inside';
    if (status == 'Near Boundary') return 'Near Boundary';
    if (status == 'Outside Fence') return 'Outside';
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Loading...'), centerTitle: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.green[700]),
              SizedBox(height: 16),
              Text(
                'Loading animal details...',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (animal == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Animal Not Found'), centerTitle: true),
        body: Center(
          child: Text('Animal not found', style: TextStyle(fontSize: 18)),
        ),
      );
    }

    final statusColor = getStatusColor(animal!.status);

    return Scaffold(
      appBar: AppBar(
        title: Text(animal!.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            tooltip: 'Delete Animal',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete Animal'),
                  content: Text(
                    'Are you sure you want to delete this animal? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _animalService.deleteAnimal(animal!.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Animal deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pets, size: 60, color: statusColor),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    '${animal!.type} - ${animal!.name}',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    getStatusLabel(animal!.status),
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  backgroundColor: statusColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
              ],
            ),
            SizedBox(height: 28),
            Divider(),
            ListTile(
              leading: Icon(
                Icons.memory,
                color: Colors.grey[700],
                size: 32,
              ),
              title: Text(
                'Device ID',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                animal!.deviceId,
                style: TextStyle(fontSize: 20),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.access_time,
                color: Colors.grey[700],
                size: 32,
              ),
              title: Text(
                'Last Seen',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                animal!.lastSeen,
                style: TextStyle(fontSize: 20),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Current Location',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            if (location != null) ...[
              ListTile(
                leading: Icon(
                  Icons.location_on,
                  color: Colors.blue,
                  size: 32,
                ),
                title: Text(
                  'Latitude: ${location!.coordinates.latitude.toStringAsFixed(6)}',
                  style: TextStyle(fontSize: 20),
                ),
                subtitle: Text(
                  'Longitude: ${location!.coordinates.longitude.toStringAsFixed(6)}',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.access_time,
                  color: Colors.grey[700],
                  size: 32,
                ),
                title: Text(
                  'Last Updated',
                  style: TextStyle(fontSize: 20),
                ),
                subtitle: Text(
                  '${location!.lastUpdated.toString().substring(0, 19)}',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ] else ...[
              ListTile(
                leading: Icon(
                  Icons.location_off,
                  color: Colors.grey,
                  size: 32,
                ),
                title: Text(
                  'Location Not Available',
                  style: TextStyle(fontSize: 20),
                ),
                subtitle: Text(
                  'No location data for this animal',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (animal != null && location != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnimalMapPage(animal: animal!, location: location!),
                    ),
                  );
                }
              },
              icon: Icon(Icons.map),
              label: Text('View on Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
