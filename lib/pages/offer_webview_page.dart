import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class OfferWebViewPage extends StatefulWidget {
  const OfferWebViewPage({Key? key}) : super(key: key);

  @override
  State<OfferWebViewPage> createState() => _OfferWebViewPageState();
}

class _OfferWebViewPageState extends State<OfferWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _loadingProgress = 0;
  bool _webViewReady = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.white100)
      ..enableZoom(true)
      ..setUserAgent('Mozilla/5.0 (Mobile; rv:100.0) Gecko/100.0 Firefox/100.0')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress;
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
                _loadingProgress = 0;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _webViewReady = true;
                _loadingProgress = 100;
              });
              
              // Injection de CSS pour optimiser l'affichage mobile
              _controller.runJavaScript('''
                var style = document.createElement('style');
                style.textContent = `
                  body { 
                    zoom: 1.0 !important; 
                    font-size: 14px !important;
                  }
                  .navbar, .header, .top-banner { 
                    display: none !important; 
                  }
                  .container, .main-content { 
                    margin-top: 0 !important; 
                    padding-top: 10px !important;
                  }
                  img { 
                    max-width: 100% !important; 
                    height: auto !important; 
                  }
                `;
                document.head.appendChild(style);
              ''');
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = error.description;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Permettre la navigation sur HelloAsso et domaines associés
            if (request.url.startsWith('https://www.helloasso.com') ||
                request.url.startsWith('https://helloasso.com') ||
                request.url.startsWith('https://checkout.helloasso.com') ||
                request.url.startsWith('https://api.helloasso.com') ||
                request.url.startsWith('https://assets.helloasso.com')) {
              return NavigationDecision.navigate;
            }
            // Bloquer les autres domaines pour la sécurité
            return NavigationDecision.prevent;
          },
        ),
      );
    
    // Pré-charger la page immédiatement
    _preloadWebView();
  }

  void _preloadWebView() async {
    try {
      await _controller.loadRequest(
        Uri.parse('https://www.helloasso.com/associations/jubile-tabernacle/formulaires/1'),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Erreur de chargement: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white100,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.white100,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Icon(
            Icons.arrow_back_ios,
            color: AppTheme.primaryColor,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        children: [
          Text(
            'Offrande en ligne',
            style: GoogleFonts.poppins(
              color: AppTheme.textPrimaryColor,
              fontSize: 18,
              fontWeight: AppTheme.fontSemiBold,
            ),
          ),
          Text(
            'HelloAsso - Sécurisé',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
              fontWeight: AppTheme.fontRegular,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.greenStandard.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: const Icon(
              Icons.security,
              color: AppTheme.greenStandard,
              size: 18,
            ),
          ),
          onPressed: () => _showSecurityInfo(),
        ),
        const SizedBox(width: 8),
      ],
      bottom: _isLoading
          ? PreferredSize(
              preferredSize: const Size.fromHeight(4),
              child: Container(
                height: 4,
                child: LinearProgressIndicator(
                  value: _loadingProgress / 100,
                  backgroundColor: AppTheme.grey500.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return _buildErrorView();
    }

    return Stack(
      children: [
        if (_webViewReady) 
          WebViewWidget(controller: _controller)
        else
          Container(color: AppTheme.white100),
        if (_isLoading) _buildLoadingOverlay(),
        if (_isLoading && _loadingProgress > 30) _buildQuickAccessButton(),
      ],
    );
  }

  Widget _buildQuickAccessButton() {
    return Positioned(
      bottom: 100,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white100,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppTheme.black100.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Chargement en cours...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'La page se charge depuis HelloAsso',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Retour'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondaryColor,
                      side: BorderSide(color: AppTheme.grey500.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _skipToWebView,
                    icon: const Icon(Icons.flash_on, size: 16),
                    label: const Text('Continuer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.white100,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 36),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _skipToWebView() {
    setState(() {
      _isLoading = false;
      _webViewReady = true;
    });
  }

  Widget _buildLoadingOverlay() {
    final tips = [
      'Plateforme sécurisée HelloAsso',
      'Reçu fiscal automatique après votre don',
      'Déduction fiscale de 66% possible',
      'Chargement de la page d\'offrande...',
    ];
    
    return Container(
      color: AppTheme.white100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              ),
              child: Icon(
                Icons.favorite,
                color: AppTheme.primaryColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Offrande en ligne',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                tips[(_loadingProgress ~/ 25).clamp(0, tips.length - 1)],
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: _webViewReady ? 1.0 : _loadingProgress / 100,
                    strokeWidth: 4,
                    backgroundColor: AppTheme.grey500.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
                Text(
                  '${_loadingProgress}%',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_loadingProgress > 50) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.greenStandard.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.security,
                      color: AppTheme.greenStandard,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Connexion sécurisée',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.greenStandard,
                        fontWeight: AppTheme.fontMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: AppTheme.white100,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.redStandard.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppTheme.redStandard,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Erreur de connexion',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Impossible de charger la page d\'offrande.\nVérifiez votre connexion internet.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.grey500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  'Détails: $_errorMessage',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Retour'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondaryColor,
                      side: BorderSide(color: AppTheme.grey500.withOpacity(0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _retryLoading,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.white100,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _retryLoading() {
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    _controller.reload();
  }

  void _showSecurityInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.white100,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.greenStandard.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: const Icon(
                    Icons.security,
                    color: AppTheme.greenStandard,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Sécurité & Confidentialité',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: AppTheme.fontSemiBold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSecurityItem(
              Icons.verified_user,
              'Plateforme certifiée',
              'HelloAsso est certifié et régulé par l\'ACPR',
            ),
            _buildSecurityItem(
              Icons.lock,
              'Paiement sécurisé',
              'Chiffrement SSL 256 bits et conformité PCI DSS',
            ),
            _buildSecurityItem(
              Icons.receipt_long,
              'Reçu fiscal automatique',
              'Déduction fiscale de 66% de votre don',
            ),
            _buildSecurityItem(
              Icons.shield,
              'Données protégées',
              'Vos informations ne sont jamais partagées',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.white100,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: Text(
                  'Compris',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: AppTheme.fontSemiBold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.greenStandard,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: AppTheme.fontSemiBold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
