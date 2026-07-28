import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:semillas_app/core/router/router.dart';
import 'package:semillas_app/core/database/database_helper.dart';
import '../layouts/base_layout.dart';
import '../../widgets/conuco_interactivo.dart';

class VillageScreen extends StatefulWidget {
  final String leaderName;
  final String villageName;

  const VillageScreen({
    super.key,
    this.leaderName = 'Inés',
    this.villageName = 'Semillas',
  });

  @override
  State<VillageScreen> createState() => _VillageScreenState();
}

class _VillageScreenState extends State<VillageScreen> {
  String _liderNombre = 'Cargando...';
  String _liderAldea = 'Cargando...';

  @override
  void initState() {
    super.initState();
    _loadLiderData();
  }

  Future<void> _loadLiderData() async {
    try {
      final lider = await DatabaseHelper.instance.verificarLiderExistente();
      if (!mounted) return;

      if (lider != null) {
        setState(() {
          _liderNombre = lider['nombre'] as String;
          _liderAldea = lider['aldea'] as String;
        });
      } else {
        setState(() {
          _liderNombre = widget.leaderName;
          _liderAldea = widget.villageName;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _liderNombre = widget.leaderName;
        _liderAldea = widget.villageName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BaseLayout(
        backgroundPath: 'assets/images/Conuco_bg.webp',
        child: Stack(
          children: [
            const ConucoInteractivo(),

            Positioned(
              bottom: 20,
              left: 20,
              child: FloatingActionButton(
                backgroundColor: const Color(0xFFD84315),
                onPressed: () => context.go('/'),
                child: const Icon(
                  Icons.home_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),

            Positioned(top: 20, left: 20, child: _buildUserPanel()),

            Positioned(
              top: 20,
              right: 20,
              bottom: 20,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _navBtn(
                    context,
                    Icons.rowing,
                    const Color(0xFF0288D1),
                    AppRoutes.curiaraTravel,
                  ),
                  _navBtn(
                    context,
                    Icons.person_2_sharp,
                    const Color(0xFFD84315),
                    AppRoutes.grandfather,
                  ),
                  _navBtn(
                    context,
                    Icons.menu_book,
                    const Color(0xFF388E3C),
                    AppRoutes.ebook,
                  ),
                  _navBtn(
                    context,
                    Icons.workspace_premium,
                    const Color(0xFFFF8F00),
                    '',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF00695C),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFFC107), width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Color(0xFF00695C)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Líder: $_liderNombre',
                style: const TextStyle(
                  color: Color(0xFFFFC107),
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Aldea: $_liderAldea',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navBtn(
    BuildContext context,
    IconData icon,
    Color color,
    String route,
  ) {
    // Debugging line
    return GestureDetector(
      onTap: () {
        if (route.isNotEmpty) {
          context.push(route);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Funcionalidad en desarrollo')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 5,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 36),
      ),
    );
  }
}
