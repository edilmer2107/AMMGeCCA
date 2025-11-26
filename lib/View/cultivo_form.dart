// lib/View/cultivo_form.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:amgeca/classes/cultivo.dart';
import 'package:amgeca/classes/tipo_cultivo.dart';
import 'package:amgeca/classes/categoria.dart';
import 'package:amgeca/Data/basedato_helper.dart';
import 'package:amgeca/services/image_service.dart';

class CultivoFormPage extends StatefulWidget {
  final Cultivo? cultivo;

  const CultivoFormPage({Key? key, this.cultivo}) : super(key: key);

  @override
  State<CultivoFormPage> createState() => _CultivoFormPageState();
}

class _CultivoFormPageState extends State<CultivoFormPage> {
  late TextEditingController _nombreCtrl;
  String? _selectedTipoSuelo;
  late TextEditingController _areaCtrl;
  late TextEditingController _fechaSiembraCtrl;
  late TextEditingController _fechaCosechaCtrl;
  String _selectedEstado = Cultivo.ESTADO_ACTIVO;
  late TextEditingController _notasCtrl;
  String? _selectedTipoRiego;
  String? _imagenPath;
  bool _imagenCambiada = false;

  final ImageService _imageService = ImageService();

  final List<String> _tipoSueloOptions = [
    'Arenoso',
    'Arcilloso',
    'Franco',
    'Limoso',
    'Humífero',
    'Pedregoso',
  ];

  final List<String> _tipoRiegoOptions = [
    'Goteo',
    'Aspersión',
    'Inundación',
    'Presurizado',
    'Lluvia Natural',
  ];

  final Map<String, Map<String, dynamic>> _estadosInfo = {
    Cultivo.ESTADO_ACTIVO: {
      'label': 'Activo',
      'icon': Icons.check_circle,
      'color': Colors.green,
    },
    Cultivo.ESTADO_EN_RIESGO: {
      'label': 'En Riesgo',
      'icon': Icons.warning,
      'color': Colors.orange,
    },
    Cultivo.ESTADO_COSECHADO: {
      'label': 'Cosechado',
      'icon': Icons.agriculture,
      'color': Colors.amber,
    },
    Cultivo.ESTADO_INACTIVO: {
      'label': 'Inactivo',
      'icon': Icons.cancel,
      'color': Colors.grey,
    },
  };

  List<TipoCultivo> _tipos = [];
  List<Categoria> _categorias = [];
  int? _selectedTipoId;
  int? _selectedCategoriaId;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.cultivo?.nombre ?? '');
    _selectedTipoSuelo = widget.cultivo?.tipoSuelo ?? _tipoSueloOptions.first;
    _areaCtrl = TextEditingController(
      text: widget.cultivo?.area.toString() ?? '',
    );
    _fechaSiembraCtrl = TextEditingController(
      text: widget.cultivo?.fechaSiembra ?? '',
    );
    _fechaCosechaCtrl = TextEditingController(
      text: widget.cultivo?.fechaCosecha ?? '',
    );
    _selectedEstado = widget.cultivo?.estado ?? Cultivo.ESTADO_ACTIVO;
    _notasCtrl = TextEditingController(text: widget.cultivo?.notas ?? '');
    _selectedTipoRiego = widget.cultivo?.tipoRiego ?? _tipoRiegoOptions.first;
    _imagenPath = widget.cultivo?.imagenUrl;
    _selectedTipoId = widget.cultivo?.tipoId;
    _selectedCategoriaId = widget.cultivo?.categoriaId;
    _loadTiposYCategorias();
  }

  Future<void> _loadTiposYCategorias() async {
    final tiposRows = await BasedatoHelper.instance.getAllTiposCultivo();
    final categoriasRows = await BasedatoHelper.instance.getAllCategorias();
    setState(() {
      _tipos = tiposRows.map((r) => TipoCultivo.fromMap(r)).toList();
      _categorias = categoriasRows.map((r) => Categoria.fromMap(r)).toList();
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _areaCtrl.dispose();
    _fechaSiembraCtrl.dispose();
    _fechaCosechaCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = picked.toIso8601String().split('T')[0];
    }
  }

  Future<void> _mostrarOpcionesImagen() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Seleccionar imagen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.blue),
                ),
                title: const Text('Tomar foto'),
                onTap: () async {
                  Navigator.pop(context);
                  await _capturarImagen(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.green),
                ),
                title: const Text('Seleccionar de galería'),
                onTap: () async {
                  Navigator.pop(context);
                  await _capturarImagen(ImageSource.gallery);
                },
              ),
              if (_imagenPath != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.red),
                  ),
                  title: const Text('Eliminar imagen'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _imagenPath = null;
                      _imagenCambiada = true;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _capturarImagen(ImageSource source) async {
    final String? newImagePath = await _imageService.seleccionarImagen(
      source: source,
    );

    if (newImagePath != null) {
      // Si había una imagen anterior y se cambió, eliminarla
      if (_imagenPath != null && _imagenCambiada) {
        await _imageService.eliminarImagen(_imagenPath);
      }

      setState(() {
        _imagenPath = newImagePath;
        _imagenCambiada = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Imagen agregada exitosamente'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _saveCultivo() async {
    if (_formKey.currentState!.validate()) {
      try {
        final cultivo = Cultivo(
          id: widget.cultivo?.id,
          nombre: _nombreCtrl.text,
          tipoSuelo: _selectedTipoSuelo ?? '',
          area: double.parse(_areaCtrl.text),
          fechaSiembra: _fechaSiembraCtrl.text,
          fechaCosecha: _fechaCosechaCtrl.text.isEmpty
              ? null
              : _fechaCosechaCtrl.text,
          estado: _selectedEstado,
          notas: _notasCtrl.text.isEmpty ? null : _notasCtrl.text,
          imagenUrl: _imagenPath,
          tipoId: _selectedTipoId,
          categoriaId: _selectedCategoriaId,
          tipoRiego: _selectedTipoRiego ?? '',
        );

        if (widget.cultivo == null) {
          await BasedatoHelper.instance.insertCultivo(cultivo.toMap());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Cultivo creado exitosamente')),
          );
        } else {
          await BasedatoHelper.instance.updateCultivo(
            widget.cultivo!.id!,
            cultivo.toMap(),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Cultivo actualizado exitosamente')),
          );
        }

        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cultivo != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Cultivo' : 'Nuevo Cultivo'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildImagenSection(),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nombreCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nombre del Cultivo',
                          prefixIcon: const Icon(
                            Icons.agriculture,
                            color: Colors.green,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.green[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El nombre es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildResponsivePair(
                        first: _buildTipoDropdown(),
                        second: _buildCategoriaDropdown(),
                        isWide: isWide,
                      ),
                      const SizedBox(height: 16),
                      _buildResponsivePair(
                        first: _buildTipoRiegoDropdown(),
                        second: _buildTipoSueloDropdown(),
                        isWide: isWide,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _areaCtrl,
                        decoration: InputDecoration(
                          labelText: 'Área (m²)',
                          prefixIcon: const Icon(
                            Icons.straighten,
                            color: Colors.green,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.green[50],
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El área es requerida';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Ingresa un número válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildResponsivePair(
                        first: TextFormField(
                          controller: _fechaSiembraCtrl,
                          decoration: InputDecoration(
                            labelText: 'Fecha de Siembra',
                            prefixIcon: const Icon(
                              Icons.calendar_today,
                              color: Colors.green,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.green[50],
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(_fechaSiembraCtrl),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Fecha requerida';
                            }
                            return null;
                          },
                        ),
                        second: TextFormField(
                          controller: _fechaCosechaCtrl,
                          decoration: InputDecoration(
                            labelText: 'Cosecha estimada',
                            prefixIcon: const Icon(
                              Icons.event_available,
                              color: Colors.green,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.green[50],
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(_fechaCosechaCtrl),
                        ),
                        isWide: isWide,
                      ),
                      const SizedBox(height: 16),
                      _buildEstadoSelector(),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notasCtrl,
                        decoration: InputDecoration(
                          labelText: 'Notas (Opcional)',
                          prefixIcon: const Icon(
                            Icons.notes,
                            color: Colors.green,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.green[50],
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _saveCultivo,
                        icon: const Icon(Icons.save),
                        label: Text(
                          isEditing ? 'Actualizar Cultivo' : 'Crear Cultivo',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          SizedBox(width: spacing),
          Expanded(child: second),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        first,
        SizedBox(height: spacing),
        second,
      ],
    );
  }

  Widget _buildImagenSection() {
    return GestureDetector(
      onTap: _mostrarOpcionesImagen,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green, width: 2),
        ),
        child: _imagenPath != null && File(_imagenPath!).existsSync()
            ? ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(_imagenPath!), fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 48, color: Colors.green[700]),
                  const SizedBox(height: 8),
                  Text(
                    'Toca para agregar foto',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cámara o Galería',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTipoDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedTipoId,
      decoration: InputDecoration(
        labelText: 'Tipo',
        prefixIcon: const Icon(Icons.category, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.green[50],
      ),
      items: _tipos
          .map((t) => DropdownMenuItem<int>(value: t.id, child: Text(t.nombre)))
          .toList(),
      onChanged: (v) => setState(() => _selectedTipoId = v),
      validator: (value) {
        if (value == null) return 'Requerido';
        return null;
      },
    );
  }

  Widget _buildCategoriaDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedCategoriaId,
      decoration: InputDecoration(
        labelText: 'Categoría',
        prefixIcon: const Icon(Icons.label, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.green[50],
      ),
      items: _categorias
          .map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.nombre)))
          .toList(),
      onChanged: (v) => setState(() => _selectedCategoriaId = v),
      validator: (value) {
        if (value == null) return 'Requerido';
        return null;
      },
    );
  }

  Widget _buildTipoRiegoDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTipoRiego,
      decoration: InputDecoration(
        labelText: 'Riego',
        prefixIcon: const Icon(Icons.water, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.green[50],
      ),
      items: _tipoRiegoOptions
          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
          .toList(),
      onChanged: (v) => setState(() => _selectedTipoRiego = v),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Requerido';
        return null;
      },
    );
  }

  Widget _buildTipoSueloDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTipoSuelo,
      decoration: InputDecoration(
        labelText: 'Suelo',
        prefixIcon: const Icon(Icons.landscape, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.green[50],
      ),
      items: _tipoSueloOptions
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
      onChanged: (v) => setState(() => _selectedTipoSuelo = v),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Requerido';
        return null;
      },
    );
  }

  Widget _buildEstadoSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado del Cultivo',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _estadosInfo.entries.map((entry) {
            final estado = entry.key;
            final info = entry.value;
            final isSelected = _selectedEstado == estado;

            return FilterChip(
              selected: isSelected,
              label: Text(info['label']),
              avatar: Icon(
                info['icon'],
                size: 18,
                color: isSelected ? Colors.white : info['color'],
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedEstado = estado);
                }
              },
              selectedColor: info['color'],
              backgroundColor: (info['color'] as Color).withOpacity(0.1),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : info['color'],
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
