// lib/View/tab_navigation_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amgeca/providers/auth_provider.dart';
import 'package:amgeca/View/auth/login_page.dart';
import 'package:amgeca/View/dashboard_page.dart';
import 'package:amgeca/View/cultivos_list_page.dart';
import 'package:amgeca/View/clima_page.dart';
import 'package:amgeca/View/amgecca_page.dart';
import 'package:amgeca/View/ajustes_page.dart';

class TabNavigationPage extends StatefulWidget {
  const TabNavigationPage({Key? key}) : super(key: key);

  @override
  _TabNavigationPageState createState() => _TabNavigationPageState();
}

class _TabNavigationPageState extends State<TabNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const CultivosListPage(),
    const ClimaPage(),
    const ReportesPage(),
    const AjustesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green,
        unselectedItemColor: const Color.fromARGB(255, 0, 1, 0),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.agriculture),
            label: 'Cultivos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.cloud), label: 'Clima'),
          BottomNavigationBarItem(
            icon: Icon(Icons.reviews),
            label: 'AMGeCA IA',
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    // Mostrar diálogo de confirmación
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }
}
