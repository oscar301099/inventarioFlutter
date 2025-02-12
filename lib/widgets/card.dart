import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../screens/edit_product.dart';
import '../helpers/database/database_helper.dart';

class CustomCard extends StatelessWidget {
  final String? imagePath; 
  final String title;
  final String description;
  final int stock;
  final String id;
  final double price;
  final Widget? childImage; 

  CustomCard({
    this.imagePath,
    required this.title,
    required this.description,
    required this.stock,
    required this.id, 
    required this.price,
    this.childImage,
  });

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content:
            const Text('¿Estás seguro de que deseas eliminar este producto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _deleteProduct(context);
    }
  }

  Future<void> _deleteProduct(BuildContext context) async {
    try {
      await _deleteImagesForProduct(id);
      final productRef = FirebaseDatabase.instance.ref('products/$id');
      await productRef.remove();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Producto "$title" y sus imágenes eliminados.')),
      );
      Navigator.pop(context); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

  Future<void> _deleteImagesForProduct(String productId) async {
    try {
      final imagesRef = FirebaseDatabase.instance.ref('images');
      final snapshot =
          await imagesRef.orderByChild('idProduct').equalTo(productId).get();

      if (snapshot.exists) {
        snapshot.children.forEach((imageSnap) {
          final imageKey = imageSnap.key; 
          imagesRef.child(imageKey!).remove(); 
        });
      }
    } catch (e) {
      print('Error al eliminar imágenes: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      margin: const EdgeInsets.all(10.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10.0),
              topRight: Radius.circular(10.0),
            ),
            child: childImage ??
                (imagePath != null && imagePath!.isNotEmpty
                    ? Image.file(
                        File(imagePath!), 
                        width: double.infinity,
                        height: 150.0,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 150.0,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image,
                          color: Colors.grey,
                        ),
                      )),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text(
                  description,
                  style: TextStyle(fontSize: 14.0, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Stock: $stock',
                  style: const TextStyle(
                      fontSize: 14.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'Price: \$${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 14.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProductScreen(
                              id: id,
                              currentTitle: title,
                              currentDescription: description,
                              currentStock: stock,
                              currentPrice: price, 
                              currentImagePath:
                                  imagePath, 
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                    ),
                    const SizedBox(width: 8.0),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => _showDeleteConfirmationDialog(context),
                      icon: const Icon(Icons.delete),
                      label: const Text('Eliminar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
