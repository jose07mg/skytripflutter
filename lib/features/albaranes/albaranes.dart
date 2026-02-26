import 'package:flutter/material.dart';
import '../../shared/widgets/common/menu_lateral.dart';

class AlbaranesPage extends StatelessWidget {
  const AlbaranesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Albaranes'),
        backgroundColor: Colors.black,
      ),
      drawer: const MenuLateral(),
      body: const Center(
        child: Text(
          'Contenido de la página de Albaranes',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
