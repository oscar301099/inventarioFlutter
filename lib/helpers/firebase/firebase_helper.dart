import 'package:firebase_database/firebase_database.dart';

class FirebaseHelper {
  static final FirebaseHelper instance = FirebaseHelper._();

  FirebaseHelper._();

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  Future<String> insertProduct(Map<String, dynamic> product) async {
    final newProductRef = _database.ref('products').push();
    await newProductRef.set(product);
    return newProductRef.key!; 
  }

  Future<void> insertImage(Map<String, dynamic> imageData) async {
    try {
      await _database.ref('images').push().set(imageData);
    } catch (e) {
      throw Exception('Error al guardar imagen: $e');
    }
  }
}
