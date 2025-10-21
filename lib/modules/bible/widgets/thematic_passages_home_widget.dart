import 'package:flutter/material.dart';
import '../../../../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/thematic_passage_model.dart';
import '../services/thematic_passage_service.dart';
import '../views/thematic_passages_view.dart';

class ThematicPassagesHomeWidget extends StatelessWidget {
  const ThematicPassagesHomeWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2)),
        ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Padding(
            padding: const EdgeInsets.all(AppTheme.space20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.space12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                  child: Icon(
                    Icons.collections_bookmark,
                    color: AppTheme.primaryColor,
                    size: 24)),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Passages thématiques',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize18,
                          fontWeight: AppTheme.fontBold,
                          color: theme.colorScheme.onSurface)),
                      const SizedBox(height: AppTheme.spaceXSmall),
                      Text(
                        'Collections de versets par thème',
                        style: GoogleFonts.inter(
                          fontSize: AppTheme.fontSize14,
                          color: theme.colorScheme.onSurface.withOpacity(0.7))),
                    ])),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ThematicPassagesView()));
                  },
                  child: Text(
                    'Voir tout',
                    style: GoogleFonts.inter(
                      fontWeight: AppTheme.fontSemiBold,
                      color: theme.colorScheme.primary))),
              ])),
          
          // Liste des thèmes populaires
          StreamBuilder<List<BiblicalTheme>>(
            stream: ThematicPassageService.getPublicThemes(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingShimmer();
              }
              
              if (snapshot.hasError) {
                print('Erreur dans ThematicPassagesHomeWidget: ${snapshot.error}');
                return Padding(
                  padding: const EdgeInsets.all(AppTheme.space20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: theme.colorScheme.error.withOpacity(0.6)),
                      const SizedBox(height: AppTheme.space12),
                      Text(
                        'Erreur de chargement',
                        style: GoogleFonts.inter(
                          color: theme.colorScheme.error,
                          fontSize: AppTheme.fontSize16,
                          fontWeight: AppTheme.fontSemiBold)),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Text(
                        'Impossible de charger les thèmes bibliques',
                        style: GoogleFonts.inter(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: AppTheme.fontSize14),
                        textAlign: TextAlign.center),
                      const SizedBox(height: AppTheme.spaceMedium),
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            // Vérifier la connexion Firebase d'abord
                            final isConnected = await ThematicPassageService.checkFirebaseConnection();
                            if (!isConnected) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Problème de connexion à Firebase'),
                                  backgroundColor: AppTheme.warningColor));
                              return;
                            }
                            
                            await ThematicPassageService.initializeDefaultThemes();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Thèmes initialisés avec succès'),
                                backgroundColor: AppTheme.successColor));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur: $e'),
                                backgroundColor: AppTheme.errorColor));
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          'Initialiser les thèmes',
                          style: GoogleFonts.inter(fontWeight: AppTheme.fontSemiBold))),
                    ]));
              }
              
              final themes = snapshot.data ?? [];
              
              if (themes.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppTheme.space20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.collections_bookmark_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurface.withOpacity(0.3)),
                      const SizedBox(height: AppTheme.space12),
                      Text(
                        'Aucun thème disponible',
                        style: GoogleFonts.inter(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: AppTheme.fontSize16)),
                      const SizedBox(height: AppTheme.spaceSmall),
                      TextButton(
                        onPressed: () async {
                          await ThematicPassageService.initializeDefaultThemes();
                        },
                        child: Text(
                          'Initialiser les thèmes par défaut',
                          style: GoogleFonts.inter(
                            color: theme.colorScheme.primary,
                            fontWeight: AppTheme.fontSemiBold))),
                    ]));
              }
              
              // Afficher les 3 premiers thèmes
              final displayedThemes = themes.take(3).toList();
              
              return Column(
                children: [
                  ...displayedThemes.map((theme) => _ThemeCard(theme: theme)),
                  if (themes.length > 3)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ThematicPassagesView()));
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.3)),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Voir ${themes.length - 3} autres thèmes',
                                style: GoogleFonts.inter(
                                  color: theme.colorScheme.primary,
                                  fontWeight: AppTheme.fontSemiBold)),
                              const SizedBox(width: AppTheme.spaceSmall),
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: theme.colorScheme.primary),
                            ])))),
                  const SizedBox(height: AppTheme.spaceSmall),
                ]);
            }),
        ]));
  }
}

class _ThemeCard extends StatelessWidget {
  final BiblicalTheme theme;
  
  const _ThemeCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ThematicPassagesView(selectedThemeId: theme.id)));
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceMedium),
          decoration: BoxDecoration(
            color: theme.color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: theme.color.withOpacity(0.2),
              width: 1)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceSmall),
                decoration: BoxDecoration(
                  color: theme.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall)),
                child: Icon(
                  theme.icon,
                  color: theme.color,
                  size: 20)),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.name,
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize15,
                        fontWeight: AppTheme.fontSemiBold,
                        color: themeData.colorScheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(
                      theme.description,
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize13,
                        color: themeData.colorScheme.onSurface.withOpacity(0.6)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  ])),
              const SizedBox(width: AppTheme.spaceSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
                child: Text(
                  '${theme.passages.length}',
                  style: GoogleFonts.inter(
                    fontSize: AppTheme.fontSize12,
                    fontWeight: AppTheme.fontSemiBold,
                    color: theme.color))),
              const SizedBox(width: AppTheme.spaceSmall),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: themeData.colorScheme.onSurface.withOpacity(0.4)),
            ]))));
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: List.generate(3, (index) => 
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.textTertiaryColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium))))));
  }
}
