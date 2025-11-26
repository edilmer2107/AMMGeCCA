// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amgeca/providers/auth_provider.dart';
import 'package:amgeca/providers/configuracion_provider.dart'; // 🆕 AGREGAR
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
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => ConfiguracionProvider()..cargarConfiguracion(),
        ), // 🆕 AGREGAR
      ],
      child: Consumer<ConfiguracionProvider>(
        // 🆕 AGREGAR Consumer
        builder: (context, configProvider, child) {
          return MaterialApp(
            title: 'AMGECA',
            theme: ThemeData(
              primarySwatch: Colors.green,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              brightness: configProvider.tema == 'dark'
                  ? Brightness.dark
                  : Brightness.light, // 🆕
            ),
            home: const AuthWrapper(),
            debugShowCheckedModeBanner: false,
            routes: {
              '/ventas': (context) => const VentasPage(),
              '/inventario': (context) => const InventarioPlaceholder(),
              '/login': (context) => const LoginPage(),
            },
          );
        },
      ),
    );
  }
}

// ... (resto del código igual)
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
