import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/card.dart';

class ViewCatalog extends StatefulWidget {
  const ViewCatalog({Key? key}) : super(key: key);

  @override
  _ViewCatalogState createState() => _ViewCatalogState();
}

class _ViewCatalogState extends State<ViewCatalog> {
  late Future<List<Map<String, dynamic>>> _products;

  @override
  void initState() {
    super.initState();
    _fetchProducts(); 
  }

  Future<List<String>> _getImageUrlsForProduct(String productId) async {
    List<String> imageUrls = [];

    try {
      final imagesRef = FirebaseDatabase.instance.ref('images');
      final snapshot = await imagesRef.orderByChild('idProduct').equalTo(productId).get();

      if (snapshot.exists) {
        snapshot.children.forEach((imageSnap) {
          final imageData = imageSnap.value as Map;
          final base64Image = imageData['img'];
          imageUrls.add(base64Image);
        });
      }
    } catch (e) {
      print('Error obteniendo imágenes: $e');
    }

    return imageUrls;
  }

  Future<List<Map<String, dynamic>>> _getProductsFromDatabase() async {
    final productsRef = FirebaseDatabase.instance.ref('products');
    final snapshot = await productsRef.get();

    List<Map<String, dynamic>> products = [];

    if (snapshot.exists) {
      for (var productSnap in snapshot.children) {
        final productData = productSnap.value as Map;
        final productId = productSnap.key!;

        // Obtener las imágenes de forma asíncrona
        final imageUrls = await _getImageUrlsForProduct(productId);

        // Agregar los datos del producto
        products.add({
          'id': productId,
          'name': productData['name'],
          'price': (productData['price'] is int)
              ? (productData['price'] as int).toDouble()
              : productData['price'],
          'stock': productData['stock'],
          'description': productData['description']?.toString() ?? 'No hay descripción',
          'imageUrls': imageUrls,
        });
      }
    }

    return products;
  }

  void _fetchProducts() {
    setState(() {
      _products = _getProductsFromDatabase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _products,
        builder: (context, snapshot) {
          // Mostrar un indicador de carga mientras se obtienen los datos
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Mostrar mensaje si no hay productos disponibles
            return const Center(child: Text('No hay productos disponibles.'));
          } else {
            final products = snapshot.data!;
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                final imageUrls = List<String>.from(product['imageUrls']);

                return CustomCard(
                  id: product['id'] as String,
                  title: product['name'] as String,
                  description: product['description'] as String? ?? 'No hay descripción',
                  stock: product['stock'] as int,
                  price: product['price'] as double,
                  childImage: SizedBox(
                    height: 200,
                    child: PageView.builder(
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FullscreenCarousel(
                                  images: imageUrls,
                                  initialIndex: index,
                                ),
                              ),
                            );
                          },
                          child: Image.memory(
                            base64Decode(imageUrls[index]),
                            width: double.infinity,
                            height: 200.0,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class FullscreenCarousel extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const FullscreenCarousel({
    Key? key,
    required this.images,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: PageController(initialPage: initialIndex),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Center(
            child: Image.memory(
              base64Decode(images[index]),
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }
}
