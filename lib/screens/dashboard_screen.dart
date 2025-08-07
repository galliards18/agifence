import 'package:flutter/material.dart';
import '../models/animal.dart';
import '../services/animal_service.dart';
import '../services/monitoring_service.dart';
import '../services/test_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AnimalService _animalService = AnimalService();
  final MonitoringService _monitoringService = MonitoringService();
  final TestService _testService = TestService();
  List<Animal> animals = [];
  bool isLoading = true;
  bool isMonitoring = false;
  bool isTestRunning = false;

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  Future<void> _loadAnimals() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _monitoringService.initialize();
      final loadedAnimals = await _animalService.getAllAnimals();
      setState(() {
        animals = loadedAnimals;
        isLoading = false;
        isMonitoring = _monitoringService.isMonitoring;
      });

      // Start monitoring if not already monitoring
      if (!isMonitoring) {
        _monitoringService.startMonitoring();
        setState(() {
          isMonitoring = true;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading animals: $e');
    }
  }

  Color getStatusColor(String status) {
    if (status == 'Inside Fence') return Colors.green;
    if (status == 'Near Boundary') return Colors.amber;
    if (status == 'Outside Fence') return Colors.red;
    return Colors.grey;
  }

  String getStatusLabel(String status) {
    if (status == 'Inside Fence') return 'Inside';
    if (status == 'Near Boundary') return 'Near';
    if (status == 'Outside Fence') return 'Outside';
    return 'Unknown';
  }

  void _showMonitoringStatus() {
    final status = _monitoringService.getMonitoringStatus();
    final alertStats = _monitoringService.getAlertStatistics();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Monitoring Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${status['isMonitoring'] ? 'Active' : 'Inactive'}'),
            Text('Check Interval: ${status['interval']} seconds'),
            SizedBox(height: 16),
            Text(
              'Alert Statistics:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('High Priority: ${alertStats['high']}'),
            Text('Medium Priority: ${alertStats['medium']}'),
            Text('Low Priority: ${alertStats['low']}'),
            Text('Total Active: ${alertStats['total']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleTestScenario() async {
    try {
      if (_testService.isRunning) {
        _testService.stopTestScenario();
        setState(() {
          isTestRunning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test scenario stopped'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        await _testService.startTestScenario();
        setState(() {
          isTestRunning = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test scenario started - events every 10 seconds'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error toggling test scenario: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'AgriFence Dashboard',
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
                'Loading animals...',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate status counts
    final insideCount = animals.where((a) => a.status == 'Inside Fence').length;
    final nearCount = animals.where((a) => a.status == 'Near Boundary').length;
    final outsideCount = animals
        .where((a) => a.status == 'Outside Fence')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AgriFence Dashboard',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        actions: [
          IconButton(
            icon: Icon(
              isTestRunning ? Icons.play_arrow : Icons.stop,
              color: isTestRunning ? Colors.red : Colors.green,
              size: 28,
            ),
            onPressed: () {
              _toggleTestScenario();
            },
          ),
          IconButton(
            icon: Icon(
              isMonitoring
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isMonitoring ? Colors.green : Colors.grey,
              size: 28,
            ),
            onPressed: () {
              // Show monitoring status
              _showMonitoringStatus();
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, size: 28),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Summary Cards
            _buildStatusSummaryCards(insideCount, nearCount, outsideCount),
            SizedBox(height: 24),

            // Animals Section Header
            Row(
              children: [
                Icon(Icons.pets, size: 28, color: Colors.green[700]),
                SizedBox(width: 12),
                Text(
                  'Your Animals (${animals.length})',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            // Animals List
            ...animals.map((animal) => _buildAnimalCard(animal, context)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/add_animal');
          // Refresh the animals list when returning from add animal screen
          _loadAnimals();
        },
        icon: Icon(Icons.add, size: 28),
        label: Text(
          'Add Animal',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[700],
        elevation: 8,
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedFontSize: 18,
        unselectedFontSize: 16,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 28),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map, size: 28),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications, size: 28),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history, size: 28),
            label: 'Events',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/map');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/alerts');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/events');
          }
        },
      ),
    );
  }

  Widget _buildStatusSummaryCards(
    int insideCount,
    int nearCount,
    int outsideCount,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Inside',
            insideCount.toString(),
            Colors.green,
            Icons.check_circle,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Near',
            nearCount.toString(),
            Colors.amber,
            Icons.location_on,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Outside',
            outsideCount.toString(),
            Colors.red,
            Icons.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String count,
    Color color,
    IconData icon,
  ) {
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
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalCard(Animal animal, BuildContext context) {
    final statusColor = getStatusColor(animal.status);
    final statusLabel = getStatusLabel(animal.status);

    return Card(
      elevation: 6,
      margin: EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/animal_detail', arguments: animal.id);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Status-colored paw icon
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.pets, size: 36, color: statusColor),
              ),
              SizedBox(width: 16),

              // Animal details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${animal.name}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${animal.type} • ${animal.breed}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.memory, size: 16, color: Colors.grey[500]),
                        SizedBox(width: 4),
                        Text(
                          animal.deviceId,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        Spacer(),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: 4),
                        Text(
                          animal.lastSeen,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
