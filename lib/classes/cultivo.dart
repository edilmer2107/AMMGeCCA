class Cultivo {
  final int? id;
  final String nombre;
  final String tipoSuelo;
  final double area;
  final String fechaSiembra;
  final String? fechaCosecha;
  final String estado;
  final String? notas;
  final String? imagenUrl;
  final int? tipoId; // FK to tipos_cultivo
  final int? categoriaId; // FK to categorias
  final String tipoRiego;
  final double? cantidadCosechada; // kg o unidades
  final double? ingresos; // dinero obtenido
  final double? egresos; // costos

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
    this.tipoRiego = '',
    this.cantidadCosechada,
    this.ingresos,
    this.egresos,
  });

  factory Cultivo.fromMap(Map<String, Object?> map) => Cultivo(
    id: map['id'] as int?,
    nombre: map['nombre'] as String? ?? '',
    tipoSuelo: map['tipoSuelo'] as String? ?? '',
    area: map['area'] is double
        ? map['area'] as double
        : double.tryParse(map['area']?.toString() ?? '0.0') ?? 0.0,
    fechaSiembra: map['fechaSiembra'] as String? ?? '',
    fechaCosecha: map['fechaCosecha'] as String?,
    estado: map['estado'] as String? ?? '',
    notas: map['notas'] as String?,
    imagenUrl: map['imagenUrl'] as String?,
    tipoId: map['tipoId'] is int
        ? map['tipoId'] as int
        : int.tryParse(map['tipoId']?.toString() ?? ''),
    categoriaId: map['categoriaId'] is int
        ? map['categoriaId'] as int
        : int.tryParse(map['categoriaId']?.toString() ?? ''),
    tipoRiego: map['tipoRiego'] as String? ?? '',
    cantidadCosechada: map['cantidadCosechada'] is double
        ? map['cantidadCosechada'] as double
        : double.tryParse(map['cantidadCosechada']?.toString() ?? ''),
    ingresos: map['ingresos'] is double
        ? map['ingresos'] as double
        : double.tryParse(map['ingresos']?.toString() ?? ''),
    egresos: map['egresos'] is double
        ? map['egresos'] as double
        : double.tryParse(map['egresos']?.toString() ?? ''),
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
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
  };
}
