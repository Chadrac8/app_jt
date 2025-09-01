import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/theme/app_theme.dart';
import '../services/branham_scraping_service.dart';

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
        quote = await _scrapingService.getQuoteOfTheDay();
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
    final refreshedBread = await _scrapingService.forceUpdate();
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
                          
                            // Verset du jour (Pain quotidien)
                            if (_quote!.dailyBread.isNotEmpty) ...[
                              _buildVersetCard(
                                title: 'Verset du jour',
                                content: _quote!.dailyBread,
                                reference: _quote!.dailyBreadReference,
                                icon: Icons.menu_book,
                              ),
                              const SizedBox(height: 32),
                            ],

                            // Citation du jour
                            if (_quote!.text.isNotEmpty) ...[
                              _buildCitationCard(
                                title: 'Citation du jour',
                                content: _quote!.text,
                                reference: _quote!.reference,
                                sermonTitle: _quote!.sermonTitle,
                                sermonDate: _quote!.sermonDate,
                                audioUrl: _quote!.audioUrl,
                              ),
                              const SizedBox(height: 32),
                            ],

                            // Bouton pour voir l'historique
                            _buildHistoryButton(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildVersetCard({
    required String title,
    required String content,
    required String reference,
    required IconData icon,
  }) {
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFF8FAFC),
                    const Color(0xFFF1F5F9).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.7,
                      letterSpacing: 0.2,
                    ),
                  ),
                  if (reference.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, Color(0xFF764BA2)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        reference,
                        style: const TextStyle(
                          color: AppTheme.surfaceColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitationCard({
    required String title,
    required String content,
    required String reference,
    String? sermonTitle,
    String? sermonDate,
    String? audioUrl,
  }) {
    return _ExpandableCitationCard(
      title: title,
      content: content,
      reference: reference,
      sermonTitle: sermonTitle,
      sermonDate: sermonDate,
      audioUrl: audioUrl,
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

/// Widget stateful pour gérer l'expansion/réduction des citations longues
class _ExpandableCitationCard extends StatefulWidget {
  final String title;
  final String content;
  final String reference;
  final String? sermonTitle;
  final String? sermonDate;
  final String? audioUrl;

  const _ExpandableCitationCard({
    required this.title,
    required this.content,
    required this.reference,
    this.sermonTitle,
    this.sermonDate,
    this.audioUrl,
  });

  @override
  State<_ExpandableCitationCard> createState() => _ExpandableCitationCardState();
}

class _ExpandableCitationCardState extends State<_ExpandableCitationCard> {
  bool _isExpanded = false;
  static const int _maxLength = 200; // Longueur max avant "Lire plus"

  @override
  Widget build(BuildContext context) {
    final bool isLongText = widget.content.length > _maxLength;
    
    String displayText = widget.content;
    if (isLongText && !_isExpanded) {
      // Trouve le dernier espace avant la limite pour éviter de couper au milieu d'un mot
      int cutPosition = _maxLength;
      for (int i = _maxLength - 1; i >= 0; i--) {
        if (widget.content[i] == ' ') {
          cutPosition = i;
          break;
        }
      }
      displayText = widget.content.substring(0, cutPosition);
    }

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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.format_quote,
                    color: Color(0xFFD97706),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFFEF3C7).withOpacity(0.3),
                    const Color(0xFFFDE68A).withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFDE68A),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '"$displayText${isLongText && !_isExpanded ? '...' : ''}"',
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.7,
                      letterSpacing: 0.2,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (isLongText) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: const Color(0xFF3B82F6),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isExpanded ? 'Lire moins' : 'Lire plus',
                              style: const TextStyle(
                                color: Color(0xFF3B82F6),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    '— William Marrion Branham',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.sermonTitle != null && widget.sermonTitle!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.sermonTitle!,
                        style: const TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
