import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/database_helper.dart';
import '../layouts/base_layout.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> with WidgetsBindingObserver {
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = AudioPlayer();
    _playBackgroundMusic();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _audioPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      _audioPlayer.resume();
    }
  }

  void _playBackgroundMusic() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource('audio/GameMusic.ogg'));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startGame() async {
    _audioPlayer.stop();
    
    // Verificamos en la DB si ya existe un líder
    final liderExistente = await DatabaseHelper.instance.verificarLiderExistente();

    if (liderExistente != null) {
      // Si hay lidel vamos directo a la Aldea
      if (!mounted) return;
      context.go('/village/${liderExistente['nombre']}/${liderExistente['aldea']}');
    } else {
      // No hay lidel vamos a la creation_screen
      if (!mounted) return;
      context.go('/creation');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      child: BaseLayout(
        backgroundPath: 'assets/images/Home_bg.webp',
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2), 
                _buildLogo(),
                const SizedBox(height: 15),
                _buildWelcomeBadge(),
                const Spacer(flex: 3), 
                _buildStartButton(),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF00695B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFC107), width: 5),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 10))],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('SEMILLAS DE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFFFC107), letterSpacing: 4)),
          Text('IDENTIDAD', style: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildWelcomeBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFAA00),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Text('¡Bienvenido a la cosecha!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
    );
  }

  Widget _buildStartButton() {
    return GestureDetector(
      onTap: _startGame,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFCA28), Color(0xFFFF8F00)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Color(0xFFB15300), offset: Offset(0, 6))],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow_rounded, color: Colors.white, size: 35),
            SizedBox(width: 10),
            Text('EMPEZAR', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}