import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../../../theme.dart';

/// Helpers pour la personnalisation avancée des actions
class ActionCustomizationHelpers {
  
  /// Upload une image vers Firebase Storage et retourne l'URL publique
  static Future<String?> uploadImageToStorage(String localPath, String actionId) async {
    try {
      final file = File(localPath.replaceFirst('file://', ''));
      if (!await file.exists()) {
        print('❌ File does not exist: $localPath');
        return null;
      }
      
      // Créer un nom unique pour le fichier
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = path.extension(localPath);
      final fileName = 'action_${actionId}_$timestamp$ext';
      
      // Upload vers Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('actions_backgrounds')
          .child(fileName);
      
      print('⬆️ Uploading image to Firebase Storage...');
      final uploadTask = await storageRef.putFile(file);
      
      // Récupérer l'URL publique
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      print('✅ Image uploaded successfully: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }
  
  /// Liste complète des icônes disponibles avec catégories
  static final List<Map<String, dynamic>> availableIcons = [
    // Icônes religieuses et spirituelles
    {'name': 'church', 'icon': Icons.church, 'label': 'Église'},
    {'name': 'volunteer_activism_rounded', 'icon': Icons.volunteer_activism_rounded, 'label': 'Mains en prière'},
    {'name': 'favorite_rounded', 'icon': Icons.favorite_rounded, 'label': 'Cœur / Amour'},
    {'name': 'auto_stories', 'icon': Icons.auto_stories, 'label': 'Bible / Écritures'},
    {'name': 'menu_book_rounded', 'icon': Icons.menu_book_rounded, 'label': 'Livre / Lecture'},
    {'name': 'campaign', 'icon': Icons.campaign, 'label': 'Annonce / Proclamation'},
    {'name': 'celebration', 'icon': Icons.celebration, 'label': 'Célébration'},
    
    // Icônes de communauté et groupes
    {'name': 'group', 'icon': Icons.group, 'label': 'Groupe de personnes'},
    {'name': 'groups', 'icon': Icons.groups, 'label': 'Communauté'},
    {'name': 'people', 'icon': Icons.people, 'label': 'Assemblée'},
    {'name': 'family_restroom', 'icon': Icons.family_restroom, 'label': 'Famille'},
    {'name': 'diversity_3', 'icon': Icons.diversity_3, 'label': 'Diversité'},
    {'name': 'handshake', 'icon': Icons.handshake, 'label': 'Partenariat'},
    
    // Icônes de calendrier et événements
    {'name': 'calendar_today', 'icon': Icons.calendar_today, 'label': 'Calendrier'},
    {'name': 'event', 'icon': Icons.event, 'label': 'Événement'},
    {'name': 'schedule', 'icon': Icons.schedule, 'label': 'Horaire'},
    {'name': 'date_range', 'icon': Icons.date_range, 'label': 'Période'},
    {'name': 'event_available', 'icon': Icons.event_available, 'label': 'Événement disponible'},
    {'name': 'today', 'icon': Icons.today, 'label': 'Aujourd\'hui'},
    
    // Icônes de communication
    {'name': 'mail', 'icon': Icons.mail, 'label': 'Enveloppe / Email'},
    {'name': 'email', 'icon': Icons.email, 'label': 'Email'},
    {'name': 'message', 'icon': Icons.message, 'label': 'Message'},
    {'name': 'phone', 'icon': Icons.phone, 'label': 'Téléphone'},
    {'name': 'contact_phone', 'icon': Icons.contact_phone, 'label': 'Contact'},
    {'name': 'forum', 'icon': Icons.forum, 'label': 'Discussion'},
    {'name': 'chat', 'icon': Icons.chat, 'label': 'Chat'},
    
    // Icônes de musique et louange
    {'name': 'music_note', 'icon': Icons.music_note, 'label': 'Note de musique'},
    {'name': 'library_music', 'icon': Icons.library_music, 'label': 'Bibliothèque musicale'},
    {'name': 'queue_music', 'icon': Icons.queue_music, 'label': 'Playlist'},
    {'name': 'mic', 'icon': Icons.mic, 'label': 'Microphone'},
    {'name': 'piano', 'icon': Icons.piano, 'label': 'Piano'},
    {'name': 'audiotrack', 'icon': Icons.audiotrack, 'label': 'Piste audio'},
    
    // Icônes de dons et finances
    {'name': 'card_giftcard_rounded', 'icon': Icons.card_giftcard_rounded, 'label': 'Don / Cadeau'},
    {'name': 'volunteer_activism', 'icon': Icons.volunteer_activism, 'label': 'Bénévolat'},
    {'name': 'monetization_on', 'icon': Icons.monetization_on, 'label': 'Finances'},
    {'name': 'account_balance_wallet', 'icon': Icons.account_balance_wallet, 'label': 'Portefeuille'},
    {'name': 'savings', 'icon': Icons.savings, 'label': 'Épargne / Trésor'},
    
    // Icônes de localisation
    {'name': 'location_on', 'icon': Icons.location_on, 'label': 'Localisation'},
    {'name': 'place', 'icon': Icons.place, 'label': 'Lieu'},
    {'name': 'map', 'icon': Icons.map, 'label': 'Carte'},
    {'name': 'directions', 'icon': Icons.directions, 'label': 'Directions'},
    {'name': 'home', 'icon': Icons.home, 'label': 'Maison'},
    
    // Icônes d'éducation et formation
    {'name': 'school', 'icon': Icons.school, 'label': 'École / Formation'},
    {'name': 'book', 'icon': Icons.book, 'label': 'Livre d\'enseignement'},
    {'name': 'quiz', 'icon': Icons.quiz, 'label': 'Questions / Quiz'},
    {'name': 'psychology', 'icon': Icons.psychology, 'label': 'Réflexion'},
    {'name': 'lightbulb', 'icon': Icons.lightbulb, 'label': 'Idée / Inspiration'},
    
    // Icônes de service et ministère
    {'name': 'work', 'icon': Icons.work, 'label': 'Service / Travail'},
    {'name': 'build', 'icon': Icons.build, 'label': 'Construction / Édification'},
    {'name': 'engineering', 'icon': Icons.engineering, 'label': 'Ingénierie / Compétences'},
    {'name': 'cleaning_services', 'icon': Icons.cleaning_services, 'label': 'Services de nettoyage'},
    {'name': 'restaurant', 'icon': Icons.restaurant, 'label': 'Restauration'},
    {'name': 'local_dining', 'icon': Icons.local_dining, 'label': 'Repas communautaire'},
    
    // Icônes diverses utiles
    {'name': 'info', 'icon': Icons.info, 'label': 'Information'},
    {'name': 'help', 'icon': Icons.help, 'label': 'Aide'},
    {'name': 'support', 'icon': Icons.support, 'label': 'Support'},
    {'name': 'star', 'icon': Icons.star, 'label': 'Étoile / Favori'},
    {'name': 'diamond', 'icon': Icons.diamond, 'label': 'Diamant / Précieux'},
    {'name': 'emoji_events', 'icon': Icons.emoji_events, 'label': 'Événement spécial'},
    {'name': 'card_membership', 'icon': Icons.card_membership, 'label': 'Membre / Adhésion'},
    {'name': 'badge', 'icon': Icons.badge, 'label': 'Badge / Identification'},
    
    // Icônes par défaut
    {'name': 'help_outline', 'icon': Icons.help_outline, 'label': 'Aide (contour)'},
  ];

  /// Palette de couleurs disponibles
  static final List<Map<String, dynamic>> availableColors = [
    {'name': 'Rouge', 'color': 0xFFE57373},
    {'name': 'Vert', 'color': 0xFF81C784},
    {'name': 'Bleu', 'color': 0xFF64B5F6},
    {'name': 'Violet', 'color': 0xFFBA68C8},
    {'name': 'Orange', 'color': 0xFFFFB74D},
    {'name': 'Rose', 'color': 0xFFF06292},
    {'name': 'Cyan', 'color': 0xFF4DD0E1},
    {'name': 'Lime', 'color': 0xFFAED581},
    {'name': 'Doré', 'color': 0xFFFFE0B2},
    {'name': 'Blanc', 'color': 0xFFFFFFFF},
    {'name': 'Gris clair', 'color': 0xFFEEEEEE},
  ];

  /// Convertir nom d'icône en IconData
  static IconData getIconData(String iconName) {
    final iconData = availableIcons.firstWhere(
      (icon) => icon['name'] == iconName,
      orElse: () => {'icon': Icons.help_outline},
    );
    return iconData['icon'] as IconData;
  }

  /// Obtenir le nom de l'icône depuis IconData
  static String getIconName(IconData icon) {
    final iconData = availableIcons.firstWhere(
      (item) => (item['icon'] as IconData).codePoint == icon.codePoint,
      orElse: () => {'name': 'help_outline'},
    );
    return iconData['name'] as String;
  }

  /// Créer un ImageProvider depuis une URL
  static ImageProvider getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('file://')) {
      final filePath = imageUrl.substring(7);
      return FileImage(File(filePath));
    } else {
      return NetworkImage(imageUrl);
    }
  }

  /// Widget de sélection de couleur
  static Widget buildColorSelector(
    String title,
    int? selectedColor,
    List<Map<String, dynamic>> colors,
    Function(int?) onColorSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((colorData) {
            final colorValue = colorData['color'] as int?;
            final isSelected = selectedColor == colorValue;
            final isAuto = colorValue == null;

            return GestureDetector(
              onTap: () => onColorSelected(colorValue),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isAuto
                      ? const Color(0xFF424242)
                      : Color(colorValue),
                  borderRadius: BorderRadius.circular(18),
                  border: isSelected
                      ? Border.all(color: AppTheme.primaryColor, width: 2.5)
                      : (colorValue == 0xFFFFFFFF ||
                              colorValue == 0xFFEEEEEE)
                          ? Border.all(
                              color: AppTheme.grey400, width: 1)
                          : null,
                ),
                child: isAuto
                    ? const Icon(Icons.auto_mode,
                        color: Colors.white, size: 16)
                    : isSelected &&
                            (colorValue == 0xFFFFFFFF ||
                                colorValue == 0xFFEEEEEE)
                        ? const Icon(Icons.check,
                            color: Colors.black, size: 14)
                        : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Widget de sélection d'arrière-plan (couleur ou image)
  static Widget buildBackgroundSelector(
    BuildContext context,
    String? selectedImageUrl,
    int selectedColor,
    List<Map<String, dynamic>> colors,
    Function(String?) onImageSelected,
    Function(int?) onColorSelected,
    Function(Function(String?)) showImagePicker,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Arrière-plan',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        
        // Toggle Couleur/Image
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onImageSelected(null),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: selectedImageUrl == null
                        ? AppTheme.primaryColor
                        : const Color(0xFF424242),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedImageUrl == null
                          ? AppTheme.primaryColor
                          : AppTheme.grey600,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.palette,
                        color: selectedImageUrl == null
                            ? Colors.white
                            : AppTheme.grey400,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Couleur',
                        style: GoogleFonts.poppins(
                          color: selectedImageUrl == null
                              ? Colors.white
                              : AppTheme.grey400,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => showImagePicker(onImageSelected),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: selectedImageUrl != null
                        ? AppTheme.primaryColor
                        : const Color(0xFF424242),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedImageUrl != null
                          ? AppTheme.primaryColor
                          : AppTheme.grey600,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        color: selectedImageUrl != null
                            ? Colors.white
                            : AppTheme.grey400,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Image',
                        style: GoogleFonts.poppins(
                          color: selectedImageUrl != null
                              ? Colors.white
                              : AppTheme.grey400,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Affichage conditionnel
        if (selectedImageUrl == null)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: colors.map((colorData) {
              final colorValue = colorData['color'] as int?;
              final isSelected = selectedColor == colorValue;

              return GestureDetector(
                onTap: () => onColorSelected(colorValue),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Color(colorValue ?? 0xFF9E9E9E),
                    borderRadius: BorderRadius.circular(18),
                    border: isSelected
                        ? Border.all(
                            color: AppTheme.primaryColor, width: 2.5)
                        : (colorValue == 0xFFFFFFFF ||
                                colorValue == 0xFFEEEEEE)
                            ? Border.all(
                                color: AppTheme.grey400, width: 1)
                            : null,
                  ),
                  child: isSelected &&
                          (colorValue == 0xFFFFFFFF ||
                              colorValue == 0xFFEEEEEE)
                      ? const Icon(Icons.check,
                          color: Colors.black, size: 14)
                      : null,
                ),
              );
            }).toList(),
          )
        else
          Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: getImageProvider(selectedImageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => onImageSelected(null),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Widget de prévisualisation de l'action
  static Widget buildActionPreview(
    String title,
    String iconName,
    int backgroundColor,
    int? iconColor,
    int? textColor,
    String? backgroundImage,
    bool showIcon,
  ) {
    final bgColor = Color(backgroundColor);

    // Calcul automatique des couleurs si non spécifiées
    Color finalIconColor;
    Color finalTextColor;

    if (iconColor != null) {
      finalIconColor = Color(iconColor);
    } else {
      final luminance = bgColor.computeLuminance();
      finalIconColor = luminance > 0.5 ? Colors.black : Colors.white;
    }

    if (textColor != null) {
      finalTextColor = Color(textColor);
    } else {
      final luminance = bgColor.computeLuminance();
      finalTextColor = luminance > 0.5 ? Colors.black : Colors.white;
    }

    return Container(
      width: 150,
      height: 100,
      decoration: BoxDecoration(
        color: backgroundImage == null ? bgColor : null,
        image: backgroundImage != null
            ? DecorationImage(
                image: getImageProvider(backgroundImage),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {},
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showIcon) ...[
            Icon(
              getIconData(iconName),
              color: finalIconColor,
              size: 24,
            ),
            const SizedBox(height: 8),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                color: finalTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Dialogue de sélection d'image
  static void showImagePicker(
    BuildContext context,
    Function(String?) onImageSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(
          'Choisir une image',
          style: GoogleFonts.poppins(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library,
                  color: AppTheme.primaryColor),
              title: Text('Galerie',
                  style: GoogleFonts.poppins(
                      color: AppTheme.textPrimaryColor)),
              subtitle: Text('Choisir depuis vos photos',
                  style: GoogleFonts.poppins(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery(context, onImageSelected);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt,
                  color: AppTheme.primaryColor),
              title: Text('Caméra',
                  style: GoogleFonts.poppins(
                      color: AppTheme.textPrimaryColor)),
              subtitle: Text('Prendre une photo',
                  style: GoogleFonts.poppins(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera(context, onImageSelected);
              },
            ),
            const Divider(color: AppTheme.grey600),
            ListTile(
              leading:
                  const Icon(Icons.link, color: AppTheme.primaryColor),
              title: Text('URL d\'image',
                  style: GoogleFonts.poppins(
                      color: AppTheme.textPrimaryColor)),
              subtitle: Text('Lien vers une image en ligne',
                  style: GoogleFonts.poppins(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _showUrlInputDialog(context, onImageSelected);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler',
                style: GoogleFonts.poppins(
                    color: AppTheme.textSecondaryColor)),
          ),
        ],
      ),
    );
  }

  static Future<void> _pickImageFromGallery(
    BuildContext context,
    Function(String?) onImageSelected,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        onImageSelected('file://${image.path}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection: $e',
                style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  static Future<void> _pickImageFromCamera(
    BuildContext context,
    Function(String?) onImageSelected,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        onImageSelected('file://${image.path}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la capture: $e',
                style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  static void _showUrlInputDialog(
    BuildContext context,
    Function(String?) onImageSelected,
  ) {
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(
          'URL de l\'image',
          style: GoogleFonts.poppins(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: urlController,
          style: GoogleFonts.poppins(color: AppTheme.textPrimaryColor),
          decoration: InputDecoration(
            hintText: 'https://exemple.com/image.jpg',
            hintStyle: GoogleFonts.poppins(
                color: AppTheme.textSecondaryColor),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.grey600),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler',
                style: GoogleFonts.poppins(
                    color: AppTheme.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () {
              if (urlController.text.isNotEmpty) {
                onImageSelected(urlController.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Confirmer',
                style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }
}
