import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/animal_service.dart';
import '../services/location_service.dart';
import '../models/animal.dart';
import '../models/animal_location.dart';

class MapPage extends StatefulWidget {
  // This is the main page for displaying the map with animal locations.
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Services to interact with animal and location data.
  final AnimalService _animalService = AnimalService();
  final LocationService _locationService = LocationService();
  // Lists to store animal and location data.
  List<Animal> animals = [];
  List<AnimalLocation> locations = [];
  // Flag to indicate if data is being loaded.
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load data when the widget is initialized.
    _loadData();
  }

  // Asynchronously loads animal and location data.
  Future<void> _loadData() async {
    // Set loading state to true while data is being fetched.
    setState(() => isLoading = true);
    // Initialize the services.
    await _animalService.initialize();
    await _locationService.initialize();
    // Fetch all animals.
    final loadedAnimals = await _animalService.getAllAnimals();
    // Fetch locations for each animal that has a location.
    final loadedLocations = loadedAnimals
        .map((a) => _locationService.getAnimalLocation(a.id))
        // Filter out animals without a location.
        .where((loc) => loc != null)
        // Cast to AnimalLocation type.
        .cast<AnimalLocation>()
        .toList();
    // Update the state with the loaded data and set loading to false.
    setState(() {
      animals = loadedAnimals;
      locations = loadedLocations;
      isLoading = false;
    });
  }

  // Builds the UI for the map page.
  @override
  Widget build(BuildContext context) {
    // Show a loading indicator if data is still loading.
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Map'), centerTitle: true),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // Determine the initial map center. Defaults to a specific location if no animals have locations.
    final LatLng center = locations.isNotEmpty
        ? locations.first.coordinates
        : LatLng(10.366, 123.951);
    // Build the main Scaffold which provides the app structure.
    return Scaffold(
      appBar: AppBar(title: Text('All Animals Map'), centerTitle: true),
      // Use SafeArea to avoid the UI being obscured by device notches or status bars.
      body: SafeArea(
        // FlutterMap widget to display the map.
        child: FlutterMap(
          // Options to configure the map's behavior.
          options: MapOptions(
            // Center the map on the determined coordinates.
            center: center,
            zoom: 15.0,
            // Set minimum and maximum zoom levels.
            minZoom: 5.0,
            maxZoom: 18.0,
          ),
          // Layers to be displayed on the map.
          children: [
            // TileLayer to display OpenStreetMap tiles.
            TileLayer(
              // URL template for fetching map tiles.
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              // Subdomains for better tile loading performance.
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.app',
            ),
            // CircleLayer to draw circles around animal locations (geofences).
            CircleLayer(
              circles: locations
                  .map(
                    (loc) => CircleMarker(
                      // Center of the circle is the animal's location.
                      point: loc.coordinates,
                      // Styling for the circle.
                      color: Colors.blue.withOpacity(0.2),
                      borderStrokeWidth: 2,
                      borderColor: Colors.blue,
                      // Radius of the geofence in meters.
                      radius: 100.0, // 100 meters
                      // Indicates that the radius value is in meters.
                      useRadiusInMeter: true,
                    ),
                  )
                  .toList(),
            ),
            // MarkerLayer to display markers for each animal.
            MarkerLayer(
              markers: [
                for (int i = 0; i < animals.length; i++)
                  if (i < locations.length)
                    // Marker for a specific animal.
                    Marker(
                      width: 60,
                      height: 60,
                      // Position of the marker is the animal's location.
                      point: locations[i].coordinates,
                      // Builder to create the widget displayed as the marker.
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
