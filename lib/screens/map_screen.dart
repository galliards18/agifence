import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/animal.dart';
import '../models/animal_location.dart';
import '../services/animal_service.dart';
import '../services/location_service.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;

  final AnimalService _animalService = AnimalService();
  final LocationService _locationService = LocationService();

  List<Animal> animals = [];
  List<AnimalLocation> animalLocations = [];
  bool isLoading = true;

  Set<Marker> _markers = {};
  Set<Circle> _circles = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _animalService.initialize();
      await _locationService.initialize();

      final loadedAnimals = await _animalService.getAllAnimals();
      final loadedLocations = _locationService.getAllLocations();

      setState(() {
        animals = loadedAnimals;
        animalLocations = loadedLocations;
        isLoading = false;
      });

      _createMarkers();
      _createGeofence();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading map data: $e');
    }
  }

  void _createMarkers() {
    _markers = animalLocations.map((location) {
      final animal = animals.firstWhere(
        (a) => a.id == location.animalId,
        orElse: () => Animal(
          id: location.animalId,
          name: 'Unknown',
          type: 'Unknown',
          breed: '',
          deviceId: location.deviceId,
          status: location.status,
          lastSeen: 'Unknown',
          createdAt: DateTime.now(),
        ),
      );

      return Marker(
        markerId: MarkerId(location.deviceId),
        position: location.coordinates,
        infoWindow: InfoWindow(
          title: '${animal.name} (${animal.type})',
          snippet: 'Status: ${location.status} • Device: ${location.deviceId}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _locationService.getMarkerHue(location.status),
        ),
      );
    }).toSet();
  }

  void _createGeofence() {
    _circles = {
      Circle(
        circleId: CircleId('geofence'),
        center: _locationService.farmCenter,
        radius: _locationService.geofenceRadius,
        fillColor: Colors.green.withOpacity(0.1),
        strokeColor: Colors.green,
        strokeWidth: 2,
      ),
    };
  }

  Color _getStatusColor(String status) {
    return _locationService.getStatusColor(status);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Live Map',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.green[700],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.green[700]),
              SizedBox(height: 16),
              Text(
                'Loading map data...',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Map',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
      ),
      body: Stack(
        children: [
          // Google Maps
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            initialCameraPosition: CameraPosition(
              target: _locationService.farmCenter,
              zoom: 15.0,
            ),
            markers: _markers,
            circles: _circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Legend
          Positioned(
            top: 20,
            right: 20,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Status Legend',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildLegendItem('Inside', Colors.green),
                    _buildLegendItem('Near Boundary', Colors.amber),
                    _buildLegendItem('Outside', Colors.red),
                  ],
                ),
              ),
            ),
          ),

          // Animal list overlay
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                height: 200,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Animal Status',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: animalLocations.length,
                        itemBuilder: (context, index) {
                          final location = animalLocations[index];
                          final animal = animals.firstWhere(
                            (a) => a.id == location.animalId,
                            orElse: () => Animal(
                              id: location.animalId,
                              name: 'Unknown',
                              type: 'Unknown',
                              breed: '',
                              deviceId: location.deviceId,
                              status: location.status,
                              lastSeen: 'Unknown',
                              createdAt: DateTime.now(),
                            ),
                          );

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(location.status),
                              radius: 20,
                              child: Icon(
                                Icons.pets,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              '${animal.name} (${animal.type})',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Status: ${location.status} • ${location.deviceId}',
                              style: TextStyle(fontSize: 16),
                            ),
                            trailing: Icon(
                              Icons.location_on,
                              color: _getStatusColor(location.status),
                              size: 28,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 8),
          Text(
            status,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
