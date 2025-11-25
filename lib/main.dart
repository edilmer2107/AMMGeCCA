// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amgeca/providers/auth_provider.dart';
import 'package:amgeca/providers/auth_wrapper.dart';
import 'package:amgeca/View/ventas_page.dart';
import 'package:amgeca/View/auth/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: MaterialApp(
        title: 'AMGECA',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
        // Rutas de la aplicación
        routes: {
          '/ventas': (context) => const VentasPage(),
          '/reportes-ventas': (context) => const ReportesVentasPlaceholder(),
          '/inventario': (context) => const InventarioPlaceholder(),
          '/login': (context) => const LoginPage(),
        },
      ),
    );
  }
}

// Placeholders temporales (crea páginas reales después)
class ReportesVentasPlaceholder extends StatelessWidget {
  const ReportesVentasPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reportes de Ventas',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[800],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Reportes de Ventas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('En desarrollo...'),
          ],
        ),
      ),
    );
  }
}

class InventarioPlaceholder extends StatelessWidget {
  const InventarioPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green[800],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Gestión de Inventario',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('En desarrollo...'),
          ],
        ),
      ),
    );
  }
}
