import 'package:flutter/material.dart';
import '../services/alerts_service.dart';

class AlertsScreen extends StatefulWidget {
  @override
  _AlertsScreenState createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final AlertsService _alertsService = AlertsService();
  List<Alert> alerts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _alertsService.initialize();
      await _alertsService.checkForAlerts(); // Check for new alerts
      final loadedAlerts = _alertsService.getActiveAlerts();
      setState(() {
        alerts = loadedAlerts;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading alerts: $e');
    }
  }

  Future<void> _dismissAlert(String alertId) async {
    await _alertsService.dismissAlert(alertId);
    _loadAlerts(); // Reload alerts
  }

  Future<void> _deleteAlert(String alertId) async {
    await _alertsService.deleteAlert(alertId);
    _loadAlerts(); // Reload alerts
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Alerts & Notifications',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.orange[700],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.orange[700]),
              SizedBox(height: 16),
              Text(
                'Loading alerts...',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Group alerts by priority
    final highPriorityAlerts = alerts
        .where((alert) => alert.priority == 'high')
        .toList();
    final mediumPriorityAlerts = alerts
        .where((alert) => alert.priority == 'medium')
        .toList();
    final lowPriorityAlerts = alerts
        .where((alert) => alert.priority == 'low')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Alerts & Notifications',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange[700],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, size: 28),
            onPressed: _loadAlerts,
          ),
          IconButton(
            icon: Icon(Icons.filter_list, size: 28),
            onPressed: () {
              // TODO: Add filter functionality
            },
          ),
        ],
      ),
      body: alerts.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Card
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem(
                            'High Priority',
                            highPriorityAlerts.length,
                            Colors.red,
                          ),
                          _buildSummaryItem(
                            'Medium Priority',
                            mediumPriorityAlerts.length,
                            Colors.amber,
                          ),
                          _buildSummaryItem(
                            'Low Priority',
                            lowPriorityAlerts.length,
                            Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // High Priority Alerts
                  if (highPriorityAlerts.isNotEmpty) ...[
                    _buildSectionHeader('High Priority Alerts', Colors.red),
                    SizedBox(height: 12),
                    ...highPriorityAlerts.map(
                      (alert) => _buildAlertCard(alert, context),
                    ),
                    SizedBox(height: 20),
                  ],

                  // Medium Priority Alerts
                  if (mediumPriorityAlerts.isNotEmpty) ...[
                    _buildSectionHeader('Medium Priority Alerts', Colors.amber),
                    SizedBox(height: 12),
                    ...mediumPriorityAlerts.map(
                      (alert) => _buildAlertCard(alert, context),
                    ),
                    SizedBox(height: 20),
                  ],

                  // Low Priority Alerts
                  if (lowPriorityAlerts.isNotEmpty) ...[
                    _buildSectionHeader('Low Priority Alerts', Colors.green),
                    SizedBox(height: 12),
                    ...lowPriorityAlerts.map(
                      (alert) => _buildAlertCard(alert, context),
                    ),
                  ],
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
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No Active Alerts',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'All your animals are safe and within the geofence.',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAlerts,
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(Alert alert, BuildContext context) {
    final statusColor = _alertsService.getStatusColor(alert.status);
    final priorityColor = _alertsService.getPriorityColor(alert.priority);
    final eventIcon = _alertsService.getEventIcon(alert.event);

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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(eventIcon, color: statusColor, size: 32),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${alert.animalName} (${alert.animalType})',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        alert.event,
                        style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    alert.priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.memory, color: Colors.grey[600], size: 20),
                SizedBox(width: 8),
                Text(
                  'Device: ${alert.deviceId}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                Spacer(),
                Icon(Icons.access_time, color: Colors.grey[600], size: 20),
                SizedBox(width: 8),
                Text(
                  _alertsService.getTimeAgo(alert.timestamp),
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                SizedBox(width: 8),
                Text(
                  'Lat: ${alert.coordinates['lat']?.toStringAsFixed(6)}, Lng: ${alert.coordinates['lng']?.toStringAsFixed(6)}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/map');
                    },
                    icon: Icon(Icons.map, size: 20),
                    label: Text('View on Map', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _dismissAlert(alert.id),
                    icon: Icon(Icons.check, size: 20),
                    label: Text('Dismiss', style: TextStyle(fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
