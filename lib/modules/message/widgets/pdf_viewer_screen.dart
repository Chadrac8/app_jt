import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/branham_message.dart';
import '../../../../theme.dart';
import '../../../theme.dart';

class PdfViewerScreen extends StatefulWidget {
  final BranhamMessage message;

  const PdfViewerScreen({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeWebView();
    }
  }

  void _initializeWebView() {
    // Utiliser Google Docs Viewer pour afficher le PDF correctement
    final String googleDocsUrl = 'https://docs.google.com/viewer?url=${Uri.encodeComponent(widget.message.pdfUrl)}&embedded=true';
    
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _error = null;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _error = 'Erreur de chargement: ${error.description}';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(googleDocsUrl));
  }

  Future<void> _openInBrowser() async {
    final Uri url = Uri.parse(widget.message.pdfUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Impossible d\'ouvrir l\'URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    }
  }

  void _shareMessage() {
    Share.share(
      'Prédication: ${widget.message.title}\n'
      'Date: ${widget.message.formattedDate}\n'
      'Lieu: ${widget.message.location}\n'
      'Lien PDF: ${widget.message.pdfUrl}',
      subject: 'Prédication - ${widget.message.title}',
    );
  }

  void _refreshPdf() {
    if (!kIsWeb) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      _webViewController.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: AppTheme.white100,
      foregroundColor: AppTheme.primaryColor,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message.title,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize16,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.primaryColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${widget.message.formattedDate} • ${widget.message.location}',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize12,
              color: AppTheme.grey500,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined),
          onPressed: _shareMessage,
          tooltip: 'Partager',
        ),
        if (!kIsWeb)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPdf,
            tooltip: 'Actualiser',
          ),
        IconButton(
          icon: const Icon(Icons.open_in_browser),
          onPressed: _openInBrowser,
          tooltip: 'Ouvrir dans le navigateur',
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (kIsWeb) {
      return _buildWebFallback();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
        if (_isLoading) _buildLoadingState(),
      ],
    );
  }

  Widget _buildWebFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceLarge),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    size: 64,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  Text(
                    widget.message.title,
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize18,
                      fontWeight: AppTheme.fontSemiBold,
                      color: AppTheme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Text(
                    'Cliquez sur le bouton ci-dessous pour ouvrir le PDF dans un nouvel onglet',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      color: AppTheme.grey500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spaceLarge),
                  ElevatedButton.icon(
                    onPressed: _openInBrowser,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Ouvrir le PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.white100,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: AppTheme.white100.withOpacity(0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Chargement du PDF...',
              style: GoogleFonts.inter(
                fontSize: AppTheme.fontSize16,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceLarge),
              decoration: BoxDecoration(
                color: AppTheme.redStandard,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(
                  color: AppTheme.redStandard,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.redStandard,
                  ),
                  const SizedBox(height: AppTheme.spaceMedium),
                  Text(
                    'Erreur de chargement',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize18,
                      fontWeight: AppTheme.fontSemiBold,
                      color: AppTheme.redStandard,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSmall),
                  Text(
                    _error ?? 'Une erreur s\'est produite',
                    style: GoogleFonts.inter(
                      fontSize: AppTheme.fontSize14,
                      color: AppTheme.redStandard,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.spaceLarge),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _refreshPdf,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.redStandard,
                          side: BorderSide(color: AppTheme.redStandard),
                        ),
                      ),
                      const SizedBox(width: AppTheme.space12),
                      ElevatedButton.icon(
                        onPressed: _openInBrowser,
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Ouvrir dans le navigateur'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.redStandard,
                          foregroundColor: AppTheme.white100,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
