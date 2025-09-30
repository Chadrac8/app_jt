import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../models/group_model.dart';
import '../services/groups_firebase_service.dart';
import '../auth/auth_service.dart';
import '../../theme.dart';
import 'group_detail_page.dart';

/// Page professionnelle "Mes Groupes" avec design moderne et images de couverture
class MemberGroupsPage extends StatefulWidget {
  const MemberGroupsPage({super.key});

  @override
  State<MemberGroupsPage> createState() => _MemberGroupsPageState();
}

class _MemberGroupsPageState extends State<MemberGroupsPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<GroupModel> _myGroups = [];
  List<GroupModel> _availableGroups = [];
  Map<String, GroupMeetingModel?> _nextMeetings = {};
  bool _isLoading = true;
  String _selectedTab = 'my_groups';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadGroupsData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  Future<void> _loadGroupsData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = AuthService.currentUser;
      if (user == null) return;

      // Charger tous les groupes actifs
      final allGroupsStream = GroupsFirebaseService.getGroupsStream(
        activeOnly: true,
        limit: 100,
      );

      await for (final allGroups in allGroupsStream.take(1)) {
        final myGroups = <GroupModel>[];
        final availableGroups = <GroupModel>[];

        // Vérifier l'appartenance pour chaque groupe
        for (final group in allGroups) {
          final members = await GroupsFirebaseService.getGroupMembersWithPersonData(group.id);
          final isMember = members.any((member) => member.id == user.uid);
          
          if (isMember) {
            myGroups.add(group);
          } else {
            availableGroups.add(group);
          }
        }

        // Charger les prochaines réunions pour mes groupes
        Map<String, GroupMeetingModel?> nextMeetings = {};
        for (final group in myGroups) {
          try {
            final nextMeeting = await GroupsFirebaseService.getNextMeeting(group.id);
            nextMeetings[group.id] = nextMeeting;
          } catch (e) {
            nextMeetings[group.id] = null;
          }
        }

        if (mounted) {
          setState(() {
            _myGroups = myGroups;
            _availableGroups = availableGroups;
            _nextMeetings = nextMeetings;
            _isLoading = false;
          });
        }
        break;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement : $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(
        title: const Text('Mes groupes'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.white100,
        elevation: 1,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadGroupsData,
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Sélecteur d'onglets
              Container(
                color: AppTheme.white100,
                padding: EdgeInsets.only(bottom: 10),
                child: _buildProfessionalTabSelector(),
              ),
              // Contenu
              _isLoading ? _buildLoadingState() : _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfessionalTabSelector() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppTheme.grey100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildProfessionalTabButton(
              'my_groups',
              'Mes Groupes',
              Icons.groups,
            ),
          ),
          Expanded(
            child: _buildProfessionalTabButton(
              'available',
              'Explorer',
              Icons.explore,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalTabButton(String tabId, String title, IconData icon) {
    final isSelected = _selectedTab == tabId;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tabId),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.all(4),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.white100 : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.black100.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.grey600,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.grey600,
                fontWeight: isSelected ? AppTheme.fontSemiBold : AppTheme.fontMedium,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
              strokeWidth: 3,
            ),
            SizedBox(height: 16),
            Text(
              'Chargement de vos groupes...',
              style: TextStyle(
                color: AppTheme.grey600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          SizedBox(height: 24),
          _selectedTab == 'my_groups'
              ? _buildProfessionalMyGroupsList()
              : _buildProfessionalAvailableGroupsList(),
        ],
      ),
    );
  }

  Widget _buildProfessionalMyGroupsList() {
    if (_myGroups.isEmpty) {
      return _buildEmptyMyGroupsState();
    }

    return Column(
      children: _myGroups.map((group) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _buildProfessionalGroupCard(group, isMyGroup: true),
        );
      }).toList(),
    );
  }

  Widget _buildProfessionalAvailableGroupsList() {
    if (_availableGroups.isEmpty) {
      return _buildEmptyAvailableGroupsState();
    }

    return Column(
      children: _availableGroups.map((group) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: _buildProfessionalGroupCard(group, isMyGroup: false),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyMyGroupsState() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.groups_outlined,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Aucun groupe rejoint',
            style: TextStyle(
              fontSize: 20,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.black100.withOpacity(0.87),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Explorez et rejoignez des groupes pour enrichir votre expérience communautaire',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.grey600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() => _selectedTab = 'available'),
            icon: Icon(Icons.explore),
            label: Text('Explorer les groupes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.white100,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAvailableGroupsState() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 48,
              color: AppTheme.secondaryColor,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Aucun groupe disponible',
            style: TextStyle(
              fontSize: 20,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.black100.withOpacity(0.87),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tous les groupes publics ont été rejoints ou aucun nouveau groupe n\'est disponible pour le moment',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.grey600,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalGroupCard(GroupModel group, {required bool isMyGroup}) {
    final groupColor = Color(int.parse(group.color.replaceFirst('#', '0xFF')));
    final nextMeeting = isMyGroup ? _nextMeetings[group.id] : null;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec image de couverture
          _buildGroupHeader(group, groupColor),
          
          // Contenu principal
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (group.description.isNotEmpty) ...[
                  Text(
                    group.description,
                    style: TextStyle(
                      color: AppTheme.grey700,
                      height: 1.4,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 16),
                ],
                
                // Informations pratiques
                _buildGroupInfo(group),
                
                // Prochaine réunion (pour mes groupes)
                if (isMyGroup && nextMeeting != null) ...[
                  SizedBox(height: 16),
                  _buildNextMeetingCard(nextMeeting, group),
                ],
                
                SizedBox(height: 16),
                
                // Actions
                _buildGroupActions(group, isMyGroup, nextMeeting),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(GroupModel group, Color groupColor) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Stack(
        children: [
          // Image de couverture ou dégradé par défaut
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: group.groupImageUrl != null
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        groupColor.withOpacity(0.8),
                        groupColor,
                      ],
                    ),
            ),
            child: group.groupImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: _buildGroupCoverImage(group.groupImageUrl!),
                  )
                : null,
          ),
          
          // Overlay dégradé pour lisibilité
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppTheme.black100.withOpacity(0.7),
                ],
              ),
            ),
          ),
          
          // Informations du groupe
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: TextStyle(
                    color: AppTheme.white100,
                    fontSize: 18,
                    fontWeight: AppTheme.fontBold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: AppTheme.black100.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.white100.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Text(
                    group.type,
                    style: TextStyle(
                      color: groupColor,
                      fontSize: 12,
                      fontWeight: AppTheme.fontSemiBold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCoverImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      // Image base64
      try {
        final bytes = base64Decode(imageUrl.split(',')[1]);
        return Image.memory(
          bytes,
          width: double.infinity,
          height: 120,
          fit: BoxFit.cover,
        );
      } catch (e) {
        return _buildDefaultGroupImage();
      }
    } else {
      // URL d'image
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: double.infinity,
        height: 120,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildImagePlaceholder(),
        errorWidget: (context, url, error) => _buildDefaultGroupImage(),
      );
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 120,
      color: AppTheme.grey200,
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildDefaultGroupImage() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.6),
            AppTheme.secondaryColor.withOpacity(0.4),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.groups,
          size: 40,
          color: AppTheme.white100.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildGroupInfo(GroupModel group) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: 16,
              color: AppTheme.grey600,
            ),
            SizedBox(width: 8),
            Text(
              '${group.dayName} à ${group.time}',
              style: TextStyle(
                color: AppTheme.grey700,
                fontWeight: AppTheme.fontMedium,
                fontSize: 14,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: AppTheme.grey600,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                group.location,
                style: TextStyle(
                  color: AppTheme.grey700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNextMeetingCard(GroupMeetingModel meeting, GroupModel group) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.upcoming,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              SizedBox(width: 8),
              Text(
                'Prochaine réunion',
                style: TextStyle(
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            meeting.title,
            style: TextStyle(
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.black100.withOpacity(0.87),
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            _formatDateTime(meeting.date),
            style: TextStyle(
              color: AppTheme.grey600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupActions(GroupModel group, bool isMyGroup, GroupMeetingModel? nextMeeting) {
    return Row(
      children: [
        if (isMyGroup) ...[
          // Bouton rejoindre réunion
          if (group.meetingLink != null && group.meetingLink!.isNotEmpty)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _launchMeetingLink(group.meetingLink),
                icon: Icon(Icons.video_call, size: 16),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Rejoindre',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.white100,
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  minimumSize: Size(0, 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          if (group.meetingLink != null && group.meetingLink!.isNotEmpty)
            SizedBox(width: 4),
          
          // Bouton signaler absence
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _reportAbsence(group, nextMeeting),
              icon: Icon(Icons.event_busy, size: 16),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Absence',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.grey700,
                side: BorderSide(color: AppTheme.grey300),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                minimumSize: Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          
          SizedBox(width: 4),
          
          // Bouton détails complets (seulement pour les membres)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupDetailPage(group: group),
                ),
              ),
              icon: Icon(Icons.info_outline, size: 16),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Détails',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                minimumSize: Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ] else ...[
          // Bouton rejoindre groupe
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _joinGroup(group),
              icon: Icon(Icons.add, size: 16),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Rejoindre',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.white100,
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                minimumSize: Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          
          SizedBox(width: 4),
          
          // Bouton voir description (pour les non-membres)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showGroupDescription(group),
              icon: Icon(Icons.description_outlined, size: 16),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Description',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.grey700,
                side: BorderSide(color: AppTheme.grey400!),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                minimumSize: Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Méthodes utilitaires
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays == 0) {
      return 'Aujourd\'hui à ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      return 'Demain à ${_formatTime(dateTime)}';
    } else if (difference.inDays < 7) {
      return '${_getDayName(dateTime.weekday)} à ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month} à ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getDayName(int weekday) {
    const days = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    return days[weekday];
  }

  Future<void> _launchMeetingLink(String? link) async {
    if (link == null || link.isEmpty) return;
    
    try {
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Impossible d\'ouvrir le lien'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _reportAbsence(GroupModel group, GroupMeetingModel? meeting) async {
    if (meeting == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aucune réunion programmée pour signaler une absence'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Ici vous pouvez implémenter la logique de signalement d'absence
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Absence signalée pour "${meeting.title}"'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _showGroupDescription(GroupModel group) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppTheme.white100,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Header avec handle
            Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Image de couverture si disponible
            if (group.groupImageUrl != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  child: _buildGroupCoverImage(group.groupImageUrl!),
                ),
              ),
              SizedBox(height: 24),
            ],
            
            // Contenu
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom du groupe
                    Text(
                      group.name,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: AppTheme.fontBold,
                        color: AppTheme.black100.withOpacity(0.87),
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    // Type de groupe
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(int.parse(group.color.replaceFirst('#', '0xFF'))).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                        border: Border.all(
                          color: Color(int.parse(group.color.replaceFirst('#', '0xFF'))).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        group.type,
                        style: TextStyle(
                          color: Color(int.parse(group.color.replaceFirst('#', '0xFF'))),
                          fontWeight: AppTheme.fontSemiBold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    
                    // Informations de base
                    _buildInfoSection('Horaires', '${group.dayName} à ${group.time}', Icons.schedule),
                    SizedBox(height: 16),
                    _buildInfoSection('Lieu', group.location, Icons.location_on),
                    SizedBox(height: 24),
                    
                    // Description
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: AppTheme.fontBold,
                        color: AppTheme.black100.withOpacity(0.87),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      group.description.isNotEmpty 
                        ? group.description
                        : 'Aucune description disponible pour ce groupe.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.grey700,
                        height: 1.6,
                      ),
                    ),
                    SizedBox(height: 32),
                    
                    // Note pour rejoindre
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Rejoignez ce groupe pour accéder aux informations détaillées, aux réunions et aux discussions.',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 14,
                                fontWeight: AppTheme.fontMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.grey50,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppTheme.grey400!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      child: Text(
                        'Fermer',
                        style: TextStyle(
                          color: AppTheme.grey700,
                          fontWeight: AppTheme.fontSemiBold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _joinGroup(group);
                      },
                      icon: Icon(Icons.add, size: 20),
                      label: Text('Rejoindre ce groupe'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.white100,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
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

  Widget _buildInfoSection(String title, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primaryColor,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.grey600,
                  fontWeight: AppTheme.fontMedium,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.black100.withOpacity(0.87),
                  fontWeight: AppTheme.fontSemiBold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _joinGroup(GroupModel group) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      await GroupsFirebaseService.addMemberToGroup(group.id, user.uid, 'member');
      
      setState(() {
        _myGroups.add(group);
        _availableGroups.remove(group);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vous avez rejoint le groupe "${group.name}"'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'inscription : $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
