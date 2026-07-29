import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../layouts/base_layout.dart';
import '../../../core/database/database_helper.dart';
 
class Historia {
  final int id;
  final String titulo;
  final String contenido;
  bool leido; 

  Historia({
    required this.id, 
    required this.titulo, 
    required this.contenido,
    this.leido = false,
  });

  factory Historia.fromJson(Map<String, dynamic> json) {
    return Historia(
      id: json['id'] as int,
      titulo: json['titulo'] as String,
      contenido: json['contenido'] as String,
    );
  }
}

class GrandfatherScreen extends StatefulWidget {
  const GrandfatherScreen({super.key});

  @override
  State<GrandfatherScreen> createState() => _GrandfatherScreenState();
}

class _GrandfatherScreenState extends State<GrandfatherScreen> {
  List<Historia> _historias = [];
  Historia? _historiaSeleccionada;
  bool _isLoading = true;

  // SOLUCIÓN ESCALABILIDAD: Identificamos que esta pantalla corresponde al Nivel 1
  final int _nivelActual = 1;

  @override
  void initState() {
    super.initState();
    _cargarCuentos();
  }

  // TAREA 1 Y 2: Carga el JSON y filtra de SQLite solo los cuentos de ESTE nivel
  Future<void> _cargarCuentos() async {
    try {
      final String response = await rootBundle.loadString('assets/data/cuentos_nivel1.json');
      final data = json.decode(response);
      final List<dynamic> listaJson = data['historias'];

      // Consumimos el método corregido pasándole el nivel actual (1)
      final List<int> idsLeidos = await DatabaseHelper.instance.obtenerCuentosLeidosPorNivel(_nivelActual);

      setState(() {
        _historias = listaJson.map((item) {
          final historia = Historia.fromJson(item);
          // La comparación sigue siendo directa y limpia
          if (idsLeidos.contains(historia.id)) {
            historia.leido = true;
          }
          return historia;
        }).toList();

        if (_historias.isNotEmpty) {
          _historiaSeleccionada = _historias.first;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error cargando el JSON o SQLite en cuentos: $e");
      setState(() => _isLoading = false);
    }
  }

  // TAREA 3: Guarda el ID del cuento vinculado a su nivel en SQLite
  Future<void> _marcarComoLeido(Historia historia) async {
    if (historia.leido) return;

    // Mandamos tanto el ID del cuento (1, 2, 3...) como el nivel (1)
    await DatabaseHelper.instance.guardarCuentoLeido(historia.id, _nivelActual);

    setState(() {
      historia.leido = true; // El check verde aparece inmediatamente
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      backgroundPath: 'assets/images/Abuelo_bg.webp',
      child: Stack(
        children: [
          // Botón Regresar
          Positioned(
            bottom: 20,
            left: 20,
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFD84315),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 5, offset: Offset(0, 5))],
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30),
              ),
            ),
          ),

          // Contenido Principal
          Positioned.fill(
            child: SafeArea(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFD84315)))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                      child: Row(
                        children: [
                          // Menú lateral
                          Container(
                            width: 160,
                            margin: const EdgeInsets.only(bottom: 80),
                            child: ListView.builder(
                              itemCount: _historias.length,
                              itemBuilder: (context, index) {
                                final historia = _historias[index];
                                final isSelected = _historiaSeleccionada?.id == historia.id;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _historiaSeleccionada = historia;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFFD84315) : Colors.white.withValues(alpha: 0.85),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: isSelected ? Colors.white : const Color(0xFFD84315).withValues(alpha: 0.5),
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              historia.titulo,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          if (historia.leido) ...[
                                            const SizedBox(width: 4),
                                            Icon(
                                              Icons.check_circle_rounded,
                                              color: isSelected ? Colors.greenAccent : Colors.green,
                                              size: 18,
                                            ),
                                          ]
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 20),

                          // Pantalla Narrativa
                          Expanded(
                            child: _historiaSeleccionada == null
                                ? const Center(child: Text("Selecciona un tema ancestral"))
                                : Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFFFC107), width: 3),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _historiaSeleccionada!.titulo,
                                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFD84315)),
                                        ),
                                        const Divider(height: 20, thickness: 2, color: Color(0xFFFFC107)),
                                        Expanded(
                                          child: SingleChildScrollView(
                                            physics: const BouncingScrollPhysics(),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                Text(
                                                  _historiaSeleccionada!.contenido,
                                                  style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.6, fontWeight: FontWeight.w500),
                                                ),
                                                const SizedBox(height: 25),
                                                
                                                // Botón interactivo condicional
                                                _historiaSeleccionada!.leido
                                                    ? const Center(
                                                        child: Padding(
                                                          padding: EdgeInsets.symmetric(vertical: 10),
                                                          child: Row(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Icon(Icons.done_all_rounded, color: Colors.green),
                                                              SizedBox(width: 8),
                                                              Text("¡Cuento completado!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 15)),
                                                            ],
                                                          ),
                                                        ),
                                                      )
                                                    : Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                                                        child: ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: const Color(0xFFFF8F00),
                                                            foregroundColor: Colors.white,
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                                          ),
                                                          onPressed: () => _marcarComoLeido(_historiaSeleccionada!),
                                                          child: const Text("Terminar Lectura", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                                        ),
                                                      ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}