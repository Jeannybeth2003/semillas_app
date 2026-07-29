// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:semillas_app/core/router/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Modo Inmersivo Total
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  // Forzar transparencia
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Semillas de Identidad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      routerConfig: AppRoutes.router,
    );
  }
}
