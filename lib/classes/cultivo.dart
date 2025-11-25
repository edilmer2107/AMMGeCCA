// lib/classes/cultivo.dart
class Cultivo {
  final int? id;
  final String nombre;
  final String tipoSuelo;
  final double area;
  final String fechaSiembra;
  final String? fechaCosecha;
  String estado; // ejemplo: "ACTIVO", "COSECHADO", "EN_RIESGO"
  final String? notas;
  final String? imagenUrl;
  final int? tipoId; // FK to tipos_cultivo
  final int? categoriaId; // FK to categorias
  final String tipoRiego;
  final double? cantidadCosechada;
  final double? ingresos;
  final double? egresos;

  // NUEVOS CAMPOS para riesgo
  bool enRiesgo;
  String? razonRiesgo;
  String? tipoRiesgo; // Climático, Plagas, Enfermedades, Suelo, Falta de agua
  String? fechaRiesgo; // ISO string, e.g. "2025-11-21"

  Cultivo({
    this.id,
    required this.nombre,
    required this.tipoSuelo,
    required this.area,
    required this.fechaSiembra,
    this.fechaCosecha,
    required this.estado,
    this.notas,
    this.imagenUrl,
    this.tipoId,
    this.categoriaId,
    required this.tipoRiego,
    this.cantidadCosechada,
    this.ingresos,
    this.egresos,
    // risk defaults:
    this.enRiesgo = false,
    this.razonRiesgo,
    this.tipoRiesgo,
    this.fechaRiesgo,
  });

  factory Cultivo.fromMap(Map<String, dynamic> map) {
    return Cultivo(
      id: map['id'] as int?,
      nombre: map['nombre'] as String? ?? '',
      tipoSuelo: map['tipoSuelo'] as String? ?? '',
      area: (map['area'] is num) ? (map['area'] as num).toDouble() : 0.0,
      fechaSiembra: map['fechaSiembra'] as String? ?? '',
      fechaCosecha: map['fechaCosecha'] as String?,
      estado: map['estado'] as String? ?? 'ACTIVO',
      notas: map['notas'] as String?,
      imagenUrl: map['imagenUrl'] as String?,
      tipoId: map['tipoId'] as int?,
      categoriaId: map['categoriaId'] as int?,
      tipoRiego: map['tipoRiego'] as String? ?? '',
      cantidadCosechada: map['cantidadCosechada'] != null
          ? (map['cantidadCosechada'] as num).toDouble()
          : null,
      ingresos: map['ingresos'] != null
          ? (map['ingresos'] as num).toDouble()
          : null,
      egresos: map['egresos'] != null
          ? (map['egresos'] as num).toDouble()
          : null,
      enRiesgo: (map['enRiesgo'] == null)
          ? false
          : ((map['enRiesgo'] as int) == 1),
      razonRiesgo: map['razonRiesgo'] as String?,
      tipoRiesgo: map['tipoRiesgo'] as String?,
      fechaRiesgo: map['fechaRiesgo'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'tipoSuelo': tipoSuelo,
      'area': area,
      'fechaSiembra': fechaSiembra,
      'fechaCosecha': fechaCosecha,
      'estado': estado,
      'notas': notas,
      'imagenUrl': imagenUrl,
      'tipoId': tipoId,
      'categoriaId': categoriaId,
      'tipoRiego': tipoRiego,
      'cantidadCosechada': cantidadCosechada,
      'ingresos': ingresos,
      'egresos': egresos,
      // campos de riesgo
      'enRiesgo': enRiesgo ? 1 : 0,
      'razonRiesgo': razonRiesgo,
      'tipoRiesgo': tipoRiesgo,
      'fechaRiesgo': fechaRiesgo,
    };
  }
}
