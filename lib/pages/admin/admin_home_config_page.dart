import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../theme.dart';
import '../../models/home_config_model.dart';
import '../../services/home_config_service.dart';
import '../../services/image_storage_service.dart';

/// Page d'administration pour configurer l'accueil membre
class AdminHomeConfigPage extends StatefulWidget {
  const AdminHomeConfigPage({super.key});

  @override
  State<AdminHomeConfigPage> createState() => _AdminHomeConfigPageState();
}

class _AdminHomeConfigPageState extends State<AdminHomeConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _coverImageUrlController = TextEditingController();
  final _coverTitleController = TextEditingController();
  final _coverSubtitleController = TextEditingController();
  final _coverVideoUrlController = TextEditingController();
  final _sermonTitleController = TextEditingController();
  final _sermonYouTubeUrlController = TextEditingController();
  final _newImageUrlController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploading = false;
  bool _useVideo = false;
  HomeConfigModel? _currentConfig;
  String? _previewImageUrl;
  
  // Variables pour gérer la liste d'images du carrousel
  List<String> _coverImageUrls = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _coverImageUrlController.dispose();
    _coverTitleController.dispose();
    _coverSubtitleController.dispose();
    _coverVideoUrlController.dispose();
    _sermonTitleController.dispose();
    _sermonYouTubeUrlController.dispose();
    _newImageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentConfig() async {
    setState(() => _isLoading = true);
    try {
      final config = await HomeConfigService.getHomeConfig();
      setState(() {
        _currentConfig = config;
        _coverImageUrlController.text = config.coverImageUrl;
        _coverTitleController.text = config.coverTitle ?? '';
        _coverSubtitleController.text = config.coverSubtitle ?? '';
        _coverVideoUrlController.text = config.coverVideoUrl ?? '';
        _sermonTitleController.text = config.sermonTitle;
        _sermonYouTubeUrlController.text = config.sermonYouTubeUrl ?? '';
        _useVideo = config.useVideo;
        _previewImageUrl = config.coverImageUrl;
        _coverImageUrls = List<String>.from(config.coverImageUrls);
      });
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement de la configuration: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Ajouter une image au carrousel depuis la galerie
  Future<void> _addImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1760,  // Adapté au format d'affichage
        maxHeight: 880,  // Ratio optimal
        imageQuality: 90, // Qualité élevée
      );

      if (image != null) {
        setState(() {
          _isUploading = true;
        });

        // Upload de l'image vers Firebase Storage
        final imageBytes = await File(image.path).readAsBytes();
        final fileName = 'carousel_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        final imageUrl = await ImageStorageService.uploadImage(
          Uint8List.fromList(imageBytes),
          customPath: 'home_covers/carousel/$fileName');

        if (imageUrl != null) {
          setState(() {
            if (!_coverImageUrls.contains(imageUrl)) {
              _coverImageUrls.add(imageUrl);
            }
          });
          _showSuccessSnackBar('Image ajoutée au carrousel');
        } else {
          _showErrorSnackBar('Erreur lors de l\'upload de l\'image');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sélection de l\'image: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// Ajouter une image de couverture unique depuis la galerie
  Future<void> _addCoverImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (image != null) {
        setState(() {
          _isUploading = true;
        });

        // Upload de l'image vers Firebase Storage
        final imageBytes = await File(image.path).readAsBytes();
        final fileName = 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        final imageUrl = await ImageStorageService.uploadImage(
          Uint8List.fromList(imageBytes),
          customPath: 'home_covers/main/$fileName');

        if (imageUrl != null) {
          setState(() {
            _coverImageUrlController.text = imageUrl;
            _previewImageUrl = imageUrl;
          });
          _showSuccessSnackBar('Image de couverture mise à jour');
        } else {
          _showErrorSnackBar('Erreur lors de l\'upload de l\'image');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sélection de l\'image: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// Ajouter une vidéo depuis la galerie
  Future<void> _addVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5), // Limite de 5 minutes
      );

      if (video != null) {
        setState(() {
          _isUploading = true;
        });

        // Upload de la vidéo vers Firebase Storage
        final videoBytes = await File(video.path).readAsBytes();
        final fileName = 'cover_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
        
        final videoUrl = await ImageStorageService.uploadImage(
          Uint8List.fromList(videoBytes),
          customPath: 'home_covers/videos/$fileName');

        if (videoUrl != null) {
          setState(() {
            _coverVideoUrlController.text = videoUrl;
          });
          _showSuccessSnackBar('Vidéo de couverture mise à jour');
        } else {
          _showErrorSnackBar('Erreur lors de l\'upload de la vidéo');
        }
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sélection de la vidéo: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _addImageUrlManually() {
    final url = _newImageUrlController.text.trim();
    if (url.isNotEmpty && !_coverImageUrls.contains(url)) {
      setState(() {
        _coverImageUrls.add(url);
        _newImageUrlController.clear();
      });
    }
  }

  void _removeImageUrl(int index) {
    setState(() {
      _coverImageUrls.removeAt(index);
    });
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _coverImageUrls.removeAt(oldIndex);
      _coverImageUrls.insert(newIndex, item);
    });
  }

  void _previewImage() {
    final url = _coverImageUrlController.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        _previewImageUrl = url;
      });
    }
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Sauvegarder la configuration de couverture
      await HomeConfigService.updateCoverConfig(
        coverImageUrl: _coverImageUrlController.text.trim(),
        coverImageUrls: _coverImageUrls,
        coverVideoUrl: _coverVideoUrlController.text.trim(),
        useVideo: _useVideo,
        coverTitle: _coverTitleController.text.trim(),
        coverSubtitle: _coverSubtitleController.text.trim(),
      );

      // Sauvegarder la configuration de la prédication (Perfect 13 compatibility)
      await HomeConfigService.updateSermonConfig(
        sermonTitle: _sermonTitleController.text.trim(),
        sermonYouTubeUrl: _sermonYouTubeUrlController.text.trim(),
      );

      // Sauvegarder dans l'historique
      await HomeConfigService.saveToHistory('Configuration mise à jour depuis l\'administration');
      
      _showSuccessSnackBar('Configuration sauvegardée avec succès');
      await _loadCurrentConfig();
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sauvegarde: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Accueil Membre'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveConfiguration,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentConfigCard(),
                    const SizedBox(height: 24),
                    _buildCoverConfigurationSection(),
                    const SizedBox(height: 24),
                    _buildTextConfigurationSection(),
                    const SizedBox(height: 24),
                    _buildSermonConfigurationSection(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentConfigCard() {
    if (_currentConfig == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Aucune configuration trouvée'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration actuelle',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_currentConfig!.useVideo)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mode: Vidéo de couverture'),
                  const SizedBox(height: 8),
                  Text('URL: ${_currentConfig!.coverVideoUrl ?? 'Non définie'}'),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mode: Images de couverture'),
                  const SizedBox(height: 8),
                  if (_previewImageUrl != null && _previewImageUrl!.isNotEmpty)
                    Container(
                      height: 100,
                      width: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(_previewImageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            Text('Titre: ${_currentConfig!.coverTitle ?? 'Non défini'}'),
            Text('Sous-titre: ${_currentConfig!.coverSubtitle ?? 'Non défini'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverConfigurationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration de la couverture',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Choix entre image et vidéo
            SwitchListTile(
              title: const Text('Utiliser une vidéo au lieu d\'images'),
              value: _useVideo,
              onChanged: (value) {
                setState(() {
                  _useVideo = value;
                });
              },
            ),
            
            const SizedBox(height: 16),
            
            if (_useVideo) 
              _buildVideoConfiguration()
            else 
              _buildImageConfiguration(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoConfiguration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Configuration vidéo'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _coverVideoUrlController,
          decoration: const InputDecoration(
            labelText: 'URL de la vidéo',
            hintText: 'https://example.com/video.mp4',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (_useVideo && (value == null || value.trim().isEmpty)) {
              return 'Veuillez saisir une URL de vidéo';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _addVideoFromGallery,
              icon: _isUploading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.video_library),
              label: const Text('Choisir depuis la galerie'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageConfiguration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Image de couverture principale'),
        const SizedBox(height: 8),
        TextFormField(
          controller: _coverImageUrlController,
          decoration: InputDecoration(
            labelText: 'URL de l\'image',
            hintText: 'https://example.com/image.jpg',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: _previewImage,
              icon: const Icon(Icons.preview),
            ),
          ),
          validator: (value) {
            if (!_useVideo && (value == null || value.trim().isEmpty)) {
              return 'Veuillez saisir une URL d\'image';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _addCoverImageFromGallery,
              icon: _isUploading 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.photo_library),
              label: const Text('Choisir depuis la galerie'),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Carrousel d'images
        const Text('Carrousel d\'images (optionnel)'),
        const SizedBox(height: 8),
        _buildImageCarouselSection(),
      ],
    );
  }

  Widget _buildImageCarouselSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ajouter une nouvelle image au carrousel
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newImageUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL de l\'image',
                  hintText: 'https://example.com/image.jpg',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addImageUrlManually,
              icon: const Icon(Icons.add),
              tooltip: 'Ajouter l\'URL',
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _isUploading ? null : _addImageFromGallery,
          icon: _isUploading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_photo_alternate),
          label: const Text('Ajouter depuis la galerie'),
        ),
        
        const SizedBox(height: 16),
        
        // Liste des images du carrousel
        if (_coverImageUrls.isNotEmpty) ...[
          const Text('Images du carrousel'),
          const SizedBox(height: 8),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _coverImageUrls.length,
            onReorder: _reorderImages,
            itemBuilder: (context, index) {
              return ListTile(
                key: ValueKey(_coverImageUrls[index]),
                leading: Container(
                  width: 60,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    image: DecorationImage(
                      image: NetworkImage(_coverImageUrls[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                title: Text(
                  _coverImageUrls[index],
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.drag_handle),
                    IconButton(
                      onPressed: () => _removeImageUrl(index),
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildTextConfigurationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Texte de la couverture',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _coverTitleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                hintText: 'Jubilé Tabernacle',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _coverSubtitleController,
              decoration: const InputDecoration(
                labelText: 'Sous-titre',
                hintText: 'Bienvenue dans la maison de Dieu',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSermonConfigurationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configuration de la dernière prédication',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sermonTitleController,
              decoration: const InputDecoration(
                labelText: 'Titre de la prédication',
                hintText: 'La grâce de Dieu',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Veuillez saisir un titre de prédication';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sermonYouTubeUrlController,
              decoration: const InputDecoration(
                labelText: 'URL YouTube',
                hintText: 'https://www.youtube.com/watch?v=...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveConfiguration,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSaving
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 8),
                  Text('Sauvegarde en cours...'),
                ],
              )
            : const Text('Sauvegarder la configuration'),
      ),
    );
  }
}
