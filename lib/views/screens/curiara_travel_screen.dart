import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:semillas_app/core/models/device_model.dart';
import 'package:semillas_app/core/router/router.dart';
import 'package:semillas_app/services/p2p_service.dart';
import 'package:semillas_app/widgets/device_list_widget.dart';
import 'package:semillas_app/views/screens/trade_screen.dart';
import '../layouts/base_layout.dart';

class CuriaraTravelScreen extends StatefulWidget {
  const CuriaraTravelScreen({super.key});

  @override
  State<CuriaraTravelScreen> createState() => _CuriaraTravelScreenState();
}

class _CuriaraTravelScreenState extends State<CuriaraTravelScreen> {
  late P2PService _p2pService;

  @override
  void initState() {
    super.initState();
    _p2pService = P2PService(
      deviceName:
          'Dispositivo-${DateTime.now().millisecondsSinceEpoch % 10000}',
    );
  }

  @override
  void dispose() {
    _p2pService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _p2pService,
      builder: (context, _) {
        return BaseLayout(
          backgroundPath: 'assets/images/Curiaras_bg.webp',
          child: _buildContent(),
        );
      },
    );
  }

  void _abrirIntercambio(DeviceModel device) {
    context.push(
      AppRoutes.trade,
      extra: {'p2pService': _p2pService, 'device': device},
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Viaje en Curiara',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Estado: ${_p2pService.status}'),
                  if (_p2pService.error != null)
                    Text(
                      'Error: ${_p2pService.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  Text(
                    'Conectados: ${_p2pService.connectedCount}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _p2pService.isPublishing
                          ? null
                          : _p2pService.startPublishing,
                  child: Text(
                    _p2pService.isPublishing ? 'Publicado' : 'Publicar',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _p2pService.isScanning ? null : _p2pService.startScanning,
                  child: Text(
                    _p2pService.isScanning ? 'Buscando...' : 'Buscar',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: DeviceListWidget(
              p2pService: _p2pService,
              onConnect: _abrirIntercambio,
              onOpenTrade: _abrirIntercambio,
            ),
          ),
        ],
      ),
    );
  }
}
