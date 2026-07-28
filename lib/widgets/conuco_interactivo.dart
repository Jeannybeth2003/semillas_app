import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/models/parcela_model.dart';
import 'package:semillas_app/core/database/database_helper.dart';

class ConucoInteractivo extends StatefulWidget {
  const ConucoInteractivo({super.key});

  @override
  State<ConucoInteractivo> createState() => _ConucoInteractivoState();
}

class _ConucoInteractivoState extends State<ConucoInteractivo> {
  List<ParcelaModel> _parcelas = [];
  String _herramientaActiva = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosBD();
  }

  @override
  void dispose() {
    for (var p in _parcelas) {
      p.timerCrecimiento?.cancel();
    }
    super.dispose();
  }

  Future<void> _cargarDatosBD() async {
    _inicializarParcelas();

    try {
      final List<Map<String, dynamic>> guardadas =
          await DatabaseHelper.instance.obtenerConucos();

      setState(() {
        for (var fila in guardadas) {
          int idBD = fila['id'] as int;
          int idCuadricula = int.parse(fila['coordenadas'] as String);
          String cultivoBD = fila['cultivo'] as String;
          int etapaBD = int.parse(fila['etapa'] as String);

          final index = _parcelas.indexWhere((p) => p.id == idCuadricula);
          if (index != -1) {
            _parcelas[index].dbId = idBD;
            _parcelas[index].estado = EstadoParcela.sembrada;
            _parcelas[index].cultivo = cultivoBD;
            _parcelas[index].etapa = etapaBD;

            if (etapaBD < 4) {
              _parcelas[index].necesitaAgua = true;
            }
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error cargando el conuco: $e");
      setState(() => _isLoading = false);
    }
  }

  void _inicializarParcelas() {
    _parcelas = [
      ParcelaModel(id: 1, position: const Offset(0.17, 0.60)),
      ParcelaModel(id: 2, position: const Offset(0.26, 0.60)),
      ParcelaModel(id: 3, position: const Offset(0.35, 0.60)),
      ParcelaModel(id: 4, position: const Offset(0.44, 0.60)),
      ParcelaModel(id: 5, position: const Offset(0.17, 0.73)),
      ParcelaModel(id: 6, position: const Offset(0.26, 0.73)),
      ParcelaModel(id: 7, position: const Offset(0.35, 0.73)),
      ParcelaModel(id: 8, position: const Offset(0.44, 0.73)),
      ParcelaModel(id: 9, position: const Offset(0.56, 0.60)),
      ParcelaModel(id: 10, position: const Offset(0.65, 0.60)),
      ParcelaModel(id: 11, position: const Offset(0.74, 0.60)),
      ParcelaModel(id: 12, position: const Offset(0.83, 0.60)),
      ParcelaModel(id: 13, position: const Offset(0.56, 0.73)),
      ParcelaModel(id: 14, position: const Offset(0.65, 0.73)),
      ParcelaModel(id: 15, position: const Offset(0.74, 0.73)),
      ParcelaModel(id: 16, position: const Offset(0.83, 0.73)),
    ];

    _parcelas[0].estado = EstadoParcela.conMaleza;
    _parcelas[11].estado = EstadoParcela.conMaleza;
  }

  Future<void> _interactuar(ParcelaModel parcela) async {
    if (_herramientaActiva.isEmpty) {
      _mostrarMensaje('Selecciona una herramienta abajo 👇');
      return;
    }

    switch (_herramientaActiva) {
      case 'Machete':
        if (parcela.estado == EstadoParcela.conMaleza) {
          setState(() => parcela.estado = EstadoParcela.vacia);
          _mostrarMensaje('🔪 Maleza cortada');
        }
        break;

      case 'Pala':
        if (parcela.estado == EstadoParcela.vacia) {
          setState(() => parcela.estado = EstadoParcela.preparada);
          _mostrarMensaje('⛏️ Tierra preparada para sembrar');
        }
        break;

      case 'Semillas':
        if (parcela.estado == EstadoParcela.preparada) {
          _mostrarMenuSiembra(parcela);
        } else {
          _mostrarMensaje('Debes usar la Pala antes de sembrar');
        }
        break;

      case 'Regadera':
        if (parcela.estado == EstadoParcela.sembrada && parcela.necesitaAgua) {
          _regarParcela(parcela);
        }
        break;

      case 'Cesta':
        if (parcela.estado == EstadoParcela.sembrada && parcela.etapa == 4) {
          if (parcela.dbId != null) {
            await DatabaseHelper.instance.eliminarCultivo(parcela.dbId!);
          }

          setState(() {
            parcela.estado = EstadoParcela.vacia;
            parcela.etapa = 0;
            parcela.cultivo = '';
            parcela.tiempoRestante = 0;
            parcela.dbId = null;
          });
          _mostrarMensaje('🧺 ¡Cosecha recolectada con éxito!');
        }
        break;
    }
  }

  void _regarParcela(ParcelaModel parcela) {
    setState(() {
      parcela.necesitaAgua = false;
      parcela.tiempoRestante = 300;
    });

    _mostrarMensaje('💧 Regada. Crecerá pronto.');

    parcela.timerCrecimiento?.cancel();

    parcela.timerCrecimiento = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (parcela.tiempoRestante > 0) {
        setState(() => parcela.tiempoRestante--);
      } else {
        timer.cancel();

        if (parcela.etapa < 4) {
          parcela.etapa++;

          if (parcela.dbId != null) {
            await DatabaseHelper.instance.actualizarEtapaCultivo(
              parcela.dbId!,
              parcela.etapa.toString(),
            );
          }

          setState(() {
            if (parcela.etapa < 4) {
              parcela.necesitaAgua = true;
            }
          });
        }
      }
    });
  }

  void _mostrarMensaje(String texto) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  String _obtenerImagenSemilla(String cultivo) {
    switch (cultivo) {
      case 'cacao':
        return 'Cacao_Semilla.png';
      case 'maiz':
        return 'Maíz_Semilla.png';
      case 'melon':
        return 'Melón_Semilla.png';
      case 'patilla':
        return 'Patilla_Semilla.png';
      case 'platano':
        return 'Platano_Semilla.png';
      case 'yuca':
        return 'Yuca_Semilla.png';
      default:
        return 'Cacao_Semilla.png';
    }
  }

  String _obtenerNombreExactoSprite(String cultivo, int etapa) {
    if (etapa == 4) {
      String capitalizado = cultivo[0].toUpperCase() + cultivo.substring(1);
      return '${capitalizado}_cosecha.png';
    }
    return '${cultivo}_$etapa.png';
  }

  String _formatearTiempo(int segundos) {
    final int minutos = segundos ~/ 60;
    final int segs = segundos % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segs.toString().padLeft(2, '0')}';
  }

  Widget _obtenerSprite(ParcelaModel parcela) {
    if (parcela.estado == EstadoParcela.conMaleza) {
      return Image.asset(
        'assets/images/sprites/Maleza.png',
        width: 65,
        height: 65,
      );
    }
    if (parcela.estado == EstadoParcela.vacia) {
      return Image.asset(
        'assets/images/sprites/parcela_vacia.png',
        width: 65,
        height: 65,
      );
    }
    if (parcela.estado == EstadoParcela.preparada) {
      return ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.black38, BlendMode.darken),
        child: Image.asset(
          'assets/images/sprites/parcela_vacia.png',
          width: 65,
          height: 65,
        ),
      );
    }

    String rutaSprite =
        'assets/images/sprites/${_obtenerNombreExactoSprite(parcela.cultivo, parcela.etapa)}';

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Image.asset(
          rutaSprite,
          width: 65,
          height: 65,
          fit: BoxFit.contain,
          errorBuilder:
              (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, color: Colors.redAccent),
        ),

        if (parcela.necesitaAgua && parcela.etapa < 4)
          const Positioned(
            top: -15,
            right: -10,
            child: Icon(Icons.water_drop, color: Colors.blueAccent, size: 28),
          ),

        if (parcela.tiempoRestante > 0)
          Positioned(
            bottom: -15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFC107), width: 1),
              ),
              child: Text(
                _formatearTiempo(parcela.tiempoRestante),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _mostrarMenuSiembra(ParcelaModel parcela) {
    setState(() {
      _herramientaActiva = '';
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF00695C),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          height: 180,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                '¿Qué semilla vas a sembrar?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _botonCultivo(context, parcela, 'Cacao', 'cacao'),
                    _botonCultivo(context, parcela, 'Maíz', 'maiz'),
                    _botonCultivo(context, parcela, 'Melón', 'melon'),
                    _botonCultivo(context, parcela, 'Patilla', 'patilla'),
                    _botonCultivo(context, parcela, 'Plátano', 'platano'),
                    _botonCultivo(context, parcela, 'Yuca', 'yuca'),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _botonCultivo(
    BuildContext context,
    ParcelaModel parcela,
    String nombre,
    String idCultivo,
  ) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);

        int nuevoIdBD = await DatabaseHelper.instance.sembrarCultivo(
          parcela.id.toString(),
          idCultivo,
          "1",
        );

        setState(() {
          parcela.dbId = nuevoIdBD;
          parcela.estado = EstadoParcela.sembrada;
          parcela.etapa = 1;
          parcela.cultivo = idCultivo;
          parcela.necesitaAgua = true;
        });

        _mostrarMensaje('🌱 ¡$nombre sembrado! Usa la regadera.');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          children: [
            Image.asset(
              'assets/images/sprites/${_obtenerImagenSemilla(idCultivo)}',
              width: 45,
              height: 45,
            ),
            const SizedBox(height: 8),
            Text(
              nombre,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF004D40),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFFC107), width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _iconoHerramienta('Machete', 'Machete.png'),
          _iconoHerramienta('Pala', 'Pala.png'),
          _iconoHerramienta('Semillas', 'Cacao_Semilla.png'),
          _iconoHerramienta('Regadera', 'Regadera.png'),
          _iconoHerramienta('Cesta', 'Cesta.png'),
        ],
      ),
    );
  }

  Widget _iconoHerramienta(String id, String assetName) {
    bool activo = _herramientaActiva == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          _herramientaActiva = activo ? '' : id;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFFFFC107) : Colors.transparent,
          shape: BoxShape.circle,
          border: activo ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Image.asset(
          'assets/images/sprites/$assetName',
          width: 35,
          height: 35,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFC107)),
      );
    }

    final Size size = MediaQuery.of(context).size;

    return Stack(
      children: [
        ..._parcelas.map((parcela) {
          final double leftPos = (parcela.position.dx * size.width) - 32.5;
          final double topPos = (parcela.position.dy * size.height) - 32.5;

          return Positioned(
            left: leftPos,
            top: topPos,
            child: GestureDetector(
              onTap: () => _interactuar(parcela),
              child: _obtenerSprite(parcela),
            ),
          );
        }),

        Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Center(child: _buildToolbar()),
        ),
      ],
    );
  }
}
