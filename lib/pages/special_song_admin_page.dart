import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/special_song_reservation_model.dart';
import '../services/special_song_reservation_service.dart';
import '../../theme.dart';

class SpecialSongAdminPage extends StatefulWidget {
  const SpecialSongAdminPage({super.key});

  @override
  State<SpecialSongAdminPage> createState() => _SpecialSongAdminPageState();
}

class _SpecialSongAdminPageState extends State<SpecialSongAdminPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  MonthlyReservationStats? _currentMonthStats;
  List<SpecialSongReservationModel> _allReservations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final currentStats = await SpecialSongReservationService.getMonthlyStats();
      final allReservations = await SpecialSongReservationService.getCurrentMonthReservations();

      setState(() {
        _currentMonthStats = currentStats;
        _allReservations = allReservations;
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.grey50,
      appBar: AppBar(
        toolbarHeight: 56.0, // Hauteur standard Material Design
        title: const Text(
          'Gestion Chants Spéciaux',
          style: TextStyle(
            fontWeight: AppTheme.fontBold,
            color: AppTheme.white100,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.white100),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.white100,
          labelColor: AppTheme.white100,
          unselectedLabelColor: AppTheme.white100.withOpacity(0.70),
          tabs: const [
            Tab(
              icon: Icon(Icons.calendar_today),
              text: 'Ce mois',
            ),
            Tab(
              icon: Icon(Icons.list),
              text: 'Toutes les réservations',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'Statistiques',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCurrentMonthView(),
                      _buildAllReservationsView(),
                      _buildStatisticsView(),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.white100,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppTheme.grey400,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Erreur de chargement',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMonthView() {
    if (_currentMonthStats == null) {
      return const Center(child: Text('Aucune donnée disponible'));
    }

    final monthName = DateFormat('MMMM yyyy', 'fr_FR').format(
      DateTime(_currentMonthStats!.year, _currentMonthStats!.month)
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du mois
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.space20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthName,
                  style: const TextStyle(
                    color: AppTheme.white100,
                    fontSize: AppTheme.fontSize24,
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                Text(
                  '${_currentMonthStats!.reservations.length} réservation(s) ce mois',
                  style: TextStyle(
                    color: AppTheme.white100.withOpacity(0.9),
                    fontSize: AppTheme.fontSize16,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceLarge),
          
          // Calendrier visuel
          if (_currentMonthStats!.reservations.isNotEmpty) ...[
            Text(
              'Réservations du mois',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: AppTheme.fontBold,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            _buildReservationsList(_currentMonthStats!.reservations),
          ] else ...[
            _buildEmptyState(),
          ],
        ],
      ),
    );
  }

  Widget _buildReservationsList(List<SpecialSongReservationModel> reservations) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reservations.length,
      itemBuilder: (context, index) {
        final reservation = reservations[index];
        return _buildReservationCard(reservation);
      },
    );
  }

  Widget _buildReservationCard(SpecialSongReservationModel reservation) {
    final isPast = reservation.reservedDate.isBefore(DateTime.now());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isPast ? AppTheme.grey300 : AppTheme.primaryColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.grey500.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date et statut
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPast 
                      ? AppTheme.grey100 
                      : AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(reservation.reservedDate),
                  style: TextStyle(
                    color: isPast ? AppTheme.grey600 : AppTheme.primaryColor,
                    fontWeight: AppTheme.fontSemiBold,
                    fontSize: AppTheme.fontSize12,
                  ),
                ),
              ),
              const Spacer(),
              if (isPast)
                Icon(Icons.history, color: AppTheme.grey400, size: 16)
              else
                Icon(Icons.event, color: AppTheme.primaryColor, size: 16),
            ],
          ),
          
          const SizedBox(height: AppTheme.space12),
          
          // Nom de la personne
          Text(
            reservation.fullName,
            style: const TextStyle(
              fontWeight: AppTheme.fontBold,
              fontSize: AppTheme.fontSize16,
            ),
          ),
          
          const SizedBox(height: AppTheme.spaceSmall),
          
          // Titre du chant
          Row(
            children: [
              Icon(Icons.music_note, color: AppTheme.grey600, size: 16),
              const SizedBox(width: AppTheme.space6),
              Expanded(
                child: Text(
                  reservation.songTitle,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSize14,
                    fontWeight: AppTheme.fontMedium,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppTheme.spaceSmall),
          
          // Contact
          Row(
            children: [
              Icon(Icons.email, color: AppTheme.grey600, size: 16),
              const SizedBox(width: AppTheme.space6),
              Expanded(
                child: Text(
                  reservation.email,
                  style: TextStyle(
                    fontSize: AppTheme.fontSize14,
                    color: AppTheme.grey600,
                  ),
                ),
              ),
            ],
          ),
          
          if (reservation.phone.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceXSmall),
            Row(
              children: [
                Icon(Icons.phone, color: AppTheme.grey600, size: 16),
                const SizedBox(width: AppTheme.space6),
                Text(
                  reservation.phone,
                  style: TextStyle(
                    fontSize: AppTheme.fontSize14,
                    color: AppTheme.grey600,
                  ),
                ),
              ],
            ),
          ],
          
          // Lien musiciens
          if (reservation.musicianLink != null && reservation.musicianLink!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceSmall),
            Row(
              children: [
                Icon(Icons.link, color: AppTheme.grey600, size: 16),
                const SizedBox(width: AppTheme.space6),
                Expanded(
                  child: Text(
                    'Lien pour musiciens',
                    style: TextStyle(
                      fontSize: AppTheme.fontSize14,
                      color: AppTheme.grey600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: AppTheme.space12),
          
          // Actions
          Row(
            children: [
              Text(
                'Réservé le ${DateFormat('d/MM/yyyy à HH:mm', 'fr_FR').format(reservation.createdAt)}',
                style: TextStyle(
                  fontSize: AppTheme.fontSize12,
                  color: AppTheme.grey500,
                ),
              ),
              const Spacer(),
              if (!isPast) ...[
                TextButton(
                  onPressed: () => _cancelReservation(reservation),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.redStandard,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Annuler'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 48),
          Icon(
            Icons.music_note_outlined,
            size: 64,
            color: AppTheme.grey400,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Aucune réservation ce mois',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.grey600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Les réservations de chants spéciaux apparaîtront ici',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.grey500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAllReservationsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Toutes les réservations',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: AppTheme.fontBold,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          if (_allReservations.isNotEmpty)
            _buildReservationsList(_allReservations)
          else
            _buildEmptyState(),
        ],
      ),
    );
  }

  Widget _buildStatisticsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: AppTheme.fontBold,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          
          // Cartes de statistiques
          _buildStatCard(
            'Réservations ce mois',
            '${_currentMonthStats?.reservations.length ?? 0}',
            Icons.calendar_today,
            AppTheme.primaryColor,
          ),
          const SizedBox(height: AppTheme.space12),
          _buildStatCard(
            'Dimanches disponibles',
            '${_currentMonthStats?.availableSundays.length ?? 0}',
            Icons.event_available,
            AppTheme.greenStandard,
          ),
          const SizedBox(height: AppTheme.space12),
          _buildStatCard(
            'Dimanches réservés',
            '${_currentMonthStats?.reservedSundays.length ?? 0}',
            Icons.event_busy,
            AppTheme.orangeStandard,
          ),
          
          const SizedBox(height: AppTheme.spaceLarge),
          
          if (_currentMonthStats != null && _currentMonthStats!.reservations.isNotEmpty) ...[
            Text(
              'Prochaines réservations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: AppTheme.fontBold,
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            ..._currentMonthStats!.reservations
                .where((r) => r.reservedDate.isAfter(DateTime.now()))
                .map((r) => _buildUpcomingReservationTile(r))
                .toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.grey500.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppTheme.spaceMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSize24,
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTheme.fontSize14,
                    color: AppTheme.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingReservationTile(SpecialSongReservationModel reservation) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        child: Icon(Icons.music_note, color: AppTheme.primaryColor),
      ),
      title: Text(reservation.fullName),
      subtitle: Text(
        '${DateFormat('d MMMM', 'fr_FR').format(reservation.reservedDate)} - ${reservation.songTitle}',
      ),
      trailing: Text(
        DateFormat('d/MM', 'fr_FR').format(reservation.reservedDate),
        style: TextStyle(
          color: AppTheme.grey600,
          fontSize: AppTheme.fontSize12,
        ),
      ),
    );
  }

  Future<void> _cancelReservation(SpecialSongReservationModel reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: Text(
          'Êtes-vous sûr de vouloir annuler la réservation de ${reservation.fullName} '
          'pour le ${DateFormat('d MMMM yyyy', 'fr_FR').format(reservation.reservedDate)} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.redStandard),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SpecialSongReservationService.cancelReservation(reservation.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation annulée avec succès'),
            backgroundColor: AppTheme.greenStandard,
          ),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'annulation: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }
}