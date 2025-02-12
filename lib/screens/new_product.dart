import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../helpers/firebase/firebase_helper.dart';

class NewProduct extends StatefulWidget {
  const NewProduct({Key? key}) : super(key: key);

  @override
  _NewProductState createState() => _NewProductState();
}

class _NewProductState extends State<NewProduct> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController(); 
  final _stockController = TextEditingController();
  final _priceController = TextEditingController();
  List<File> _images = [];  
  final ImagePicker _picker = ImagePicker();

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
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  Future<List<String>> _imagesToBase64(List<File> images) async {
    List<String> base64Images = [];
    for (var image in images) {
      List<int> imageBytes = await image.readAsBytes();
      base64Images.add(base64Encode(imageBytes));
    }
    return base64Images;
  }

  Future<void> _saveProduct(BuildContext context) async {
    if (_nameController.text.isEmpty ||
        _stockController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _descriptionController.text.isEmpty) {  
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos requeridos')),
      );
      return;
    }

    final stock = int.tryParse(_stockController.text);
    final price = double.tryParse(_priceController.text);

    if (stock == null || stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un stock válido')),
      );
      return;
    }

    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un precio válido')),
      );
      return;
    }

    try {
      final productData = {
        'name': _nameController.text,
        'description': _descriptionController.text, 
        'stock': stock,
        'price': price,
      };

      final productId = await FirebaseHelper.instance.insertProduct(productData);

      if (_images.isNotEmpty) {
        final base64Images = await _imagesToBase64(_images);
        for (var base64Image in base64Images) {
          final imageData = {
            'idProduct': productId, 
            'img': base64Image,
          };
          await FirebaseHelper.instance.insertImage(imageData);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto guardado exitosamente')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el producto: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Nuevo Producto'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: _showImageSourceDialog,  
                child: const Text('Tomar Foto(s)'),
              ),
              const SizedBox(height: 20),
              if (_images.isNotEmpty)
                Wrap(
                  children: _images.map((image) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.file(
                        image,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del producto',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,  
                decoration: const InputDecoration(
                  labelText: 'Descripción del producto',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Precio',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _saveProduct(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Guardar Producto'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
