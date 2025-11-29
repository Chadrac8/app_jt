import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../theme.dart';
import '../services/branham_scraping_service.dart';

class DailyBreadPage extends StatefulWidget {
  const DailyBreadPage({
    Key? key,
  }) : super(key: key);

  @override
  State<DailyBreadPage> createState() => _DailyBreadPageState();
}

class _DailyBreadPageState extends State<DailyBreadPage> {
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

      // Récupérer le contenu depuis branham.org
      final quote = await BranhamScrapingService.instance.getQuoteOfTheDay();
      
      if (quote != null) {
        setState(() {
          _quote = quote;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Impossible de charger le pain quotidien';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement: $e';
        _isLoading = false;
      });
    }
  }

  // Copier le contenu dans le presse-papiers
  Future<void> _copyContent() async {
    if (_quote == null) return;

    try {
      await Clipboard.setData(ClipboardData(text: _quote!.shareText));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Contenu copié dans le presse-papiers'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Erreur lors de la copie : ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Copier uniquement le verset
  Future<void> _copyVerse() async {
    if (_quote == null) return;

    try {
      final verseText = '${_quote!.dailyBread}\n${_quote!.dailyBreadReference}';
      await Clipboard.setData(ClipboardData(text: verseText));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Verset copié'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Copier uniquement la citation
  Future<void> _copyQuote() async {
    if (_quote == null) return;

    try {
      final quoteText = '"${_quote!.text}"\n— William Marrion Branham\n${_quote!.sermonTitle}';
      await Clipboard.setData(ClipboardData(text: quoteText));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Citation copiée'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Afficher le dialog avec les options de partage
  Future<void> _showShareOptions() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.white100,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.share, color: AppTheme.primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Partager le pain quotidien',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Option 1: Partager tout via les applications
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.share_outlined, color: AppTheme.primaryColor),
              ),
              title: const Text('Partager tout'),
              subtitle: const Text('Verset + Citation via WhatsApp, Email, etc.'),
              onTap: () {
                Navigator.pop(context);
                _shareViaApps();
              },
            ),
            
            // Option 2: Copier tout
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.content_copy, color: AppTheme.secondaryColor),
              ),
              title: const Text('Copier tout'),
              subtitle: const Text('Copier le verset et la citation'),
              onTap: () {
                Navigator.pop(context);
                _copyContent();
              },
            ),
            
            // Option 3: Copier uniquement le verset
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.menu_book, color: Colors.blue),
              ),
              title: const Text('Copier le verset'),
              subtitle: const Text('Verset biblique uniquement'),
              onTap: () {
                Navigator.pop(context);
                _copyVerse();
              },
            ),
            
            // Option 4: Copier uniquement la citation
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.tertiaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.format_quote, color: AppTheme.tertiaryColor),
              ),
              title: const Text('Copier la citation'),
              subtitle: const Text('Citation de William Branham uniquement'),
              onTap: () {
                Navigator.pop(context);
                _copyQuote();
              },
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // Partager via les applications système
  Future<void> _shareViaApps() async {
    if (_quote == null) return;

    try {
      // Utiliser Share.share au lieu de shareWithResult pour éviter les problèmes iOS
      await Share.share(
        _quote!.shareText,
        subject: 'Pain quotidien - ${_quote!.date}',
      );
      
      // Note: Share.share ne retourne pas de résultat, donc pas de feedback de succès
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Erreur lors du partage : ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Méthode principale de partage (appelle le dialog)
  Future<void> _shareContent() async {
    await _showShareOptions();
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Theme(
      data: theme.copyWith(
        // Force Material 3 color scheme
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primaryColor,
          brightness: theme.brightness,
          surface: AppTheme.surface,
          onSurface: AppTheme.onSurface,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 1,
          surfaceTintColor: AppTheme.surfaceTint,
          backgroundColor: AppTheme.surface,
          foregroundColor: AppTheme.onSurface,
          centerTitle: defaultTargetPlatform == TargetPlatform.iOS,
          title: Text(
            'Pain quotidien',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: AppTheme.onSurface,
            ),
          ),
          actions: [
            if (_quote != null) ...[
              IconButton(
                icon: Icon(
                  Icons.share_outlined,
                  color: AppTheme.onSurface,
                ),
                tooltip: 'Partager',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _shareContent();
                },
              ),
              const SizedBox(width: 4),
            ],
          ],
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: theme.brightness == Brightness.light 
                ? Brightness.dark 
                : Brightness.light,
            systemNavigationBarColor: AppTheme.surface,
            systemNavigationBarIconBrightness: theme.brightness == Brightness.light 
                ? Brightness.dark 
                : Brightness.light,
          ),
        ),
        body: _isLoading
            ? _buildLoadingState()
            : _error != null
                ? _buildErrorState()
                : _quote == null
                    ? _buildEmptyState()
                    : _buildContentState(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Loading indicator with Material 3 style
          SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: AppTheme.spaceLarge),
          Text(
            'Chargement du pain quotidien...',
            style: TextStyle(
              color: AppTheme.onSurface.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon with Material 3 styling
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusRound),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppTheme.error,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              _error!,
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            // Retry button with Material 3 styling
            FilledButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                _loadContent();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.onPrimaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceLarge,
                  vertical: AppTheme.spaceMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusRound),
              ),
              child: Icon(
                Icons.menu_book_outlined,
                size: 40,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLarge),
            Text(
              'Aucun contenu disponible',
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Text(
              'Le pain quotidien n\'est pas disponible pour le moment.',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentState() {
    return CustomScrollView(
      physics: defaultTargetPlatform == TargetPlatform.iOS 
          ? const BouncingScrollPhysics()
          : const ClampingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.all(
            defaultTargetPlatform == TargetPlatform.iOS 
                ? AppTheme.spaceLarge 
                : AppTheme.spaceMedium,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Content Card avec verset et citation (commence directement)
              _buildContentCard(),
              const SizedBox(height: AppTheme.spaceLarge),

              // Source attribution
              _buildSourceAttribution(),
              const SizedBox(height: AppTheme.spaceMedium),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildContentCard() {
    return Card(
      elevation: 0,
      color: AppTheme.surface,
      surfaceTintColor: AppTheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        side: BorderSide(
          color: AppTheme.outline.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verset biblique section
            if (_quote!.dailyBread.isNotEmpty) ...[
              _buildVerseSection(),
              
              // Divider entre verset et citation
              if (_quote!.text.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceXLarge),
                _buildSectionDivider(),
                const SizedBox(height: AppTheme.spaceXLarge),
              ],
            ],

            // Citation section
            if (_quote!.text.isNotEmpty) ...[
              _buildQuoteSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSourceAttribution() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMedium,
          vertical: AppTheme.spaceSmall,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: Text(
          'Source : www.branham.org',
          style: TextStyle(
            color: AppTheme.onSurfaceVariant.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildVerseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(
                Icons.menu_book_outlined,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: Text(
                'Verset du jour',
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceLarge),
        
        // Verse content
        Text(
          _quote!.dailyBread,
          style: TextStyle(
            color: AppTheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            height: 1.6,
            letterSpacing: 0.2,
          ),
        ),
        
        // Bible reference
        if (_quote!.dailyBreadReference.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceMedium),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMedium,
                vertical: AppTheme.spaceSmall,
              ),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Text(
                _quote!.dailyBreadReference,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.outline.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium),
          padding: const EdgeInsets.all(AppTheme.spaceSmall),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(
            Icons.auto_awesome_outlined,
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
                  AppTheme.outline.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppTheme.tertiaryColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: Image.asset(
                  'assets/branham.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spaceMedium),
            Expanded(
              child: Text(
                'Citation du jour',
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceLarge),
        
        // Quote content
        Text(
          '"${_quote!.text}"',
          style: TextStyle(
            color: AppTheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 1.6,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: AppTheme.spaceLarge),
        
        // Attribution
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_quote!.sermonTitle.isNotEmpty) ...[
              Text(
                _quote!.sermonTitle,
                style: TextStyle(
                  color: AppTheme.tertiaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXSmall),
            ],
            Text(
              '— William Marrion Branham',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        
        // Audio button if available
        if (_quote!.audioUrl.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spaceLarge),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Lecture audio - Bientôt disponible'),
                    backgroundColor: AppTheme.tertiaryColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    ),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.tertiaryColor,
                side: BorderSide(
                  color: AppTheme.tertiaryColor.withOpacity(0.5),
                  width: 1.5,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceLarge,
                  vertical: AppTheme.spaceMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                ),
              ),
              icon: const Icon(Icons.play_circle_outline_rounded),
              label: const Text(
                'Écouter la prédication',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

}


