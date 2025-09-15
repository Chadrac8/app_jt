import 'package:flutter/material.dart';
import '../services/roles_firebase_service.dart';
import '../image_upload.dart';
import '../services/image_storage_service.dart' as ImageStorage;
import '../auth/auth_service.dart';

/// Widget d'amélioration des performances pour gérer le lazy loading des rôles
class LazyRoleChipsList extends StatefulWidget {
  final List<String> roleIds;
  final Function(String) onRoleRemoved;
  
  const LazyRoleChipsList({
    super.key,
    required this.roleIds,
    required this.onRoleRemoved,
  });

  @override
  State<LazyRoleChipsList> createState() => _LazyRoleChipsListState();
}

class _LazyRoleChipsListState extends State<LazyRoleChipsList> {
  final Map<String, Widget> _cachedChips = {};
  
  @override
  Widget build(BuildContext context) {
    if (widget.roleIds.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: widget.roleIds.map((roleId) {
        // Utiliser le cache si disponible
        if (_cachedChips.containsKey(roleId)) {
          return _cachedChips[roleId]!;
        }
        
        // Créer et mettre en cache le chip
        final chip = FutureBuilder<Widget>(
          future: _buildRoleChip(roleId),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _cachedChips[roleId] = snapshot.data!;
              return snapshot.data!;
            }
            
            // Widget placeholder pendant le chargement
            return Chip(
              label: SizedBox(
                width: 80,
                height: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            );
          },
        );
        
        return chip;
      }).toList(),
    );
  }
  
  Future<Widget> _buildRoleChip(String roleId) async {
    try {
      final role = await RolesFirebaseService.getRole(roleId);
      
      if (role == null) {
        return _buildErrorChip(roleId);
      }
      
      return Chip(
        avatar: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Color(int.parse(role.color.replaceFirst('#', '0xFF'))),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getIconData(role.icon),
            color: Colors.white,
            size: 12,
          ),
        ),
        label: Text(
          role.name,
          style: const TextStyle(fontSize: 12),
        ),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: () => widget.onRoleRemoved(roleId),
      );
    } catch (e) {
      return _buildErrorChip(roleId);
    }
  }
  
  Widget _buildErrorChip(String roleId) {
    return Chip(
      avatar: const Icon(Icons.error, size: 16, color: Colors.red),
      label: const Text('Erreur', style: TextStyle(fontSize: 12)),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: () => widget.onRoleRemoved(roleId),
    );
  }
  
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'security': return Icons.security;
      case 'admin_panel_settings': return Icons.admin_panel_settings;
      case 'church': return Icons.church;
      case 'supervisor_account': return Icons.supervisor_account;
      case 'person': return Icons.person;
      case 'people': return Icons.people;
      case 'group': return Icons.group;
      case 'groups': return Icons.groups;
      case 'event': return Icons.event;
      case 'assignment': return Icons.assignment;
      case 'description': return Icons.description;
      case 'work': return Icons.work;
      case 'school': return Icons.school;
      case 'volunteer_activism': return Icons.volunteer_activism;
      case 'manage_accounts': return Icons.manage_accounts;
      case 'psychology': return Icons.psychology;
      case 'music_note': return Icons.music_note;
      case 'mic': return Icons.mic;
      case 'campaign': return Icons.campaign;
      case 'handshake': return Icons.handshake;
      default: return Icons.security;
    }
  }
}

/// Widget optimisé pour la sélection d'image avec preview et loading states
class OptimizedImagePicker extends StatefulWidget {
  final String? currentImageUrl;
  final Function(String?) onImageChanged;
  final bool isLoading;
  
  const OptimizedImagePicker({
    super.key,
    this.currentImageUrl,
    required this.onImageChanged,
    this.isLoading = false,
  });

  @override
  State<OptimizedImagePicker> createState() => _OptimizedImagePickerState();
}

class _OptimizedImagePickerState extends State<OptimizedImagePicker> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        onTapCancel: () => _animationController.reverse(),
        onTap: widget.isLoading ? null : _pickImage,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _buildImageContent(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildImageContent() {
    if (widget.isLoading) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    
    if (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty) {
      return Image.network(
        widget.currentImageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Theme.of(context).colorScheme.surface,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(hasError: true);
        },
      );
    }
    
    return _buildPlaceholder();
  }
  
  Widget _buildPlaceholder({bool hasError = false}) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasError ? Icons.error : Icons.camera_alt,
            size: 32,
            color: hasError 
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            hasError ? 'Erreur' : 'Ajouter photo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: hasError 
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Future<void> _pickImage() async {
    try {
      final imageBytes = await ImageUploadHelper.pickImageFromGallery();
      if (imageBytes != null) {
        final currentUser = AuthService.currentUser;
        if (currentUser == null) {
          throw Exception('Utilisateur non connecté');
        }
        
        final imageUrl = await ImageStorage.ImageStorageService.uploadImage(
          imageBytes,
          customPath: 'profiles/${currentUser.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        
        if (imageUrl != null) {
          widget.onImageChanged(imageUrl);
        } else {
          throw Exception('Échec de l\'upload de l\'image');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

/// Widget de formulaire responsive avec animations fluides
class ResponsiveFormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final IconData? icon;
  final bool isExpanded;
  final VoidCallback? onToggle;
  
  const ResponsiveFormSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
    this.isExpanded = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8 : 16,
        vertical: 8,
      ),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  if (onToggle != null)
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}