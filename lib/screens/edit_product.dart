import 'package:flutter/material.dart';
import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import '../screens/view_catalog.dart';
import 'dart:convert';

class EditProductScreen extends StatefulWidget {
  final String id;
  final String currentTitle;
  final String currentDescription;
  final int currentStock;
  final double currentPrice;
  final String? currentImagePath;

  EditProductScreen({
    required this.id,
    required this.currentTitle,
    required this.currentDescription,
    required this.currentStock,
    required this.currentPrice,
    this.currentImagePath,
  });

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late String title;
  late String description;
  late int stock;
  late double price;
  List<Map<String, dynamic>> _images = [];
  final ImagePicker _picker = ImagePicker();
  File? _newImage;

  @override
  void initState() {
    super.initState();
    title = widget.currentTitle;
    description = widget.currentDescription;
    stock = widget.currentStock;
    price = widget.currentPrice;

    _fetchImages(); 
  }

  Future<void> _fetchImages() async {
    final imagesRef = FirebaseDatabase.instance.ref('images');
    final snapshot = await imagesRef.orderByChild('idProduct').equalTo(widget.id).get();

    if (snapshot.exists) {
      setState(() {
        _images = snapshot.children.map((imageSnap) {
          final imageData = imageSnap.value as Map;
          return {'key': imageSnap.key, 'img': imageData['img']};
        }).toList();
      });
    }
  }

  Future<void> _deleteImage(String key) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmación de eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar esta imagen?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final imagesRef = FirebaseDatabase.instance.ref('images/$key');
                await imagesRef.remove();

                setState(() {
                  _images.removeWhere((image) => image['key'] == key);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Imagen eliminada.')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al eliminar la imagen: $e')),
                );
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final productRef = FirebaseDatabase.instance.ref('products/${widget.id}');
    await productRef.update({
      'name': title,
      'description': description,
      'stock': stock,
      'price': price,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Producto actualizado.')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ViewCatalog()),
    );
  }

  Future<void> _showImageSourceDialog() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selecciona una fuente de imagen'),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              _pickImage(ImageSource.camera); 
            },
            child: const Text('Tomar foto'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); 
              _pickImage(ImageSource.gallery); 
            },
            child: const Text('Seleccionar de la galería'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      try {
        final imagesRef = FirebaseDatabase.instance.ref('images');
        final newImageRef = imagesRef.push();
        await newImageRef.set({
          'idProduct': widget.id,
          'img': base64Image,
        });

        setState(() {
          _images.add({'key': newImageRef.key, 'img': base64Image});
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen añadida.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al añadir la imagen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Producto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Imágenes del producto',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _images.isEmpty
                  ? const Text('No hay imágenes disponibles.')
                  : Wrap(
                      spacing: 8.0,
                      children: _images.map((image) {
                        return Stack(
                          children: [
                            Image.memory(
                              base64Decode(image['img']),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _deleteImage(image['key']),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _showImageSourceDialog, 
                child: const Text('Añadir Foto'),
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: title,
                decoration: const InputDecoration(labelText: 'Título'),
                onSaved: (value) => title = value!,
                validator: (value) => value!.isEmpty ? 'El título no puede estar vacío' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: description,
                decoration: const InputDecoration(labelText: 'Descripción'),
                onSaved: (value) => description = value!,
                validator: (value) =>
                    value!.isEmpty ? 'La descripción no puede estar vacía' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: stock.toString(),
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                onSaved: (value) => stock = int.parse(value!),
                validator: (value) =>
                    int.tryParse(value!) == null ? 'El stock debe ser un número válido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                initialValue: price.toStringAsFixed(2),
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: TextInputType.number,
                onSaved: (value) => price = double.parse(value!),
                validator: (value) =>
                    double.tryParse(value!) == null ? 'El precio debe ser un número válido' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _saveChanges(context),
                child: const Text('Guardar Cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
