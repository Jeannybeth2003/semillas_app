class DeviceModel {
  final String id;
  final String name;
  final String host;
  final int port;
  final bool isConnected;
  final bool isController;

  DeviceModel({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    this.isConnected = false,
    this.isController = false,
  });

  DeviceModel copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    bool? isConnected,
    bool? isController,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      isConnected: isConnected ?? this.isConnected,
      isController: isController ?? this.isController,
    );
  }
}