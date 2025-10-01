import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/reading_plan.dart';
import '../services/reading_plan_service.dart';
import 'daily_reading_view.dart';
import '../../../../theme.dart';
import '../../../theme.dart';

class ActiveReadingPlanView extends StatefulWidget {
  final ReadingPlan plan;
  final UserReadingProgress? progress;
  final VoidCallback? onProgressUpdated;

  const ActiveReadingPlanView({
    Key? key,
    required this.plan,
    this.progress,
    this.onProgressUpdated,
  }) : super(key: key);

  @override
  State<ActiveReadingPlanView> createState() => _ActiveReadingPlanViewState();
}

class _ActiveReadingPlanViewState extends State<ActiveReadingPlanView> {
  UserReadingProgress? _progress;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _progress = widget.progress;
  }

  @override
  void didUpdateWidget(ActiveReadingPlanView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _progress = widget.progress;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_progress == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentDay = _progress!.currentDay;
    final completedDays = _progress!.completedDays;
    final progressPercentage = completedDays.length / widget.plan.totalDays;
    final todayTask = widget.plan.days.firstWhere(
      (day) => day.day == currentDay,
      orElse: () => widget.plan.days.first,
    );

    return RefreshIndicator(
      onRefresh: () async {
        await _refreshProgress();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec progrès
            _buildProgressHeader(theme, progressPercentage),
            
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Lecture du jour
            _buildTodayReading(theme, todayTask),
            
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Actions rapides
            _buildQuickActions(theme),
            
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Historique récent
            _buildRecentHistory(theme),
            
            const SizedBox(height: AppTheme.spaceLarge),
            
            // Statistiques
            _buildStatistics(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader(ThemeData theme, double progressPercentage) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plan.name,
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize20,
                        fontWeight: AppTheme.fontBold,
                      ),
                    ),
                    Text(
                      'Jour ${_progress!.currentDay} sur ${widget.plan.totalDays}',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              CircularProgressIndicator(
                value: progressPercentage,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          LinearProgressIndicator(
            value: progressPercentage,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_progress!.completedDays.length} jours terminés',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize14,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Text(
                '${(progressPercentage * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: AppTheme.fontSize14,
                  fontWeight: AppTheme.fontSemiBold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayReading(ThemeData theme, ReadingPlanDay todayTask) {
    final isCompleted = _progress!.completedDays.contains(todayTask.day);
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                  color: isCompleted 
                      ? AppTheme.greenStandard.withOpacity(0.2)
                      : theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle : Icons.today,
                  color: isCompleted ? AppTheme.greenStandard : theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted ? 'Lecture terminée !' : 'Lecture du jour',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize18,
                        fontWeight: AppTheme.fontBold,
                        color: isCompleted ? AppTheme.greenStandard : null,
                      ),
                    ),
                    Text(
                      todayTask.title,
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          
          // Lectures du jour
          Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            decoration: BoxDecoration(
              color: theme.colorScheme.background,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lectures',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize14,
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSmall),
                Text(
                  todayTask.readings.map((r) => r.displayText).join(' • '),
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize16,
                    color: theme.colorScheme.primary,
                    fontWeight: AppTheme.fontMedium,
                  ),
                ),
              ],
            ),
          ),
          
          if (todayTask.reflection != null) ...[
            const SizedBox(height: AppTheme.space12),
            Text(
              'Réflexion',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                fontWeight: AppTheme.fontSemiBold,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXSmall),
            Text(
              todayTask.reflection!,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize14,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                height: 1.4,
              ),
            ),
          ],
          
          const SizedBox(height: AppTheme.spaceMedium),
          
          // Bouton d'action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isCompleted 
                    ? AppTheme.greenStandard 
                    : theme.colorScheme.primary,
                foregroundColor: AppTheme.white100,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              onPressed: _isLoading ? null : () => _openDailyReading(todayTask),
              child: Text(
                isCompleted ? 'Relire' : 'Commencer la lecture',
                style: GoogleFonts.inter(fontWeight: AppTheme.fontSemiBold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize18,
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                theme: theme,
                icon: Icons.history,
                title: 'Historique',
                subtitle: 'Voir toutes les lectures',
                onTap: () => _showHistoryDialog(),
              ),
            ),
            const SizedBox(width: AppTheme.space12),
            Expanded(
              child: _buildActionCard(
                theme: theme,
                icon: Icons.note_add,
                title: 'Mes notes',
                subtitle: 'Voir mes réflexions',
                onTap: () => _showNotesDialog(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 32),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: AppTheme.fontSemiBold,
                fontSize: AppTheme.fontSize14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceXSmall),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize12,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentHistory(ThemeData theme) {
    final recentDays = _progress!.completedDays.toList()
      ..sort((a, b) => b.compareTo(a));
    final displayDays = recentDays.take(3).toList();
    
    if (displayDays.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lectures récentes',
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize18,
            fontWeight: AppTheme.fontBold,
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        ...displayDays.map((dayNumber) {
          final day = widget.plan.days.firstWhere(
            (d) => d.day == dayNumber,
            orElse: () => widget.plan.days.first,
          );
          return _buildHistoryItem(theme, day, true);
        }),
      ],
    );
  }

  Widget _buildHistoryItem(ThemeData theme, ReadingPlanDay day, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppTheme.space12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted 
                  ? AppTheme.greenStandard.withOpacity(0.2)
                  : theme.colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Center(
              child: Text(
                '${day.day}',
                style: GoogleFonts.inter(
                  fontWeight: AppTheme.fontBold,
                  color: isCompleted ? AppTheme.greenStandard : theme.colorScheme.primary,
                  fontSize: AppTheme.fontSize12,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.title,
                  style: GoogleFonts.inter(
                    fontWeight: AppTheme.fontMedium,
                    fontSize: AppTheme.fontSize14,
                  ),
                ),
                Text(
                  day.readings.map((r) => r.displayText).join(', '),
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize12,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          if (isCompleted)
            Icon(
              Icons.check_circle,
              color: AppTheme.greenStandard,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildStatistics(ThemeData theme) {
    final totalDays = widget.plan.totalDays;
    final completedDays = _progress!.completedDays.length;
    final remainingDays = totalDays - completedDays;
    final streak = _calculateStreak();
    
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontBold,
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  theme: theme,
                  value: '$completedDays',
                  label: 'Jours terminés',
                  color: AppTheme.greenStandard,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  theme: theme,
                  value: '$remainingDays',
                  label: 'Jours restants',
                  color: theme.colorScheme.primary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  theme: theme,
                  value: '$streak',
                  label: 'Série actuelle',
                  color: AppTheme.orangeStandard,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required ThemeData theme,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize24,
            fontWeight: AppTheme.fontBold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: AppTheme.fontSize12,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  int _calculateStreak() {
    if (_progress!.completedDays.isEmpty) return 0;
    
    final sortedDays = _progress!.completedDays.toList()..sort();
    int streak = 1;
    int maxStreak = 1;
    
    for (int i = 1; i < sortedDays.length; i++) {
      if (sortedDays[i] == sortedDays[i - 1] + 1) {
        streak++;
        maxStreak = maxStreak > streak ? maxStreak : streak;
      } else {
        streak = 1;
      }
    }
    
    return maxStreak;
  }

  Future<void> _refreshProgress() async {
    final progress = await ReadingPlanService.getPlanProgress(widget.plan.id);
    setState(() {
      _progress = progress;
    });
    widget.onProgressUpdated?.call();
  }

  void _openDailyReading(ReadingPlanDay day) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DailyReadingView(
          plan: widget.plan,
          day: day,
          progress: _progress!,
          onCompleted: (note) async {
            await ReadingPlanService.completeDayReading(
              widget.plan.id,
              day.day,
              note: note,
            );
            await _refreshProgress();
          },
        ),
      ),
    );
  }

  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Historique des lectures'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.plan.days.where((day) => 
              _progress!.completedDays.contains(day.day)
            ).map((day) => _buildHistoryItem(Theme.of(context), day, true)).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showNotesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mes notes'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _progress!.dayNotes.entries.map((entry) {
              final day = widget.plan.days.firstWhere(
                (d) => d.day == entry.key,
                orElse: () => widget.plan.days.first,
              );
              return ListTile(
                title: Text('Jour ${entry.key}: ${day.title}'),
                subtitle: Text(entry.value),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
