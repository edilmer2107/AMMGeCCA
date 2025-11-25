// lib/View/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amgeca/providers/auth_provider.dart';
import 'package:amgeca/View/ventas_page.dart';
import 'package:amgeca/View/ajustes_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userName = authProvider.user?['nombre'] ?? 'Usuario';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green[800],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            onPressed: () => _handleLogout(context),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      drawer: _buildCustomDrawer(context, userName),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header de bienvenida
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[700]!, Colors.green[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BIENVENIDO',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userName.split(' ').first,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Visualiza el estado de tus cultivos, consulta el clima y\nrecibe alertas personalizadas.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            // Contenido del dashboard
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Tarjeta de Cultivos Activos
                  _buildDashboardCard(
                    context,
                    title: 'CULTIVOS ACTIVOS',
                    subtitle: 'Monitorea 2 parcelas',
                    detail: '+0% VS MES ANTERIOR',
                    color: Colors.green,
                    icon: Icons.agriculture,
                  ),
                  const SizedBox(height: 16),

                  // Tarjeta de Alertas
                  _buildDashboardCard(
                    context,
                    title: 'ALERTAS',
                    subtitle: '0 campos requieren atención',
                    detail: 'REVISA SÍNTOMAS REPORTADOS',
                    color: Colors.orange,
                    icon: Icons.warning_amber_rounded,
                  ),
                  const SizedBox(height: 16),

                  // Resumen General
                  _buildResumenGeneral(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomDrawer(BuildContext context, String userName) {
    return Drawer(
      width:
          MediaQuery.of(context).size.width * 0.65, // 65% del ancho de pantalla
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header del Drawer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[700]!, Colors.green[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Agricultor',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Opciones del menú
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    context,
                    icon: Icons.shopping_cart,
                    title: 'Ventas',
                    subtitle: 'Gestiona tus ventas',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VentasPage(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.inventory,
                    title: 'Inventario',
                    subtitle: 'Control de stock',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/inventario');
                    },
                  ),
                  const Divider(height: 1),
                  _buildDrawerItem(
                    context,
                    icon: Icons.settings,
                    title: 'Ajustes',
                    subtitle: 'Configuración',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AjustesPage(),
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Ayuda',
                    subtitle: 'Centro de soporte',
                    onTap: () {
                      Navigator.pop(context);
                      _showHelpDialog(context);
                    },
                  ),
                ],
              ),
            ),

            // Footer con versión
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(
                    'AMGECA v1.0.0',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sistema de Gestión Agrícola',
                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.green[700], size: 24),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String detail,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                Icon(icon, color: Colors.white, size: 28),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenGeneral() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.blue[50],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RESUMEN GENERAL',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildResumenItem(
                  icon: Icons.agriculture,
                  count: '3',
                  label: 'Total',
                  color: Colors.blue,
                ),
                _buildResumenItem(
                  icon: Icons.check_circle,
                  count: '2',
                  label: 'Activos',
                  color: Colors.green,
                ),
                _buildResumenItem(
                  icon: Icons.emoji_events,
                  count: '1',
                  label: 'Cosechados',
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenItem({
    required IconData icon,
    required String count,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.green),
            SizedBox(width: 8),
            Text('Centro de Ayuda'),
          ],
        ),
        content: const Text(
          'Para soporte técnico, contacta a:\n\n'
          '📧 soporte@amgeca.com\n'
          '📱 +51 957 492 678\n\n'
          'Horario de atención:\n'
          'Lun - Vie: 8:00 AM - 5:00 PM',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
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

    if (shouldLogout == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (context.mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }
}
