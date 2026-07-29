import 'dart:async';
import 'package:flutter/material.dart';
import 'package:semillas_app/core/database/database_helper.dart';
import 'package:semillas_app/core/models/device_model.dart';
import 'package:semillas_app/core/models/semilla_info.dart';
import 'package:semillas_app/services/p2p_service.dart';

/// Pantalla de intercambio de semillas entre dos dispositivos conectados,

class TradeScreen extends StatefulWidget {
  final P2PService p2pService;
  final DeviceModel device;

  const TradeScreen({
    super.key,
    required this.p2pService,
    required this.device,
  });

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  StreamSubscription<P2PMessage>? _sub;

  Map<String, int> _miInventario = {};
  bool _cargando = true;

  String? _miOferta;
  String? _suOferta;
  bool _miConfirmado = false;
  bool _suConfirmado = false;
  bool _procesandoIntercambio = false;

  @override
  void initState() {
    super.initState();
    _cargarInventario();

    _sub = widget.p2pService.messages
        .where((m) => m.deviceId == widget.device.id)
        .listen(_onMensaje);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _cargarInventario() async {
    final rows = await DatabaseHelper.instance.obtenerInventarioSemillas();
    if (!mounted) return;
    setState(() {
      _miInventario = {
        for (final row in rows)
          row['cultivo'] as String: row['cantidad'] as int,
      };
      _cargando = false;
    });
  }

  void _onMensaje(P2PMessage mensaje) {
    final accion = mensaje.data['accion'];

    switch (accion) {
      case 'oferta':
        setState(() {
          _suOferta = mensaje.data['semilla'] as String?;
          _suConfirmado = false;
        });
        break;
      case 'confirmar':
        setState(() => _suConfirmado = true);
        _intentarCompletarIntercambio();
        break;
      case 'cancelar':
        _resetOferta('El otro jugador canceló el intercambio.');
        break;
    }
  }

  void _elegirSemilla(String idCultivo) {
    if (_miConfirmado) return;

    setState(() => _miOferta = idCultivo);

    widget.p2pService.sendMessage(widget.device.id, {
      'accion': 'oferta',
      'semilla': idCultivo,
    });
  }

  void _confirmar() {
    if (_miOferta == null || _miConfirmado) return;

    setState(() => _miConfirmado = true);
    widget.p2pService.sendMessage(widget.device.id, {'accion': 'confirmar'});
    _intentarCompletarIntercambio();
  }

  Future<void> _intentarCompletarIntercambio() async {
    if (!_miConfirmado || !_suConfirmado) return;
    if (_miOferta == null || _suOferta == null) return;
    if (_procesandoIntercambio) return;

    _procesandoIntercambio = true;

    final exito = await DatabaseHelper.instance.intercambiarSemilla(
      semillaQueDoy: _miOferta!,
      semillaQueRecibo: _suOferta!,
    );

    if (!mounted) return;

    if (exito) {
      final recibida = semillaPorId(_suOferta!).nombre;
      await _cargarInventario();
      setState(() {
        _miOferta = null;
        _suOferta = null;
        _miConfirmado = false;
        _suConfirmado = false;
        _procesandoIntercambio = false;
      });
      _mostrarMensaje('🌱 ¡Intercambio completado! Recibiste $recibida.');
    } else {
      _procesandoIntercambio = false;
      _mostrarMensaje(
        'No tienes suficientes semillas para completar el intercambio.',
      );
    }
  }

  void _cancelar() {
    widget.p2pService.sendMessage(widget.device.id, {'accion': 'cancelar'});
    _resetOferta('Cancelaste el intercambio.');
  }

  void _resetOferta(String mensaje) {
    if (!mounted) return;
    setState(() {
      _miOferta = null;
      _suOferta = null;
      _miConfirmado = false;
      _suConfirmado = false;
      _procesandoIntercambio = false;
    });
    _mostrarMensaje(mensaje);
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  Widget build(BuildContext context) {
    final puedeConfirmar =
        _miOferta != null && _suOferta != null && !_miConfirmado;

    return Scaffold(
      backgroundColor: const Color(0xFF00695C),
      appBar: AppBar(
        title: Text('Intercambio con ${widget.device.name}'),
        backgroundColor: const Color(0xFF00695C),
      ),
      body:
          _cargando
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _ofertaCard(
                            titulo: 'Tú ofreces',
                            idCultivo: _miOferta,
                            confirmado: _miConfirmado,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.swap_horiz,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ofertaCard(
                            titulo: '${widget.device.name} ofrece',
                            idCultivo: _suOferta,
                            confirmado: _suConfirmado,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tu inventario:',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                            ),
                        itemCount: catalogoSemillas.length,
                        itemBuilder: (context, index) {
                          final semilla = catalogoSemillas[index];
                          final cantidad = _miInventario[semilla.id] ?? 0;
                          final seleccionada = _miOferta == semilla.id;

                          return GestureDetector(
                            onTap:
                                cantidad > 0
                                    ? () => _elegirSemilla(semilla.id)
                                    : null,
                            child: Opacity(
                              opacity: cantidad > 0 ? 1 : 0.35,
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      seleccionada
                                          ? Colors.white24
                                          : Colors.white10,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      seleccionada
                                          ? Border.all(
                                            color: Colors.amberAccent,
                                            width: 2,
                                          )
                                          : null,
                                ),
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      semilla.imagen,
                                      width: 36,
                                      height: 36,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      semilla.nombre,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      'x$cantidad',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _cancelar,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: puedeConfirmar ? _confirmar : null,
                            child: Text(
                              _miConfirmado ? 'Esperando...' : 'Confirmar',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _ofertaCard({
    required String titulo,
    required String? idCultivo,
    required bool confirmado,
  }) {
    final semilla = idCultivo != null ? semillaPorId(idCultivo) : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border:
            confirmado ? Border.all(color: Colors.greenAccent, width: 2) : null,
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (semilla != null) ...[
            Image.asset(semilla.imagen, width: 48, height: 48),
            const SizedBox(height: 4),
            Text(
              semilla.nombre,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ] else
            const SizedBox(
              height: 48,
              child: Icon(Icons.help_outline, color: Colors.white38),
            ),
          if (confirmado)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Confirmado ✓',
                style: TextStyle(color: Colors.greenAccent, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}
