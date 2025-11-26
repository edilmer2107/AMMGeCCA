// lib/View/ajustes_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:amgeca/providers/auth_provider.dart';
import 'package:amgeca/providers/configuracion_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AjustesPage extends StatefulWidget {
  const AjustesPage({super.key});

  @override
  State<AjustesPage> createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  bool _mostrarPerfil = false;
  bool _mostrarPreferencias = false;

  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _correoController = TextEditingController();

  String _rolSeleccionado = 'Agricultor';
  String _idiomaSeleccionado = 'es';
  File? _imagenPerfil;

  final List<String> _roles = ['Agricultor', 'Técnico', 'Administrador'];
  final Map<String, String> _idiomas = {
    'es': 'Español',
    'en': 'English',
    'qu': 'Quechua',
  };

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
  }

  void _cargarDatosUsuario() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _nombreController.text = authProvider.user?['nombre'] ?? 'Usuario';
    _correoController.text = authProvider.user?['correo'] ?? '';
    _telefonoController.text = '+51 999 999 999'; // Valor por defecto
  }

  Future<void> _seleccionarImagen() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _imagenPerfil = File(image.path);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto de perfil actualizada'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _guardarCambios() {
    // Aquí puedes agregar la lógica para guardar en la base de datos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Cambios guardados exitosamente'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final configProvider = Provider.of<ConfiguracionProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar personalizado
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: Colors.green[700],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.green[600]!, Colors.green[800]!],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: _seleccionarImagen,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.white,
                                backgroundImage: _imagenPerfil != null
                                    ? FileImage(_imagenPerfil!)
                                    : null,
                                child: _imagenPerfil == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Colors.green,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          flex: 3,
                          child: Text(
                            _nombreController.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _rolSeleccionado,
                            style: TextStyle(
                              color: Colors.green[100],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth = constraints.maxWidth;
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth > 900 ? 900 : maxWidth,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // 📋 PERFIL DEL USUARIO
                          _buildSeccionExpandible(
                            titulo: 'Perfil del Usuario',
                            subtitulo: 'Información personal',
                            icono: Icons.person,
                            colorIcono: Colors.green,
                            expandido: _mostrarPerfil,
                            onTap: () => setState(
                              () => _mostrarPerfil = !_mostrarPerfil,
                            ),
                            contenido: _buildContenidoPerfil(),
                          ),

                          const SizedBox(height: 16),

                          // 🎨 PREFERENCIAS DE LA APP
                          _buildSeccionExpandible(
                            titulo: 'Preferencias de la App',
                            subtitulo: 'Personaliza tu experiencia',
                            icono: Icons.settings,
                            colorIcono: Colors.blue,
                            expandido: _mostrarPreferencias,
                            onTap: () => setState(
                              () =>
                                  _mostrarPreferencias = !_mostrarPreferencias,
                            ),
                            contenido: _buildContenidoPreferencias(
                              configProvider,
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 💡 Beneficio
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green[50]!, Colors.blue[50]!],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lightbulb,
                                  color: Colors.amber,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Beneficio: Información más personalizada en toda la app según tus preferencias.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey[200]!)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'AMGECA v1.0.0',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              'Sistema de Gestión Agrícola',
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionExpandible({
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Color colorIcono,
    required bool expandido,
    required VoidCallback onTap,
    required Widget contenido,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorIcono.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icono, color: colorIcono, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          subtitulo,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expandido
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ),
          ),
          if (expandido)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: contenido,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContenidoPerfil() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        return Column(
          children: [
            _buildResponsivePair(
              first: _buildCampoTexto(
                'Nombre',
                _nombreController,
                Icons.person_outline,
              ),
              second: _buildDropdown(
                'Rol',
                _rolSeleccionado,
                _roles,
                Icons.work_outline,
                (valor) => setState(() => _rolSeleccionado = valor!),
              ),
              isWide: isWide,
            ),
            const SizedBox(height: 16),
            _buildResponsivePair(
              first: _buildCampoTexto(
                'Teléfono',
                _telefonoController,
                Icons.phone_outlined,
              ),
              second: _buildCampoTexto(
                'Correo',
                _correoController,
                Icons.email_outlined,
              ),
              isWide: isWide,
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              'Idioma preferido',
              _idiomaSeleccionado,
              _idiomas.keys.toList(),
              Icons.language,
              (valor) => setState(() => _idiomaSeleccionado = valor!),
              mostrarValor: (key) => _idiomas[key]!,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _guardarCambios,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text(
                'Guardar cambios',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContenidoPreferencias(ConfiguracionProvider configProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tema
        const Text(
          'Tema',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 100,
              child: _buildBotonTema(
                'Claro',
                Icons.wb_sunny,
                Colors.amber,
                'light',
                configProvider,
              ),
            ),
            SizedBox(
              width: 100,
              child: _buildBotonTema(
                'Oscuro',
                Icons.nightlight_round,
                Colors.indigo,
                'dark',
                configProvider,
              ),
            ),
            SizedBox(
              width: 100,
              child: _buildBotonTema(
                'Auto',
                Icons.brightness_auto,
                Colors.grey,
                'auto',
                configProvider,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Tamaño de fuente
        const Text(
          'Tamaño de fuente',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildOpcionTamano('Pequeña', 'small', configProvider),
        const SizedBox(height: 8),
        _buildOpcionTamano('Normal', 'medium', configProvider),
        const SizedBox(height: 8),
        _buildOpcionTamano('Grande', 'large', configProvider),
        const SizedBox(height: 24),

        // Animaciones
        _buildSwitch(
          'Animaciones',
          'Efectos visuales en la app',
          Icons.animation,
          configProvider.animaciones,
          () => configProvider.toggleAnimaciones(),
        ),
        const SizedBox(height: 12),

        // Vibración
        _buildSwitch(
          'Vibración',
          'Al presionar botones',
          Icons.vibration,
          configProvider.vibracion,
          () => configProvider.toggleVibracion(),
        ),
      ],
    );
  }

  Widget _buildCampoTexto(
    String label,
    TextEditingController controller,
    IconData icono,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icono, color: Colors.green[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green[600]!, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String valor,
    List<String> opciones,
    IconData icono,
    Function(String?) onChanged, {
    String Function(String)? mostrarValor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: valor,
          items: opciones.map((opcion) {
            return DropdownMenuItem(
              value: opcion,
              child: Text(mostrarValor != null ? mostrarValor(opcion) : opcion),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green[600]!, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildBotonTema(
    String label,
    IconData icono,
    Color color,
    String valor,
    ConfiguracionProvider configProvider,
  ) {
    final seleccionado = configProvider.tema == valor;

    return Expanded(
      child: InkWell(
        onTap: () {
          configProvider.cambiarTema(valor);
          if (configProvider.vibracion) {
            HapticFeedback.lightImpact();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: seleccionado ? Colors.green[50] : Colors.white,
            border: Border.all(
              color: seleccionado ? Colors.green[600]! : Colors.grey[300]!,
              width: seleccionado ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icono, color: color, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: seleccionado
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpcionTamano(
    String label,
    String valor,
    ConfiguracionProvider configProvider,
  ) {
    final seleccionado = configProvider.tamanoFuente == valor;

    return InkWell(
      onTap: () {
        configProvider.cambiarTamanoFuente(valor);
        if (configProvider.vibracion) {
          HapticFeedback.lightImpact();
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: seleccionado ? Colors.green[50] : Colors.white,
          border: Border.all(
            color: seleccionado ? Colors.green[600]! : Colors.grey[300]!,
            width: seleccionado ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: valor == 'small' ? 14 : (valor == 'large' ? 18 : 16),
            fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildSwitch(
    String titulo,
    String subtitulo,
    IconData icono,
    bool valor,
    VoidCallback onTap,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icono, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitulo,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: valor,
            onChanged: (_) {
              onTap();
              if (valor) {
                HapticFeedback.lightImpact();
              }
            },
            activeColor: Colors.green[600],
          ),
        ],
      ),
    );
  }

  Widget _buildResponsivePair({
    required Widget first,
    required Widget second,
    required bool isWide,
    double spacing = 12,
  }) {
    if (isWide) {
      return Row(
        children: [
          Expanded(child: first),
          SizedBox(width: spacing),
          Expanded(child: second),
        ],
      );
    } else {
      return Column(
        children: [
          first,
          SizedBox(height: spacing),
          second,
        ],
      );
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _correoController.dispose();
    super.dispose();
  }
}
