// lib/View/cultivos_list_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:amgeca/classes/cultivo.dart';
import 'package:amgeca/Data/basedato_helper.dart';
import 'package:amgeca/classes/tipo_cultivo.dart';
import 'package:amgeca/classes/categoria.dart';
import 'cultivo_form.dart';
import 'tipos_list_page.dart';
import 'categorias_list_page.dart';
import 'cosecha_form.dart';

class CultivosListPage extends StatefulWidget {
  const CultivosListPage({Key? key}) : super(key: key);

  @override
  State<CultivosListPage> createState() => _CultivosListPageState();
}

class _CultivosListPageState extends State<CultivosListPage> {
  late Future<List<Cultivo>> _cultivosFuture;
  Map<int, String> _tipoMap = {};
  Map<int, String> _categoriaMap = {};
  String? _filtroActivo;

  @override
  void initState() {
    super.initState();
    _loadCultivos();
    _loadAuxData();
  }

  void _loadCultivos() {
    _cultivosFuture = _getCultivosFromDB();
  }

  Future<void> _loadAuxData() async {
    final tiposRows = await BasedatoHelper.instance.getAllTiposCultivo();
    final categoriasRows = await BasedatoHelper.instance.getAllCategorias();
    setState(() {
      _tipoMap = Map.fromEntries(
        tiposRows.map((r) {
          final t = TipoCultivo.fromMap(r);
          return MapEntry(t.id ?? 0, t.nombre);
        }),
      );
      _categoriaMap = Map.fromEntries(
        categoriasRows.map((r) {
          final c = Categoria.fromMap(r);
          return MapEntry(c.id ?? 0, c.nombre);
        }),
      );
    });
  }

  Future<List<Cultivo>> _getCultivosFromDB() async {
    final rows = await BasedatoHelper.instance.getAllCultivos();
    final cultivos = rows.map((r) => Cultivo.fromMap(r)).toList();

    if (_filtroActivo == null) {
      return cultivos;
    } else {
      return cultivos.where((c) => c.estado == _filtroActivo).toList();
    }
  }

  void _navigateToForm({Cultivo? cultivo}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CultivoFormPage(cultivo: cultivo),
      ),
    );
    if (result == true) {
      setState(() => _loadCultivos());
    }
  }

  Future<void> _deleteCultivo(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cultivo'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este cultivo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await BasedatoHelper.instance.deleteCultivo(id);
      setState(() => _loadCultivos());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cultivo eliminado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cultivos'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox(),
        actions: [
          PopupMenuButton<int>(
            onSelected: (v) {
              if (v == 1)
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TiposListPage()),
                );
              if (v == 2)
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CategoriasListPage()),
                );
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 1, child: Text('Gestionar Tipos')),
              PopupMenuItem(value: 2, child: Text('Gestionar Categorías')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Cultivo>>(
        future: _cultivosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final cultivos = snapshot.data ?? [];
          if (cultivos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.agriculture, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No hay cultivos registrados'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _navigateToForm(),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Cultivo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          final activos = cultivos.where((c) => c.estado == 'activo').length;
          final cosechados = cultivos
              .where((c) => c.estado == 'cosechado')
              .length;
          final enRiesgo = cultivos
              .where((c) => c.estado == 'en_riesgo')
              .length;

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumen de cultivos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              '$activos',
                              'Activos',
                              Colors.green,
                              onTap: () {
                                setState(() {
                                  _filtroActivo = 'activo';
                                  _loadCultivos();
                                });
                              },
                              isActive: _filtroActivo == 'activo',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryCard(
                              '$cosechados',
                              'Cosechados',
                              Colors.amber,
                              onTap: () {
                                setState(() {
                                  _filtroActivo = 'cosechado';
                                  _loadCultivos();
                                });
                              },
                              isActive: _filtroActivo == 'cosechado',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSummaryCard(
                              '$enRiesgo',
                              'En riesgo',
                              Colors.orange,
                              onTap: () {
                                setState(() {
                                  _filtroActivo = 'en_riesgo';
                                  _loadCultivos();
                                });
                              },
                              isActive: _filtroActivo == 'en_riesgo',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_filtroActivo != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _filtroActivo = null;
                          _loadCultivos();
                        });
                      },
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Mostrar todos los cultivos'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: cultivos.length,
                  itemBuilder: (context, index) {
                    final cultivo = cultivos[index];
                    return _buildCultivoCard(cultivo);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        tooltip: 'Agregar Cultivo',
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCard(
    String number,
    String label,
    Color color, {
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.9) : color,
            borderRadius: BorderRadius.circular(16),
            border: isActive ? Border.all(color: Colors.white, width: 3) : null,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCultivoCard(Cultivo cultivo) {
    final tipoNombre = _tipoMap[cultivo.tipoId ?? 0] ?? 'Sin tipo';
    final categoriaNombre =
        _categoriaMap[cultivo.categoriaId ?? 0] ?? 'Sin categoría';

    Color colorEstado;
    IconData iconEstado;

    switch (cultivo.estado) {
      case 'activo':
        colorEstado = Colors.green;
        iconEstado = Icons.check_circle;
        break;
      case 'cosechado':
        colorEstado = Colors.amber;
        iconEstado = Icons.agriculture;
        break;
      case 'en_riesgo':
        colorEstado = Colors.orange;
        iconEstado = Icons.warning;
        break;
      case 'inactivo':
        colorEstado = Colors.grey;
        iconEstado = Icons.cancel;
        break;
      default:
        colorEstado = Colors.grey;
        iconEstado = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del cultivo
          if (cultivo.imagenUrl != null &&
              File(cultivo.imagenUrl!).existsSync())
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.file(
                File(cultivo.imagenUrl!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cultivo.nombre,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$tipoNombre • $categoriaNombre',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorEstado,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(iconEstado, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            cultivo.estado.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.calendar_today,
                        'Fecha Siembra',
                        cultivo.fechaSiembra,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.event_available,
                        'Cosecha Estimada',
                        cultivo.fechaCosecha ?? 'N/A',
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        Icons.straighten,
                        'Área',
                        '${cultivo.area} m²',
                        Colors.teal,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.water,
                        'Riego',
                        cultivo.tipoRiego,
                        Colors.cyan,
                      ),
                    ),
                  ],
                ),
                if (cultivo.notas != null && cultivo.notas!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.notes, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cultivo.notas!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (cultivo.estado == 'activo') {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    CosechaFormPage(cultivo: cultivo),
                              ),
                            );
                            if (result == true) {
                              setState(() => _loadCultivos());
                            }
                          } else {
                            await BasedatoHelper.instance.updateEstado(
                              cultivo.id!,
                              'activo',
                            );
                            setState(() => _loadCultivos());
                          }
                        },
                        icon: Icon(
                          cultivo.estado == 'activo'
                              ? Icons.agriculture
                              : Icons.restart_alt,
                          size: 18,
                        ),
                        label: Text(
                          cultivo.estado == 'activo' ? 'Cosechar' : 'Activar',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _navigateToForm(cultivo: cultivo),
                      icon: const Icon(Icons.edit),
                      color: Colors.blue,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.blue[50],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteCultivo(cultivo.id!),
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red[50],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
