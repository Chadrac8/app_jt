import 'package:flutter/material.dart';
import '../../theme.dart';

class UrgentDiagnosticBanner extends StatelessWidget {
  const UrgentDiagnosticBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.redStandard, AppTheme.orangeStandard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.redStandard.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning,
                color: AppTheme.white100,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '🚨 PROBLÈME CRITIQUE - Personnes invisibles',
                  style: TextStyle(
                    color: AppTheme.white100,
                    fontSize: 18,
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Vous ne voyez aucune personne dans les sélecteurs ? '
            'Lancez le diagnostic immédiat pour identifier le problème.',
            style: TextStyle(
              color: AppTheme.white100,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Module de diagnostic supprimé',
                style: TextStyle(
                  color: AppTheme.white100,
                  fontWeight: AppTheme.fontBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Le module de gestion des projets a été supprimé.',
            style: TextStyle(
              color: AppTheme.white100.withOpacity(0.70),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
