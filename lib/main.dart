import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/animal_detail_screen.dart';
import 'screens/map_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/events_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/add_animal_screen.dart';
import 'services/monitoring_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize monitoring service
    final monitoringService = MonitoringService();
    await monitoringService.initialize();
    print('AgriFence app initialized successfully');
  } catch (e) {
    print('Error initializing AgriFence app: $e');
    // Continue with app startup even if initialization fails
  }

  runApp(AgriFenceApp());
}

class AgriFenceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriFence',
      theme: ThemeData(
        primarySwatch: Colors.green,
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/animal_detail': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          final animalId = args as String? ?? '1';
          return AnimalDetailScreen(animalId: animalId);
        },
        '/map': (context) => MapScreen(),
        '/alerts': (context) => AlertsScreen(),
        '/events': (context) => EventsScreen(),
        '/settings': (context) => SettingsScreen(),
        '/add_animal': (context) => AddAnimalScreen(),
      },
    );
  }
}
