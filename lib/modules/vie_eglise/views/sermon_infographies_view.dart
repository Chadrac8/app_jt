import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme.dart';
import '../models/sermon.dart';

class SermonInfographiesView extends StatefulWidget {
  final Sermon sermon;

  const SermonInfographiesView({
    Key? key,
    required this.sermon,
  }) : super(key: key);

  @override
  State<SermonInfographiesView> createState() => _SermonInfographiesViewState();
}

class _SermonInfographiesViewState extends State<SermonInfographiesView> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final infographies = widget.sermon.infographiesUrls;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isIOS ? CupertinoIcons.back : Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schémas et infographies',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: AppTheme.fontSemiBold,
                color: Colors.white,
              ),
            ),
            Text(
              widget.sermon.titre,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: infographies.isEmpty
          ? _buildEmptyState(colorScheme, isIOS)
          : Column(
              children: [
                // Galerie d'images principale avec zoom
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: infographies.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final infographieUrl = infographies[index];
                      return InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Center(
                          child: Image.network(
                            infographieUrl,
                            fit: BoxFit.contain,
                            cacheWidth: 800,
                            cacheHeight: 1200,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.primaryColor,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Erreur de chargement',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Barre de miniatures en bas
                if (infographies.length > 1)
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.9),
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Indicateur de page
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '${_currentIndex + 1} / ${infographies.length}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: AppTheme.fontMedium,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                        // Liste horizontale de miniatures
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: infographies.length,
                            itemBuilder: (context, index) {
                              final isSelected = index == _currentIndex;
                              return GestureDetector(
                                onTap: () {
                                  _pageController.animateToPage(
                                    index,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(right: 12, bottom: 8),
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppTheme.primaryColor
                                          : Colors.white.withOpacity(0.3),
                                      width: isSelected ? 3 : 2,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primaryColor.withOpacity(0.5),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          infographies[index],
                                          fit: BoxFit.cover,
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                          errorBuilder: (context, error, stackTrace) {
                                            return Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                color: Colors.white.withOpacity(0.5),
                                                size: 24,
                                              ),
                                            );
                                          },
                                        ),
                                        // Overlay pour l'image non sélectionnée
                                        if (!isSelected)
                                          Container(
                                            color: Colors.black.withOpacity(0.4),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, bool isIOS) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isIOS ? CupertinoIcons.photo : Icons.image_not_supported_outlined,
            size: 64,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun schéma disponible',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: AppTheme.fontSemiBold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les schémas et infographies de ce sermon\nseront bientôt disponibles',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
