import 'package:flutter/material.dart';
import '../widgets/thematic_passages_home_widget.dart';
import '../views/thematic_passages_view.dart';
import '../widgets/theme_creation_dialog.dart';
import '../widgets/add_passage_dialog.dart';
import '../services/thematic_passage_service.dart';
import '../services/predefined_themes.dart';
import '../../../../theme.dart';

/// Fichier de démonstration des passages thématiques
/// 
/// Ce fichier montre comment utiliser toutes les fonctionnalités 
/// implémentées pour les passages thématiques bibliques.

void main() {
  runApp(const ThematicPassagesDemoApp());
}

class ThematicPassagesDemoApp extends StatelessWidget {
  const ThematicPassagesDemoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Passages Thématiques - Démo',
      theme: ThemeData(
        primarySwatch: AppTheme.blueStandard,
        fontFamily: 'Inter',
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatelessWidget {
  const DemoHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Démo Passages Thématiques'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Widget d\'accueil'),
            const SizedBox(height: AppTheme.spaceMedium),
            // Widget d'accueil intégré
            const ThematicPassagesHomeWidget(),
            
            const SizedBox(height: AppTheme.spaceXLarge),
            
            _buildSectionHeader('Actions disponibles'),
            const SizedBox(height: AppTheme.spaceMedium),
            
            // Boutons de démonstration
            _buildActionButton(
              context,
              'Voir tous les thèmes',
              Icons.collections_bookmark,
              AppTheme.blueStandard,
              () => _showFullView(context),
            ),
            
            const SizedBox(height: AppTheme.space12),
            
            _buildActionButton(
              context,
              'Créer un nouveau thème',
              Icons.add_circle_outline,
              AppTheme.greenStandard,
              () => _showCreateThemeDialog(context),
            ),
            
            const SizedBox(height: AppTheme.space12),
            
            _buildActionButton(
              context,
              'Ajouter un passage',
              Icons.add,
              AppTheme.orangeStandard,
              () => _showAddPassageDialog(context),
            ),
            
            const SizedBox(height: AppTheme.space12),
            
            _buildActionButton(
              context,
              'Initialiser thèmes par défaut',
              Icons.refresh,
              AppTheme.primaryColor,
              () => _initializeDefaultThemes(context),
            ),
            
            const SizedBox(height: AppTheme.spaceXLarge),
            
            _buildSectionHeader('Informations'),
            const SizedBox(height: AppTheme.spaceMedium),
            
            _buildInfoCard(
              'Thèmes pré-définis',
              '10 thèmes avec 58 passages bibliques',
              Icons.auto_awesome,
              AppTheme.blueStandard,
            ),
            
            const SizedBox(height: AppTheme.space12),
            
            _buildInfoCard(
              'Fonctionnalités',
              'Création, édition, suppression, ajout de passages',
              Icons.build,
              AppTheme.greenStandard,
            ),
            
            const SizedBox(height: AppTheme.space12),
            
            _buildInfoCard(
              'Support des plages',
              'Versets individuels ou plages (ex: Matthieu 5:3-12)',
              Icons.view_agenda,
              AppTheme.orangeStandard,
            ),
            
            const SizedBox(height: AppTheme.spaceXLarge),
            
            _buildSectionHeader('Données de démonstration'),
            const SizedBox(height: AppTheme.spaceMedium),
            
            _buildThemesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: AppTheme.fontSize20,
        fontWeight: AppTheme.fontBold,
        color: AppTheme.black100.withOpacity(0.87),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: AppTheme.white100,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spaceMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spaceSmall),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: AppTheme.fontSize16,
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: AppTheme.fontSize14,
                    color: AppTheme.black100.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemesList() {
    final themes = PredefinedThemes.getDefaultThemes();
    
    return Column(
      children: themes.map((themeData) {
        final passages = themeData['passages'] as List;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(AppTheme.space12),
          decoration: BoxDecoration(
            color: AppTheme.grey50,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(color: AppTheme.grey300),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceSmall),
                decoration: BoxDecoration(
                  color: Color(themeData['color'] as int).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  IconData(
                    themeData['iconCodePoint'] as int,
                    fontFamily: themeData['iconFontFamily'] as String?,
                  ),
                  color: Color(themeData['color'] as int),
                  size: 18,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      themeData['name'] as String,
                      style: const TextStyle(
                        fontSize: AppTheme.fontSize14,
                        fontWeight: AppTheme.fontSemiBold,
                      ),
                    ),
                    Text(
                      '${passages.length} passages',
                      style: const TextStyle(
                        fontSize: AppTheme.fontSize12,
                        color: AppTheme.grey500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showFullView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ThematicPassagesView(),
      ),
    );
  }

  void _showCreateThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ThemeCreationDialog(),
    );
  }

  void _showAddPassageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddPassageDialog(
        themeId: 'demo-theme-id',
        themeName: 'Démo Thème',
      ),
    );
  }

  void _initializeDefaultThemes(BuildContext context) async {
    try {
      // Simuler l'initialisation (normalement connecté à Firebase)
      await Future.delayed(const Duration(seconds: 1));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thèmes par défaut initialisés (simulation)'),
            backgroundColor: AppTheme.greenStandard,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }
}

/// Exemples d'utilisation programmatique

class ThematicPassagesExamples {
  
  /// Exemple 1: Initialiser les thèmes par défaut
  static Future<void> initializeDefaultThemes() async {
    try {
      await ThematicPassageService.initializeDefaultThemes();
      print('✅ Thèmes par défaut initialisés avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation: $e');
    }
  }
  
  /// Exemple 2: Créer un thème personnalisé
  static Future<void> createCustomTheme() async {
    try {
      final themeId = await ThematicPassageService.createTheme(
        name: 'Mon Thème Personnel',
        description: 'Un thème créé par l\'utilisateur',
        color: AppTheme.primaryColor,
        icon: Icons.star,
        isPublic: false,
      );
      print('✅ Thème créé avec ID: $themeId');
    } catch (e) {
      print('❌ Erreur lors de la création: $e');
    }
  }
  
  /// Exemple 3: Ajouter un passage à un thème
  static Future<void> addPassageToTheme(String themeId) async {
    try {
      await ThematicPassageService.addPassageToTheme(
        themeId: themeId,
        reference: 'Jean 3:16',
        book: 'Jean',
        chapter: 3,
        startVerse: 16,
        endVerse: null,
        description: 'Le verset le plus connu de la Bible',
      );
      print('✅ Passage ajouté au thème');
    } catch (e) {
      print('❌ Erreur lors de l\'ajout: $e');
    }
  }
  
  /// Exemple 4: Récupérer les thèmes publics
  static void listenToPublicThemes() {
    ThematicPassageService.getPublicThemes().listen(
      (themes) {
        print('📚 ${themes.length} thèmes publics disponibles:');
        for (final theme in themes) {
          print('  - ${theme.name}: ${theme.passages.length} passages');
        }
      },
      onError: (error) {
        print('❌ Erreur lors de l\'écoute: $error');
      },
    );
  }
  
  /// Exemple 5: Afficher les données des thèmes pré-définis
  static void showPredefinedThemesData() {
    final themes = PredefinedThemes.getDefaultThemes();
    
    print('📋 Thèmes pré-définis (${themes.length}):');
    
    int totalPassages = 0;
    for (final themeData in themes) {
      final passages = themeData['passages'] as List;
      totalPassages += passages.length;
      
      print('\n🎯 ${themeData['name']}:');
      print('   Description: ${themeData['description']}');
      print('   Passages: ${passages.length}');
      
      for (final passage in passages) {
        print('   - ${passage['reference']}: ${passage['description']}');
      }
    }
    
    print('\n📊 Total: $totalPassages passages dans ${themes.length} thèmes');
  }
}
