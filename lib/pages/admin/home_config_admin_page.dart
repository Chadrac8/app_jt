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
      case 'favorite_rounded':
        return Icons.favorite_rounded;
      case 'menu_book_rounded':
        return Icons.menu_book_rounded;
      case 'volunteer_activism_rounded':
        return Icons.volunteer_activism_rounded;
      case 'card_giftcard_rounded':
        return Icons.card_giftcard_rounded;
      case 'church':
        return Icons.church;
      case 'prayer_times':
        return Icons.schedule;
      case 'group':
        return Icons.group;
      case 'music_note':
        return Icons.music_note;
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

    final availableIcons = [
      {'name': 'favorite_rounded', 'icon': Icons.favorite_rounded, 'label': 'Cœur'},
      {'name': 'menu_book_rounded', 'icon': Icons.menu_book_rounded, 'label': 'Livre'},
      {'name': 'volunteer_activism_rounded', 'icon': Icons.volunteer_activism_rounded, 'label': 'Prière'},
      {'name': 'card_giftcard_rounded', 'icon': Icons.card_giftcard_rounded, 'label': 'Don'},
      {'name': 'church', 'icon': Icons.church, 'label': 'Église'},
      {'name': 'group', 'icon': Icons.group, 'label': 'Groupe'},
      {'name': 'music_note', 'icon': Icons.music_note, 'label': 'Musique'},
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
                
                // Sélection de couleur
                const Text(
                  'Couleur',
                  style: TextStyle(color: AppTheme.white100, fontSize: AppTheme.fontSize16),
                ),
                const SizedBox(height: AppTheme.space12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableColors.map((colorData) {
                    final isSelected = selectedColor == colorData['color'];
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = colorData['color'] as int),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(colorData['color'] as int),
                          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                          border: isSelected ? Border.all(color: AppTheme.white100, width: 3) : null,
                        ),
                      ),
                    );
                  }).toList(),
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
                  'color': selectedColor,
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

}
