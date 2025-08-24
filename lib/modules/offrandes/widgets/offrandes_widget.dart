import 'package:flutter/material.dart';
import '../../../theme.dart';

class OffrandesWidget extends StatelessWidget {
  const OffrandesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.withOpacity(0.1),
              Colors.green.withOpacity(0.05),
            ])),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Soutenir l\'œuvre',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor)),
              ]),
            const SizedBox(height: 16),
            Text(
              'Votre générosité permet de soutenir les ministères de l\'église et d\'étendre le Royaume de Dieu.',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigation vers la page de don
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                    icon: const Icon(Icons.volunteer_activism, size: 20),
                    label: const Text(
                      'Faire un don',
                      style: TextStyle(fontWeight: FontWeight.w600)))),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    // Afficher plus d'informations sur les dons
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.green),
                    foregroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
                  icon: const Icon(Icons.info_outline, size: 20),
                  label: const Text('Info')),
              ]),
          ])),
    );
  }
}
