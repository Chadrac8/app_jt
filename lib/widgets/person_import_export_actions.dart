import 'package:flutter/material.dart';
import '../pages/person_import_export_page.dart';
import '../models/person_model.dart';
import '../theme.dart';

/// Widget d'actions rapides pour l'import/export des personnes
class PersonImportExportActions extends StatelessWidget {
  final List<PersonModel>? selectedPeople;
  final VoidCallback? onImportComplete;
  final VoidCallback? onExportComplete;

  const PersonImportExportActions({
    Key? key,
    this.selectedPeople,
    this.onImportComplete,
    this.onExportComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.import_export,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Import / Export',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Gérez vos données de personnes en important ou exportant des fichiers.',
              style: TextStyle(color: Colors.grey),
            ),
            
            const SizedBox(height: 16),
            
            // Actions rapides
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Export rapide
                ElevatedButton.icon(
                  onPressed: () => _openImportExportPage(context, 0), // Tab Export
                  icon: const Icon(Icons.file_download, size: 18),
                  label: const Text('Export'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                
                // Import rapide
                ElevatedButton.icon(
                  onPressed: () => _openImportExportPage(context, 1), // Tab Import
                  icon: const Icon(Icons.file_upload, size: 18),
                  label: const Text('Import'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
                
                // Export sélection (si des personnes sont sélectionnées)
                if (selectedPeople != null && selectedPeople!.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _openImportExportPageWithSelection(context),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: Text('Export (${selectedPeople!.length})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Liens vers la page complète
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _openImportExportPage(context),
                  icon: const Icon(Icons.settings, size: 16),
                  label: const Text('Options avancées'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
                
                TextButton.icon(
                  onPressed: () => _showHelpDialog(context),
                  icon: const Icon(Icons.help_outline, size: 16),
                  label: const Text('Aide'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openImportExportPage(BuildContext context, [int? initialTab]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PersonImportExportPage(
          selectedPeople: selectedPeople,
        ),
      ),
    ).then((_) {
      // Callback après fermeture de la page
      onImportComplete?.call();
      onExportComplete?.call();
    });
  }

  void _openImportExportPageWithSelection(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PersonImportExportPage(
          selectedPeople: selectedPeople,
        ),
      ),
    ).then((_) {
      onExportComplete?.call();
    });
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aide Import/Export'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Export',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Exportez toutes les personnes ou une sélection'),
              Text('• Formats supportés: CSV, JSON, Excel'),
              Text('• Choisissez les champs à inclure'),
              Text('• Filtrez par statut (actif/inactif)'),
              
              SizedBox(height: 16),
              
              Text(
                'Import',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• Importez depuis CSV, JSON ou TXT'),
              Text('• Utilisez nos templates pour faciliter le mapping'),
              Text('• Validation automatique des emails et téléphones'),
              Text('• Gestion des doublons et mise à jour'),
              
              SizedBox(height: 16),
              
              Text(
                'Formats CSV recommandés',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text('• Première ligne: en-têtes des colonnes'),
              Text('• Encodage: UTF-8'),
              Text('• Séparateur: virgule (,)'),
              Text('• Dates: YYYY-MM-DD ou DD/MM/YYYY'),
              
              SizedBox(height: 16),
              
              Text(
                'Champs supportés',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              SizedBox(height: 4),
              Text('• firstName, lastName (requis)'),
              Text('• email, phone, address'),
              Text('• birthDate, roles'),
              Text('• Champs personnalisés supportés'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Widget de statistiques d'import/export
class ImportExportStats extends StatelessWidget {
  final int totalPeople;
  final int activePeople;
  final DateTime? lastImport;
  final DateTime? lastExport;

  const ImportExportStats({
    Key? key,
    required this.totalPeople,
    required this.activePeople,
    this.lastImport,
    this.lastExport,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.people,
                    label: 'Total',
                    value: totalPeople.toString(),
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.people_alt,
                    label: 'Actives',
                    value: activePeople.toString(),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            if (lastImport != null || lastExport != null) ...[
              const Divider(),
              const SizedBox(height: 12),
              
              if (lastImport != null)
                _buildLastActionItem(
                  icon: Icons.file_upload,
                  label: 'Dernier import',
                  date: lastImport!,
                ),
              
              if (lastExport != null)
                _buildLastActionItem(
                  icon: Icons.file_download,
                  label: 'Dernier export',
                  date: lastExport!,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastActionItem({
    required IconData icon,
    required String label,
    required DateTime date,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const Spacer(),
          Text(
            _formatDate(date),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}