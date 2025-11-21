import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/special_song_reservation_model.dart';
import '../services/special_song_reservation_service.dart';
import '../../theme.dart';

class SundayCalendarWidget extends StatefulWidget {
  final Function(DateTime selectedSunday) onSundaySelected;
  final MonthlyReservationStats? initialStats;
  final String? currentUserId;
  final VoidCallback? onReservationCancelled;

  const SundayCalendarWidget({
    super.key,
    required this.onSundaySelected,
    this.initialStats,
    this.currentUserId,
    this.onReservationCancelled,
  });

  @override
  State<SundayCalendarWidget> createState() => _SundayCalendarWidgetState();
}

class _SundayCalendarWidgetState extends State<SundayCalendarWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  MonthlyReservationStats? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    if (widget.initialStats != null) {
      _stats = widget.initialStats;
      _isLoading = false;
      _animationController.forward();
    } else {
      _loadMonthlyStats();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMonthlyStats() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final stats = await SpecialSongReservationService.getMonthlyStats();
      
      setState(() {
        _stats = stats;
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
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
              onPressed: _loadMonthlyStats,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_stats == null) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: _buildCalendar(),
    );
  }

  Widget _buildCalendar() {
    final monthName = DateFormat('MMMM yyyy', 'fr_FR').format(DateTime(_stats!.year, _stats!.month));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête du mois
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spaceSmall), // Réduit de 12 à 8
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall), // Réduit de 10 à 8
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppTheme.white100,
                    size: 18, // Réduit de 20 à 18
                  ),
                  const SizedBox(width: AppTheme.spaceSmall), // Réduit de 10 à 8
                  Expanded(
                    child: Text(
                      monthName,
                      style: const TextStyle(
                        color: AppTheme.white100,
                        fontSize: AppTheme.fontSize16, // Réduit de 18 à 16
                        fontWeight: AppTheme.fontBold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceXSmall), // Réduit de 6 à 4
              Text(
                'Réservations pour les chants spéciaux',
                style: TextStyle(
                  color: AppTheme.white100.withOpacity(0.9),
                  fontSize: AppTheme.fontSize11, // Réduit de 12 à 11
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppTheme.spaceMedium), // Ajout d'espacement entre l'en-tête et le calendrier
        
        // Calendrier des dimanches 
        if (_stats!.availableSundays.isEmpty && _stats!.reservedSundays.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.event_busy,
                  size: 48,
                  color: AppTheme.grey400,
                ),
                const SizedBox(height: AppTheme.spaceMedium),
                Text(
                  'Aucun dimanche disponible ce mois',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.grey600,
                  ),
                ),
              ],
            ),
          )
        else
          _buildSundaysGrid(),
      ],
    );
  }

  Widget _buildSundaysGrid() {
    // Combine tous les dimanches et trie par date
    final allSundays = <DateTime>{};
    allSundays.addAll(_stats!.availableSundays);
    allSundays.addAll(_stats!.reservedSundays);
    
    // Ajouter les dimanches du mois passés
    final allSundaysInMonth = MonthlyReservationStats.getSundaysInMonth(_stats!.year, _stats!.month);
    allSundays.addAll(allSundaysInMonth);
    
    final sortedSundays = allSundays.toList()..sort();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedSundays.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppTheme.space6), // Réduit de 8 à 6
      itemBuilder: (context, index) {
        final sunday = sortedSundays[index];
        return _buildSundayCard(sunday);
      },
    );
  }

  Widget _buildSundayCard(DateTime sunday) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sundayDate = DateTime(sunday.year, sunday.month, sunday.day);
    
    final isPast = sundayDate.isBefore(today);
    final isReserved = _stats!.reservedSundays.contains(sunday);
    final isAvailable = _stats!.availableSundays.contains(sunday) && !isReserved && !isPast;
    
    // Trouver la réservation pour ce dimanche
    final reservation = _stats!.reservations.firstWhere(
      (r) => DateTime(r.reservedDate.year, r.reservedDate.month, r.reservedDate.day) == sundayDate,
      orElse: () => SpecialSongReservationModel(
        id: '',
        personId: '',
        fullName: '',
        email: '',
        phone: '',
        songTitle: '',
        reservedDate: sunday,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // Vérifier si c'est la réservation de l'utilisateur actuel
    final isUserReservation = isReserved && 
        reservation.id.isNotEmpty && 
        widget.currentUserId != null && 
        reservation.personId == widget.currentUserId;

    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String status;

    if (isPast) {
      backgroundColor = AppTheme.grey100;
      borderColor = AppTheme.grey300;
      textColor = AppTheme.grey600;
      icon = Icons.history;
      status = 'Passé';
    } else if (isReserved) {
      if (isUserReservation) {
        backgroundColor = const Color(0xFFF0F4FF); // Bleu très subtil
        borderColor = AppTheme.blueStandard.withOpacity(0.6);
        textColor = AppTheme.blueStandard.withOpacity(0.9);
        icon = Icons.person_rounded;
        status = 'Ma réservation';
      } else {
        backgroundColor = const Color(0xFFFFF4E6); // Orange très subtil
        borderColor = AppTheme.orangeStandard.withOpacity(0.5);
        textColor = AppTheme.orangeStandard.withOpacity(0.8);
        icon = Icons.event_busy_rounded;
        status = 'Réservé';
      }
    } else if (isAvailable) {
      backgroundColor = const Color(0xFFF0FFF4); // Vert très subtil
      borderColor = AppTheme.greenStandard.withOpacity(0.6);
      textColor = AppTheme.greenStandard.withOpacity(0.9);
      icon = Icons.event_available_rounded;
      status = 'Disponible';
    } else {
      backgroundColor = const Color(0xFFFAFAFA); // Gris très clair
      borderColor = AppTheme.grey400.withOpacity(0.5);
      textColor = AppTheme.grey600;
      icon = Icons.event_note_rounded;
      status = 'Indisponible';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isAvailable ? () => widget.onSundaySelected(sunday) : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        hoverColor: isAvailable ? AppTheme.greenStandard.withOpacity(0.05) : null,
        splashColor: isAvailable ? AppTheme.greenStandard.withOpacity(0.1) : null,
        highlightColor: isAvailable ? AppTheme.greenStandard.withOpacity(0.08) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppTheme.space10), // Réduit de 12 à 10
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(
              color: borderColor,
              width: isUserReservation ? 2.5 : 1.5,
            ),
            borderRadius: BorderRadius.circular(10), // Réduit de 12 à 10
            boxShadow: _buildCardShadow(isAvailable, isUserReservation, isReserved, borderColor),
          ),
          child: Row(
            children: [
              // Section gauche : Date et icône
              Container(
                padding: const EdgeInsets.all(AppTheme.space10), // Réduit de 12 à 10
                decoration: BoxDecoration(
                  color: _getIconBackgroundColor(isAvailable, isUserReservation, isReserved, borderColor),
                  borderRadius: BorderRadius.circular(10), // Réduit de 12 à 10
                  border: isAvailable ? Border.all(
                    color: AppTheme.greenStandard.withOpacity(0.3),
                    width: 1,
                  ) : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          icon,
                          color: textColor,
                          size: 18, // Réduit de 20 à 18
                        ),
                        // Petit point indicateur pour les dates disponibles
                        if (isAvailable)
                          Positioned(
                            top: -2,
                            right: -2,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppTheme.greenStandard,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.greenStandard.withOpacity(0.5),
                                    blurRadius: 2,
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3), // Réduit de 4 à 3
                    Text(
                      DateFormat('d', 'fr_FR').format(sunday),
                      style: TextStyle(
                        color: textColor,
                        fontWeight: AppTheme.fontBold,
                        fontSize: AppTheme.fontSize14, // Réduit de 16 à 14
                      ),
                    ),
                    Text(
                      DateFormat('MMM', 'fr_FR').format(sunday),
                      style: TextStyle(
                        color: textColor.withOpacity(0.8),
                        fontSize: 9, // Réduit de 10 à 9
                        fontWeight: AppTheme.fontSemiBold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: AppTheme.space10), // Réduit de 12 à 10
              
              // Section centrale : Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Réduit
                      decoration: BoxDecoration(
                        color: borderColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6), // Réduit de 8 à 6
                        border: Border.all(
                          color: borderColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: textColor,
                          fontSize: AppTheme.fontSize10, // Réduit de 12 à 10
                          fontWeight: AppTheme.fontSemiBold,
                        ),
                      ),
                    ),
                    
                    // Informations de réservation
                    if (isReserved && reservation.id.isNotEmpty) ...[
                      const SizedBox(height: AppTheme.space6), // Réduit de 8 à 6
                      if (isUserReservation) ...[
                        Text(
                          'Chant: ${reservation.songTitle}',
                          style: TextStyle(
                            color: textColor,
                            fontSize: AppTheme.fontSize13,
                            fontWeight: AppTheme.fontSemiBold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ] else ...[
                        Text(
                          'Réservé par: ${reservation.fullName}',
                          style: TextStyle(
                            color: textColor,
                            fontSize: AppTheme.fontSize13,
                            fontWeight: AppTheme.fontSemiBold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              
              // Section droite : Bouton d'annulation si applicable
              if (isUserReservation && !isPast) ...[
                const SizedBox(width: AppTheme.space12),
                _buildCompactCancelButton(reservation),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<BoxShadow>? _buildCardShadow(bool isAvailable, bool isUserReservation, bool isReserved, Color borderColor) {
    if (isAvailable) {
      // Ombre subtile verte pour les dates disponibles
      return [
        BoxShadow(
          color: AppTheme.greenStandard.withOpacity(0.15),
          blurRadius: 6,
          offset: const Offset(0, 2),
          spreadRadius: 1,
        ),
        BoxShadow(
          color: AppTheme.greenStandard.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
    } else if (isUserReservation) {
      // Ombre bleue pour les réservations de l'utilisateur
      return [
        BoxShadow(
          color: AppTheme.blueStandard.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 3),
          spreadRadius: 1,
        ),
      ];
    } else if (isReserved) {
      // Ombre orange subtile pour les dates réservées par d'autres
      return [
        BoxShadow(
          color: AppTheme.orangeStandard.withOpacity(0.12),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
    } else {
      // Ombre très subtile pour les dates indisponibles
      return [
        BoxShadow(
          color: AppTheme.grey400.withOpacity(0.08),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ];
    }
  }

  Color _getIconBackgroundColor(bool isAvailable, bool isUserReservation, bool isReserved, Color borderColor) {
    if (isAvailable) {
      return AppTheme.greenStandard.withOpacity(0.15);
    } else if (isUserReservation) {
      return AppTheme.blueStandard.withOpacity(0.15);
    } else if (isReserved) {
      return AppTheme.orangeStandard.withOpacity(0.12);
    } else {
      return borderColor.withOpacity(0.1);
    }
  }

  Widget _buildCompactCancelButton(SpecialSongReservationModel reservation) {
    return SizedBox(
      width: 70,
      height: 32,
      child: ElevatedButton(
        onPressed: () => _showCancelDialog(reservation),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.grey100,
          foregroundColor: AppTheme.grey700,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            side: BorderSide(
              color: AppTheme.grey300,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        child: const Text(
          'Annuler',
          style: TextStyle(
            fontSize: AppTheme.fontSize10,
            fontWeight: AppTheme.fontSemiBold,
          ),
        ),
      ),
    );
  }

  Future<void> _showCancelDialog(SpecialSongReservationModel reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppTheme.grey600),
            const SizedBox(width: AppTheme.spaceSmall),
            const Text('Annuler la réservation'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Êtes-vous sûr de vouloir annuler votre réservation ?',
              style: const TextStyle(fontWeight: AppTheme.fontMedium),
            ),
            const SizedBox(height: AppTheme.space12),
            Container(
              padding: const EdgeInsets.all(AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.grey50,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: AppTheme.grey200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: AppTheme.grey600),
                      const SizedBox(width: AppTheme.space6),
                      Text(
                        DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(reservation.reservedDate),
                        style: const TextStyle(fontWeight: AppTheme.fontMedium),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space6),
                  Row(
                    children: [
                      Icon(Icons.music_note, size: 16, color: AppTheme.grey600),
                      const SizedBox(width: AppTheme.space6),
                      Expanded(
                        child: Text(
                          reservation.songTitle,
                          style: const TextStyle(fontWeight: AppTheme.fontMedium),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            Text(
              'Cette action ne peut pas être annulée.',
              style: TextStyle(
                fontSize: AppTheme.fontSize12,
                color: AppTheme.grey600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Garder ma réservation'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.redStandard,
              foregroundColor: AppTheme.white100,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cancelReservation(reservation);
    }
  }

  Future<void> _cancelReservation(SpecialSongReservationModel reservation) async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      await SpecialSongReservationService.cancelReservation(reservation.id);

      // Fermer l'indicateur de chargement
      if (mounted) Navigator.pop(context);

      // Recharger les données
      await _loadMonthlyStats();

      // Notifier le parent si callback fourni
      if (widget.onReservationCancelled != null) {
        widget.onReservationCancelled!();
      }

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.white100),
                const SizedBox(width: AppTheme.spaceSmall),
                const Text('Réservation annulée avec succès'),
              ],
            ),
            backgroundColor: AppTheme.greenStandard,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      if (mounted) Navigator.pop(context);

      // Afficher l'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: AppTheme.white100),
                const SizedBox(width: AppTheme.spaceSmall),
                Expanded(child: Text('Erreur: $e')),
              ],
            ),
            backgroundColor: AppTheme.redStandard,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}