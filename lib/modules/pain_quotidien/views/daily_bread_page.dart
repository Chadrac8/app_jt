import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../theme.dart';

class DailyBreadPage extends StatefulWidget {
  const DailyBreadPage({
    Key? key,
  }) : super(key: key);

  @override
  State<DailyBreadPage> createState() => _DailyBreadPageState();
}

class _DailyBreadPageState extends State<DailyBreadPage> {
  Map<String, dynamic>? _quote;
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

      // Contenu temporaire par défaut
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _quote = {
          'dailyBread': 'Jésus lui dit: Je suis le chemin, la vérité, et la vie. Nul ne vient au Père que par moi.',
          'dailyBreadReference': 'Jean 14:6',
          'text': 'Dieu est amour, et Il veut le meilleur pour chacun de nous. Tournons nos cœurs vers Lui aujourd\'hui.',
          'sermonTitle': 'La Vie en Christ',
          'sermonDate': DateTime.now().toString(),
          'audioUrl': '',
          'date': DateTime.now().toString(),
          'shareText': 'Pain quotidien - Citation du jour',
        };
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
      _quote!['shareText'] ?? 'Pain quotidien',
      subject: 'Pain quotidien - ${_quote!['date'] ?? ''}',
    );
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
            if ((_quote!['dailyBread'] ?? '').toString().isNotEmpty) ...[
              _buildVerseSection(),
              
              // Divider entre verset et citation
              if ((_quote!['text'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: AppTheme.spaceXLarge),
                _buildSectionDivider(),
                const SizedBox(height: AppTheme.spaceXLarge),
              ],
            ],

            // Citation section
            if ((_quote!['text'] ?? '').toString().isNotEmpty) ...[
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
          _quote!['dailyBread'] ?? '',
          style: TextStyle(
            color: AppTheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            height: 1.6,
            letterSpacing: 0.2,
          ),
        ),
        
        // Bible reference
        if ((_quote!['dailyBreadReference'] ?? '').toString().isNotEmpty) ...[
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
                _quote!['dailyBreadReference'] ?? '',
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
                color: AppTheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(
                Icons.format_quote_outlined,
                color: AppTheme.tertiaryColor,
                size: 24,
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
          '"${_quote!['text'] ?? ''}"',
          style: TextStyle(
            color: AppTheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 1.6,
            letterSpacing: 0.2,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: AppTheme.spaceLarge),
        
        // Attribution
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((_quote!['sermonTitle'] ?? '').toString().isNotEmpty) ...[
              Text(
                _quote!['sermonTitle'] ?? '',
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
        if ((_quote!['audioUrl'] ?? '').toString().isNotEmpty) ...[
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


