import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/home_config_model.dart';
import '../../services/home_config_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/image_storage_service.dart';
import 'package:file_picker/file_picker.dart';
import '../../../theme.dart';

/// Page d'administration pour configurer la dashboard membre
class HomeConfigAdminPage extends StatefulWidget {
  const HomeConfigAdminPage({super.key});

  @override
  State<HomeConfigAdminPage> createState() => _HomeConfigAdminPageState();
}

class _HomeConfigAdminPageState extends State<HomeConfigAdminPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  bool _isLoading = false;
  bool _isSaving = false;
  HomeConfigModel? _currentConfig;

  // Controllers pour la couverture
  final _coverImageUrlController = TextEditingController();
  final _coverTitleController = TextEditingController();
  final _coverSubtitleController = TextEditingController();
  final _coverVideoUrlController = TextEditingController();
  bool _useVideo = false;
  // Cover assets local lists
  List<String> _coverImageUrls = [];
  String? _coverVideoUrl;

  // Controllers pour le live
  final _liveUrlController = TextEditingController();
  final _liveDescriptionController = TextEditingController();
  DateTime? _liveDateTime;
  bool _isLiveActive = false;

  // Controllers pour le pain quotidien
  final _dailyBreadTitleController = TextEditingController();
  final _dailyBreadVerseController = TextEditingController();
  final _dailyBreadReferenceController = TextEditingController();
  bool _isDailyBreadActive = true;

  // Controllers pour la prédication
  final _sermonTitleController = TextEditingController();
  final _sermonPreacherController = TextEditingController();
  final _sermonDurationController = TextEditingController();
  final _sermonThumbnailController = TextEditingController();
  final _sermonUrlController = TextEditingController();
  bool _isLastSermonActive = true;

  // Variables pour les événements
  List<Map<String, dynamic>> _events = [];
  bool _areEventsActive = true;

  // Variables pour les actions rapides
  List<Map<String, dynamic>> _quickActions = [];
  bool _areQuickActionsActive = true;

  // Controllers pour le contact
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactWhatsAppController = TextEditingController();
  final _contactAddressController = TextEditingController();
  bool _isContactActive = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    
    // Synchroniser _coverVideoUrl avec le controller quand l'utilisateur tape manuellement
    _coverVideoUrlController.addListener(() {
      setState(() {
        _coverVideoUrl = _coverVideoUrlController.text.isNotEmpty ? _coverVideoUrlController.text : null;
        // Activer/désactiver automatiquement l'utilisation de la vidéo selon l'URL
        _useVideo = _coverVideoUrlController.text.isNotEmpty;
      });
    });
    
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _coverImageUrlController.dispose();
    _coverTitleController.dispose();
    _coverSubtitleController.dispose();
    _coverVideoUrlController.dispose();
    _liveUrlController.dispose();
    _liveDescriptionController.dispose();
    _dailyBreadTitleController.dispose();
    _dailyBreadVerseController.dispose();
    _dailyBreadReferenceController.dispose();
    _sermonTitleController.dispose();
    _sermonPreacherController.dispose();
    _sermonDurationController.dispose();
    _sermonThumbnailController.dispose();
    _sermonUrlController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _contactWhatsAppController.dispose();
    _contactAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentConfig() async {
    setState(() => _isLoading = true);
    try {
      final config = await HomeConfigService.getActiveHomeConfig();
      setState(() {
        _currentConfig = config;
        _loadConfigData(config);
      });
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }


  void _loadConfigData(HomeConfigModel config) {
    // Couverture
    _coverImageUrlController.text = config.coverImageUrl;
    _coverImageUrls = List<String>.from(config.coverImageUrls);
    _coverTitleController.text = config.coverTitle ?? '';
    _coverSubtitleController.text = config.coverSubtitle ?? '';
    _coverVideoUrl = config.coverVideoUrl;
    _coverVideoUrlController.text = config.coverVideoUrl ?? '';
    _useVideo = config.useVideo;

    // Live
    _liveUrlController.text = config.liveUrl ?? '';
    _liveDescriptionController.text = config.liveDescription ?? '';
    _liveDateTime = config.liveDateTime;
    _isLiveActive = config.isLiveActive;

    // Pain quotidien
    _dailyBreadTitleController.text = config.dailyBreadTitle ?? '';
    _dailyBreadVerseController.text = config.dailyBreadVerse ?? '';
    _dailyBreadReferenceController.text = config.dailyBreadReference ?? '';
    _isDailyBreadActive = config.isDailyBreadActive;

    // Prédication
    _sermonTitleController.text = config.lastSermonTitle ?? '';
    _sermonPreacherController.text = config.lastSermonPreacher ?? '';
    _sermonDurationController.text = config.lastSermonDuration ?? '';
    _sermonThumbnailController.text = config.lastSermonThumbnailUrl ?? '';
    _sermonUrlController.text = config.lastSermonUrl ?? '';
    _isLastSermonActive = config.isLastSermonActive;

    // Événements
    _events = List<Map<String, dynamic>>.from(config.upcomingEvents);
    _areEventsActive = config.areEventsActive;

    // Actions rapides
    _quickActions = List<Map<String, dynamic>>.from(config.quickActions);
    _areQuickActionsActive = config.areQuickActionsActive;

    // Contact
    _contactEmailController.text = config.contactEmail ?? '';
    _contactPhoneController.text = config.contactPhone ?? '';
    _contactWhatsAppController.text = config.contactWhatsApp ?? '';
    _contactAddressController.text = config.contactAddress ?? '';
    _isContactActive = config.isContactActive;
  }

  @override
  Widget build(BuildContext context) {
    final isApple = AppTheme.isApplePlatform;
    
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: _buildModernAppBar(isApple),
      body: _isLoading
          ? _buildLoadingState(isApple)
          : _buildModernTabBarView(isApple),
    );
  }

  PreferredSizeWidget _buildModernAppBar(bool isApple) {
    return AppBar(
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: AppTheme.onPrimaryColor,
      elevation: 0,
      title: Text(
        'Configuration Dashboard',
        style: GoogleFonts.inter(
          fontSize: AppTheme.fontSize18,
          fontWeight: AppTheme.fontSemiBold,
          color: AppTheme.onPrimaryColor,
        ),
      ),
      leading: IconButton(
        icon: Icon(
          isApple ? CupertinoIcons.back : Icons.arrow_back_rounded,
          color: AppTheme.onPrimaryColor,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
      ),
      actions: [
        if (_isSaving)
          Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.onPrimaryColor),
              ),
            ),
          )
        else
          IconButton(
            icon: Icon(
              isApple ? CupertinoIcons.checkmark_alt : Icons.save_rounded,
              color: AppTheme.onPrimaryColor,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              _saveConfiguration();
            },
            tooltip: 'Sauvegarder',
          ),
      ],
      bottom: _buildModernTabBar(isApple),
    );
  }

  PreferredSize _buildModernTabBar(bool isApple) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(48.0),
      child: Container(
        color: AppTheme.primaryColor,
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.onPrimaryColor,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: AppTheme.onPrimaryColor,
          unselectedLabelColor: AppTheme.onPrimaryColor.withOpacity(0.7),
          labelStyle: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontSemiBold,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontMedium,
          ),
          tabs: [
            Tab(
              icon: Icon(
                isApple ? CupertinoIcons.photo : Icons.image_rounded,
                size: 18,
              ),
              text: 'Couverture',
            ),
            Tab(
              icon: Icon(
                isApple ? CupertinoIcons.tv : Icons.live_tv_rounded,
                size: 18,
              ),
              text: 'Live',
            ),
            Tab(
              icon: Icon(
                isApple ? CupertinoIcons.book : Icons.menu_book_rounded,
                size: 18,
              ),
              text: 'Pain quotidien',
            ),
            Tab(
              icon: Icon(
                isApple ? CupertinoIcons.play_circle : Icons.play_circle_rounded,
                size: 18,
              ),
              text: 'Prédication',
            ),
            Tab(
              icon: Icon(
                isApple ? CupertinoIcons.calendar : Icons.event_rounded,
                size: 18,
              ),
              text: 'Événements',
            ),
            Tab(
              icon: Icon(
                isApple ? CupertinoIcons.bolt : Icons.flash_on_rounded,
                size: 18,
              ),
              text: 'Actions',
            ),
            Tab(
              icon: Icon(
                isApple ? CupertinoIcons.phone : Icons.contact_phone_rounded,
                size: 18,
              ),
              text: 'Contact',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isApple) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: AppTheme.borderRadiusLarge,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              strokeWidth: 3,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Chargement de la configuration...',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize16,
                fontWeight: AppTheme.fontMedium,
                color: AppTheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTabBarView(bool isApple) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildModernCoverTab(isApple),
        _buildModernLiveTab(isApple),
        _buildModernDailyBreadTab(isApple),
        _buildModernSermonTab(isApple),
        _buildModernEventsTab(isApple),
        _buildModernQuickActionsTab(isApple),
        _buildModernContactTab(isApple),
      ],
    );
  }

  Widget _buildModernCoverTab(bool isApple) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildCoverHeader(isApple),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                _buildCoverBasicInfoSection(isApple),
                const SizedBox(height: AppTheme.spaceMedium),
                _buildCoverMediaSection(isApple),
                const SizedBox(height: AppTheme.spaceLarge),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverHeader(bool isApple) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryContainer,
            AppTheme.primaryContainer.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceSmall),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                child: Icon(
                  isApple ? CupertinoIcons.photo : Icons.image_rounded,
                  color: AppTheme.onPrimaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Expanded(
                child: Text(
                  'Configuration Couverture',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize20,
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Personnalisez l\'image ou vidéo de couverture qui s\'affiche en haut du dashboard membre.',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              fontWeight: AppTheme.fontMedium,
              color: AppTheme.onPrimaryContainer.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverBasicInfoSection(bool isApple) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(
          color: AppTheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isApple ? CupertinoIcons.textformat : Icons.title_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Informations Textuelles',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            _buildModernTextField(
              controller: _coverTitleController,
              label: 'Titre de la couverture',
              hint: 'Jubilé Tabernacle',
              isApple: isApple,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            _buildModernTextField(
              controller: _coverSubtitleController,
              label: 'Sous-titre',
              hint: 'Bienvenue dans la maison de Dieu',
              isApple: isApple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverMediaSection(bool isApple) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(
          color: AppTheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isApple ? CupertinoIcons.play_rectangle : Icons.video_library_rounded,
                  color: AppTheme.secondaryColor,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Configuration Média',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            _buildModernSwitchTile(
              'Utiliser une vidéo de couverture',
              'Afficher une vidéo au lieu d\'une image statique',
              _useVideo,
              isApple ? CupertinoIcons.videocam : Icons.videocam_rounded,
              (value) => setState(() => _useVideo = value),
              isApple,
            ),
            if (_useVideo) ...[
              const SizedBox(height: AppTheme.spaceMedium),
              _buildModernTextField(
                controller: _coverVideoUrlController,
                label: 'URL de la vidéo',
                hint: 'https://example.com/video.mp4',
                isApple: isApple,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              _buildVideoUploadSection(isApple),
            ] else ...[
              const SizedBox(height: AppTheme.spaceMedium),
              _buildModernTextField(
                controller: _coverImageUrlController,
                label: 'URL de l\'image de couverture',
                hint: 'https://example.com/image.jpg',
                isApple: isApple,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              _buildImageUploadSection(isApple),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoUploadSection(bool isApple) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _pickAndUploadVideo();
            },
            icon: Icon(
              isApple ? CupertinoIcons.cloud_upload : Icons.upload_file_rounded,
              size: 18,
            ),
            label: const Text('Sélectionner une vidéo'),
          ),
        ),
        if (_coverVideoUrl != null && _coverVideoUrl!.isNotEmpty) ...[
          const SizedBox(width: AppTheme.spaceSmall),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceSmall,
              vertical: AppTheme.spaceXSmall,
            ),
            decoration: BoxDecoration(
              color: AppTheme.successContainer,
              borderRadius: AppTheme.borderRadiusSmall,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isApple ? CupertinoIcons.checkmark_alt : Icons.check_rounded,
                  color: AppTheme.onSuccessContainer,
                  size: 16,
                ),
                const SizedBox(width: AppTheme.spaceXSmall),
                Text(
                  'Vidéo ajoutée',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize12,
                    fontWeight: AppTheme.fontMedium,
                    color: AppTheme.onSuccessContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageUploadSection(bool isApple) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _pickAndUploadImages();
                },
                icon: Icon(
                  isApple ? CupertinoIcons.photo_camera : Icons.photo_library_rounded,
                  size: 18,
                ),
                label: const Text('Sélectionner des images'),
              ),
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            FilledButton.tonalIcon(
              onPressed: () {
                HapticFeedback.lightImpact();
                _clearCoverImages();
              },
              icon: Icon(
                isApple ? CupertinoIcons.delete : Icons.delete_forever_rounded,
                size: 18,
              ),
              label: const Text('Effacer toutes'),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: AppTheme.onError,
              ),
            ),
          ],
        ),
        if (_coverImageUrls.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceMedium),
          _buildCoverThumbnails(),
        ],
      ],
    );
  }

  Widget _buildLiveTab() {
    final isApple = AppTheme.isApplePlatform;
    
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildLiveHeader(isApple),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                _buildLiveConfigSection(isApple),
                const SizedBox(height: AppTheme.spaceLarge),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveHeader(bool isApple) {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.error.withOpacity(0.15),
            AppTheme.error.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: [
          BoxShadow(
            color: AppTheme.error.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceSmall),
                decoration: BoxDecoration(
                  color: AppTheme.error,
                  borderRadius: AppTheme.borderRadiusSmall,
                ),
                child: Icon(
                  isApple ? CupertinoIcons.tv : Icons.live_tv_rounded,
                  color: AppTheme.onError,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Expanded(
                child: Text(
                  'Configuration Live',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize20,
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Configurez la diffusion en direct pour vos cultes et événements spéciaux.',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              fontWeight: AppTheme.fontMedium,
              color: AppTheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveConfigSection(bool isApple) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(
          color: AppTheme.outline.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernSwitchTile(
              'Activer la section live',
              'Afficher la section de diffusion en direct',
              _isLiveActive,
              isApple ? CupertinoIcons.tv : Icons.live_tv_rounded,
              (value) => setState(() => _isLiveActive = value),
              isApple,
            ),
            if (_isLiveActive) ...[
              const SizedBox(height: AppTheme.spaceMedium),
              _buildModernTextField(
                controller: _liveDescriptionController,
                label: 'Description du live',
                hint: 'Prochain culte dans',
                isApple: isApple,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              _buildModernTextField(
                controller: _liveUrlController,
                label: 'URL du live stream',
                hint: 'https://youtube.com/watch?v=...',
                isApple: isApple,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              _buildLiveDateTimeSection(isApple),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLiveDateTimeSection(bool isApple) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: AppTheme.borderRadiusSmall,
        border: Border.all(
          color: AppTheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppTheme.borderRadiusSmall,
          onTap: () {
            HapticFeedback.lightImpact();
            _selectLiveDateTime();
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spaceXSmall),
                  decoration: BoxDecoration(
                    color: AppTheme.tertiaryContainer,
                    borderRadius: AppTheme.borderRadiusSmall,
                  ),
                  child: Icon(
                    isApple ? CupertinoIcons.calendar : Icons.calendar_today_rounded,
                    color: AppTheme.onTertiaryContainer,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date et heure du prochain live',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize14,
                          fontWeight: AppTheme.fontSemiBold,
                          color: AppTheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _liveDateTime?.toString() ?? 'Aucune date sélectionnée',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize12,
                          fontWeight: AppTheme.fontMedium,
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isApple ? CupertinoIcons.chevron_right : Icons.chevron_right_rounded,
                  color: AppTheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyBreadTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDailyBreadHeader(),
              const SizedBox(height: AppTheme.space20),
              _buildDailyBreadConfigSection(),
              if (_isDailyBreadActive) ...[
                const SizedBox(height: AppTheme.space20),
                _buildDailyBreadContentSection(),
              ],
              const SizedBox(height: AppTheme.space20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDailyBreadHeader() {
    final bool isApple = Platform.isIOS || Platform.isMacOS;
    
    return Container(
      margin: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isApple ? CupertinoIcons.book : Icons.menu_book_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spaceLarge),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pain quotidien',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize20,
                      fontWeight: AppTheme.fontBold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Text(
                    'Gérez le verset et la méditation quotidienne',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      fontWeight: AppTheme.fontMedium,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyBreadConfigSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space20,
              AppTheme.space20,
              AppTheme.space20,
              AppTheme.spaceMedium,
            ),
            child: Text(
              'Configuration',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize16,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          _buildModernSwitchTile(
            'Activer le pain quotidien',
            'Afficher la section pain quotidien sur l\'accueil',
            _isDailyBreadActive,
            Platform.isIOS || Platform.isMacOS ? CupertinoIcons.book : Icons.menu_book_rounded,
            (value) => setState(() => _isDailyBreadActive = value),
            Platform.isIOS || Platform.isMacOS,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBreadContentSection() {
    final bool isApple = Platform.isIOS || Platform.isMacOS;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contenu',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize16,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            _buildModernTextField(
              controller: _dailyBreadTitleController,
              label: 'Titre',
              hint: 'Pain quotidien',
              isApple: isApple,
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            _buildModernTextField(
              controller: _dailyBreadVerseController,
              label: 'Verset du jour',
              hint: 'Car l\'Éternel, ton Dieu, t\'a béni...',
              isApple: isApple,
              maxLines: 3,
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            _buildModernTextField(
              controller: _dailyBreadReferenceController,
              label: 'Référence biblique',
              hint: 'Deutéronome 2:7',
              isApple: isApple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSermonTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSermonHeader(),
              const SizedBox(height: AppTheme.space20),
              _buildSermonConfigSection(),
              if (_isLastSermonActive) ...[
                const SizedBox(height: AppTheme.space20),
                _buildSermonContentSection(),
              ],
              const SizedBox(height: AppTheme.space20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSermonHeader() {
    final bool isApple = Platform.isIOS || Platform.isMacOS;
    
    return Container(
      margin: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isApple ? CupertinoIcons.play_rectangle : Icons.play_circle_fill_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spaceLarge),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prédication',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize20,
                      fontWeight: AppTheme.fontBold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Text(
                    'Gérez les informations de la dernière prédication',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      fontWeight: AppTheme.fontMedium,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSermonConfigSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space20,
              AppTheme.space20,
              AppTheme.space20,
              AppTheme.spaceMedium,
            ),
            child: Text(
              'Configuration',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize16,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          _buildModernSwitchTile(
            'Afficher la dernière prédication',
            'Afficher la section prédication sur l\'accueil',
            _isLastSermonActive,
            Platform.isIOS || Platform.isMacOS ? CupertinoIcons.play_rectangle : Icons.play_circle_fill_rounded,
            (value) => setState(() => _isLastSermonActive = value),
            Platform.isIOS || Platform.isMacOS,
          ),
        ],
      ),
    );
  }

  Widget _buildSermonContentSection() {
    final bool isApple = Platform.isIOS || Platform.isMacOS;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations de la prédication',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize16,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            _buildModernTextField(
              controller: _sermonTitleController,
              label: 'Titre de la prédication',
              hint: 'La grâce de Dieu',
              isApple: isApple,
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            _buildModernTextField(
              controller: _sermonPreacherController,
              label: 'Prédicateur',
              hint: 'Pasteur Jean-Baptiste',
              isApple: isApple,
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            _buildModernTextField(
              controller: _sermonDurationController,
              label: 'Durée',
              hint: '45 min',
              isApple: isApple,
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            _buildModernTextField(
              controller: _sermonThumbnailController,
              label: 'URL de la miniature',
              hint: 'https://example.com/thumbnail.jpg',
              isApple: isApple,
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            _buildModernTextField(
              controller: _sermonUrlController,
              label: 'URL de la prédication',
              hint: 'https://youtube.com/watch?v=...',
              isApple: isApple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEventsHeader(),
              const SizedBox(height: AppTheme.space20),
              _buildEventsConfigSection(),
              if (_areEventsActive) ...[
                const SizedBox(height: AppTheme.space20),
                _buildEventsContentSection(),
              ],
              const SizedBox(height: AppTheme.space20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventsHeader() {
    final bool isApple = Platform.isIOS || Platform.isMacOS;
    
    return Container(
      margin: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isApple ? CupertinoIcons.calendar : Icons.event_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spaceLarge),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Événements',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize20,
                      fontWeight: AppTheme.fontBold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Text(
                    'Gérez les événements à venir de l\'église',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      fontWeight: AppTheme.fontMedium,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsConfigSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space20,
              AppTheme.space20,
              AppTheme.space20,
              AppTheme.spaceMedium,
            ),
            child: Text(
              'Configuration',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize16,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          _buildModernSwitchTile(
            'Afficher les événements',
            'Afficher la section événements sur l\'accueil',
            _areEventsActive,
            Platform.isIOS || Platform.isMacOS ? CupertinoIcons.calendar : Icons.event_rounded,
            (value) => setState(() => _areEventsActive = value),
            Platform.isIOS || Platform.isMacOS,
          ),
        ],
      ),
    );
  }

  Widget _buildEventsContentSection() {
    final bool isApple = Platform.isIOS || Platform.isMacOS;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Événements à venir',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.onSurface,
                  ),
                ),
                Material(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _addEvent();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceMedium,
                        vertical: AppTheme.spaceSmall,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isApple ? CupertinoIcons.add : Icons.add_rounded,
                            color: AppTheme.white100,
                            size: 18,
                          ),
                          const SizedBox(width: AppTheme.spaceSmall),
                          Text(
                            'Ajouter',
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize14,
                              fontWeight: AppTheme.fontMedium,
                              color: AppTheme.white100,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            if (_events.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.space20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isApple ? CupertinoIcons.calendar_badge_plus : Icons.event_busy_rounded,
                      color: AppTheme.onSurfaceVariant,
                      size: 48,
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                    Text(
                      'Aucun événement configuré',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        fontWeight: AppTheme.fontMedium,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: _events.asMap().entries.map((entry) => 
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key < _events.length - 1 ? AppTheme.spaceMedium : 0,
                    ),
                    child: _buildEventCard(entry.key, entry.value),
                  ),
                ).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickActionsHeader(),
              const SizedBox(height: AppTheme.space20),
              _buildQuickActionsConfigSection(),
              if (_areQuickActionsActive) ...[
                const SizedBox(height: AppTheme.space20),
                _buildQuickActionsContentSection(),
              ],
              const SizedBox(height: AppTheme.space20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsHeader() {
    final bool isApple = Platform.isIOS || Platform.isMacOS;
    
    return Container(
      margin: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isApple ? CupertinoIcons.bolt : Icons.flash_on_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spaceLarge),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actions rapides',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize20,
                      fontWeight: AppTheme.fontBold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Text(
                    'Configurez les raccourcis pour l\'accueil',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      fontWeight: AppTheme.fontMedium,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsConfigSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space20,
              AppTheme.space20,
              AppTheme.space20,
              AppTheme.spaceMedium,
            ),
            child: Text(
              'Configuration',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize16,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          _buildModernSwitchTile(
            'Afficher les actions rapides',
            'Afficher les raccourcis sur l\'accueil',
            _areQuickActionsActive,
            Platform.isIOS || Platform.isMacOS ? CupertinoIcons.bolt : Icons.flash_on_rounded,
            (value) => setState(() => _areQuickActionsActive = value),
            Platform.isIOS || Platform.isMacOS,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsContentSection() {
    final bool isApple = Platform.isIOS || Platform.isMacOS;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Actions disponibles',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.onSurface,
                  ),
                ),
                Material(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _addQuickAction();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spaceMedium,
                        vertical: AppTheme.spaceSmall,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isApple ? CupertinoIcons.add : Icons.add_rounded,
                            color: AppTheme.white100,
                            size: 18,
                          ),
                          const SizedBox(width: AppTheme.spaceSmall),
                          Text(
                            'Ajouter',
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize14,
                              fontWeight: AppTheme.fontMedium,
                              color: AppTheme.white100,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            if (_quickActions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.space20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      isApple ? CupertinoIcons.bolt_slash : Icons.flash_off_rounded,
                      color: AppTheme.onSurfaceVariant,
                      size: 48,
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                    Text(
                      'Aucune action configurée',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        fontWeight: AppTheme.fontMedium,
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: ReorderableListView(
                  padding: EdgeInsets.zero,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex--;
                      final item = _quickActions.removeAt(oldIndex);
                      _quickActions.insert(newIndex, item);
                    });
                  },
                  children: [
                    for (int i = 0; i < _quickActions.length; i++)
                      Container(
                        key: ValueKey('quick_action_$i'),
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: _buildQuickActionCard(i, _quickActions[i]),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTab() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildContactHeader(),
              const SizedBox(height: AppTheme.space20),
              _buildContactConfigSection(),
              if (_isContactActive) ...[
                const SizedBox(height: AppTheme.space20),
                _buildContactContentSection(),
              ],
              const SizedBox(height: AppTheme.space20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactHeader() {
    final bool isApple = Platform.isIOS || Platform.isMacOS;
    
    return Container(
      margin: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isApple ? CupertinoIcons.phone : Icons.contact_phone_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spaceLarge),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize20,
                      fontWeight: AppTheme.fontBold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Text(
                    'Gérez les informations de contact de l\'église',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      fontWeight: AppTheme.fontMedium,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactConfigSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space20,
              AppTheme.space20,
              AppTheme.space20,
              AppTheme.spaceMedium,
            ),
            child: Text(
              'Configuration',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize16,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.onSurface,
              ),
            ),
          ),
          _buildModernSwitchTile(
            'Afficher la section contact',
            'Afficher les informations de contact sur l\'accueil',
            _isContactActive,
            Platform.isIOS || Platform.isMacOS ? CupertinoIcons.phone : Icons.contact_phone_rounded,
            (value) => setState(() => _isContactActive = value),
            Platform.isIOS || Platform.isMacOS,
          ),
        ],
      ),
    );
  }

  Widget _buildContactContentSection() {
    final bool isApple = Platform.isIOS || Platform.isMacOS;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations de contact',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize16,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.onSurface,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            _buildModernTextField(
              controller: _contactEmailController,
              label: 'Email',
              hint: 'contact@jubiletabernacle.org',
              isApple: isApple,
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            _buildModernTextField(
              controller: _contactPhoneController,
              label: 'Téléphone',
              hint: '+33 6 77 45 72 78',
              isApple: isApple,
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            _buildModernTextField(
              controller: _contactWhatsAppController,
              label: 'WhatsApp',
              hint: '+33 6 77 45 72 78',
              isApple: isApple,
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            
            _buildModernTextField(
              controller: _contactAddressController,
              label: 'Adresse',
              hint: 'Jubilé Tabernacle\n124 bis rue de l\'Épidème\n59200 Tourcoing',
              isApple: isApple,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildEventCard(int index, Map<String, dynamic> event) {
    return Card(
      color: const Color(0xFF2A2D3A),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          event['title'] ?? 'Événement',
          style: const TextStyle(color: AppTheme.white100),
        ),
        subtitle: Text(
          '${event['day']} ${event['month']} - ${event['time']} - ${event['description']}',
          style: const TextStyle(color: AppTheme.grey500),
        ),
        trailing: IconButton(
          onPressed: () => _removeEvent(index),
          icon: const Icon(Icons.delete, color: AppTheme.redStandard),
        ),
        onTap: () => _editEvent(index, event),
      ),
    );
  }

  Widget _buildQuickActionCard(int index, Map<String, dynamic> action) {
    return Card(
      color: const Color(0xFF2A2D3A),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Color(action['color'] ?? 0xFF2196F3),
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          ),
          child: Icon(
            _getIconData(action['icon'] ?? 'help_outline'),
            color: AppTheme.white100,
            size: 20,
          ),
        ),
        title: Text(
          action['title'] ?? 'Action',
          style: const TextStyle(color: AppTheme.white100),
        ),
        subtitle: Text(
          action['description'] ?? '',
          style: const TextStyle(color: AppTheme.grey500),
        ),
        trailing: IconButton(
          onPressed: () => _removeQuickAction(index),
          icon: const Icon(Icons.delete, color: AppTheme.redStandard),
        ),
        onTap: () => _editQuickAction(index, action),
      ),
    );
  }

  Future<void> _selectLiveDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _liveDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.blueStandard,
              surface: Color(0xFF2A2D3A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_liveDateTime ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.blueStandard,
                surface: Color(0xFF2A2D3A),
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _liveDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _addEvent() {
    _showEventDialog();
  }

  void _editEvent(int index, Map<String, dynamic> event) {
    _showEventDialog(index: index, event: event);
  }

  void _removeEvent(int index) {
    setState(() {
      _events.removeAt(index);
    });
  }

  void _addQuickAction() {
    _showQuickActionDialog();
  }

  void _editQuickAction(int index, Map<String, dynamic> action) {
    _showQuickActionDialog(index: index, action: action);
  }

  void _removeQuickAction(int index) {
    setState(() {
      _quickActions.removeAt(index);
    });
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      // Icônes religieuses et spirituelles
      case 'church': return Icons.church;
      case 'volunteer_activism_rounded': return Icons.volunteer_activism_rounded;
      case 'favorite_rounded': return Icons.favorite_rounded;
      case 'auto_stories': return Icons.auto_stories;
      case 'menu_book_rounded': return Icons.menu_book_rounded;
      case 'campaign': return Icons.campaign;
      case 'celebration': return Icons.celebration;
      case 'temple_buddhist': return Icons.temple_buddhist;
      
      // Icônes de communauté et groupes
      case 'group': return Icons.group;
      case 'groups': return Icons.groups;
      case 'people': return Icons.people;
      case 'family_restroom': return Icons.family_restroom;
      case 'diversity_3': return Icons.diversity_3;
      case 'handshake': return Icons.handshake;
      
      // Icônes de calendrier et événements
      case 'calendar_today': return Icons.calendar_today;
      case 'event': return Icons.event;
      case 'schedule': return Icons.schedule;
      case 'date_range': return Icons.date_range;
      case 'event_available': return Icons.event_available;
      case 'today': return Icons.today;
      
      // Icônes de communication
      case 'mail': return Icons.mail;
      case 'email': return Icons.email;
      case 'message': return Icons.message;
      case 'phone': return Icons.phone;
      case 'contact_phone': return Icons.contact_phone;
      case 'forum': return Icons.forum;
      case 'chat': return Icons.chat;
      
      // Icônes de musique et louange
      case 'music_note': return Icons.music_note;
      case 'library_music': return Icons.library_music;
      case 'queue_music': return Icons.queue_music;
      case 'mic': return Icons.mic;
      case 'piano': return Icons.piano;
      case 'audiotrack': return Icons.audiotrack;
      
      // Icônes de dons et finances
      case 'card_giftcard_rounded': return Icons.card_giftcard_rounded;
      case 'volunteer_activism': return Icons.volunteer_activism;
      case 'monetization_on': return Icons.monetization_on;
      case 'account_balance_wallet': return Icons.account_balance_wallet;
      case 'savings': return Icons.savings;
      
      // Icônes de localisation
      case 'location_on': return Icons.location_on;
      case 'place': return Icons.place;
      case 'map': return Icons.map;
      case 'directions': return Icons.directions;
      case 'home': return Icons.home;
      
      // Icônes d'éducation et formation
      case 'school': return Icons.school;
      case 'book': return Icons.book;
      case 'quiz': return Icons.quiz;
      case 'psychology': return Icons.psychology;
      case 'lightbulb': return Icons.lightbulb;
      
      // Icônes de service et ministère
      case 'work': return Icons.work;
      case 'build': return Icons.build;
      case 'engineering': return Icons.engineering;
      case 'cleaning_services': return Icons.cleaning_services;
      case 'restaurant': return Icons.restaurant;
      case 'local_dining': return Icons.local_dining;
      
      // Icônes diverses utiles
      case 'info': return Icons.info;
      case 'help': return Icons.help;
      case 'support': return Icons.support;
      case 'star': return Icons.star;
      case 'diamond': return Icons.diamond;
      case 'emoji_events': return Icons.emoji_events;
      case 'card_membership': return Icons.card_membership;
      case 'badge': return Icons.badge;
      
      // Icônes par défaut
      case 'help_outline':
      default:
        return Icons.help_outline;
    }
  }

  void _showEventDialog({int? index, Map<String, dynamic>? event}) {
    final dayController = TextEditingController(text: event?['day'] ?? '');
    final monthController = TextEditingController(text: event?['month'] ?? '');
    final titleController = TextEditingController(text: event?['title'] ?? '');
    final descriptionController = TextEditingController(text: event?['description'] ?? '');
    final timeController = TextEditingController(text: event?['time'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2D3A),
        title: Text(
          index != null ? 'Modifier l\'événement' : 'Ajouter un événement',
          style: const TextStyle(color: AppTheme.white100),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: dayController,
                      style: const TextStyle(color: AppTheme.white100),
                      decoration: const InputDecoration(
                        labelText: 'Jour',
                        labelStyle: TextStyle(color: AppTheme.grey500),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.grey500),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceMedium),
                  Expanded(
                    child: TextField(
                      controller: monthController,
                      style: const TextStyle(color: AppTheme.white100),
                      decoration: const InputDecoration(
                        labelText: 'Mois',
                        labelStyle: TextStyle(color: AppTheme.grey500),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.grey500),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              TextField(
                controller: titleController,
                style: const TextStyle(color: AppTheme.white100),
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  labelStyle: TextStyle(color: AppTheme.grey500),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.grey500),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: AppTheme.white100),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: AppTheme.grey500),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.grey500),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              TextField(
                controller: timeController,
                style: const TextStyle(color: AppTheme.white100),
                decoration: const InputDecoration(
                  labelText: 'Heure',
                  labelStyle: TextStyle(color: AppTheme.grey500),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.grey500),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: AppTheme.grey500)),
          ),
          ElevatedButton(
            onPressed: () {
              final newEvent = {
                'day': dayController.text,
                'month': monthController.text,
                'title': titleController.text,
                'description': descriptionController.text,
                'time': timeController.text,
              };

              setState(() {
                if (index != null) {
                  _events[index] = newEvent;
                } else {
                  _events.add(newEvent);
                }
              });

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.blueStandard,
              foregroundColor: AppTheme.white100,
            ),
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _showQuickActionDialog({int? index, Map<String, dynamic>? action}) {
    final titleController = TextEditingController(text: action?['title'] ?? '');
    final descriptionController = TextEditingController(text: action?['description'] ?? '');
    String selectedIcon = action?['icon'] ?? 'help_outline';
    int selectedColor = action?['color'] ?? 0xFF2196F3;
    int? selectedIconColor = action?['iconColor'];
    int? selectedBackgroundColor = action?['backgroundColor'];
    int? selectedTextColor = action?['textColor'];
    String? selectedBackgroundImage = action?['backgroundImage'];
    bool showIcon = action?['showIcon'] ?? true;

    final availableIcons = [
      // Icônes religieuses et spirituelles
      {'name': 'church', 'icon': Icons.church, 'label': 'Église'},
      {'name': 'volunteer_activism_rounded', 'icon': Icons.volunteer_activism_rounded, 'label': 'Mains en prière'},
      {'name': 'favorite_rounded', 'icon': Icons.favorite_rounded, 'label': 'Cœur / Amour'},
      {'name': 'auto_stories', 'icon': Icons.auto_stories, 'label': 'Bible / Écritures'},
      {'name': 'menu_book_rounded', 'icon': Icons.menu_book_rounded, 'label': 'Livre / Lecture'},
      {'name': 'campaign', 'icon': Icons.campaign, 'label': 'Annonce / Proclamation'},
      {'name': 'celebration', 'icon': Icons.celebration, 'label': 'Célébration'},
      {'name': 'temple_buddhist', 'icon': Icons.temple_buddhist, 'label': 'Temple / Sanctuaire'},
      
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

    final availableColors = [
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF2A2D3A),
          title: Text(
            index != null ? 'Modifier l\'action' : 'Ajouter une action',
            style: const TextStyle(color: AppTheme.white100),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: AppTheme.white100),
                  decoration: const InputDecoration(
                    labelText: 'Titre',
                    labelStyle: TextStyle(color: AppTheme.grey500),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.grey500),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                TextField(
                  controller: descriptionController,
                  style: const TextStyle(color: AppTheme.white100),
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    labelStyle: TextStyle(color: AppTheme.grey500),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.grey500),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space20),
                
                // Sélection d'icône
                const Text(
                  'Icône',
                  style: TextStyle(color: AppTheme.white100, fontSize: AppTheme.fontSize16),
                ),
                const SizedBox(height: AppTheme.space12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableIcons.map((iconData) {
                    final isSelected = selectedIcon == iconData['name'];
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = iconData['name'] as String),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.blueStandard : AppTheme.grey700,
                          borderRadius: BorderRadius.circular(25),
                          border: isSelected ? Border.all(color: AppTheme.blueStandard, width: 2) : null,
                        ),
                        child: Icon(
                          iconData['icon'] as IconData,
                          color: AppTheme.white100,
                          size: 24,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppTheme.space20),
                
                // Sélection des couleurs personnalisées et image d'arrière-plan
                const Text(
                  'Personnalisation de l\'apparence',
                  style: TextStyle(color: AppTheme.white100, fontSize: AppTheme.fontSize18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                // Sélecteur d'image d'arrière-plan
                _buildBackgroundSelector(
                  selectedBackgroundImage,
                  selectedBackgroundColor ?? selectedColor,
                  availableColors,
                  (imageUrl) => setDialogState(() => selectedBackgroundImage = imageUrl),
                  (color) => setDialogState(() {
                    selectedBackgroundColor = color;
                    if (color != null) selectedBackgroundImage = null; // Reset image si couleur sélectionnée
                  }),
                ),
                const SizedBox(height: 16),

                
                // Couleur de l'icône
                _buildColorSelector(
                  'Couleur de l\'icône',
                  selectedIconColor,
                  [...availableColors, {'name': 'Auto (blanc/noir)', 'color': null}],
                  (color) => setDialogState(() => selectedIconColor = color),
                ),
                const SizedBox(height: 16),
                
                // Couleur du texte
                _buildColorSelector(
                  'Couleur du texte',
                  selectedTextColor,
                  [...availableColors, {'name': 'Auto (contraste)', 'color': null}],
                  (color) => setDialogState(() => selectedTextColor = color),
                ),
                const SizedBox(height: AppTheme.space20),
                
                // Preview de l'action
                const Text(
                  'Aperçu',
                  style: TextStyle(color: AppTheme.white100, fontSize: AppTheme.fontSize16),
                ),
                const SizedBox(height: AppTheme.space12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: _buildActionPreview(
                    titleController.text.isEmpty ? 'Titre de l\'action' : titleController.text,
                    selectedIcon,
                    selectedBackgroundColor ?? selectedColor,
                    selectedIconColor,
                    selectedTextColor,
                    selectedBackgroundImage,
                    showIcon,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: AppTheme.grey500)),
            ),
            ElevatedButton(
              onPressed: () {
                final newAction = {
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'icon': selectedIcon,
                  'color': selectedBackgroundColor ?? selectedColor,
                  'iconColor': selectedIconColor,
                  'backgroundColor': selectedBackgroundColor ?? selectedColor,
                  'textColor': selectedTextColor,
                  'backgroundImage': selectedBackgroundImage,
                  'showIcon': showIcon,
                };

                setState(() {
                  if (index != null) {
                    _quickActions[index] = newAction;
                  } else {
                    _quickActions.add(newAction);
                  }
                });

                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.blueStandard,
                foregroundColor: AppTheme.white100,
              ),
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }



  Future<void> _saveConfiguration() async {
    setState(() => _isSaving = true);
    
    try {
      final config = _currentConfig?.copyWith(
        // Couverture
        coverImageUrl: _coverImageUrlController.text,
        coverTitle: _coverTitleController.text,
        coverSubtitle: _coverSubtitleController.text,
        coverVideoUrl: _coverVideoUrlController.text.isNotEmpty ? _coverVideoUrlController.text : _coverVideoUrl,
        useVideo: _useVideo,
        
        // Live
        liveUrl: _liveUrlController.text,
        liveDescription: _liveDescriptionController.text,
        liveDateTime: _liveDateTime,
        isLiveActive: _isLiveActive,
        
        // Pain quotidien
        dailyBreadTitle: _dailyBreadTitleController.text,
        dailyBreadVerse: _dailyBreadVerseController.text,
        dailyBreadReference: _dailyBreadReferenceController.text,
        isDailyBreadActive: _isDailyBreadActive,
        
        // Prédication
        lastSermonTitle: _sermonTitleController.text,
        lastSermonPreacher: _sermonPreacherController.text,
        lastSermonDuration: _sermonDurationController.text,
        lastSermonThumbnailUrl: _sermonThumbnailController.text,
        lastSermonUrl: _sermonUrlController.text,
        isLastSermonActive: _isLastSermonActive,
        
        // Événements
        upcomingEvents: _events,
        areEventsActive: _areEventsActive,
        
  // Actions rapides (sauvegarder la liste modifiée)
  areQuickActionsActive: _areQuickActionsActive,
  quickActions: _quickActions,
        
        // Contact
        contactEmail: _contactEmailController.text,
        contactPhone: _contactPhoneController.text,
        contactWhatsApp: _contactWhatsAppController.text,
        contactAddress: _contactAddressController.text,
        isContactActive: _isContactActive,
  // Cover assets
  coverImageUrls: _coverImageUrls,
      ) ?? HomeConfigModel.defaultConfig.copyWith(
        // Valeurs depuis les contrôleurs...
      );

      await HomeConfigService.updateHomeConfig(config);
      await HomeConfigService.saveToHistory('Configuration mise à jour depuis l\'interface admin');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration sauvegardée avec succès !'),
            backgroundColor: AppTheme.greenStandard,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sauvegarde: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.redStandard,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.greenStandard,
        ),
      );
    }
  }
  /// Sélectionner et uploader plusieurs images depuis la galerie
  Future<void> _pickAndUploadImages() async {
    try {
      final picker = ImagePicker();
      final List<XFile>? files = await picker.pickMultiImage(imageQuality: 80);
      if (files == null || files.isEmpty) return;

      setState(() => _isSaving = true);

      for (final f in files) {
        final bytes = await f.readAsBytes();
        final url = await ImageStorageService.uploadImage(bytes);
        if (url != null) _coverImageUrls.add(url);
      }

      setState(() => _isSaving = false);
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Erreur lors de la sélection ou l\'upload des images: $e');
    }
  }

  /// Sélectionner et uploader une vidéo (via FilePicker)
  Future<void> _pickAndUploadVideo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return;

      setState(() => _isSaving = true);

      final file = result.files.first;
      if (file.path == null) {
        _showErrorSnackBar('Chemin de fichier vidéo introuvable');
        setState(() => _isSaving = false);
        return;
      }

      final bytes = await File(file.path!).readAsBytes();
      final url = await ImageStorageService.uploadImage(bytes, customPath: 'page_components/videos');
      if (url != null) {
        // Debug pour vérifier l'URL
        print('🎥 URL vidéo générée: $url');
        
        setState(() {
          _coverVideoUrl = url;
          _useVideo = true; // Activer automatiquement l'utilisation de la vidéo
        });
        
        // Mettre à jour le contrôleur après setState pour éviter les conflits avec le listener
        _coverVideoUrlController.text = url;
        
        // Petit délai pour s'assurer que l'interface se met à jour
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Sauvegarder automatiquement la configuration avec la nouvelle vidéo
        await _saveConfiguration();
        _showSuccessSnackBar('Vidéo ajoutée avec succès !');
      }

      setState(() => _isSaving = false);
    } catch (e) {
      setState(() => _isSaving = false);
      _showErrorSnackBar('Erreur lors de la sélection ou l\'upload de la vidéo: $e');
    }
  }

  /// Effacer les images locales
  void _clearCoverImages() {
    setState(() {
      _coverImageUrls.clear();
      _coverImageUrlController.clear();
    });
  }

  Widget _buildCoverThumbnails() {
    if (_coverImageUrls.isEmpty) {
      return const Card(
        color: Color(0xFF2A2D3A),
        child: Padding(
          padding: EdgeInsets.all(AppTheme.space12),
          child: Center(
            child: Text('Aucune image sélectionnée', style: TextStyle(color: AppTheme.grey500)),
          ),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _coverImageUrls.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppTheme.spaceSmall),
        itemBuilder: (context, index) {
          final url = _coverImageUrls[index];
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: Image.network(url, width: 140, height: 100, fit: BoxFit.cover),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () async {
                    // Optionnel: supprimer du storage
                    final success = await ImageStorageService.deleteImageByUrl(url);
                    if (success) {
                      setState(() => _coverImageUrls.removeAt(index));
                    } else {
                      _showErrorSnackBar('Impossible de supprimer l\'image du storage');
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.black100,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    padding: const EdgeInsets.all(AppTheme.spaceXSmall),
                    child: const Icon(Icons.delete, color: AppTheme.white100, size: 18),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper methods for modern UI components
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isApple,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.onSurface,
          ),
        ),
        const SizedBox(height: AppTheme.spaceXSmall),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize14,
            fontWeight: AppTheme.fontMedium,
            color: AppTheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              fontWeight: AppTheme.fontMedium,
              color: AppTheme.onSurfaceVariant,
            ),
            filled: true,
            fillColor: AppTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusSmall,
              borderSide: BorderSide(color: AppTheme.outline.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusSmall,
              borderSide: BorderSide(color: AppTheme.outline.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppTheme.borderRadiusSmall,
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.all(AppTheme.spaceMedium),
          ),
        ),
      ],
    );
  }

  Widget _buildModernSwitchTile(
    String title,
    String subtitle,
    bool value,
    IconData icon,
    ValueChanged<bool> onChanged,
    bool isApple,
  ) {
    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceXSmall),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceXSmall),
              decoration: BoxDecoration(
                color: value 
                    ? AppTheme.primaryContainer 
                    : AppTheme.surfaceVariant,
                borderRadius: AppTheme.borderRadiusSmall,
              ),
              child: Icon(
                icon,
                color: value 
                    ? AppTheme.onPrimaryContainer 
                    : AppTheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      fontWeight: AppTheme.fontSemiBold,
                      color: AppTheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize12,
                      fontWeight: AppTheme.fontMedium,
                      color: AppTheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              onChanged: (newValue) {
                HapticFeedback.lightImpact();
                onChanged(newValue);
              },
              activeColor: AppTheme.primaryColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder modern tab methods - keeping original functionality
  Widget _buildModernLiveTab(bool isApple) => _buildLiveTab();
  Widget _buildModernDailyBreadTab(bool isApple) => _buildDailyBreadTab();
  Widget _buildModernSermonTab(bool isApple) => _buildSermonTab();
  Widget _buildModernEventsTab(bool isApple) => _buildEventsTab();
  Widget _buildModernQuickActionsTab(bool isApple) => _buildQuickActionsTab();
  Widget _buildModernContactTab(bool isApple) => _buildContactTab();

  Widget _buildColorSelector(String title, int? selectedColor, List<Map<String, dynamic>> colors, Function(int?) onColorSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: AppTheme.white100, fontSize: 14, fontWeight: FontWeight.w600),
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
                  color: isAuto ? const Color(0xFF424242) : Color(colorValue),
                  borderRadius: BorderRadius.circular(18),
                  border: isSelected 
                    ? Border.all(color: AppTheme.white100, width: 2.5) 
                    : (colorValue == 0xFFFFFFFF || colorValue == 0xFFEEEEEE)
                      ? Border.all(color: AppTheme.grey400, width: 1)
                      : null,
                ),
                child: isAuto 
                  ? const Icon(Icons.auto_mode, color: Colors.white, size: 16)
                  : isSelected && (colorValue == 0xFFFFFFFF || colorValue == 0xFFEEEEEE)
                    ? const Icon(Icons.check, color: Colors.black, size: 14)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBackgroundSelector(String? selectedImageUrl, int selectedColor, List<Map<String, dynamic>> colors, Function(String?) onImageSelected, Function(int?) onColorSelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Arrière-plan',
          style: TextStyle(color: AppTheme.white100, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        
        // Options : Couleur unie ou Image
        Row(
          children: [
            // Toggle Couleur
            Expanded(
              child: GestureDetector(
                onTap: () => onImageSelected(null),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: selectedImageUrl == null ? AppTheme.primaryColor : const Color(0xFF424242),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedImageUrl == null ? AppTheme.primaryColor : AppTheme.grey600,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.palette,
                        color: selectedImageUrl == null ? Colors.white : AppTheme.grey400,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Couleur',
                        style: TextStyle(
                          color: selectedImageUrl == null ? Colors.white : AppTheme.grey400,
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
            // Toggle Image
            Expanded(
              child: GestureDetector(
                onTap: () => _showImagePicker(onImageSelected),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: selectedImageUrl != null ? AppTheme.primaryColor : const Color(0xFF424242),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedImageUrl != null ? AppTheme.primaryColor : AppTheme.grey600,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        color: selectedImageUrl != null ? Colors.white : AppTheme.grey400,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Image',
                        style: TextStyle(
                          color: selectedImageUrl != null ? Colors.white : AppTheme.grey400,
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
        
        // Affichage conditionnel selon le type sélectionné
        if (selectedImageUrl == null)
          // Sélecteur de couleurs
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
                      ? Border.all(color: AppTheme.white100, width: 2.5) 
                      : (colorValue == 0xFFFFFFFF || colorValue == 0xFFEEEEEE)
                        ? Border.all(color: AppTheme.grey400, width: 1)
                        : null,
                  ),
                  child: isSelected && (colorValue == 0xFFFFFFFF || colorValue == 0xFFEEEEEE)
                    ? const Icon(Icons.check, color: Colors.black, size: 14)
                    : null,
                ),
              );
            }).toList(),
          )
        else
          // Aperçu de l'image sélectionnée
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.grey400, width: 1),
            ),
            child: _buildImageWidget(selectedImageUrl, 7.0),
          ),
      ],
    );
  }

  void _showImagePicker(Function(String?) onImageSelected) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2D3A),
        title: const Text(
          'Choisir une image',
          style: TextStyle(color: AppTheme.white100),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.white100),
              title: const Text('Galerie', style: TextStyle(color: AppTheme.white100)),
              subtitle: const Text('Choisir depuis vos photos', style: TextStyle(color: AppTheme.grey400, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery(onImageSelected);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.white100),
              title: const Text('Caméra', style: TextStyle(color: AppTheme.white100)),
              subtitle: const Text('Prendre une photo', style: TextStyle(color: AppTheme.grey400, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera(onImageSelected);
              },
            ),
            const Divider(color: AppTheme.grey600),
            ListTile(
              leading: const Icon(Icons.link, color: AppTheme.white100),
              title: const Text('URL d\'image', style: TextStyle(color: AppTheme.white100)),
              subtitle: const Text('Lien vers une image en ligne', style: TextStyle(color: AppTheme.grey400, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _showUrlInputDialog(onImageSelected);
              },
            ),
            ListTile(
              leading: const Icon(Icons.collections, color: AppTheme.white100),
              title: const Text('Images suggérées', style: TextStyle(color: AppTheme.white100)),
              subtitle: const Text('Sélection d\'images de qualité', style: TextStyle(color: AppTheme.grey400, fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _showPredefinedImagesDialog(onImageSelected);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: AppTheme.grey500)),
          ),
        ],
      ),
    );
  }

  void _showUrlInputDialog(Function(String?) onImageSelected) {
    final urlController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2D3A),
        title: const Text(
          'URL de l\'image',
          style: TextStyle(color: AppTheme.white100),
        ),
        content: TextField(
          controller: urlController,
          style: const TextStyle(color: AppTheme.white100),
          decoration: const InputDecoration(
            hintText: 'https://exemple.com/image.jpg',
            hintStyle: TextStyle(color: AppTheme.grey500),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.grey600),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: AppTheme.grey500)),
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
              foregroundColor: AppTheme.white100,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery(Function(String?) onImageSelected) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // Pour l'instant, on utilise le chemin local de l'image
        // Dans une vraie app, il faudrait uploader l'image vers un serveur
        onImageSelected('file://${image.path}');
        
        // Afficher un message d'information
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image sélectionnée depuis la galerie'),
              backgroundColor: AppTheme.successColor,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera(Function(String?) onImageSelected) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // Pour l'instant, on utilise le chemin local de l'image
        // Dans une vraie app, il faudrait uploader l'image vers un serveur
        onImageSelected('file://${image.path}');
        
        // Afficher un message d'information
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo prise avec la caméra'),
              backgroundColor: AppTheme.successColor,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la prise de photo: $e'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showPredefinedImagesDialog(Function(String?) onImageSelected) {
    final predefinedImages = [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
      'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=400',
      'https://images.unsplash.com/photo-1515378960530-7c0da6231fb1?w=400',
      'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=400',
      'https://images.unsplash.com/photo-1544725176-7c40e5a71c5e?w=400',
      'https://images.unsplash.com/photo-1556075798-4825dfaaf498?w=400',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2D3A),
        title: const Text(
          'Images prédéfinies',
          style: TextStyle(color: AppTheme.white100),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: predefinedImages.length,
            itemBuilder: (context, index) {
              final imageUrl = predefinedImages[index];
              return GestureDetector(
                onTap: () {
                  onImageSelected(imageUrl);
                  Navigator.pop(context);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF424242),
                      child: const Icon(Icons.broken_image, color: AppTheme.grey400),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: AppTheme.grey500)),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl, double borderRadius) {
    if (imageUrl.startsWith('file://')) {
      // Image locale
      final filePath = imageUrl.substring(7); // Enlever 'file://'
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.file(
          File(filePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFF424242),
            child: const Icon(Icons.broken_image, color: AppTheme.grey400),
          ),
        ),
      );
    } else {
      // Image réseau
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: const Color(0xFF424242),
            child: const Icon(Icons.broken_image, color: AppTheme.grey400),
          ),
        ),
      );
    }
  }

  ImageProvider _getImageProvider(String imageUrl) {
    if (imageUrl.startsWith('file://')) {
      final filePath = imageUrl.substring(7); // Enlever 'file://'
      return FileImage(File(filePath));
    } else {
      return NetworkImage(imageUrl);
    }
  }

  Widget _buildActionPreview(String title, String iconName, int backgroundColor, int? iconColor, int? textColor, String? backgroundImage, bool showIcon) {
    final bgColor = Color(backgroundColor);
    
    // Calcul automatique des couleurs si non spécifiées
    Color finalIconColor;
    Color finalTextColor;
    
    if (iconColor != null) {
      finalIconColor = Color(iconColor);
    } else {
      // Auto: blanc sur fond sombre, noir sur fond clair
      final luminance = bgColor.computeLuminance();
      finalIconColor = luminance > 0.5 ? Colors.black : Colors.white;
    }
    
    if (textColor != null) {
      finalTextColor = Color(textColor);
    } else {
      // Auto: contraste optimal
      final luminance = bgColor.computeLuminance();
      finalTextColor = luminance > 0.5 ? Colors.black : Colors.white;
    }
    
    return Container(
      width: 150,
      height: 100,
      decoration: BoxDecoration(
        color: backgroundImage == null ? bgColor : null,
        image: backgroundImage != null ? DecorationImage(
          image: _getImageProvider(backgroundImage),
          fit: BoxFit.cover,
          onError: (exception, stackTrace) {
            // En cas d'erreur, utiliser la couleur de fond
          },
        ) : null,
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
              _getIconData(iconName),
              color: finalIconColor,
              size: 24,
            ),
            const SizedBox(height: 8),
          ],
          Text(
            title,
            style: TextStyle(
              color: finalTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

}
