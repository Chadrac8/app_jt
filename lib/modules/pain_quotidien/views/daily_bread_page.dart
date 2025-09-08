import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/theme/app_theme.dart';
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

  Future<void> _refreshContent() async {
    // Utiliser le même système que _loadContent pour iOS vs Web
    if (defaultTargetPlatform == TargetPlatform.iOS || 
        defaultTargetPlatform == TargetPlatform.android) {
      print('📱 Rafraîchissement iOS optimisé');
      final iosQuote = await IOSBranhamService.getTodaysQuote();
      if (mounted) {
        setState(() {
          _quote = BranhamQuoteModel(
            text: iosQuote.text,
            reference: iosQuote.reference,
            date: iosQuote.date,
            dailyBread: iosQuote.dailyBread,
            dailyBreadReference: iosQuote.dailyBreadReference,
            sermonTitle: 'Citation du jour',
            sermonDate: 'Mobile',
            audioUrl: '',
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pain quotidien mis à jour (iOS)'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } else {
      // Web - utiliser le service normal
      final refreshedBread = await _scrapingService.getQuoteOfTheDay();
      if (refreshedBread != null && mounted) {
        setState(() {
          _quote = refreshedBread;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pain quotidien mis à jour'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    }
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
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.textSecondaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF374151),
              size: 16,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Pain quotidien',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_quote != null)
            IconButton(
              icon: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.share,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
              onPressed: _shareContent,
            ),
          IconButton(
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.refresh,
                color: AppTheme.primaryColor,
                size: 16,
              ),
            ),
            onPressed: _refreshContent,
          ),
          const SizedBox(width: 8),
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
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
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
                                      borderRadius: BorderRadius.circular(16),
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
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _quote!.date.isNotEmpty ? _quote!.date : _getFormattedDate(),
                                    style: const TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                            // Page continue avec verset et citation
                            _buildContinuousContent(),

                            const SizedBox(height: 32),

                            // Bouton pour voir l'historique
                            _buildHistoryButton(),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                      borderRadius: BorderRadius.circular(12),
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
                        fontWeight: FontWeight.w700,
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
                  fontWeight: FontWeight.w500,
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _quote!.dailyBreadReference,
                      style: const TextStyle(
                        color: AppTheme.surfaceColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
                      borderRadius: BorderRadius.circular(8),
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
                      borderRadius: BorderRadius.circular(12),
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
                        fontWeight: FontWeight.w700,
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
                      fontWeight: FontWeight.w500,
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
                            fontWeight: FontWeight.w600,
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
                          fontWeight: FontWeight.w500,
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFAA6C39).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
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
                                fontWeight: FontWeight.w600,
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

  Widget _buildHistoryButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            const Color(0xFF764BA2).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // TODO: Navigate to history page
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Historique - Bientôt disponible'),
                backgroundColor: AppTheme.primaryColor,
              ),
            );
          },
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                SizedBox(width: 12),
                Text(
                  'Voir l\'historique',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.primaryColor,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


