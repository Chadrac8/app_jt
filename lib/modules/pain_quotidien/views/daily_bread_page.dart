import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../theme.dart';
import '../services/branham_scraping_service.dart';
import '../services/ios_branham_service.dart';

class DailyBreadPage extends StatefulWidget {
  final BranhamQuoteModel? initialQuote;
  
  const DailyBreadPage({
    Key? key,
    this.initialQuote,
  }) : super(key: key);

  @override
  State<DailyBreadPage> createState() => _DailyBreadPageState();
}

class _DailyBreadPageState extends State<DailyBreadPage> {
  final BranhamScrapingService _scrapingService = BranhamScrapingService.instance;
  BranhamQuoteModel? _quote;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      BranhamQuoteModel? quote;
      if (widget.initialQuote != null) {
        quote = widget.initialQuote;
      } else {
        // Détecter si on est sur iOS/mobile et utiliser le service approprié
        if (defaultTargetPlatform == TargetPlatform.iOS || 
            defaultTargetPlatform == TargetPlatform.android) {
          print('📱 Utilisation du service iOS optimisé');
          final iosQuote = await IOSBranhamService.getTodaysQuote();
          quote = BranhamQuoteModel(
            text: iosQuote.text,
            reference: iosQuote.reference,
            date: iosQuote.date,
            dailyBread: iosQuote.dailyBread,
            dailyBreadReference: iosQuote.dailyBreadReference,
            sermonTitle: 'Citation du jour',
            sermonDate: 'Mobile',
            audioUrl: '',
          );
        } else {
          // Utiliser le service normal pour web
          quote = await _scrapingService.getQuoteOfTheDay();
        }
      }

      setState(() {
        _quote = quote;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _shareContent() async {
    if (_quote == null) return;

    await Share.share(
      _quote!.shareText,
      subject: 'Pain quotidien - ${_quote!.date}',
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        toolbarHeight: 56.0, // Hauteur standard Material Design
        title: const Text('Pain quotidien'),
        actions: [
          if (_quote != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareContent,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.textPrimaryColor),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadContent,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.surfaceColor,
                        ),
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _quote == null
                  ? const Center(
                      child: Text(
                        'Aucun contenu disponible',
                        style: TextStyle(color: AppTheme.textPrimaryColor),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFF8F9FA),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header avec date
                            Container(
                              margin: const EdgeInsets.only(bottom: 32),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceColor,
                                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.black100.withOpacity(0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                    ),
                                    child: const Icon(
                                      Icons.today_rounded,
                                      color: AppTheme.primaryColor,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Pain quotidien',
                                    style: TextStyle(
                                      color: Color(0xFF1A1A1A),
                                      fontSize: 24,
                                      fontWeight: AppTheme.fontBold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _quote!.date.isNotEmpty ? _quote!.date : _getFormattedDate(),
                                    style: const TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 16,
                                      fontWeight: AppTheme.fontMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                            // Page continue avec verset et citation
                            _buildContinuousContent(),

                            const SizedBox(height: 32),

                            // Source attribution
                            Center(
                              child: Text(
                                'Source : www.branham.org',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor.withOpacity(0.6),
                                  fontSize: 12,
                                  fontWeight: AppTheme.fontRegular,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildContinuousContent() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black100.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verset biblique
            if (_quote!.dailyBread.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: const Icon(
                      Icons.menu_book,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Verset du jour',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 20,
                        fontWeight: AppTheme.fontBold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Contenu du verset
              Text(
                _quote!.dailyBread,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 19,
                  fontWeight: AppTheme.fontMedium,
                  height: 1.7,
                  letterSpacing: 0.2,
                ),
              ),
              
              if (_quote!.dailyBreadReference.isNotEmpty) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, Color(0xFF764BA2)],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: Text(
                      _quote!.dailyBreadReference,
                      style: const TextStyle(
                        color: AppTheme.surfaceColor,
                        fontSize: 14,
                        fontWeight: AppTheme.fontSemiBold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ],

            // Séparateur élégant
            if (_quote!.dailyBread.isNotEmpty && _quote!.text.isNotEmpty) ...[
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppTheme.primaryColor.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppTheme.primaryColor.withOpacity(0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],

            // Citation du jour
            if (_quote!.text.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFAA6C39).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                    child: const Icon(
                      Icons.format_quote,
                      color: Color(0xFFAA6C39),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Citation du jour',
                      style: TextStyle(
                        color: Color(0xFF1A1A1A),
                        fontSize: 20,
                        fontWeight: AppTheme.fontBold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Contenu de la citation
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"${_quote!.text}"',
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 18,
                      fontWeight: AppTheme.fontMedium,
                      height: 1.6,
                      letterSpacing: 0.2,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Informations sur la prédication
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_quote!.sermonTitle.isNotEmpty) ...[
                        Text(
                          _quote!.sermonTitle,
                          style: const TextStyle(
                            color: Color(0xFFAA6C39),
                            fontSize: 15,
                            fontWeight: AppTheme.fontSemiBold,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        '— William Marrion Branham',
                        style: TextStyle(
                          color: const Color(0xFF1E293B).withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: AppTheme.fontMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Bouton audio si disponible
              if (_quote!.audioUrl.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFAA6C39).withOpacity(0.1),
                        const Color(0xFFAA6C39).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: const Color(0xFFAA6C39).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      onTap: () {
                        // TODO: Implémenter la lecture audio
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Lecture audio - Bientôt disponible'),
                            backgroundColor: Color(0xFFAA6C39),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              color: Color(0xFFAA6C39),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Écouter la prédication',
                              style: TextStyle(
                                color: Color(0xFFAA6C39),
                                fontSize: 15,
                                fontWeight: AppTheme.fontSemiBold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}


