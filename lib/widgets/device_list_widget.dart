import 'package:flutter/material.dart';
import 'package:semillas_app/core/models/device_model.dart';
import '../services/p2p_service.dart';

class DeviceListWidget extends StatelessWidget {
  final P2PService p2pService;
  final VoidCallback onConnect;

  const DeviceListWidget({
    super.key,
    required this.p2pService,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final devices = p2pService.discoveredDevices;
    final connected = p2pService.connectedDevices;

    if (devices.isEmpty && connected.isEmpty) {
      return const Center(
        child: Text('No hay dispositivos disponibles'),
      );
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
          ...connected.map((device) => _buildDeviceTile(device, true)),
          const SizedBox(height: 16),
        ],
        if (devices.isNotEmpty) ...[
          const Text(
            'Dispositivos disponibles:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...devices.map((device) => _buildDeviceTile(device, false)),
        ],
      ],
    );
  }

  Widget _buildDeviceTile(DeviceModel device, bool isConnected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          isConnected ? Icons.check_circle : Icons.devices,
          color: isConnected ? Colors.green : Colors.blue,
        ),
        title: Text(device.name),
        subtitle: Text('${device.host}:${device.port}'),
        trailing: isConnected
            ? Chip(
                label: const Text('Conectado'),
                backgroundColor: Colors.green.shade100,
              )
            : ElevatedButton(
                onPressed: () => _connectToDevice(device),
                child: const Text('Conectar'),
              ),
      ),
    );
  }

  void _connectToDevice(DeviceModel device) async {
    await p2pService.connectToDevice(device);
    onConnect();
  }
}