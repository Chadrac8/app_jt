import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/event_model.dart';
import '../services/events_firebase_service.dart';
import '../auth/auth_service.dart';
import '../../theme.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class MemberEventDetailPage extends StatefulWidget {
  final EventModel event;

  const MemberEventDetailPage({
    super.key,
    required this.event,
  });

  @override
  State<MemberEventDetailPage> createState() => _MemberEventDetailPageState();
}

class _MemberEventDetailPageState extends State<MemberEventDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  EventRegistrationModel? _userRegistration;
  bool _isLoading = true;
  bool _isRegistering = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _loadUserRegistration();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRegistration() async {
    try {
      final user = AuthService.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final registrations = await EventsFirebaseService.getEventRegistrationsStream(widget.event.id)
          .first
          .timeout(const Duration(seconds: 10));

      final userRegistration = registrations
          .where((r) => r.personId == user.uid)
          .isNotEmpty
          ? registrations.firstWhere((r) => r.personId == user.uid)
          : null;

      if (mounted) {
        setState(() {
          _userRegistration = userRegistration;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur chargement inscription: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _registerForEvent() async {
    if (_isRegistering) return;
    
    setState(() => _isRegistering = true);
    
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      final registration = EventRegistrationModel(
        id: '',
        eventId: widget.event.id,
        personId: user.uid,
        firstName: user.displayName?.split(' ').first ?? 'Prénom',
        lastName: user.displayName?.split(' ').last ?? 'Nom',
        email: user.email ?? '',
        registrationDate: DateTime.now(),
      );

      await EventsFirebaseService.createRegistration(registration);
      await _loadUserRegistration(); // Recharger les données

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inscription à "${widget.event.title}" confirmée'),
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
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }

  Future<void> _unregisterFromEvent() async {
    if (_userRegistration == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler l\'inscription'),
        content: Text(
          'Voulez-vous vraiment annuler votre inscription à "${widget.event.title}" ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await EventsFirebaseService.cancelRegistration(_userRegistration!.id);
        await _loadUserRegistration(); // Recharger les données

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inscription annulée avec succès'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'annulation : $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _addToCalendar() async {
    try {
      final event = widget.event;
      final startDate = event.startDate;
      final endDate = event.endDate ?? startDate.add(const Duration(hours: 2));
      
      // Format des dates pour le calendrier (format ISO 8601)
      final startDateFormatted = DateFormat('yyyyMMddTHHmmss').format(startDate);
      final endDateFormatted = DateFormat('yyyyMMddTHHmmss').format(endDate);
      
      // URL pour Google Calendar
      final googleCalendarUrl = Uri.parse(
        'https://calendar.google.com/calendar/render?action=TEMPLATE'
        '&text=${Uri.encodeComponent(event.title)}'
        '&dates=$startDateFormatted/$endDateFormatted'
        '&details=${Uri.encodeComponent(event.description)}'
        '&location=${Uri.encodeComponent(event.location)}'
        '&sf=true&output=xml'
      );

      if (await canLaunchUrl(googleCalendarUrl)) {
        await launchUrl(googleCalendarUrl, mode: LaunchMode.externalApplication);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Calendrier ouvert pour ajouter l\'événement'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } else {
        // Fallback : créer un fichier ICS ou copier les informations
        await _copyEventInfoToClipboard();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'ajout au calendrier : $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _copyEventInfoToClipboard() async {
    final event = widget.event;
    final startDate = DateFormat('dd/MM/yyyy à HH:mm').format(event.startDate);
    final endDate = event.endDate != null 
        ? DateFormat('dd/MM/yyyy à HH:mm').format(event.endDate!)
        : null;
    
    final eventInfo = '''
📅 ${event.title}
🏷️ ${event.typeLabel}
📍 ${event.location}
🕐 $startDate${endDate != null ? ' - $endDate' : ''}

${event.description.isNotEmpty ? '📝 ${event.description}' : ''}
''';

    await Clipboard.setData(ClipboardData(text: eventInfo.trim()));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informations de l\'événement copiées dans le presse-papier'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _shareEvent() async {
    try {
      final event = widget.event;
      final startDate = DateFormat('dd/MM/yyyy à HH:mm').format(event.startDate);
      final endDate = event.endDate != null 
          ? DateFormat('dd/MM/yyyy à HH:mm').format(event.endDate!)
          : null;
      
      final shareText = '''
🎉 ${event.title}

📅 ${event.typeLabel}
📍 ${event.location}
🕐 $startDate${endDate != null ? ' - $endDate' : ''}

${event.description.isNotEmpty ? event.description : 'Rejoignez-nous pour cet événement !'}

#JubileTabernacle #Événement
''';

      await Share.share(
        shareText.trim(),
        subject: event.title,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du partage : $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventColor = _getEventColor(widget.event.type);
    final isUpcoming = widget.event.startDate.isAfter(DateTime.now());
    final isRegistrationOpen = widget.event.isRegistrationEnabled &&
        (widget.event.closeDate == null || widget.event.closeDate!.isAfter(DateTime.now()));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                slivers: [
                  _buildSliverAppBar(eventColor),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spaceMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEventHeader(),
                          const SizedBox(height: AppTheme.spaceLarge),
                          _buildEventDetails(),
                          const SizedBox(height: AppTheme.spaceLarge),
                          _buildQuickActions(),
                          const SizedBox(height: AppTheme.spaceLarge),
                          _buildEventDescription(),
                          const SizedBox(height: AppTheme.spaceLarge),
                          if (_userRegistration != null)
                            _buildRegistrationStatus()
                          else if (isRegistrationOpen && isUpcoming)
                            _buildRegistrationCard(),
                          const SizedBox(height: 100), // Space for FAB
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: _buildFloatingActionButton(isUpcoming, isRegistrationOpen),
    );
  }

  Widget _buildSliverAppBar(Color eventColor) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: eventColor,
      foregroundColor: AppTheme.white100,
      actions: [
        // Bouton Ajouter au calendrier
        IconButton(
          onPressed: _addToCalendar,
          icon: const Icon(Icons.calendar_today),
          tooltip: 'Ajouter au calendrier',
        ),
        // Bouton Partager
        IconButton(
          onPressed: _shareEvent,
          icon: const Icon(Icons.share),
          tooltip: 'Partager',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image de l'événement
            _buildEventImage(),
            // Overlay dégradé
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    eventColor.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventImage() {
    if (widget.event.imageUrl?.isNotEmpty == true) {
      return CachedNetworkImage(
        imageUrl: widget.event.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: _getEventColor(widget.event.type).withOpacity(0.3),
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.white100),
          ),
        ),
        errorWidget: (context, url, error) => _buildDefaultEventImage(),
      );
    } else {
      return _buildDefaultEventImage();
    }
  }

  Widget _buildDefaultEventImage() {
    final eventColor = _getEventColor(widget.event.type);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            eventColor,
            eventColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getEventIcon(widget.event.type),
          size: 80,
          color: AppTheme.white100.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildEventHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type d'événement
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getEventColor(widget.event.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            border: Border.all(
              color: _getEventColor(widget.event.type).withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getEventIcon(widget.event.type),
                size: 16,
                color: _getEventColor(widget.event.type),
              ),
              const SizedBox(width: AppTheme.spaceXSmall),
              Text(
                widget.event.typeLabel,
                style: TextStyle(
                  color: _getEventColor(widget.event.type),
                  fontWeight: AppTheme.fontSemiBold,
                  fontSize: AppTheme.fontSize12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        
        // Titre
        Text(
          widget.event.title,
          style: const TextStyle(
            fontSize: AppTheme.fontSize28,
            fontWeight: AppTheme.fontBold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEventDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          children: [
            _buildDetailRow(
              Icons.access_time,
              'Date et heure',
              _formatEventDateTime(),
            ),
            const Divider(height: 24),
            _buildDetailRow(
              Icons.location_on,
              'Lieu',
              widget.event.location,
            ),
            if (widget.event.maxParticipants != null) ...[
              const Divider(height: 24),
              _buildDetailRow(
                Icons.people,
                'Participants',
                'Maximum ${widget.event.maxParticipants} personnes',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spaceSmall),
          decoration: BoxDecoration(
            color: _getEventColor(widget.event.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(
            icon,
            size: 20,
            color: _getEventColor(widget.event.type),
          ),
        ),
        const SizedBox(width: AppTheme.spaceMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXSmall),
              Text(
                value,
                style: const TextStyle(
                  fontSize: AppTheme.fontSize16,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventDescription() {
    if (widget.event.description.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.description,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: AppTheme.fontSize18,
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            Text(
              widget.event.description,
              style: const TextStyle(
                fontSize: AppTheme.fontSize16,
                color: AppTheme.textPrimaryColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: AppTheme.spaceSmall),
                Text(
                  'Actions rapides',
                  style: TextStyle(
                    fontSize: AppTheme.fontSize18,
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addToCalendar,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Ajouter au calendrier'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getEventColor(widget.event.type),
                      foregroundColor: AppTheme.white100,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _shareEvent,
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Partager'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _getEventColor(widget.event.type),
                      side: BorderSide(color: _getEventColor(widget.event.type)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationStatus() {
    final registration = _userRegistration!;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    if (registration.isCancelled) {
      statusColor = AppTheme.errorColor;
      statusIcon = Icons.cancel;
      statusText = 'Inscription annulée';
    } else if (registration.isConfirmed) {
      statusColor = AppTheme.successColor;
      statusIcon = Icons.check_circle;
      statusText = 'Inscription confirmée';
    } else {
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.access_time;
      statusText = 'En attente de confirmation';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Votre inscription',
                        style: TextStyle(
                          fontSize: AppTheme.fontSize14,
                          fontWeight: AppTheme.fontSemiBold,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spaceXSmall),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: AppTheme.fontSize18,
                          fontWeight: AppTheme.fontBold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Inscrit le ${DateFormat('dd/MM/yyyy à HH:mm').format(registration.registrationDate)}',
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: AppTheme.fontSize14,
              ),
            ),
            if (widget.event.startDate.isAfter(DateTime.now()) && !registration.isCancelled) ...[
              const SizedBox(height: AppTheme.spaceMedium),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _unregisterFromEvent,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Se désinscrire'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: BorderSide(color: AppTheme.errorColor),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: _getEventColor(widget.event.type).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add,
                    color: _getEventColor(widget.event.type),
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Participer',
                        style: TextStyle(
                          fontSize: AppTheme.fontSize18,
                          fontWeight: AppTheme.fontBold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: AppTheme.spaceXSmall),
                      Text(
                        'Inscrivez-vous pour participer à cet événement',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isRegistering ? null : _registerForEvent,
                icon: _isRegistering
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white100),
                        ),
                      )
                    : const Icon(Icons.add),
                label: Text(_isRegistering ? 'Inscription...' : 'S\'inscrire'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getEventColor(widget.event.type),
                  foregroundColor: AppTheme.white100,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(bool isUpcoming, bool isRegistrationOpen) {
    if (!isUpcoming) return null;

    if (_userRegistration != null && !_userRegistration!.isCancelled) {
      return FloatingActionButton.extended(
        onPressed: _unregisterFromEvent,
        backgroundColor: AppTheme.errorColor,
        foregroundColor: AppTheme.white100,
        icon: const Icon(Icons.cancel),
        label: const Text('Se désinscrire'),
      );
    } else if (isRegistrationOpen) {
      return FloatingActionButton.extended(
        onPressed: _isRegistering ? null : _registerForEvent,
        backgroundColor: _getEventColor(widget.event.type),
        foregroundColor: AppTheme.white100,
        icon: _isRegistering
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white100),
                ),
              )
            : const Icon(Icons.add),
        label: Text(_isRegistering ? 'Inscription...' : 'S\'inscrire'),
      );
    }

    return null;
  }

  String _formatEventDateTime() {
    final startDate = widget.event.startDate;
    final endDate = widget.event.endDate;
    
    final dateFormat = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm', 'fr_FR');
    
    String result = '${dateFormat.format(startDate)} à ${timeFormat.format(startDate)}';
    
    if (endDate != null) {
      if (DateFormat('yyyy-MM-dd').format(startDate) == DateFormat('yyyy-MM-dd').format(endDate)) {
        // Même jour
        result += ' - ${timeFormat.format(endDate)}';
      } else {
        // Jours différents
        result += '\nJusqu\'au ${dateFormat.format(endDate)} à ${timeFormat.format(endDate)}';
      }
    }
    
    return result;
  }

  Color _getEventColor(String type) {
    switch (type) {
      case 'celebration':
        return const Color(0xFF4CAF50);
      case 'bapteme':
        return const Color(0xFF2196F3);
      case 'formation':
        return const Color(0xFF9C27B0);
      case 'conference':
        return const Color(0xFFFF9800);
      case 'communion':
        return const Color(0xFFE91E63);
      case 'service':
        return const Color(0xFF795548);
      case 'evenement_special':
        return const Color(0xFFFFEB3B);
      case 'reunion':
        return const Color(0xFF607D8B);
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getEventIcon(String type) {
    switch (type) {
      case 'celebration':
        return Icons.celebration;
      case 'bapteme':
        return Icons.water_drop;
      case 'formation':
        return Icons.school;
      case 'conference':
        return Icons.mic;
      case 'communion':
        return Icons.dining;
      case 'service':
        return Icons.volunteer_activism;
      case 'evenement_special':
        return Icons.star;
      case 'reunion':
        return Icons.group;
      default:
        return Icons.event;
    }
  }
}
