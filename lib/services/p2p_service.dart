import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:nsd/nsd.dart';
import 'package:flutter/material.dart';
import 'package:semillas_app/core/models/device_model.dart';

class P2PService extends ChangeNotifier {
  static const String serviceType = '_snap360p2p._tcp';

  final String deviceName;

  // Estado
  final List<DeviceModel> _discoveredDevices = [];
  final List<DeviceModel> _connectedDevices = [];
  bool _isPublishing = false;
  bool _isScanning = false;
  String _status = 'Inactivo';
  String? _error;

  // Servicios
  ServerSocket? _server;
  Registration? _registration;
  Discovery? _discovery;
  final Map<String, Socket> _sockets = {};
  final Set<String> _connectingIds = {};

  // Getters
  List<DeviceModel> get discoveredDevices => _discoveredDevices;
  List<DeviceModel> get connectedDevices => _connectedDevices;
  bool get isPublishing => _isPublishing;
  bool get isScanning => _isScanning;
  String get status => _status;
  String? get error => _error;
  int get connectedCount => _connectedDevices.length;

  P2PService({required this.deviceName});

  Future<void> startPublishing() async {
    await _stopPublishingOnly();

    _isPublishing = true;
    _status = 'Publicando dispositivo...';
    _error = null;
    notifyListeners();

    try {
      _server = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        0,
        shared: true,
      );

      _server!.listen(
        _handleIncomingConnection,
        onError: (error) {
          _status = 'Error del servidor: $error';
          _error = error.toString();
          notifyListeners();
        },
      );

      _registration = await register(
        Service(name: deviceName, type: serviceType, port: _server!.port),
      );

      _status = 'Dispositivo publicado en la red';
      _error = null;
      notifyListeners();
    } catch (e) {
      _status = 'Error al publicar: $e';
      _error = e.toString();
      await _shutdown();
      _isPublishing = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> startScanning() async {
    await _stopDiscoveryOnly();

    _isScanning = true;
    _status = 'Buscando dispositivos...';
    _discoveredDevices.clear();
    _error = null;
    notifyListeners();

    try {
      _discovery = await startDiscovery(
        serviceType,
        autoResolve: true,
        ipLookupType: IpLookupType.any,
      );

      _discovery!.addServiceListener((service, status) {
        _handleServiceDiscovery(service, status);
      });

      // Procesar servicios ya encontrados
      for (final service in List<Service>.from(_discovery!.services)) {
        _handleServiceDiscovery(service, ServiceStatus.found);
      }

      _status = 'Escaneando activamente...';
      notifyListeners();
    } catch (e) {
      _status = 'Error al escanear: $e';
      _error = e.toString();
      await _shutdown();
      _isScanning = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> connectToDevice(DeviceModel device) async {
    if (_connectedDevices.any((d) => d.id == device.id)) {
      _status = 'Ya estás conectado a este dispositivo';
      notifyListeners();
      return false;
    }

    if (_connectingIds.contains(device.id)) {
      _status = 'Conectando en progreso...';
      notifyListeners();
      return false;
    }

    _connectingIds.add(device.id);
    _status = 'Conectando a ${device.name}...';
    notifyListeners();

    try {
      final socket = await Socket.connect(
        device.host,
        device.port,
        timeout: const Duration(seconds: 5),
      );

      socket.setOption(SocketOption.tcpNoDelay, true);
      _sockets[device.id] = socket;

      // Escuchar respuestas
      String buffer = '';
      socket.listen(
        (data) {
          buffer += utf8.decode(data, allowMalformed: true);
          int newLineIndex;
          while ((newLineIndex = buffer.indexOf('\n')) >= 0) {
            final line = buffer.substring(0, newLineIndex).trim();
            buffer = buffer.substring(newLineIndex + 1);
            _handlePeerResponse(device.id, line);
          }
        },
        onDone: () => _disconnectDevice(device.id),
        onError: (_) => _disconnectDevice(device.id),
        cancelOnError: true,
      );

      socket.writeln('HELLO:$deviceName');

      final updatedDevice = device.copyWith(isConnected: true);
      _connectedDevices.add(updatedDevice);

      _discoveredDevices.removeWhere((d) => d.id == device.id);

      _status = 'Conectado a ${device.name}';
      _error = null;
      _connectingIds.remove(device.id);
      notifyListeners();

      return true;
    } catch (e) {
      _status = 'Error al conectar: $e';
      _error = e.toString();
      _connectingIds.remove(device.id);
      notifyListeners();
      return false;
    }
  }

  void disconnectDevice(String deviceId) {
    _disconnectDevice(deviceId);
  }

  void _disconnectDevice(String deviceId) {
    _sockets.remove(deviceId)?.destroy();
    _connectedDevices.removeWhere((d) => d.id == deviceId);
    _status = 'Desconectado de dispositivo';
    notifyListeners();
  }

  void _handleIncomingConnection(Socket socket) {
    String buffer = '';
    String? peerId;

    socket.setOption(SocketOption.tcpNoDelay, true);

    socket.listen(
      (data) {
        buffer += utf8.decode(data, allowMalformed: true);
        int newLineIndex;
        while ((newLineIndex = buffer.indexOf('\n')) >= 0) {
          final line = buffer.substring(0, newLineIndex).trim();
          buffer = buffer.substring(newLineIndex + 1);
          _handleIncomingMessage(socket, line, (id) => peerId = id);
        }
      },
      onDone: () {
        if (peerId != null) {
          _sockets.remove(peerId);
          _connectedDevices.removeWhere((d) => d.id == peerId);
          notifyListeners();
        }
        socket.destroy();
      },
      onError: (_) => socket.destroy(),
      cancelOnError: true,
    );
  }

  void _handleIncomingMessage(
    Socket socket,
    String message,
    Function(String) setPeerId,
  ) {
    if (message.startsWith('HELLO:')) {
      final controllerName = message.substring('HELLO:'.length);
      final id = 'controller_${DateTime.now().millisecondsSinceEpoch}';
      setPeerId(id);

      socket.writeln('ACK:$deviceName');

      final device = DeviceModel(
        id: id,
        name: controllerName,
        host: socket.remoteAddress.address,
        port: socket.remotePort,
        isConnected: true,
        isController: true,
      );

      _sockets[id] = socket;
      _connectedDevices.add(device);
      _status = 'Conectado con $controllerName';
      notifyListeners();
    }
  }

  void _handleServiceDiscovery(Service service, ServiceStatus status) {
    debugPrint(
      'NSD: $status | '
      'name=${service.name} | '
      'host=${service.host} | '
      'port=${service.port} | '
      'addresses=${service.addresses}',
    );

    if (status == ServiceStatus.lost) {
      _discoveredDevices.removeWhere((device) => device.id == service.name);
      notifyListeners();
      return;
    }

    final host = _getServiceHost(service);
    final port = service.port;

    if (host == null || port == null) {
      debugPrint('Servicio todavía no resuelto');
      return;
    }

    final id = '${service.name}-$host-$port';

    if (_connectedDevices.any((device) => device.id == id) ||
        _connectingIds.contains(id)) {
      return;
    }

    final device = DeviceModel(
      id: id,
      name: service.name ?? 'Dispositivo desconocido',
      host: host,
      port: port,
    );

    if (!_discoveredDevices.any((item) => item.id == id)) {
      _discoveredDevices.add(device);
      notifyListeners();
    }

    if (_connectedDevices.length < 2) {
      unawaited(connectToDevice(device));
    }
  }

  String? _getServiceHost(Service service) {
    final addresses = service.addresses ?? [];
    for (final address in addresses) {
      if (address.type == InternetAddressType.IPv4) {
        return address.address;
      }
    }
    return service.host;
  }

  void _handlePeerResponse(String deviceId, String message) {
    if (message.startsWith('ACK:')) {
      final peerName = message.substring('ACK:'.length);
      _status = 'Respuesta recibida de $peerName';
      notifyListeners();
    }
  }

  Future<void> stop() async {
    await _shutdown();
    _isPublishing = false;
    _isScanning = false;
    _status = 'Detenido';
    _discoveredDevices.clear();
    _connectedDevices.clear();
    notifyListeners();
  }

  Future<void> _shutdown() async {
    await _stopDiscoveryOnly();
    await _stopPublishingOnly();

    for (final socket in _sockets.values) {
      socket.destroy();
    }

    _sockets.clear();
    _connectingIds.clear();
  }

  Future<void> _stopDiscoveryOnly() async {
    final discovery = _discovery;
    _discovery = null;

    if (discovery != null) {
      try {
        await stopDiscovery(discovery);
      } catch (_) {}
    }

    _isScanning = false;
  }

  Future<void> _stopPublishingOnly() async {
    final registration = _registration;
    _registration = null;

    if (registration != null) {
      try {
        await unregister(registration);
      } catch (_) {}
    }

    final server = _server;
    _server = null;

    try {
      await server?.close();
    } catch (_) {}

    _isPublishing = false;
  }

  @override
  void dispose() {
    _shutdown();
    super.dispose();
  }
}
