// lib/classes/cultivo.dart
class Cultivo {
  final int? id;
  final String nombre;
  final String tipoSuelo;
  final double area;
  final String fechaSiembra;
  final String? fechaCosecha;
  String estado; // "activo", "inactivo", "cosechado", "en_riesgo"
  final String? notas;
  final String? imagenUrl; // Ruta local de la imagen
  final int? tipoId;
  final int? categoriaId;
  final String tipoRiego;
  final double? cantidadCosechada;
  final double? ingresos;
  final double? egresos;
  String? razonRiesgo;
  String? tipoRiesgo;
  String? fechaRiesgo;

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
    this.razonRiesgo,
    this.tipoRiesgo,
    this.fechaRiesgo,
  });

  // Estados válidos
  static const String ESTADO_ACTIVO = 'activo';
  static const String ESTADO_INACTIVO = 'inactivo';
  static const String ESTADO_COSECHADO = 'cosechado';
  static const String ESTADO_EN_RIESGO = 'en_riesgo';

  bool get esActivo => estado == ESTADO_ACTIVO;
  bool get esInactivo => estado == ESTADO_INACTIVO;
  bool get esCosechado => estado == ESTADO_COSECHADO;
  bool get esEnRiesgo => estado == ESTADO_EN_RIESGO;

  factory Cultivo.fromMap(Map<String, dynamic> map) {
    return Cultivo(
      id: map['id'] as int?,
      nombre: map['nombre'] as String? ?? '',
      tipoSuelo: map['tipoSuelo'] as String? ?? '',
      area: (map['area'] is num) ? (map['area'] as num).toDouble() : 0.0,
      fechaSiembra: map['fechaSiembra'] as String? ?? '',
      fechaCosecha: map['fechaCosecha'] as String?,
      estado: (map['estado'] as String? ?? 'activo').toLowerCase(),
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
      razonRiesgo: map['riskReason'] as String?,
      tipoRiesgo: map['riskType'] as String?,
      fechaRiesgo: map['riskDate'] as String?,
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
      'estado': estado.toLowerCase(),
      'notas': notas,
      'imagenUrl': imagenUrl,
      'tipoId': tipoId,
      'categoriaId': categoriaId,
      'tipoRiego': tipoRiego,
      'cantidadCosechada': cantidadCosechada,
      'ingresos': ingresos,
      'egresos': egresos,
      'riskReason': razonRiesgo,
      'riskType': tipoRiesgo,
      'riskDate': fechaRiesgo,
      // Mantener compatibilidad con el campo isRisk
      'isRisk': estado == ESTADO_EN_RIESGO ? 1 : 0,
    };
  }
}
