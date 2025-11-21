import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../theme.dart';

class HelloAssoIframePage extends StatefulWidget {
  final String donationType;
  final IconData icon;
  final Color color;
  final String donationUrl;

  const HelloAssoIframePage({
    Key? key,
    required this.donationType,
    required this.icon,
    required this.color,
    required this.donationUrl,
  }) : super(key: key);

  @override
  State<HelloAssoIframePage> createState() => _HelloAssoIframePageState();
}

class _HelloAssoIframePageState extends State<HelloAssoIframePage> {
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
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadHtmlString(_buildHtmlContent());
  }

  String _buildHtmlContent() {
    return '''
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Faire un don - Jubilé Tabernacle</title>
    <style>
        body {
            margin: 0;
            padding: 20px;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
            background-color: #f8f9fa;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            border-radius: 12px;
            padding: 24px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 24px;
        }
        .header h1 {
            color: #1976d2;
            margin-bottom: 8px;
        }
        .header p {
            color: #666;
            margin: 0;
        }
        .iframe-container {
            width: 100%;
            display: flex;
            justify-content: center;
            margin-top: 20px;
        }
        iframe {
            border: none;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .footer {
            text-align: center;
            margin-top: 24px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            color: #666;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>${widget.donationType}</h1>
            <p>Plateforme sécurisée HelloAsso</p>
        </div>
        
        <div class="iframe-container">
            <iframe 
                id="haWidgetLight" 
                allowtransparency="true" 
                allow="payment" 
                scrolling="auto" 
                src="${widget.donationUrl}/widget?view=form" 
                style="width: clamp(300px, 100%, 26rem); margin: 0 auto; border: none;" 
                onload="window.addEventListener('message', e => {
                    const dataHeight = e.data.height; 
                    const haWidgetElement = document.getElementById('haWidgetLight'); 
                    haWidgetElement.height = dataHeight + 'px';
                })">
            </iframe>
        </div>
        
        <div class="footer">
            <p>🔒 Paiement 100% sécurisé</p>
            <p>Reçu fiscal automatique par email</p>
        </div>
    </div>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.donationType,
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        foregroundColor: colorScheme.primary,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: colorScheme.surface,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: widget.color,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chargement du formulaire de don...',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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