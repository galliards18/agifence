import 'package:flutter/material.dart';
import '../services/events_service.dart';

class EventsScreen extends StatefulWidget {
  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final EventsService _eventsService = EventsService();
  List<FarmEvent> events = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _eventsService.initialize();
      final loadedEvents = _eventsService.getAllEvents();
      setState(() {
        events = loadedEvents;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading events: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Farm Events & History',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.blue[700],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.blue[700]),
              SizedBox(height: 16),
              Text(
                'Loading events...',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _eventsService.getEventStatistics();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Farm Events & History',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue[700],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 28),
            onPressed: _loadEvents,
          ),
        ],
      ),
      body: events.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Cards
                  _buildStatisticsCards(stats),
                  SizedBox(height: 24),

                  // Events List
                  Row(
                    children: [
                      Icon(Icons.history, size: 28, color: Colors.blue[700]),
                      SizedBox(width: 12),
                      Text(
                        'Event History (${events.length})',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Events List
                  ...events.map((event) => _buildEventCard(event)),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No Events Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Events will appear here as animals are monitored.',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadEvents,
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCards(Map<String, int> stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Events',
            stats['total'].toString(),
            Colors.blue,
            Icons.history,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Active Events',
            stats['active'].toString(),
            Colors.orange,
            Icons.warning,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Geofence Breaches',
            stats['geofenceBreaches'].toString(),
            Colors.red,
            Icons.location_off,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, Color color, IconData icon) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            SizedBox(height: 12),
            Text(
              count,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(FarmEvent event) {
    final severityColor = event.getSeverityColor();
    final eventIcon = event.getEventIcon();

    return Card(
      elevation: 6,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(eventIcon, color: severityColor, size: 32),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        event.description,
                        style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: severityColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getSeverityLabel(event.severity),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            if (event.animalName != null) ...[
              Row(
                children: [
                  Icon(Icons.pets, color: Colors.grey[600], size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Animal: ${event.animalName}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 8),
            ],
            if (event.deviceId != null) ...[
              Row(
                children: [
                  Icon(Icons.memory, color: Colors.grey[600], size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Device: ${event.deviceId}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                SizedBox(width: 8),
                Text(
                  event.getTimeAgo(),
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Spacer(),
                Text(
                  _getEventTypeLabel(event.type),
                  style: TextStyle(
                    fontSize: 14,
                    color: severityColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getSeverityLabel(EventSeverity severity) {
    switch (severity) {
      case EventSeverity.low:
        return 'LOW';
      case EventSeverity.medium:
        return 'MEDIUM';
      case EventSeverity.high:
        return 'HIGH';
      case EventSeverity.critical:
        return 'CRITICAL';
    }
  }

  String _getEventTypeLabel(EventType type) {
    switch (type) {
      case EventType.geofenceBreach:
        return 'Geofence Breach';
      case EventType.deterrentActivation:
        return 'Deterrent';
      case EventType.animalReturned:
        return 'Animal Returned';
      case EventType.deviceOffline:
        return 'Device Offline';
      case EventType.deviceOnline:
        return 'Device Online';
      case EventType.lowBattery:
        return 'Low Battery';
      case EventType.animalAdded:
        return 'Animal Added';
      case EventType.animalRemoved:
        return 'Animal Removed';
      case EventType.systemAlert:
        return 'System Alert';
    }
  }
} 