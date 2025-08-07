import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/animal.dart';
import '../models/animal_location.dart';

class AnimalMapPage extends StatelessWidget {
  final Animal animal;
  final AnimalLocation location;

  const AnimalMapPage({required this.animal, required this.location, Key? key})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LatLng center = location.coordinates;
    final double geofenceRadius = 100.0;
    return Scaffold(
      appBar: AppBar(title: Text('${animal.name} Location'), centerTitle: true),
      body: SafeArea(
        child: FlutterMap(
          options: MapOptions(
            center: center,
            zoom: 16.0,
            minZoom: 5.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.app',
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: center,
                  color: Colors.blue.withOpacity(0.2),
                  borderStrokeWidth: 2,
                  borderColor: Colors.blue,
                  radius: geofenceRadius,
                  useRadiusInMeter: true,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: 60,
                  height: 60,
                  point: center,
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
                          animal.name,
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
