import 'package:flutter/material.dart';
import 'package:amgeca/classes/cultivo.dart';
import 'package:amgeca/classes/tipo_cultivo.dart';
import 'package:amgeca/classes/categoria.dart';
import 'package:amgeca/Data/basedato_helper.dart';

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
  late TextEditingController _estadoCtrl;
  late TextEditingController _notasCtrl;
  late TextEditingController _imagenUrlCtrl;
  String? _selectedTipoRiego;

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
    _estadoCtrl = TextEditingController(
      text: widget.cultivo?.estado ?? 'activo',
    );
    _notasCtrl = TextEditingController(text: widget.cultivo?.notas ?? '');
    _imagenUrlCtrl = TextEditingController(
      text: widget.cultivo?.imagenUrl ?? '',
    );
    _selectedTipoRiego = widget.cultivo?.tipoRiego ?? _tipoRiegoOptions.first;
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
    _estadoCtrl.dispose();
    _notasCtrl.dispose();
    _imagenUrlCtrl.dispose();
    // no controllers for tipo suelo/riego to dispose
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
          estado: _estadoCtrl.text,
          notas: _notasCtrl.text.isEmpty ? null : _notasCtrl.text,
          imagenUrl: _imagenUrlCtrl.text.isEmpty ? null : _imagenUrlCtrl.text,
          tipoId: _selectedTipoId,
          categoriaId: _selectedCategoriaId,
          tipoRiego: _selectedTipoRiego ?? '',
        );

        if (widget.cultivo == null) {
          // Crear
          await BasedatoHelper.instance.insertCultivo(cultivo.toMap());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cultivo creado exitosamente')),
          );
        } else {
          // Actualizar
          await BasedatoHelper.instance.updateCultivo(
            widget.cultivo!.id!,
            cultivo.toMap(),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cultivo actualizado exitosamente')),
          );
        }

        Navigator.of(context).pop(true);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cultivo != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Cultivo' : 'Nuevo Cultivo'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Cultivo',
                  prefixIcon: Icon(Icons.agriculture),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Tipo de cultivo (desde tabla)
              FutureBuilder<List<Map<String, Object?>>>(
                future: BasedatoHelper.instance.getAllTiposCultivo(),
                builder: (context, snapshot) {
                  final tipos = (snapshot.data ?? [])
                      .map((r) => TipoCultivo.fromMap(r))
                      .toList();
                  return DropdownButtonFormField<int>(
                    value: _selectedTipoId,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de cultivo',
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                    items: tipos
                        .map(
                          (t) => DropdownMenuItem<int>(
                            value: t.id,
                            child: Text(t.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedTipoId = v),
                    validator: (value) {
                      if (value == null) return 'Selecciona un tipo de cultivo';
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              // Categoria (desde tabla)
              FutureBuilder<List<Map<String, Object?>>>(
                future: BasedatoHelper.instance.getAllCategorias(),
                builder: (context, snapshot) {
                  final categorias = (snapshot.data ?? [])
                      .map((r) => Categoria.fromMap(r))
                      .toList();
                  return DropdownButtonFormField<int>(
                    value: _selectedCategoriaId,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      prefixIcon: Icon(Icons.label),
                      border: OutlineInputBorder(),
                    ),
                    items: categorias
                        .map(
                          (c) => DropdownMenuItem<int>(
                            value: c.id,
                            child: Text(c.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategoriaId = v),
                    validator: (value) {
                      if (value == null) return 'Selecciona una categoría';
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              // Tipo de riego (combobox)
              DropdownButtonFormField<String>(
                value: _selectedTipoRiego,
                decoration: const InputDecoration(
                  labelText: 'Tipo de riego',
                  prefixIcon: Icon(Icons.water),
                  border: OutlineInputBorder(),
                ),
                items: _tipoRiegoOptions
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedTipoRiego = v),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Selecciona tipo de riego';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Tipo de Suelo (combobox)
              DropdownButtonFormField<String>(
                value: _selectedTipoSuelo,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Suelo',
                  prefixIcon: Icon(Icons.landscape),
                  border: OutlineInputBorder(),
                ),
                items: _tipoSueloOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedTipoSuelo = v),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'El tipo de suelo es requerido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _areaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Área (m²)',
                  prefixIcon: Icon(Icons.straighten),
                  border: OutlineInputBorder(),
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
              TextFormField(
                controller: _fechaSiembraCtrl,
                decoration: InputDecoration(
                  labelText: 'Fecha de Siembra',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(_fechaSiembraCtrl),
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La fecha de siembra es requerida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fechaCosechaCtrl,
                decoration: InputDecoration(
                  labelText: 'Fecha de Cosecha (Opcional)',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(_fechaCosechaCtrl),
                  ),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _estadoCtrl.text.isEmpty ? 'activo' : _estadoCtrl.text,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  prefixIcon: Icon(Icons.info),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'activo', child: Text('Activo')),
                  DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
                  DropdownMenuItem(
                    value: 'cosechado',
                    child: Text('Cosechado'),
                  ),
                ].toList(),
                onChanged: (value) => _estadoCtrl.text = value ?? 'activo',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notasCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notas (Opcional)',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imagenUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'URL de Imagen (Opcional)',
                  prefixIcon: Icon(Icons.image),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveCultivo,
                icon: const Icon(Icons.save),
                label: Text(isEditing ? 'Actualizar' : 'Crear'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
