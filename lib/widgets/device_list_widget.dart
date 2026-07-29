import 'package:flutter/material.dart';
import 'package:semillas_app/core/models/device_model.dart';
import '../services/p2p_service.dart';

class DeviceListWidget extends StatelessWidget {
  final P2PService p2pService;

  /// Se llama justo después de conectarte con éxito a un dispositivo
  /// (útil para navegar directo a la pantalla de intercambio).
  final void Function(DeviceModel device) onConnect;

  /// Se llama al tocar un dispositivo que YA está conectado, para
  /// volver a abrir la pantalla de intercambio con él.
  final void Function(DeviceModel device)? onOpenTrade;

  const DeviceListWidget({
    super.key,
    required this.p2pService,
    required this.onConnect,
    this.onOpenTrade,
  });

  @override
  Widget build(BuildContext context) {
    final devices = p2pService.discoveredDevices;
    final connected = p2pService.connectedDevices;

    if (devices.isEmpty && connected.isEmpty) {
      return const Center(child: Text('No hay dispositivos disponibles'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (connected.isNotEmpty) ...[
          const Text(
            'Conectados:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...connected.map((device) => _buildDeviceTile(context, device, true)),
          const SizedBox(height: 16),
        ],
        if (devices.isNotEmpty) ...[
          const Text(
            'Dispositivos disponibles:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...devices.map((device) => _buildDeviceTile(context, device, false)),
        ],
      ],
    );
  }

  Widget _buildDeviceTile(
    BuildContext context,
    DeviceModel device,
    bool isConnected,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: isConnected ? () => onOpenTrade?.call(device) : null,
        leading: Icon(
          isConnected ? Icons.check_circle : Icons.devices,
          color: isConnected ? Colors.green : Colors.blue,
        ),
        title: Text(device.name),
        subtitle: Text('${device.host}:${device.port}'),
        trailing:
            isConnected
                ? const Icon(Icons.swap_horiz, color: Colors.green)
                : ElevatedButton(
                  onPressed: () => _connectToDevice(device),
                  child: const Text('Conectar'),
                ),
      ),
    );
  }

  void _connectToDevice(DeviceModel device) async {
    final ok = await p2pService.connectToDevice(device);
    if (ok) onConnect(device);
  }
}
