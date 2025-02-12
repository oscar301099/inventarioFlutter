import 'package:flutter/material.dart';
import '../widgets/button.dart';
import './view_catalog.dart';
import './new_product.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Button(
              text: 'Ver Catálogo',
              onPressed: () {
                print("Botón presionado, navegando a catálogo...");
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ViewCatalog()),
                );
              },
            ),
            const SizedBox(height: 20),
            Button(
              text: 'Añadir Producto al Catálogo',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewProduct()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
