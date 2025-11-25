// lib/View/amgecca_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'recomendaciones_helper.dart';
import '../services/deepseek_chat.dart';
import 'package:file_picker/file_picker.dart';

// Definir cultivos disponibles
class Cultivo {
  final String id;
  final String nombre;
  final String icono;
  final String modeloPath;
  final String labelsPath;

  const Cultivo({
    required this.id,
    required this.nombre,
    required this.icono,
    required this.modeloPath,
    required this.labelsPath,
  });
}

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  // Lista de cultivos disponibles
  final List<Cultivo> _cultivos = const [
    Cultivo(
      id: 'tomate',
      nombre: 'Tomate',
      icono: '🍅',
      modeloPath: 'assets/modelo_tomate.tflite',
      labelsPath: 'assets/labels_tomate.txt',
    ),
    Cultivo(
      id: 'platano',
      nombre: 'Plátano',
      icono: '🍌',
      modeloPath: 'assets/modelo_platano.tflite',
      labelsPath: 'assets/labels_platano.txt',
    ),
    Cultivo(
      id: 'cafe',
      nombre: 'Café',
      icono: '☕',
      modeloPath: 'assets/modelo_cafe.tflite',
      labelsPath: 'assets/labels_cafe.txt',
    ),
    Cultivo(
      id: 'cacao',
      nombre: 'Cacao',
      icono: '🍫',
      modeloPath: 'assets/modelo_cacao.tflite',
      labelsPath: 'assets/labels_cacao.txt',
    ),
    Cultivo(
      id: 'maiz',
      nombre: 'Maíz',
      icono: '🌽',
      modeloPath: 'assets/modelo_maiz.tflite',
      labelsPath: 'assets/labels_maiz.txt',
    ),
    Cultivo(
      id: 'arroz',
      nombre: 'Arroz',
      icono: '🌾',
      modeloPath: 'assets/modelo_arroz.tflite',
      labelsPath: 'assets/labels_arroz.txt',
    ),
  ];

  Cultivo? _cultivoSeleccionado;
  File? _image;
  bool _loading = false;
  bool _modeloListo = false;
  String? _resultado;
  double? _confianza;
  Interpreter? _interpreter;
  List<String> _labels = [];

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  Future<void> cargarModelo(Cultivo cultivo) async {
    setState(() {
      _modeloListo = false;
      _resultado = null;
      _confianza = null;
      _image = null;
    });

    _interpreter?.close();
    _interpreter = null;

    try {
      final modelData = await rootBundle.load(cultivo.modeloPath);
      final tempDir = await getTemporaryDirectory();
      final modelFile = File('${tempDir.path}/${cultivo.id}_model.tflite');
      await modelFile.writeAsBytes(modelData.buffer.asUint8List());

      _interpreter = Interpreter.fromFile(modelFile);

      final labelsData = await rootBundle.loadString(cultivo.labelsPath);
      _labels = labelsData
          .split('\n')
          .map((l) => l.replaceAll(RegExp(r'^\d+\s*'), '').trim())
          .where((l) => l.isNotEmpty)
          .toList();

      setState(() {
        _cultivoSeleccionado = cultivo;
        _modeloListo = true;
      });

      debugPrint(
        '✅ Modelo ${cultivo.nombre} cargado: ${_labels.length} clases',
      );
    } catch (e) {
      debugPrint('❌ Error cargando ${cultivo.nombre}: $e');
      setState(() {
        _resultado = "Error cargando modelo de ${cultivo.nombre}";
        _modeloListo = false;
      });
    }
  }

  Future<void> seleccionarImagen(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? foto = await picker.pickImage(source: source);

    if (foto != null) {
      setState(() {
        _image = File(foto.path);
        _loading = true;
        _resultado = null;
        _confianza = null;
      });
      await analizarImagen(File(foto.path));
    }
  }

  Future<void> analizarImagen(File imageFile) async {
    if (_interpreter == null) {
      setState(() {
        _loading = false;
        _resultado = "Primero selecciona un cultivo";
      });
      return;
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        setState(() {
          _loading = false;
          _resultado = "No se pudo leer la imagen";
        });
        return;
      }

      final resized = img.copyResize(image, width: 224, height: 224);

      var input = List.generate(
        1,
        (_) => List.generate(
          224,
          (y) => List.generate(224, (x) {
            final pixel = resized.getPixel(x, y);
            return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
          }),
        ),
      );

      var output = List.filled(
        _labels.length,
        0.0,
      ).reshape([1, _labels.length]);

      _interpreter!.run(input, output);

      final results = (output[0] as List).cast<double>();
      int maxIdx = 0;
      double maxConf = results[0];

      for (int i = 1; i < results.length; i++) {
        if (results[i] > maxConf) {
          maxConf = results[i];
          maxIdx = i;
        }
      }

      setState(() {
        _loading = false;
        _confianza = maxConf;
        _resultado = maxIdx < _labels.length
            ? _labels[maxIdx]
            : "Clase desconocida";
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _resultado = "Error: $e";
      });
    }
  }

  Color _getColorConfianza(double conf) {
    if (conf >= 0.8) return Colors.green;
    if (conf >= 0.5) return Colors.orange;
    return Colors.red;
  }

  Widget _buildRecomendaciones() {
    if (_resultado == null || _cultivoSeleccionado == null) {
      return const SizedBox.shrink();
    }

    String claveEnfermedad = '${_cultivoSeleccionado!.nombre}_$_resultado';
    final recomendacion = RecomendacionesHelper.obtenerRecomendacion(
      claveEnfermedad,
    );

    if (recomendacion == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No hay recomendaciones disponibles para esta detección.',
          style: TextStyle(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: recomendacion.color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(recomendacion.icono, color: recomendacion.color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    recomendacion.enfermedad,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: recomendacion.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recomendacion.descripcion,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                _buildSeccion(
                  'Síntomas',
                  Icons.visibility,
                  recomendacion.sintomas,
                  Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildSeccion(
                  'Tratamientos Recomendados',
                  Icons.medical_services,
                  recomendacion.tratamientos,
                  Colors.red,
                ),
                const SizedBox(height: 12),
                _buildSeccion(
                  'Prevención',
                  Icons.shield,
                  recomendacion.prevencion,
                  Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccion(
    String titulo,
    IconData icono,
    List<String> items,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(left: 28, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: color, fontSize: 16)),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarChatBot() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => const ChatBotModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AMGeCA IA'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecciona el cultivo:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: _cultivos.length,
                    itemBuilder: (context, index) {
                      final cultivo = _cultivos[index];
                      final isSelected = _cultivoSeleccionado?.id == cultivo.id;

                      return GestureDetector(
                        onTap: () => cargarModelo(cultivo),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.green[100]
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.green
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                cultivo.icono,
                                style: const TextStyle(fontSize: 32),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cultivo.nombre,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.green[800]
                                      : Colors.black87,
                                ),
                              ),
                              if (isSelected && _modeloListo)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 16,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_cultivoSeleccionado != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _modeloListo
                            ? Colors.green[50]
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _modeloListo
                                ? Icons.check_circle
                                : Icons.hourglass_empty,
                            color: _modeloListo ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _modeloListo
                                ? '${_cultivoSeleccionado!.nombre}: ${_labels.length} enfermedades'
                                : 'Cargando modelo...',
                            style: TextStyle(
                              color: _modeloListo
                                  ? Colors.green[800]
                                  : Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_image!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _cultivoSeleccionado == null
                                    ? 'Primero selecciona un cultivo'
                                    : 'Selecciona una imagen',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _modeloListo
                              ? () => seleccionarImagen(ImageSource.camera)
                              : null,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Cámara'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _modeloListo
                              ? () => seleccionarImagen(ImageSource.gallery)
                              : null,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galería'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_loading)
                    const Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Colors.green),
                          SizedBox(height: 12),
                          Text('Analizando imagen...'),
                        ],
                      ),
                    ),
                  if (_resultado != null && !_loading)
                    Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                _cultivoSeleccionado?.icono ?? '🌱',
                                style: const TextStyle(fontSize: 40),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Resultado del análisis',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _resultado!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_confianza != null) ...[
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value: _confianza,
                                  backgroundColor: Colors.grey[200],
                                  color: _getColorConfianza(_confianza!),
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Confianza: ${(_confianza! * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    color: _getColorConfianza(_confianza!),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildRecomendaciones(),
                      ],
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Botón flotante del ChatBot
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              onPressed: _mostrarChatBot,
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.reviews_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Modal del ChatBot con soporte de archivos
class ChatBotModal extends StatefulWidget {
  const ChatBotModal({Key? key}) : super(key: key);

  @override
  State<ChatBotModal> createState() => _ChatBotModalState();
}

class _ChatBotModalState extends State<ChatBotModal> {
  final DeepSeekChat bot = DeepSeekChat();
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  List<Map<String, dynamic>> messages = [];
  bool isLoading = false;
  bool showAttachmentMenu = false;

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  void send() async {
    String text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"user": text, "type": "text"});
      isLoading = true;
    });

    controller.clear();
    _scrollToBottom();

    String reply = await bot.sendMessage(text);

    setState(() {
      messages.add({"bot": reply, "type": "text"});
      isLoading = false;
    });
    _scrollToBottom();
  }

  void pickImage() async {
    setState(() => showAttachmentMenu = false);

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        messages.add({
          "user": "📷 Imagen adjunta",
          "type": "image",
          "file": File(image.path),
        });
        isLoading = true;
      });
      _scrollToBottom();

      String reply = await bot.sendMessageWithImage(
        "Analiza esta imagen relacionada con cultivos agrícolas y dame información relevante",
        File(image.path),
      );

      setState(() {
        messages.add({"bot": reply, "type": "text"});
        isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void pickDocument() async {
    setState(() => showAttachmentMenu = false);

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'csv'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileName = result.files.single.name;

      setState(() {
        messages.add({
          "user": "📄 $fileName",
          "type": "document",
          "file": file,
          "fileName": fileName,
        });
        isLoading = true;
      });
      _scrollToBottom();

      String reply = await bot.sendMessageWithDocument(
        "He adjuntado un documento. Por favor analízalo y dame un resumen.",
        file,
        fileName,
      );

      setState(() {
        messages.add({"bot": reply, "type": "text"});
        isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void takePhoto() async {
    setState(() => showAttachmentMenu = false);

    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (photo != null) {
      setState(() {
        messages.add({
          "user": "📸 Foto tomada",
          "type": "image",
          "file": File(photo.path),
        });
        isLoading = true;
      });
      _scrollToBottom();

      String reply = await bot.sendMessageWithImage(
        "Analiza esta foto relacionada con cultivos agrícolas y dame información relevante",
        File(photo.path),
      );

      setState(() {
        messages.add({"bot": reply, "type": "text"});
        isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessage(Map<String, dynamic> msg, bool isBot) {
    if (msg["type"] == "image" && !isBot) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(maxWidth: 200),
        decoration: BoxDecoration(
          color: Colors.deepPurple[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                msg["file"],
                height: 150,
                width: 150,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 4),
            Text(msg["user"], style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    if (msg["type"] == "document" && !isBot) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: Colors.deepPurple[100],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insert_drive_file,
              size: 32,
              color: Colors.deepPurple,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg["user"],
                style: const TextStyle(fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isBot ? Colors.grey[200] : Colors.deepPurple[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        isBot ? msg["bot"] : msg["user"],
        style: const TextStyle(fontSize: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      duration: const Duration(milliseconds: 100),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.smart_toy, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Asistente IA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'AMGeCCA',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '¡Hola! Soy tu asistente agrícola',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pregúntame sobre cultivos, plagas o enfermedades',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'También puedes enviar fotos 📷 o documentos 📄',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[400],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length + (isLoading ? 1 : 0),
                      itemBuilder: (_, index) {
                        if (index == messages.length && isLoading) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text('Analizando...'),
                                ],
                              ),
                            ),
                          );
                        }

                        final msg = messages[index];
                        final isBot = msg.containsKey("bot");

                        return Align(
                          alignment: isBot
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          child: _buildMessage(msg, isBot),
                        );
                      },
                    ),
            ),

            // Menú de adjuntos
            if (showAttachmentMenu)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentButton(
                      icon: Icons.camera_alt,
                      label: 'Cámara',
                      color: Colors.blue,
                      onTap: takePhoto,
                    ),
                    _buildAttachmentButton(
                      icon: Icons.photo_library,
                      label: 'Galería',
                      color: Colors.green,
                      onTap: pickImage,
                    ),
                    _buildAttachmentButton(
                      icon: Icons.insert_drive_file,
                      label: 'Documento',
                      color: Colors.orange,
                      onTap: pickDocument,
                    ),
                  ],
                ),
              ),

            // Input
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Botón de adjuntos
                    IconButton(
                      icon: Icon(
                        showAttachmentMenu ? Icons.close : Icons.add_circle,
                        color: Colors.deepPurple,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          showAttachmentMenu = !showAttachmentMenu;
                        });
                      },
                    ),
                    const SizedBox(width: 4),
                    // Campo de texto
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: TextField(
                          controller: controller,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.send,
                          decoration: InputDecoration(
                            hintText: "Escribe tu consulta...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => send(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Botón de enviar
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: send,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
