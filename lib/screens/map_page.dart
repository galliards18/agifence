import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/animal_service.dart';
import '../services/location_service.dart';
import '../models/animal.dart';
import '../models/animal_location.dart';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final AnimalService _animalService = AnimalService();
  final LocationService _locationService = LocationService();
  List<Animal> animals = [];
  List<AnimalLocation> locations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    await _animalService.initialize();
    await _locationService.initialize();
    final loadedAnimals = await _animalService.getAllAnimals();
    final loadedLocations = loadedAnimals
        .map((a) => _locationService.getAnimalLocation(a.id))
        .where((loc) => loc != null)
        .cast<AnimalLocation>()
        .toList();
    setState(() {
      animals = loadedAnimals;
      locations = loadedLocations;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Map'), centerTitle: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // Default center: first animal or fallback
    final LatLng center = locations.isNotEmpty
        ? locations.first.coordinates
        : LatLng(10.366, 123.951);
    return Scaffold(
      appBar: AppBar(title: Text('All Animals Map'), centerTitle: true),
      body: SafeArea(
        child: FlutterMap(
          options: MapOptions(
            center: center,
            zoom: 15.0,
            minZoom: 5.0,
            maxZoom: 18.0,
          ),
          children: [
            // OSM Tiles
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.app',
            ),
            // Geofence Circles
            CircleLayer(
              circles: locations
                  .map(
                    (loc) => CircleMarker(
                      point: loc.coordinates,
                      color: Colors.blue.withOpacity(0.2),
                      borderStrokeWidth: 2,
                      borderColor: Colors.blue,
                      radius: 100.0, // 100 meters
                      useRadiusInMeter: true,
                    ),
                  )
                  .toList(),
            ),
            // Animal Markers
            MarkerLayer(
              markers: [
                for (int i = 0; i < animals.length; i++)
                  if (i < locations.length)
                    Marker(
                      width: 60,
                      height: 60,
                      point: locations[i].coordinates,
                      builder: (ctx) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, color: Colors.red, size: 40),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white70,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              animals[i].name,
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      anchorPos: AnchorPos.align(AnchorAlign.top),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
