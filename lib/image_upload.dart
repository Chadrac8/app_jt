import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Service pour uploader des images vers Firebase Storage
class ImageUploadService {
  /// Upload une image vers Firebase Storage
  /// 
  /// [file] : Le fichier image à uploader
  /// [path] : Le chemin de destination dans Firebase Storage
  /// 
  /// Retourne l'URL de téléchargement de l'image uploadée
  static Future<String> uploadImage(File file, String path) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child(path);
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Erreur lors de l\'upload de l\'image: $e');
    }
  }

  /// Supprime une image de Firebase Storage
  /// 
  /// [imageUrl] : L'URL de l'image à supprimer
  static Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'image: $e');
    }
  }
}

/// Helper pour sélectionner et capturer des images
class ImageUploadHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Sélectionner une image depuis la galerie
  static Future<Uint8List?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        return await image.readAsBytes();
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la sélection de l\'image: $e');
    }
  }

  /// Capturer une image avec la caméra
  static Future<Uint8List?> captureImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        return await image.readAsBytes();
      }
      return null;
    } catch (e) {
      throw Exception('Erreur lors de la capture de l\'image: $e');
    }
  }
}
