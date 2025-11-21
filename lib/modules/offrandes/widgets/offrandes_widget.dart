import 'package:flutter/material.dart';
import '../../../../theme.dart';

class OffrandesWidget extends StatelessWidget {
  const OffrandesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.greenStandard.withOpacity(0.1),
              AppTheme.greenStandard.withOpacity(0.05),
            ])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: AppTheme.greenStandard, size: 28),
                const SizedBox(width: AppTheme.space12),
                Text(
                  'Soutenir l\'œuvre',
                  style: TextStyle(
                    fontSize: AppTheme.fontSize20,
                    fontWeight: AppTheme.fontBold,
                    color: AppTheme.textPrimaryColor)),
              ]),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Votre générosité permet de soutenir les ministères de l\'église et d\'étendre le Royaume de Dieu.',
              style: TextStyle(
                fontSize: AppTheme.fontSize16,
                color: AppTheme.textSecondaryColor)),
            const SizedBox(height: AppTheme.space20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigation vers la page de don
                      Navigator.of(context).pushNamed('/admin/offrandes');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.greenStandard,
                      foregroundColor: AppTheme.white100,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium))),
                    icon: const Icon(Icons.volunteer_activism, size: 20),
                    label: const Text(
                      'Faire un don',
                      style: TextStyle(fontWeight: AppTheme.fontSemiBold)))),
                const SizedBox(width: AppTheme.space12),
                OutlinedButton.icon(
                  onPressed: () {
                    // Afficher plus d'informations sur les dons
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.greenStandard),
                    foregroundColor: AppTheme.greenStandard,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium))),
                  icon: const Icon(Icons.info_outline, size: 20),
                  label: const Text('Info')),
              ]),
          ])),
    );
  }
}
