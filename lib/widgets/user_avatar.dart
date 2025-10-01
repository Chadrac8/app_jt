import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/person_model.dart';
import '../services/profile_image_cache_service.dart';
import '../../theme.dart';

/// Widget réutilisable pour afficher l'avatar d'un utilisateur
/// Ce widget gère automatiquement le fallback vers l'icône par défaut,
/// le cache local et garantit une apparence cohérente dans toute l'application
class UserAvatar extends StatefulWidget {
  final PersonModel? person;
  final double radius;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;

  const UserAvatar({
    Key? key,
    this.person,
    this.radius = 20,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2,
  }) : super(key: key);

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  String? _cachedImageUrl;

  @override
  void initState() {
    super.initState();
    _loadCachedImage();
  }

  @override
  void didUpdateWidget(UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.person?.id != widget.person?.id ||
        oldWidget.person?.profileImageUrl != widget.person?.profileImageUrl) {
      _loadCachedImage();
    }
  }

  Future<void> _loadCachedImage() async {
    if (widget.person?.id != null) {
      final cachedUrl = await ProfileImageCacheService.getCachedProfileImageUrl(widget.person!.id);
      if (mounted && cachedUrl != null) {
        setState(() {
          _cachedImageUrl = cachedUrl;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CircleAvatar(
        radius: widget.radius,
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: widget.showBorder
                ? Border.all(
                    color: widget.borderColor ?? AppTheme.white100,
                    width: widget.borderWidth,
                  )
                : null,
          ),
          child: ClipOval(
            child: _buildAvatarContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent() {
    // Utiliser l'URL du cache en priorité, puis celle du modèle
    final imageUrl = _cachedImageUrl ?? widget.person?.profileImageUrl;
    
    // Si on a une URL d'image de profil valide
    if (imageUrl != null && imageUrl.isNotEmpty) {
      
      // Gestion des images base64 (legacy)
      if (imageUrl.startsWith('data:image')) {
        try {
          final base64String = imageUrl.split(',')[1];
          final bytes = base64Decode(base64String);
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: widget.radius * 2,
            height: widget.radius * 2,
            errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
          );
        } catch (e) {
          return _buildFallbackIcon();
        }
      }
      
      // Gestion des URLs normales (Firebase Storage, etc.)
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: widget.radius * 2,
        height: widget.radius * 2,
        placeholder: (context, url) => _buildLoadingIndicator(),
        errorWidget: (context, url, error) => _buildFallbackIcon(),
        // Mettre en cache automatiquement
        cacheManager: null, // Utilise le cache par défaut
      );
    }
    
    // Fallback vers l'icône par défaut
    return _buildFallbackIcon();
  }

  Widget _buildLoadingIndicator() {
    return Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Center(
        child: SizedBox(
          width: widget.radius * 0.6,
          height: widget.radius * 0.6,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.primaryColor.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: widget.radius * 2,
      height: widget.radius * 2,
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Icon(
        Icons.person,
        size: widget.radius * 1.2,
        color: AppTheme.primaryColor.withOpacity(0.7),
      ),
    );
  }
}

/// Widget spécialisé pour l'avatar dans la navigation
class NavigationUserAvatar extends StatelessWidget {
  final PersonModel? person;
  final VoidCallback? onTap;

  const NavigationUserAvatar({
    Key? key,
    this.person,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.black100.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: UserAvatar(
          person: person,
          radius: 16,
          showBorder: true,
          borderColor: AppTheme.white100,
          borderWidth: 1.5,
        ),
      ),
    );
  }
}

/// Widget spécialisé pour l'avatar de profil (grand format)
class ProfileUserAvatar extends StatelessWidget {
  final PersonModel? person;
  final bool isEditable;
  final VoidCallback? onTap;

  const ProfileUserAvatar({
    Key? key,
    this.person,
    this.isEditable = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEditable ? onTap : null,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.white100, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.black100.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: UserAvatar(
                person: person,
                radius: 56, // 120/2 - 4 (border)
              ),
            ),
          ),
          if (isEditable)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spaceSmall),
                decoration: const BoxDecoration(
                  color: AppTheme.secondaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: 20,
                  color: AppTheme.white100,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
