import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class DonationWebViewPage extends StatefulWidget {
  final String donationType;
  final String url;
  final IconData icon;
  final Color color;

  const DonationWebViewPage({
    Key? key,
    required this.donationType,
    required this.url,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  State<DonationWebViewPage> createState() => _DonationWebViewPageState();
}

class _DonationWebViewPageState extends State<DonationWebViewPage> {
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
      ..clearCache()
      ..clearLocalStorage()
      ..setUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1')
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
              
              // Injection de CSS pour optimiser l'affichage mobile sans cacher les éléments de paiement
              _controller.runJavaScript('''
                // Attendre que la page soit complètement chargée
                setTimeout(function() {
                  var style = document.createElement('style');
                  style.textContent = `
                    body { 
                      font-size: 14px !important;
                      line-height: 1.4 !important;
                    }
                    .container, .main-content { 
                      padding: 10px !important;
                    }
                    img { 
                      max-width: 100% !important; 
                      height: auto !important; 
                    }
                    /* Assurer que les formulaires de paiement restent visibles */
                    form, .form-group, .payment-form, .checkout-form,
                    input[type="text"], input[type="email"], input[type="tel"],
                    select, button, .btn, .button {
                      display: block !important;
                      visibility: visible !important;
                      opacity: 1 !important;
                    }
                    /* Améliorer la lisibilité sur mobile */
                    .form-control, input, select, textarea {
                      font-size: 16px !important;
                      padding: 12px !important;
                      border-radius: 8px !important;
                    }
                  `;
                  document.head.appendChild(style);
                  
                  // Forcer le rechargement des scripts de paiement si nécessaire
                  var scripts = document.querySelectorAll('script[src*="stripe"], script[src*="payment"], script[src*="checkout"]');
                  scripts.forEach(function(script) {
                    var newScript = document.createElement('script');
                    newScript.src = script.src;
                    script.parentNode.replaceChild(newScript, script);
                  });
                }, 2000);
              ''');
            }
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView Error: ${error.description} - ${error.errorCode}');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = error.description;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation request: ${request.url}');
            // Permettre la navigation sur HelloAsso et tous les domaines de paiement
            if (request.url.startsWith('https://www.helloasso.com') ||
                request.url.startsWith('https://helloasso.com') ||
                request.url.startsWith('https://checkout.helloasso.com') ||
                request.url.startsWith('https://api.helloasso.com') ||
                request.url.startsWith('https://assets.helloasso.com') ||
                request.url.startsWith('https://js.stripe.com') ||
                request.url.startsWith('https://checkout.stripe.com') ||
                request.url.startsWith('https://m.stripe.com') ||
                request.url.startsWith('https://hooks.stripe.com') ||
                request.url.startsWith('https://payments.helloasso.org') ||
                request.url.startsWith('https://secure.helloasso.org')) {
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
      // Ajouter des en-têtes pour améliorer la compatibilité
      await _controller.loadRequest(
        Uri.parse(widget.url),
        headers: {
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'fr-FR,fr;q=0.8,en-US;q=0.5,en;q=0.3',
          'Accept-Encoding': 'gzip, deflate, br',
          'DNT': '1',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
          'Sec-Fetch-Dest': 'document',
          'Sec-Fetch-Mode': 'navigate',
          'Sec-Fetch-Site': 'none',
          'Cache-Control': 'max-age=0',
        },
      );
    } catch (e) {
      print('Error loading WebView: $e');
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
            color: widget.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Icon(
            Icons.arrow_back_ios,
            color: widget.color,
            size: 18,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        children: [
          Text(
            widget.donationType,
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
              color: AppTheme.blueStandard.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: const Icon(
              Icons.refresh,
              color: AppTheme.blueStandard,
              size: 18,
            ),
          ),
          onPressed: () => _reloadPage(),
        ),
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
                  valueColor: AlwaysStoppedAnimation<Color>(widget.color),
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

  Widget _buildLoadingOverlay() {
    final tips = _getTipsForDonationType();
    
    return Container(
      color: AppTheme.white100,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              ),
              child: Icon(
                widget.icon,
                color: widget.color,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.donationType,
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
                    valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                  ),
                ),
                Text(
                  '${_loadingProgress}%',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: AppTheme.fontSemiBold,
                    color: widget.color,
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

  List<String> _getTipsForDonationType() {
    switch (widget.donationType.toLowerCase()) {
      case 'loyer de l\'église':
        return [
          'Soutenez notre lieu de culte',
          'Participation aux frais de location',
          'Plateforme sécurisée HelloAsso',
          'Chargement de la page de don...',
        ];
      case 'dîme':
        return [
          'Fidélité selon les Écritures',
          'Apportez toutes les dîmes à la maison du trésor',
          'Plateforme sécurisée HelloAsso',
          'Chargement de la page de dîme...',
        ];
      case 'achat du local':
        return [
          'Investir dans l\'avenir de l\'église',
          'Acquisition de notre propre lieu',
          'Plateforme sécurisée HelloAsso',
          'Chargement de la page de contribution...',
        ];
      default:
        return [
          'Plateforme sécurisée HelloAsso',
          'Reçu fiscal automatique après votre don',
          'Déduction fiscale de 66% possible',
          'Chargement de la page de don...',
        ];
    }
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
                      backgroundColor: widget.color,
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
              'Impossible de charger la page de don.\nVérifiez votre connexion internet.',
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
                      backgroundColor: widget.color,
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

  void _reloadPage() {
    setState(() {
      _hasError = false;
      _isLoading = true;
      _webViewReady = false;
      _loadingProgress = 0;
    });
    _controller.clearCache();
    _controller.clearLocalStorage();
    _preloadWebView();
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
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.blueStandard.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Problème de chargement ?',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: AppTheme.fontSemiBold,
                      color: AppTheme.blueStandard,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Si les informations de paiement ne s\'affichent pas, essayez de recharger la page avec le bouton 🔄',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
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
