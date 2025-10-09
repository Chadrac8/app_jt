import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // unused
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
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D29),
      appBar: AppBar(
        title: const Text(
          'Configuration Dashboard',
          style: TextStyle(color: AppTheme.white100),
        ),
        backgroundColor: const Color(0xFF1A1D29),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.white100),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white100),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _saveConfiguration,
              icon: const Icon(Icons.save),
              tooltip: 'Sauvegarder',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.blueStandard,
          labelColor: AppTheme.white100,
          unselectedLabelColor: AppTheme.grey500,
          tabs: const [
            Tab(text: 'Couverture'),
            Tab(text: 'Live'),
            Tab(text: 'Pain quotidien'),
            Tab(text: 'Prédication'),
            Tab(text: 'Événements'),
            Tab(text: 'Actions'),
            Tab(text: 'Contact'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white100),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCoverTab(),
                _buildLiveTab(),
                _buildDailyBreadTab(),
                _buildSermonTab(),
                _buildEventsTab(),
                _buildQuickActionsTab(),
                _buildContactTab(),
              ],
            ),
    );
  }

  Widget _buildCoverTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Configuration de la couverture'),
          const SizedBox(height: AppTheme.space20),
          
          _buildTextField(
            controller: _coverTitleController,
            label: 'Titre de la couverture',
            hint: 'Jubilé Tabernacle',
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          
          _buildTextField(
            controller: _coverSubtitleController,
            label: 'Sous-titre',
            hint: 'Bienvenue dans la maison de Dieu',
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          
          SwitchListTile(
            title: const Text(
              'Utiliser une vidéo de couverture',
              style: TextStyle(color: AppTheme.white100),
            ),
            value: _useVideo,
            onChanged: (value) => setState(() => _useVideo = value),
            activeColor: AppTheme.blueStandard,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          
          if (_useVideo) ...[
            _buildTextField(
              controller: _coverVideoUrlController,
              label: 'URL de la vidéo',
              hint: 'https://example.com/video.mp4',
            ),
            const SizedBox(height: AppTheme.space12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickAndUploadVideo,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Sélectionner une vidéo'),
                ),
                const SizedBox(width: AppTheme.space12),
                if (_coverVideoUrl != null && _coverVideoUrl!.isNotEmpty)
                  Expanded(
                    child: Text(
                      'Vidéo sélectionnée',
                      style: const TextStyle(color: AppTheme.grey500),
                    ),
                  ),
              ],
            ),
          ] else ...[
            _buildTextField(
              controller: _coverImageUrlController,
              label: 'URL de l\'image de couverture',
              hint: 'https://example.com/image.jpg',
            ),
            const SizedBox(height: AppTheme.space12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickAndUploadImages,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Sélectionner des images'),
                ),
                const SizedBox(width: AppTheme.space12),
                ElevatedButton.icon(
                  onPressed: _clearCoverImages,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Effacer toutes'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.redStandard),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            _buildCoverThumbnails(),
          ],
          
          const SizedBox(height: AppTheme.space20),
          _buildPreviewButton('Prévisualiser la couverture'),
        ],
      ),
    );
  }

  Widget _buildLiveTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Configuration du live'),
          const SizedBox(height: AppTheme.space20),
          
          SwitchListTile(
            title: const Text(
              'Activer la section live',
              style: TextStyle(color: AppTheme.white100),
            ),
            value: _isLiveActive,
            onChanged: (value) => setState(() => _isLiveActive = value),
            activeColor: AppTheme.blueStandard,
          ),
          
          if (_isLiveActive) ...[
            const SizedBox(height: AppTheme.spaceMedium),
            
            _buildTextField(
              controller: _liveDescriptionController,
              label: 'Description du live',
              hint: 'Prochain culte dans',
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            _buildTextField(
              controller: _liveUrlController,
              label: 'URL du live stream',
              hint: 'https://youtube.com/watch?v=...',
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            Card(
              color: const Color(0xFF2A2D3A),
              child: ListTile(
                title: const Text(
                  'Date et heure du prochain live',
                  style: TextStyle(color: AppTheme.white100),
                ),
                subtitle: Text(
                  _liveDateTime?.toString() ?? 'Aucune date sélectionnée',
                  style: const TextStyle(color: AppTheme.grey500),
                ),
                trailing: const Icon(Icons.calendar_today, color: AppTheme.white100),
                onTap: _selectLiveDateTime,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDailyBreadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Configuration du pain quotidien'),
          const SizedBox(height: AppTheme.space20),
          
          SwitchListTile(
            title: const Text(
              'Activer le pain quotidien',
              style: TextStyle(color: AppTheme.white100),
            ),
            value: _isDailyBreadActive,
            onChanged: (value) => setState(() => _isDailyBreadActive = value),
            activeColor: AppTheme.blueStandard,
          ),
          
          if (_isDailyBreadActive) ...[
            const SizedBox(height: AppTheme.spaceMedium),
            
            _buildTextField(
              controller: _dailyBreadTitleController,
              label: 'Titre',
              hint: 'Pain quotidien',
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            _buildTextField(
              controller: _dailyBreadVerseController,
              label: 'Verset du jour',
              hint: 'Car l\'Éternel, ton Dieu, t\'a béni...',
              maxLines: 3,
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            _buildTextField(
              controller: _dailyBreadReferenceController,
              label: 'Référence biblique',
              hint: 'Deutéronome 2:7',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSermonTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Configuration de la dernière prédication'),
          const SizedBox(height: AppTheme.space20),
          
          SwitchListTile(
            title: const Text(
              'Afficher la dernière prédication',
              style: TextStyle(color: AppTheme.white100),
            ),
            value: _isLastSermonActive,
            onChanged: (value) => setState(() => _isLastSermonActive = value),
            activeColor: AppTheme.blueStandard,
          ),
          
          if (_isLastSermonActive) ...[
            const SizedBox(height: AppTheme.spaceMedium),
            
            _buildTextField(
              controller: _sermonTitleController,
              label: 'Titre de la prédication',
              hint: 'La grâce de Dieu',
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            _buildTextField(
              controller: _sermonPreacherController,
              label: 'Prédicateur',
              hint: 'Pasteur Jean-Baptiste',
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            _buildTextField(
              controller: _sermonDurationController,
              label: 'Durée',
              hint: '45 min',
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            _buildTextField(
              controller: _sermonThumbnailController,
              label: 'URL de la miniature',
              hint: 'https://example.com/thumbnail.jpg',
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            _buildTextField(
              controller: _sermonUrlController,
              label: 'URL de la prédication',
              hint: 'https://youtube.com/watch?v=...',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Configuration des événements'),
          const SizedBox(height: AppTheme.space20),
          
          SwitchListTile(
            title: const Text(
              'Afficher les événements',
              style: TextStyle(color: AppTheme.white100),
            ),
            value: _areEventsActive,
            onChanged: (value) => setState(() => _areEventsActive = value),
            activeColor: AppTheme.blueStandard,
          ),
          
          if (_areEventsActive) ...[
            const SizedBox(height: AppTheme.space20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Événements à venir',
                  style: TextStyle(
                    color: AppTheme.white100,
                    fontSize: AppTheme.fontSize18,
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addEvent,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.blueStandard,
                    foregroundColor: AppTheme.white100,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            if (_events.isEmpty)
              const Card(
                color: Color(0xFF2A2D3A),
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.space20),
                  child: Center(
                    child: Text(
                      'Aucun événement configuré',
                      style: TextStyle(color: AppTheme.grey500),
                    ),
                  ),
                ),
              )
            else
              ..._events.asMap().entries.map((entry) => _buildEventCard(entry.key, entry.value)),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Configuration des actions rapides'),
          const SizedBox(height: AppTheme.space20),
          
          SwitchListTile(
            title: const Text(
              'Afficher les actions rapides',
              style: TextStyle(color: AppTheme.white100),
            ),
            value: _areQuickActionsActive,
            onChanged: (value) => setState(() => _areQuickActionsActive = value),
            activeColor: AppTheme.blueStandard,
          ),
          
          if (_areQuickActionsActive) ...[
            const SizedBox(height: AppTheme.space20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Actions disponibles',
                  style: TextStyle(
                    color: AppTheme.white100,
                    fontSize: AppTheme.fontSize18,
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addQuickAction,
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.blueStandard,
                    foregroundColor: AppTheme.white100,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            if (_quickActions.isEmpty)
              const Card(
                color: Color(0xFF2A2D3A),
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.space20),
                  child: Center(
                    child: Text(
                      'Aucune action configurée',
                      style: TextStyle(color: AppTheme.grey500),
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 400,
                child: ReorderableListView(
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
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: _buildQuickActionCard(i, _quickActions[i]),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Configuration des contacts'),
          const SizedBox(height: AppTheme.space20),
          
          SwitchListTile(
            title: const Text(
              'Afficher la section contact',
              style: TextStyle(color: AppTheme.white100),
            ),
            value: _isContactActive,
            onChanged: (value) => setState(() => _isContactActive = value),
            activeColor: AppTheme.blueStandard,
          ),
          
          if (_isContactActive) ...[
            const SizedBox(height: AppTheme.spaceMedium),
            
            _buildTextField(
              controller: _contactEmailController,
              label: 'Email',
              hint: 'contact@jubiletabernacle.org',
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            _buildTextField(
              controller: _contactPhoneController,
              label: 'Téléphone',
              hint: '+33 6 77 45 72 78',
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            _buildTextField(
              controller: _contactWhatsAppController,
              label: 'WhatsApp',
              hint: '+33 6 77 45 72 78',
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            
            _buildTextField(
              controller: _contactAddressController,
              label: 'Adresse',
              hint: 'Jubilé Tabernacle\n124 bis rue de l\'Épidème\n59200 Tourcoing',
              maxLines: 3,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.white100,
        fontSize: AppTheme.fontSize20,
        fontWeight: AppTheme.fontBold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppTheme.white100),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppTheme.grey500),
        hintStyle: const TextStyle(color: AppTheme.grey500),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.grey500),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.grey500),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.blueStandard),
        ),
        filled: true,
        fillColor: const Color(0xFF2A2D3A),
      ),
    );
  }

  Widget _buildPreviewButton(String text) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showPreview(),
        icon: const Icon(Icons.preview),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.grey700,
          foregroundColor: AppTheme.white100,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
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

  void _showPreview() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de prévisualisation bientôt disponible'),
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
  coverVideoUrl: _coverVideoUrl ?? _coverVideoUrlController.text,
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
        setState(() => _coverVideoUrl = url);
        _coverVideoUrlController.text = url;
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

}
