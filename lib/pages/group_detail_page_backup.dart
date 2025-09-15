import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../models/group_model.dart';
import '../models/group_statistics.dart';
// import '../models/person_model.dart';
import '../services/groups_firebase_service.dart';
// import '../services/firebase_service.dart';
import '../widgets/group_members_list.dart';
import '../widgets/group_meetings_list.dart';
import '../widgets/group_member_attendance_stats.dart';
import 'group_form_page.dart';
import 'group_meeting_page.dart';
import 'group_attendance_stats_page.dart';
import '../theme.dart';


class GroupDetailPage extends StatefulWidget {
  final GroupModel group;

  const GroupDetailPage({
    super.key,
    required this.group,
  });

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> with TickerProviderStateMixin {

  IconData _getResourceIcon(String type) {
    switch (type) {
      case 'file':
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
        return Icons.description;
      case 'excel':
        return Icons.table_chart;
      case 'image':
        return Icons.image;
      case 'audio':
        return Icons.audiotrack;
      case 'media':
      case 'youtube':
        return Icons.play_circle;
      case 'spotify':
        return Icons.music_note;
      case 'photo_gallery':
        return Icons.photo_library;
      case 'video_file':
        return Icons.video_file;
      case 'podcast':
        return Icons.podcasts;
      case 'stream':
        return Icons.live_tv;
      case 'link':
        return Icons.link;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getResourceColor(String type) {
    switch (type) {
      case 'file':
      case 'pdf':
        return Colors.red;
      case 'doc':
        return Colors.blue;
      case 'excel':
        return Colors.green;
      case 'image':
        return Colors.orange;
      case 'audio':
        return Colors.purple;
      case 'media':
      case 'youtube':
        return Colors.red;
      case 'spotify':
        return Colors.green;
      case 'photo_gallery':
        return Colors.orange;
      case 'video_file':
        return Colors.purple;
      case 'podcast':
        return Colors.indigo;
      case 'stream':
        return Colors.teal;
      case 'link':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  GroupModel? _currentGroup;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
    _currentGroup = widget.group;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _refreshGroupData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final updatedGroup = await GroupsFirebaseService.getGroup(widget.group.id);
      if (updatedGroup != null) {
        setState(() {
          _currentGroup = updatedGroup;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du rafraîchissement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _editGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupFormPage(group: _currentGroup),
      ),
    );
    
    if (result == true) {
      await _refreshGroupData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Groupe mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _launchMeetingLink() async {
    if (_currentGroup?.meetingLink != null) {
      final uri = Uri.parse(_currentGroup!.meetingLink!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _toggleActiveStatus() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final updatedGroup = _currentGroup!.copyWith(
        isActive: !_currentGroup!.isActive,
        updatedAt: DateTime.now(),
      );
      
      await GroupsFirebaseService.updateGroup(updatedGroup);
      
      setState(() {
        _currentGroup = updatedGroup;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updatedGroup.isActive 
                  ? 'Groupe réactivé'
                  : 'Groupe désactivé',
            ),
            backgroundColor: updatedGroup.isActive ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _takeAttendance() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupMeetingPage(group: _currentGroup!),
      ),
    );
    
    if (result == true) {
      await _refreshGroupData();
    }
  }

  Color get _groupColor => Color(int.parse(_currentGroup!.color.replaceFirst('#', '0xFF')));

  Widget _buildGroupImage() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _groupColor.withOpacity(0.1),
        boxShadow: [
          BoxShadow(
            color: _groupColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _currentGroup!.groupImageUrl != null && _currentGroup!.groupImageUrl!.isNotEmpty
            ? (_currentGroup!.groupImageUrl!.startsWith('data:image')
                ? Image.memory(
                    base64Decode(_currentGroup!.groupImageUrl!.split(',').last),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildFallbackImage(),
                  )
                : CachedNetworkImage(
                    imageUrl: _currentGroup!.groupImageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildLoadingImage(),
                    errorWidget: (context, url, error) => _buildFallbackImage(),
                  ))
            : _buildFallbackImage(),
      ),
    );
  }

  Widget _buildLoadingImage() {
    return Container(
      color: _groupColor.withOpacity(0.1),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(_groupColor),
        ),
      ),
    );
  }

  Widget _buildFallbackImage() {
    IconData groupIcon;
    switch (_currentGroup!.type.toLowerCase()) {
      case 'prayer':
      case 'prière':
        groupIcon = Icons.favorite;
        break;
      case 'youth':
      case 'jeunesse':
        groupIcon = Icons.sports_soccer;
        break;
      case 'bible study':
      case 'étude biblique':
        groupIcon = Icons.menu_book;
        break;
      case 'worship':
      case 'louange':
        groupIcon = Icons.music_note;
        break;
      case 'leadership':
        groupIcon = Icons.account_tree;
        break;
      default:
        groupIcon = Icons.groups;
    }

    return Container(
      color: _groupColor.withOpacity(0.1),
      child: Center(
        child: Icon(
          groupIcon,
          size: 48,
          color: _groupColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentGroup == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        extendBodyBehindAppBar: true,
        body: CustomScrollView(
          slivers: [
            // Modern Header with Hero Image
            _buildModernHeader(),
            
            // Content Sections
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Quick Actions Bar
                  _buildQuickActionsBar(),
                  
                  // Stats Cards
                  _buildStatsCards(),
                  
                  // Tabbed Content
                  _buildTabbedContent(),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _buildModernFAB(),
      ),
    );
  }

  /// Header moderne avec image et informations principales
  Widget _buildModernHeader() {
    return SliverAppBar(
      expandedHeight: 320,
      floating: false,
      pinned: true,
      backgroundColor: _groupColor,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: [
        IconButton(
          onPressed: _editGroup,
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Modifier',
        ),
        PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'toggle_status':
                await _toggleActiveStatus();
                break;
              case 'duplicate':
                // TODO: Implement duplicate
                break;
              case 'export':
                // TODO: Implement export
                break;
              case 'attendance_stats':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupAttendanceStatsPage(
                      group: _currentGroup!,
                    ),
                  ),
                );
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'toggle_status',
              child: Row(
                children: [
                  Icon(
                    _currentGroup!.isActive ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(_currentGroup!.isActive ? 'Désactiver' : 'Activer'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Dupliquer'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Exporter'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'attendance_stats',
              child: Row(
                children: [
                  Icon(Icons.analytics_outlined, size: 20),
                  SizedBox(width: 12),
                  Text('Statistiques détaillées'),
                ],
              ),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _groupColor,
                _groupColor.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Image du groupe avec design moderne
                  Hero(
                    tag: 'group_image_${_currentGroup!.id}',
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: _buildGroupImage(),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Nom du groupe
                  Text(
                    _currentGroup!.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Type et statut
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getGroupIcon(),
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _currentGroup!.type,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!_currentGroup!.isActive) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'INACTIF',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Barre d'actions rapides
  Widget _buildQuickActionsBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionButton(
              icon: Icons.how_to_reg_outlined,
              label: 'Présence',
              onTap: _takeAttendance,
              color: _groupColor,
            ),
          ),
          Expanded(
            child: _buildQuickActionButton(
              icon: Icons.event_note_outlined,
              label: 'Réunion',
              onTap: () => _createMeeting(),
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          if (_currentGroup!.meetingLink != null && _currentGroup!.meetingLink!.isNotEmpty)
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.video_call_outlined,
                label: 'Rejoindre',
                onTap: _launchMeetingLink,
                color: Colors.green,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Cartes de statistiques
  Widget _buildStatsCards() {
    return FutureBuilder<GroupStatistics?>(
      future: GroupsFirebaseService.getGroupStatistics(_currentGroup!.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Membres',
                  value: stats.totalMembers.toString(),
                  icon: Icons.group_outlined,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Réunions',
                  value: stats.totalMeetings.toString(),
                  icon: Icons.event_outlined,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Présence',
                  value: '${stats.averageAttendance.toStringAsFixed(0)}%',
                  icon: Icons.trending_up_outlined,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Contenu avec onglets modernisé
  Widget _buildTabbedContent() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Onglets modernisés
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Infos'),
                Tab(text: 'Membres'),
                Tab(text: 'Réunions'),
                Tab(text: 'Ressources'),
                Tab(text: 'Stats'),
              ],
              labelColor: _groupColor,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              indicatorColor: _groupColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          
          // Contenu des onglets
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInformationTab(),
                _buildMembersTab(),
                _buildMeetingsTab(),
                _buildResourcesTab(),
                _buildStatisticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// FAB moderne
  Widget _buildModernFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "attendance",
          onPressed: _takeAttendance,
          backgroundColor: _groupColor,
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.how_to_reg_outlined),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: "meeting",
          onPressed: _createMeeting,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
          elevation: 4,
          icon: const Icon(Icons.event_note_outlined),
          label: const Text('Nouvelle réunion'),
        ),
      ],
    );
  }

  /// Méthode pour créer une réunion
  Future<void> _createMeeting() async {
    final result = await showDialog<GroupMeetingModel>(
      context: context,
      builder: (context) => _CreateMeetingDialog(group: _currentGroup!),
    );

    if (result != null) {
      try {
        await GroupsFirebaseService.createMeeting(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réunion créée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Obtenir l'icône du groupe selon son type
  IconData _getGroupIcon() {
    switch (_currentGroup!.type.toLowerCase()) {
      case 'prayer':
      case 'prière':
        return Icons.favorite_outlined;
      case 'youth':
      case 'jeunesse':
        return Icons.sports_soccer_outlined;
      case 'bible study':
      case 'étude biblique':
        return Icons.menu_book_outlined;
      case 'worship':
      case 'louange':
        return Icons.music_note_outlined;
      case 'leadership':
        return Icons.account_tree_outlined;
      default:
        return Icons.groups_outlined;
    }
  }
  }

  Widget _buildInformationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (_currentGroup!.description.isNotEmpty)
            _buildInfoCard(
              title: 'Description',
              icon: Icons.description,
              children: [
                Text(
                  _currentGroup!.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),

          const SizedBox(height: 16),

          // Schedule Information
          _buildInfoCard(
            title: 'Horaires',
            icon: Icons.schedule,
            children: [
              _buildInfoRow(
                icon: Icons.calendar_today,
                label: 'Fréquence',
                value: _getFrequencyText(_currentGroup!.frequency),
              ),
              _buildInfoRow(
                icon: Icons.access_time,
                label: 'Horaire',
                value: _currentGroup!.scheduleText,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Location Information
          _buildInfoCard(
            title: 'Lieu',
            icon: Icons.location_on,
            children: [
              _buildInfoRow(
                icon: Icons.place,
                label: 'Adresse',
                value: _currentGroup!.location,
              ),
              if (_currentGroup!.meetingLink != null)
                _buildInfoRow(
                  icon: Icons.link,
                  label: 'Lien de réunion',
                  value: 'Cliquer pour ouvrir',
                  onTap: _launchMeetingLink,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Settings Information
          _buildInfoCard(
            title: 'Paramètres',
            icon: Icons.settings,
            children: [
              _buildInfoRow(
                icon: Icons.visibility,
                label: 'Visibilité',
                value: _currentGroup!.isPublic ? 'Public' : 'Privé',
              ),
              _buildInfoRow(
                icon: Icons.palette,
                label: 'Couleur',
                value: '',
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _groupColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Tags
          if (_currentGroup!.tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildTagSection('Tags', _currentGroup!.tags, _groupColor),
          ],

          const SizedBox(height: 100), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    return GroupMembersList(group: _currentGroup!);
  }

  Widget _buildMeetingsTab() {
    return GroupMeetingsList(group: _currentGroup!);
  }

  Widget _buildResourcesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: GroupsFirebaseService.getGroupResourcesStream(_currentGroup!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final resources = snapshot.data ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ressources du groupe',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _groupColor,
                ),
              ),
              const SizedBox(height: 24),
              if (resources.isEmpty)
                const Text('Aucune ressource pour le moment', style: TextStyle(color: Colors.grey)),
              if (resources.isNotEmpty)
                ...resources.map((res) => _buildResourceItem(
                  title: res['title'] ?? '',
                  subtitle: res['description'] ?? res['url'] ?? '',
                  icon: _getResourceIcon(res['type'] ?? ''),
                  color: _getResourceColor(res['type'] ?? ''),
                  onTap: () async {
                    final url = res['url'] as String?;
                    if (url != null && url.isNotEmpty) {
                      final uri = Uri.tryParse(url);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Impossible d\'ouvrir ce lien.')),
                          );
                        }
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Aucune action disponible pour cette ressource.')),
                        );
                      }
                    }
                  },
                  onEditResource: () {
                    _showAddResourceDialog(res['type'] ?? '', initialData: res, resourceId: res['id']);
                  },
                  onDeleteResource: () {
                    _confirmDeleteResource(res['id'], res['title'] ?? '');
                  },
                )),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.add_circle, color: _groupColor, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Actions rapides',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              'Ajouter fichier',
                              Icons.upload_file,
                              Colors.blue,
                              () {
                                _showAddResourceDialog('file');
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildActionButton(
                              'Ajouter média',
                              Icons.video_library,
                              Colors.purple,
                              () {
                                _showAddResourceDialog('media');
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildActionButton(
                              'Ajouter lien',
                              Icons.add_link,
                              Colors.green,
                              () {
                                _showAddResourceDialog('link');
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        );
      },
    );
  }

  // _buildResourceSection removed (legacy, unused)

  Widget _buildResourceItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? onEditResource,
    VoidCallback? onDeleteResource,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
              onSelected: (value) async {
                if (value == 'edit' && onEditResource != null) {
                  onEditResource();
                } else if (value == 'delete' && onDeleteResource != null) {
                  onDeleteResource();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Modifier'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Supprimer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  void _showAddResourceDialog(String type, {Map<String, dynamic>? initialData, String? resourceId}) {
    showDialog(
      context: context,
      builder: (context) => _AddResourceDialog(
        type: type,
        groupColor: _groupColor,
        initialData: initialData,
        onResourceAdded: (resourceData) async {
          try {
            if (resourceId != null) {
              await GroupsFirebaseService.updateGroupResource(_currentGroup!.id, resourceId, resourceData);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${_getResourceTypeLabel(type)} modifié avec succès !'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            } else {
              await GroupsFirebaseService.addGroupResource(_currentGroup!.id, resourceData);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${_getResourceTypeLabel(type)} ajouté avec succès !'),
                    backgroundColor: AppTheme.successColor,
                    action: SnackBarAction(
                      label: 'Voir',
                      textColor: Colors.white,
                      onPressed: () {
                        // TODO: Ouvrir la ressource ajoutée
                      },
                    ),
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur lors de l\'enregistrement de la ressource: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _confirmDeleteResource(String resourceId, String resourceTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la ressource'),
        content: Text('Voulez-vous vraiment supprimer la ressource "$resourceTitle" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await GroupsFirebaseService.deleteGroupResource(_currentGroup!.id, resourceId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ressource supprimée avec succès !'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la suppression: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  String _getResourceTypeLabel(String type) {
    switch (type) {
      case 'file':
        return 'Fichier';
      case 'media':
        return 'Média';
      case 'link':
        return 'Lien';
      default:
        return 'Ressource';
    }
  }

  Widget _buildStatisticsTab() {
    return FutureBuilder<GroupStatisticsModel>(
      future: GroupsFirebaseService.getGroupStatistics(_currentGroup!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur lors du chargement des statistiques',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final stats = snapshot.data!;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Global Statistics Cards
              Text(
                'Vue d\'ensemble',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _groupColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Membres actifs',
                      stats.activeMembers.toString(),
                      Icons.group,
                      _groupColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Réunions',
                      stats.totalMeetings.toString(),
                      Icons.event,
                      Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Présence moy.',
                      '${(stats.averageAttendance * 100).round()}%',
                      Icons.how_to_reg,
                      Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Total membres',
                      stats.totalMembers.toString(),
                      Icons.people,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Individual Member Attendance
              GroupMemberAttendanceStats(
                memberAttendance: stats.memberAttendance.map((key, value) => MapEntry(
                  key,
                  MemberAttendance(
                    personName: value.personName,
                    attendanceRate: value.attendanceRate,
                    consecutiveAbsences: value.consecutiveAbsences,
                    totalMeetings: value.totalMeetings,
                    presentCount: value.presentCount,
                    absentCount: value.absentCount,
                    lastAttendance: value.lastAttendance,
                  ),
                )),
                isExpanded: true,
              ),
              
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _groupColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: _groupColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  if (value.isNotEmpty)
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagSection(String title, List<String> items, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _getFrequencyText(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'weekly':
        return 'Hebdomadaire';
      case 'biweekly':
        return 'Bi-mensuel';
      case 'monthly':
        return 'Mensuel';
      case 'quarterly':
        return 'Trimestriel';
      default:
        return frequency;
    }
  }
}

class _CreateMeetingDialog extends StatefulWidget {
  final GroupModel group;

  const _CreateMeetingDialog({required this.group});

  @override
  State<_CreateMeetingDialog> createState() => _CreateMeetingDialogState();
}

class _CreateMeetingDialogState extends State<_CreateMeetingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    _locationController.text = widget.group.location;
    _titleController.text = 'Réunion du ${_formatDate(DateTime.now())}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _saveMeeting() {
    if (_formKey.currentState!.validate()) {
      final meetingDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final meeting = GroupMeetingModel(
        id: '',
        groupId: widget.group.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        date: meetingDate,
        location: _locationController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      Navigator.pop(context, meeting);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle réunion'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le titre est requis';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optionnelle)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _selectTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Heure',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Lieu',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le lieu est requis';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveMeeting,
          child: const Text('Créer'),
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}


class _AddResourceDialog extends StatefulWidget {
  final String type;
  final Color groupColor;
  final Function(Map<String, dynamic>) onResourceAdded;
  final Map<String, dynamic>? initialData;

  const _AddResourceDialog({
    Key? key,
    required this.type,
    required this.groupColor,
    required this.onResourceAdded,
    this.initialData,
  }) : super(key: key);

  @override
  State<_AddResourceDialog> createState() => _AddResourceDialogState();
}

class _AddResourceDialogState extends State<_AddResourceDialog> {
  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _titleController.text = data['title'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _urlController.text = data['url'] ?? '';
      _selectedFileType = data['fileType'];
      _selectedMediaType = data['mediaType'];
    }
  }
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();
  
  String? _selectedFileType;
  String? _selectedMediaType;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _fileTypes = [
    {'value': 'pdf', 'label': 'Document PDF', 'icon': Icons.picture_as_pdf, 'color': Colors.red},
    {'value': 'doc', 'label': 'Document Word', 'icon': Icons.description, 'color': Colors.blue},
    {'value': 'excel', 'label': 'Feuille Excel', 'icon': Icons.table_chart, 'color': Colors.green},
    {'value': 'image', 'label': 'Image', 'icon': Icons.image, 'color': Colors.orange},
    {'value': 'audio', 'label': 'Fichier audio', 'icon': Icons.audio_file, 'color': Colors.purple},
    {'value': 'other', 'label': 'Autre', 'icon': Icons.insert_drive_file, 'color': Colors.grey},
  ];

  final List<Map<String, dynamic>> _mediaTypes = [
    {'value': 'youtube', 'label': 'Vidéo YouTube', 'icon': Icons.play_circle, 'color': Colors.red},
    {'value': 'spotify', 'label': 'Playlist Spotify', 'icon': Icons.music_note, 'color': Colors.green},
    {'value': 'photo_gallery', 'label': 'Galerie photos', 'icon': Icons.photo_library, 'color': Colors.orange},
    {'value': 'video_file', 'label': 'Fichier vidéo', 'icon': Icons.video_file, 'color': Colors.purple},
    {'value': 'podcast', 'label': 'Podcast', 'icon': Icons.podcasts, 'color': Colors.indigo},
    {'value': 'stream', 'label': 'Diffusion en direct', 'icon': Icons.live_tv, 'color': Colors.teal},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _selectFile() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Implémenter la sélection de fichier
      await Future.delayed(const Duration(seconds: 1)); // Simulation
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fonctionnalité de sélection de fichier à venir'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sélection du fichier: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addResource() {
    if (_formKey.currentState!.validate()) {
      final resourceData = {
        'type': widget.type,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'fileType': _selectedFileType,
        'mediaType': _selectedMediaType,
        'url': _urlController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      widget.onResourceAdded(resourceData);
      Navigator.of(context).pop();
    }
  }

  String get _dialogTitle {
    switch (widget.type) {
      case 'file':
        return 'Ajouter un fichier';
      case 'media':
        return 'Ajouter un média';
      case 'link':
        return 'Ajouter un lien';
      default:
        return 'Ajouter une ressource';
    }
  }

  IconData get _dialogIcon {
    switch (widget.type) {
      case 'file':
        return Icons.upload_file;
      case 'media':
        return Icons.video_library;
      case 'link':
        return Icons.add_link;
      default:
        return Icons.add;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(_dialogIcon, color: widget.groupColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _dialogTitle,
              style: TextStyle(color: widget.groupColor),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Titre *',
                    hintText: _getTitleHint(),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le titre est obligatoire';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Description optionnelle de la ressource',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                
                const SizedBox(height: 16),
                
                // Type spécifique selon la ressource
                if (widget.type == 'file') ..._buildFileFields(),
                if (widget.type == 'media') ..._buildMediaFields(),
                if (widget.type == 'link') ..._buildLinkFields(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addResource,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.groupColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Ajouter'),
        ),
      ],
    );
  }

  String _getTitleHint() {
    switch (widget.type) {
      case 'file':
        return 'Guide d\'étude, Manuel, etc.';
      case 'media':
        return 'Enseignement vidéo, Playlist, etc.';
      case 'link':
        return 'Site web du groupe, Ressource externe, etc.';
      default:
        return 'Nom de la ressource';
    }
  }

  List<Widget> _buildFileFields() {
    return [
      // Type de fichier
      Text(
        'Type de fichier',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _fileTypes.map((fileType) => 
          FilterChip(
            selected: _selectedFileType == fileType['value'],
            onSelected: (selected) {
              setState(() {
                _selectedFileType = selected ? fileType['value'] : null;
              });
            },
            avatar: Icon(
              fileType['icon'],
              size: 18,
              color: _selectedFileType == fileType['value'] 
                  ? Colors.white 
                  : fileType['color'],
            ),
            label: Text(fileType['label']),
            selectedColor: fileType['color'],
            checkmarkColor: Colors.white,
          ),
        ).toList(),
      ),
      
      const SizedBox(height: 16),
      
      // Bouton de sélection de fichier
      SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _isLoading ? null : _selectFile,
          icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.upload_file),
          label: Text(_isLoading ? 'Sélection...' : 'Sélectionner le fichier'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.all(12),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildMediaFields() {
    return [
      // Type de média
      Text(
        'Type de média',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 8),
      
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _mediaTypes.map((mediaType) => 
          FilterChip(
            selected: _selectedMediaType == mediaType['value'],
            onSelected: (selected) {
              setState(() {
                _selectedMediaType = selected ? mediaType['value'] : null;
              });
            },
            avatar: Icon(
              mediaType['icon'],
              size: 18,
              color: _selectedMediaType == mediaType['value'] 
                  ? Colors.white 
                  : mediaType['color'],
            ),
            label: Text(mediaType['label']),
            selectedColor: mediaType['color'],
            checkmarkColor: Colors.white,
          ),
        ).toList(),
      ),
      
      const SizedBox(height: 16),
      
      // URL du média
      TextFormField(
        controller: _urlController,
        decoration: const InputDecoration(
          labelText: 'URL du média *',
          hintText: 'https://youtube.com/watch?v=...',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.link),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'L\'URL est obligatoire pour un média';
          }
          final uri = Uri.tryParse(value);
          if (uri == null || !uri.hasAbsolutePath || (!uri.hasScheme)) {
            return 'Veuillez entrer une URL valide';
          }
          return null;
        },
      ),
    ];
  }

  List<Widget> _buildLinkFields() {
    return [
      // URL du lien
      TextFormField(
        controller: _urlController,
        decoration: const InputDecoration(
          labelText: 'URL *',
          hintText: 'https://exemple.com',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.link),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'L\'URL est obligatoire';
          }
          final uri = Uri.tryParse(value);
          if (uri == null || !uri.hasAbsolutePath || (!uri.hasScheme)) {
            return 'Veuillez entrer une URL valide';
          }
          return null;
        },
      ),
      
      const SizedBox(height: 8),
      
      // Aide pour les URLs
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Vous pouvez ajouter des liens vers des sites web, des documents en ligne, ou des ressources externes.',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}