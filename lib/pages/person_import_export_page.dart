import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../services/person_import_export_service.dart';
import '../models/person_model.dart';

/// Page d'import et export des personnes
class PersonImportExportPage extends StatefulWidget {
  final List<PersonModel>? selectedPeople;
  
  const PersonImportExportPage({
    Key? key,
    this.selectedPeople,
  }) : super(key: key);

  @override
  State<PersonImportExportPage> createState() => _PersonImportExportPageState();
}

class _PersonImportExportPageState extends State<PersonImportExportPage>
    with TickerProviderStateMixin {
  final PersonImportExportService _importExportService = PersonImportExportService();
  late TabController _tabController;
  
  bool _isLoading = false;
  String? _statusMessage;
  Color _statusColor = Colors.blue;

  // Configuration pour export
  ExportFormat _exportFormat = ExportFormat.csv;
  bool _includeInactive = false;
  final List<String> _selectedFields = [];
  final List<String> _excludedFields = [];

  // Configuration pour import
  String? _selectedTemplate;
  bool _validateEmails = true;
  bool _validatePhones = true;
  bool _allowDuplicateEmail = false;
  bool _updateExisting = false;
  bool _createUserAccounts = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedFields.addAll(PersonImportExportService.standardFields);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import/Export Personnes'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.file_download),
              text: 'Export',
            ),
            Tab(
              icon: Icon(Icons.file_upload),
              text: 'Import',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExportTab(),
          _buildImportTab(),
        ],
      ),
    );
  }

  Widget _buildExportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statut
          if (_statusMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                border: Border.all(color: _statusColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage!,
                style: TextStyle(color: _statusColor),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Type d'export
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Type d\'export',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  if (widget.selectedPeople != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.selectedPeople!.length} personnes sélectionnées',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _exportAll(),
                          icon: const Icon(Icons.people),
                          label: const Text('Toutes les personnes'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      if (widget.selectedPeople != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : () => _exportSelected(),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Sélection'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _showFilterDialog(),
                    icon: const Icon(Icons.filter_alt),
                    label: const Text('Export avec filtres'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Format d'export
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Format d\'export',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  ...ExportFormat.values.map((format) => RadioListTile<ExportFormat>(
                    title: Text(_getFormatName(format)),
                    subtitle: Text(_getFormatDescription(format)),
                    value: format,
                    groupValue: _exportFormat,
                    onChanged: (value) {
                      setState(() {
                        _exportFormat = value!;
                      });
                    },
                  )),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuration',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  CheckboxListTile(
                    title: const Text('Inclure les personnes inactives'),
                    value: _includeInactive,
                    onChanged: (value) {
                      setState(() {
                        _includeInactive = value!;
                      });
                    },
                  ),
                  
                  ListTile(
                    title: const Text('Champs à exporter'),
                    subtitle: Text('${_selectedFields.length} champs sélectionnés'),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _showFieldsDialog(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statut
          if (_statusMessage != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                border: Border.all(color: _statusColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _statusMessage!,
                style: TextStyle(color: _statusColor),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Action d'import
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Importer des personnes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  const Text(
                    'Formats supportés: CSV, JSON, TXT, Excel (.xlsx/.xls)',
                    style: TextStyle(color: Colors.grey),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Nouvelle section expliquant les capacités robustes
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_fix_high, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Import Intelligent',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Détection automatique des colonnes (nom, prénom, email, etc.)\n'
                          '• Support multilingue (français, anglais)\n'
                          '• Formats de date flexibles (DD/MM/YYYY, YYYY-MM-DD, etc.)\n'
                          '• Nettoyage automatique des données\n'
                          '• Gestion intelligente des doublons',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _importFromFile(),
                      icon: const Icon(Icons.file_upload),
                      label: const Text('Sélectionner un fichier'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Templates
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Templates de mapping',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Template',
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _selectedTemplate,
                    items: PersonImportExportService.importTemplates.keys
                        .map((template) => DropdownMenuItem(
                              value: template,
                              child: Text(_getTemplateName(template)),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTemplate = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 12),
                  
                  ElevatedButton.icon(
                    onPressed: () => _showTemplateDownload(),
                    icon: const Icon(Icons.download),
                    label: const Text('Télécharger template CSV'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Configuration d'import
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configuration d\'import',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  CheckboxListTile(
                    title: const Text('Valider les emails'),
                    subtitle: const Text('Vérifier le format des adresses email'),
                    value: _validateEmails,
                    onChanged: (value) {
                      setState(() {
                        _validateEmails = value!;
                      });
                    },
                  ),
                  
                  CheckboxListTile(
                    title: const Text('Valider les téléphones'),
                    subtitle: const Text('Vérifier le format des numéros de téléphone'),
                    value: _validatePhones,
                    onChanged: (value) {
                      setState(() {
                        _validatePhones = value!;
                      });
                    },
                  ),
                  
                  CheckboxListTile(
                    title: const Text('Autoriser emails dupliqués'),
                    subtitle: const Text('Permettre plusieurs personnes avec le même email'),
                    value: _allowDuplicateEmail,
                    onChanged: (value) {
                      setState(() {
                        _allowDuplicateEmail = value!;
                      });
                    },
                  ),
                  
                  CheckboxListTile(
                    title: const Text('Mettre à jour existants'),
                    subtitle: const Text('Mettre à jour les personnes existantes au lieu de les ignorer'),
                    value: _updateExisting,
                    onChanged: (value) {
                      setState(() {
                        _updateExisting = value!;
                      });
                    },
                  ),
                  
                  CheckboxListTile(
                    title: const Text('Créer des comptes utilisateurs'),
                    subtitle: const Text('Créer automatiquement des identifiants de connexion pour toutes les personnes importées (nécessite un email valide)'),
                    value: _createUserAccounts,
                    onChanged: (value) {
                      print('🔄 CHECKBOX ÉTAT CHANGÉ: $_createUserAccounts -> $value');
                      setState(() {
                        _createUserAccounts = value!;
                      });
                      print('✅ CHECKBOX ÉTAT FINAL: $_createUserAccounts');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================
  // FONCTIONS D'EXPORT
  // ===========================

  Future<void> _exportAll() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Export en cours...';
      _statusColor = Colors.blue;
    });

    try {
      final config = ImportExportConfig(
        includeInactive: _includeInactive,
        includeFields: _selectedFields,
        excludeFields: _excludedFields,
      );

      final result = await _importExportService.exportAll(
        format: _exportFormat,
        config: config,
      );

      if (result.success) {
        setState(() {
          _statusMessage = result.message;
          _statusColor = Colors.green;
        });
        
        if (result.filePath != null) {
          _showShareDialog(result.filePath!);
        }
      } else {
        setState(() {
          _statusMessage = result.error ?? 'Erreur lors de l\'export';
          _statusColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Erreur: $e';
        _statusColor = Colors.red;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportSelected() async {
    if (widget.selectedPeople == null) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Export en cours...';
      _statusColor = Colors.blue;
    });

    try {
      final config = ImportExportConfig(
        includeInactive: _includeInactive,
        includeFields: _selectedFields,
        excludeFields: _excludedFields,
      );

      final result = await _importExportService.exportSelected(
        people: widget.selectedPeople!,
        format: _exportFormat,
        config: config,
      );

      if (result.success) {
        setState(() {
          _statusMessage = result.message;
          _statusColor = Colors.green;
        });
        
        if (result.filePath != null) {
          _showShareDialog(result.filePath!);
        }
      } else {
        setState(() {
          _statusMessage = result.error ?? 'Erreur lors de l\'export';
          _statusColor = Colors.red;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Erreur: $e';
        _statusColor = Colors.red;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ===========================
  // FONCTIONS D'IMPORT
  // ===========================

  Future<void> _importFromFile() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Import intelligent en cours...';
      _statusColor = Colors.blue;
    });

    try {
      print('=== DEBUG IMPORT UI CONFIG ===');
      print('_createUserAccounts (checkbox state): $_createUserAccounts');
      print('_validateEmails: $_validateEmails');
      print('_allowDuplicateEmail: $_allowDuplicateEmail');
      print('_updateExisting: $_updateExisting');
      
      final config = ImportExportConfig(
        validateEmails: _validateEmails,
        validatePhones: _validatePhones,
        allowDuplicateEmail: _allowDuplicateEmail,
        updateExisting: _updateExisting,
        createUserAccounts: _createUserAccounts,
      );

      print('Config object created - createUserAccounts: ${config.createUserAccounts}');
      print('===============================');

      final result = await _importExportService.importFromFile(
        config: config,
        templateName: _selectedTemplate,
      );

      if (result.success) {
        final successRate = result.successRate.toStringAsFixed(1);
        setState(() {
          _statusMessage = result.message ?? 
              '✅ ${result.importedRecords}/${result.totalRecords} personnes importées ($successRate% de réussite)';
          _statusColor = Colors.green;
        });
        
        if (result.errors.isNotEmpty) {
          _showErrorsDialog(result);
        }
      } else {
        setState(() {
          _statusMessage = result.errors.isNotEmpty 
              ? result.errors.first 
              : 'Erreur lors de l\'import';
          _statusColor = Colors.red;
        });
        
        if (result.errors.length > 1) {
          _showErrorsDialog(result);
        }
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Erreur: $e';
        _statusColor = Colors.red;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ===========================
  // DIALOGS ET HELPERS
  // ===========================

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export avec filtres'),
        content: const Text('Fonctionnalité en développement'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showFieldsDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Champs à exporter'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView(
              children: PersonImportExportService.standardFields.map((field) => 
                CheckboxListTile(
                  title: Text(_getFieldName(field)),
                  value: _selectedFields.contains(field),
                  onChanged: (value) {
                    setStateDialog(() {
                      if (value!) {
                        _selectedFields.add(field);
                      } else {
                        _selectedFields.remove(field);
                      }
                    });
                  },
                ),
              ).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export terminé'),
        content: const Text('Voulez-vous partager le fichier exporté ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _importExportService.shareExportFile(
                filePath,
                context: context,
              );
            },
            child: const Text('Partager'),
          ),
        ],
      ),
    );
  }

  void _showErrorsDialog(ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Résultat de l\'import'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total: ${result.totalRecords}'),
              Text('Importées: ${result.importedRecords}'),
              Text('Ignorées: ${result.skippedRecords}'),
              Text('Taux de réussite: ${result.successRate.toStringAsFixed(1)}%'),
              const SizedBox(height: 16),
              if (result.errors.isNotEmpty) ...[
                const Text('Erreurs:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: result.errors.take(20).length,
                    itemBuilder: (context, index) => Text(
                      '• ${result.errors[index]}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                if (result.errors.length > 20)
                  Text('... et ${result.errors.length - 20} autres erreurs'),
              ],
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

  void _showTemplateDownload() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Template CSV'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Copiez ce template dans un fichier CSV :'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  _importExportService.getCsvTemplate(
                    templateName: _selectedTemplate ?? 'default',
                  ),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: _importExportService.getCsvTemplate(
                  templateName: _selectedTemplate ?? 'default',
                ),
              ));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Template copié dans le presse-papiers')),
              );
            },
            child: const Text('Copier'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  // ===========================
  // HELPERS
  // ===========================

  String _getFormatName(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.json:
        return 'JSON';
      case ExportFormat.excel:
        return 'Excel';
    }
  }

  String _getFormatDescription(ExportFormat format) {
    switch (format) {
      case ExportFormat.csv:
        return 'Fichier texte compatible avec Excel et Google Sheets';
      case ExportFormat.json:
        return 'Format structuré avec toutes les données';
      case ExportFormat.excel:
        return 'Fichier Excel natif (.xlsx) avec formatage avancé';
    }
  }

  String _getTemplateName(String template) {
    switch (template) {
      case 'default':
        return 'Défaut';
      case 'mailchimp':
        return 'MailChimp';
      case 'google_contacts':
        return 'Google Contacts';
      default:
        return template;
    }
  }

  String _getFieldName(String field) {
    switch (field) {
      case 'firstName':
        return 'Prénom';
      case 'lastName':
        return 'Nom';
      case 'email':
        return 'Email';
      case 'phone':
        return 'Téléphone';
      case 'address':
        return 'Adresse';
      case 'birthDate':
        return 'Date de naissance';
      case 'age':
        return 'Âge';
      case 'roles':
        return 'Rôles';
      case 'isActive':
        return 'Actif';
      case 'createdAt':
        return 'Créé le';
      case 'updatedAt':
        return 'Modifié le';
      default:
        return field;
    }
  }
}