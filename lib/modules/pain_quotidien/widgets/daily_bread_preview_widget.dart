import 'package:flutter/material.dart';
import '../../../../theme.dart';
import '../services/branham_scraping_service.dart';
import '../views/daily_bread_page.dart';
import '../../../theme.dart';

/// Widget d'aperçu du pain quotidien pour la page d'accueil
class DailyBreadPreviewWidget extends StatefulWidget {
  const DailyBreadPreviewWidget({Key? key}) : super(key: key);

  @override
  State<DailyBreadPreviewWidget> createState() => _DailyBreadPreviewWidgetState();
}

class _DailyBreadPreviewWidgetState extends State<DailyBreadPreviewWidget> {
  BranhamQuoteModel? _dailyQuote;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDailyContent();
  }

  Future<void> _loadDailyContent() async {
    try {
      final quote = await BranhamScrapingService.instance.getQuoteOfTheDay();
      if (mounted) {
        setState(() {
          _dailyQuote = quote;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getPreviewText() {
    if (_dailyQuote == null) return '';
    
    // Prendre les 2 premières lignes du pain quotidien (verset biblique)
    final lines = _dailyQuote!.dailyBread
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .take(2)
        .toList();
    
    return lines.join('\n');
  }

  void _navigateToDailyBreadPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DailyBreadPage(initialQuote: _dailyQuote),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFDFDFD), // Blanc pur
            Color(0xFFF8FAFC), // Gris très clair
            Color(0xFFF1F5F9), // Slate très clair
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusCircular),
        border: Border.all(
          color: const Color(0xFFE2E8F0), // Bordure slate subtile
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF475569).withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 12),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppTheme.surfaceColor.withOpacity(0.8),
            blurRadius: 1,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header élégant et professionnel
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        Color(0xFF764BA2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_stories,
                    color: AppTheme.surfaceColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Pain quotidien',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: AppTheme.fontSize20,
                              fontWeight: AppTheme.fontExtraBold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: AppTheme.spaceSmall),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            ),
                            child: const Text(
                              'NOUVEAU',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: AppTheme.fontSize10,
                                fontWeight: AppTheme.fontBold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Verset et citation du jour',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: AppTheme.fontSize14,
                          fontWeight: AppTheme.fontMedium,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.space18),
            
            // Contenu élégant ou état de chargement
            if (_isLoading)
              Container(
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFF8FAFC),
                      const Color(0xFFF1F5F9).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                        ),
                      ),
                      SizedBox(height: AppTheme.spaceSmall),
                      Text(
                        'Chargement...',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: AppTheme.fontSize12,
                          fontWeight: AppTheme.fontMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_dailyQuote != null && _dailyQuote!.dailyBread.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.surfaceColor.withOpacity(0.9),
                      const Color(0xFFF8FAFC).withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E293B).withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.space20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icône de citation élégante
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spaceSmall),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: const Icon(
                          Icons.format_quote,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space10),
                      Text(
                        _getPreviewText(),
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: AppTheme.fontSize14,
                          fontWeight: AppTheme.fontMedium,
                          height: 1.5,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 2, // Limite à 2 lignes
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_dailyQuote!.dailyBreadReference.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.space10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                Color(0xFF764BA2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                          child: Text(
                            _dailyQuote!.dailyBreadReference,
                            style: const TextStyle(
                              color: AppTheme.surfaceColor,
                              fontSize: AppTheme.fontSize13,
                              fontWeight: AppTheme.fontSemiBold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(AppTheme.space20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFF1F5F9),
                      const Color(0xFFE2E8F0).withOpacity(0.5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Text(
                        'Aucun contenu disponible aujourd\'hui',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: AppTheme.fontSize14,
                          fontWeight: AppTheme.fontMedium,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: AppTheme.space18),
            
            // Bouton élégant pour accéder à la page complète
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    Color(0xFF764BA2),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: AppTheme.black100.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  onTap: _navigateToDailyBreadPage,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_stories,
                          color: AppTheme.surfaceColor,
                          size: 18,
                        ),
                        SizedBox(width: AppTheme.space10),
                        Text(
                          'Lire le pain quotidien complet',
                          style: TextStyle(
                            color: AppTheme.surfaceColor,
                            fontSize: AppTheme.fontSize14,
                            fontWeight: AppTheme.fontSemiBold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(width: AppTheme.space6),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: AppTheme.surfaceColor,
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
