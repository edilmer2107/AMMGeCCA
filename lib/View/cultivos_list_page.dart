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
  String? _filtroActivo; // null = todos, 'activo', 'cosechado', 'en_riesgo'

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
                  ),
                ],
              ),
            );
          }

          // Calcular resumen
          final registrados = cultivos.length;
          final cosechados = cultivos
              .where((c) => c.estado == 'cosechado')
              .length;
          final enRiesgo = cultivos
              .where((c) => c.estado == 'en_riesgo')
              .length;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Resumen de cultivos
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: _buildSummaryCard(
                                '$registrados',
                                'Registrados',
                                Colors.cyan,
                                onTap: () {
                                  setState(() {
                                    _filtroActivo = 'activo';
                                    _loadCultivos();
                                  });
                                },
                                isActive: _filtroActivo == 'activo',
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
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
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                              ),
                              child: _buildSummaryCard(
                                '$enRiesgo',
                                'En riesgo',
                                Colors.pink,
                                onTap: () {
                                  setState(() {
                                    _filtroActivo = 'en_riesgo';
                                    _loadCultivos();
                                  });
                                },
                                isActive: _filtroActivo == 'en_riesgo',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Botón para mostrar todos los cultivos
                if (_filtroActivo != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
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
                // Lista de cultivos
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 26),
                  itemCount: cultivos.length,
                  itemBuilder: (context, index) {
                    final cultivo = cultivos[index];
                    final colorEstado = cultivo.estado == 'activo'
                        ? Colors.green
                        : cultivo.estado == 'cosechado'
                        ? Colors.amber
                        : Colors.red;
                    return _buildCultivoCard(cultivo, colorEstado);
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        tooltip: 'Agregar Cultivo',
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
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
          width: 100,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.9) : color,
            borderRadius: BorderRadius.circular(16),
            border: isActive ? Border.all(color: Colors.black, width: 2) : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                number,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCultivoCard(Cultivo cultivo, Color colorEstado) {
    final tipoNombre = _tipoMap[cultivo.tipoId ?? 0] ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado: nombre e icono
            Row(
              children: [
                const Icon(Icons.agriculture, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cultivo.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        tipoNombre,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                  child: Text(
                    cultivo.estado.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Fechas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Siembra:',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    Text(
                      cultivo.fechaSiembra,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Cosecha:',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    Text(
                      cultivo.fechaCosecha ?? 'Por definir',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Notas
            if (cultivo.notas != null && cultivo.notas!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  cultivo.notas!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      if (cultivo.estado == 'activo') {
                        // Abrir formulario de cosecha
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
                        // Si no está activo, marcar como activo
                        BasedatoHelper.instance.updateEstado(
                          cultivo.id!,
                          'activo',
                        );
                        setState(() => _loadCultivos());
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                    ),
                    child: Text(
                      cultivo.estado == 'activo'
                          ? 'Marcar cosechado'
                          : 'Marcar activo',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  CultivoFormPage(cultivo: cultivo),
                            ),
                          )
                          .then((_) {
                            // Recargar la lista después de marcar el riesgo
                            _loadCultivos();
                          });
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Center(
                      child: Text(
                        'Marcar riesgo',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.green),
                  onPressed: () => _navigateToForm(cultivo: cultivo),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteCultivo(cultivo.id!),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
