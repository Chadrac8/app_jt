import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme.dart';

class SimpleDonationWebViewPage extends StatefulWidget {
  final String donationType;
  final String url;
  final IconData icon;
  final Color color;

  const SimpleDonationWebViewPage({
    Key? key,
    required this.donationType,
    required this.url,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  State<SimpleDonationWebViewPage> createState() => _SimpleDonationWebViewPageState();
}

class _SimpleDonationWebViewPageState extends State<SimpleDonationWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

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
      ..setUserAgent('Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1')
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            // Permettre tous les domaines nécessaires pour HelloAsso et le paiement
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.white100,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(AppTheme.spaceSmall),
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
        title: Text(
          widget.donationType,
          style: GoogleFonts.poppins(
            color: AppTheme.textPrimaryColor,
            fontSize: AppTheme.fontSize18,
            fontWeight: AppTheme.fontSemiBold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(AppTheme.spaceSmall),
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
            onPressed: () => _controller.reload(),
          ),
          const SizedBox(width: AppTheme.spaceSmall),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: AppTheme.white100,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                    Text(
                      'Chargement de ${widget.donationType}...',
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize16,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
