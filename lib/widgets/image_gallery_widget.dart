import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/image_storage_service.dart';
import '../../theme.dart';

class ImageGalleryWidget extends StatefulWidget {
  final Function(String) onImageSelected;
  final String? selectedImageUrl;

  const ImageGalleryWidget({
    super.key,
    required this.onImageSelected,
    this.selectedImageUrl,
  });

  @override
  State<ImageGalleryWidget> createState() => _ImageGalleryWidgetState();
}

class _ImageGalleryWidgetState extends State<ImageGalleryWidget> {
  List<String> _userImages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserImages();
  }

  Future<void> _loadUserImages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final images = await ImageStorageService.listUserImages();
      setState(() {
        _userImages = images;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteImage(String imageUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'image'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette image ? '
          'Cette action est irréversible et l\'image sera supprimée '
          'de tous les composants où elle est utilisée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.redStandard,
              foregroundColor: AppTheme.white100,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ImageStorageService.deleteImageByUrl(imageUrl);
      if (success) {
        setState(() {
          _userImages.remove(imageUrl);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image supprimée avec succès'),
              backgroundColor: AppTheme.greenStandard,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la suppression'),
              backgroundColor: AppTheme.redStandard,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête avec bouton de rafraîchissement
        Row(
          children: [
            Text(
              'Mes images (${_userImages.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTheme.fontBold,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _loadUserImages,
              icon: const Icon(Icons.refresh),
              tooltip: 'Actualiser',
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Contenu principal
        SizedBox(
          height: 400,
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement de vos images...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: AppTheme.redStandard),
            const SizedBox(height: 16),
            Text(
              'Erreur: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.redStandard),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserImages,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_userImages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: AppTheme.grey400,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune image trouvée',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.grey600,
                fontWeight: AppTheme.fontMedium,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Uploadez des images depuis l\'onglet précédent',
              style: TextStyle(
                color: AppTheme.grey500,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: _userImages.length,
      itemBuilder: (context, index) {
        final imageUrl = _userImages[index];
        final isSelected = imageUrl == widget.selectedImageUrl;

        return GestureDetector(
          onTap: () => widget.onImageSelected(imageUrl),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: Border.all(
                color: isSelected 
                    ? AppTheme.primaryColor 
                    : AppTheme.grey300!,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: Stack(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (context, url) => Container(
                      color: AppTheme.grey200,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.grey200,
                      child: const Center(
                        child: Icon(Icons.error, color: AppTheme.grey500),
                      ),
                    ),
                  ),
                ),

                // Overlay de sélection
                if (isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle,
                          color: AppTheme.white100,
                          size: 32,
                        ),
                      ),
                    ),
                  ),

                // Bouton de suppression
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.black100,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => _deleteImage(imageUrl),
                      icon: const Icon(
                        Icons.delete,
                        color: AppTheme.white100,
                        size: 16,
                      ),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}