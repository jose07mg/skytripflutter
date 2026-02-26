import 'package:flutter/material.dart';
import '../../shared/widgets/common/menu_lateral.dart';

class VacacionesPage extends StatelessWidget {
  const VacacionesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vacaciones'),
        backgroundColor: Colors.black,
      ),
      drawer: const MenuLateral(),
      body: const Center(
        child: Text(
          'Contenido de la página de Vacaciones',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
