import 'package:flutter/material.dart';
import 'package:amgeca/classes/cultivo.dart';
import 'package:amgeca/Data/basedato_helper.dart';

class CosechaFormPage extends StatefulWidget {
  final Cultivo cultivo;

  const CosechaFormPage({Key? key, required this.cultivo}) : super(key: key);

  @override
  State<CosechaFormPage> createState() => _CosechaFormPageState();
}

class _CosechaFormPageState extends State<CosechaFormPage> {
  late TextEditingController _cantidadCtrl;
  late TextEditingController _ingresosCtrl;
  late TextEditingController _egresosCtrl;
  late TextEditingController _fechaCosechaCtrl;
  late TextEditingController _notasCtrl;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _cantidadCtrl = TextEditingController(
      text: widget.cultivo.cantidadCosechada?.toString() ?? '',
    );
    _ingresosCtrl = TextEditingController(
      text: widget.cultivo.ingresos?.toString() ?? '',
    );
    _egresosCtrl = TextEditingController(
      text: widget.cultivo.egresos?.toString() ?? '',
    );
    _fechaCosechaCtrl = TextEditingController(
      text: widget.cultivo.fechaCosecha ?? '',
    );
    _notasCtrl = TextEditingController(text: widget.cultivo.notas ?? '');
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _ingresosCtrl.dispose();
    _egresosCtrl.dispose();
    _fechaCosechaCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _fechaCosechaCtrl.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  void _saveCosecha() async {
    if (_formKey.currentState!.validate()) {
      final cultivo = Cultivo(
        id: widget.cultivo.id,
        nombre: widget.cultivo.nombre,
        tipoSuelo: widget.cultivo.tipoSuelo,
        area: widget.cultivo.area,
        fechaSiembra: widget.cultivo.fechaSiembra,
        fechaCosecha: _fechaCosechaCtrl.text,
        estado: 'cosechado',
        notas: _notasCtrl.text,
        imagenUrl: widget.cultivo.imagenUrl,
        tipoId: widget.cultivo.tipoId,
        categoriaId: widget.cultivo.categoriaId,
        tipoRiego: widget.cultivo.tipoRiego,
        cantidadCosechada: double.tryParse(_cantidadCtrl.text),
        ingresos: double.tryParse(_ingresosCtrl.text),
        egresos: double.tryParse(_egresosCtrl.text),
      );

      await BasedatoHelper.instance.updateCultivo(cultivo.id!, cultivo.toMap());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cosecha registrada exitosamente')),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ganancia =
        (double.tryParse(_ingresosCtrl.text) ?? 0) -
        (double.tryParse(_egresosCtrl.text) ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Cosecha'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Información del cultivo
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cultivo.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sembrío: ${widget.cultivo.fechaSiembra}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        'Área: ${widget.cultivo.area} m²',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Cantidad cosechada
              TextFormField(
                controller: _cantidadCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cantidad cosechada (kg)',
                  prefixIcon: Icon(Icons.agriculture),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa la cantidad cosechada';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Fecha de cosecha
              TextFormField(
                controller: _fechaCosechaCtrl,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Fecha de cosecha',
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _selectDate,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Selecciona la fecha de cosecha';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Ingresos
              TextFormField(
                controller: _ingresosCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ingresos (\$)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa los ingresos';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 16),
              // Egresos
              TextFormField(
                controller: _egresosCtrl,
                decoration: const InputDecoration(
                  labelText: 'Egresos (\$)',
                  prefixIcon: Icon(Icons.money_off),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa los egresos';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Ingresa un número válido';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 16),
              // Ganancia
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ganancia >= 0 ? Colors.green[50] : Colors.red[50],
                  border: Border.all(
                    color: ganancia >= 0 ? Colors.green : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ganancia neta:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\$${ganancia.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ganancia >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Notas
              TextFormField(
                controller: _notasCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notas adicionales',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveCosecha,
                  icon: const Icon(Icons.check),
                  label: const Text('Guardar Cosecha'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
