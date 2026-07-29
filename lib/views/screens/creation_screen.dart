import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/database_helper.dart';
import '../layouts/base_layout.dart';

class CreationScreen extends StatefulWidget {
  const CreationScreen({super.key});

  @override
  State<CreationScreen> createState() => _CreationScreenState();
}

class _CreationScreenState extends State<CreationScreen> {
  final TextEditingController _leaderController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      // Guardamos los datos en la bd
      await DatabaseHelper.instance.crearNuevoLider(
        _leaderController.text, 
        _villageController.text
      );

      // Vamos a la aldea pasando los datos
      if (!mounted) return;
      context.go('/village/${_leaderController.text}/${_villageController.text}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeLeft: true,
      removeRight: true,
      child: BaseLayout(
        backgroundPath: 'assets/images/Conuco_bg.webp',
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: true, 
          body: Stack(
            children: [
              Positioned(
                top: 20,
                left: 20,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 35),
                  onPressed: () => context.go('/'),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: 450,
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00695C).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: const Color(0xFFFFC107), width: 4),
                      boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('REGISTRO', style: TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 15),
                          _buildField(_leaderController, 'Nombre del Líder', Icons.person),
                          const SizedBox(height: 15),
                          _buildField(_villageController, 'Nombre de la Aldea', Icons.home_work),
                          const SizedBox(height: 25),
                          _buildBtn(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.amber, size: 22),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 14),
        filled: true,
        fillColor: Colors.black26,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        errorStyle: const TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
    );
  }

  Widget _buildBtn() {
    return ElevatedButton(
      onPressed: _submit,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.amber,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: const Text('COMENZAR', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}