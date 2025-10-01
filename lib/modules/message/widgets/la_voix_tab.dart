import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../theme.dart';
import '../models/youtube_playlist_model.dart';
import '../services/youtube_playlist_service.dart';
import '../../../theme.dart';

/// Onglet "La voix" avec playlists YouTube de William Marrion Branham
class LaVoixTab extends StatefulWidget {
  const LaVoixTab({Key? key}) : super(key: key);

  @override
  State<LaVoixTab> createState() => _LaVoixTabState();
}

class _LaVoixTabState extends State<LaVoixTab> with AutomaticKeepAliveClientMixin {
  List<YouTubePlaylist> _playlists = [];
  YouTubePlaylist? _currentPlaylist;
  bool _isLoading = true;
  WebViewController? _webViewController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.black100)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('🎥 Chargement YouTube: $url');
          },
          onPageFinished: (String url) {
            print('✅ YouTube chargé: $url');
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ Erreur YouTube: ${error.description}');
          },
        ),
      );
  }

  Future<void> _loadPlaylists() async {
    setState(() => _isLoading = true);
    
    try {
      final playlists = await YouTubePlaylistService.getActivePlaylists();
      setState(() {
        _playlists = playlists;
        if (playlists.isNotEmpty && _currentPlaylist == null) {
          _currentPlaylist = playlists.first;
          _loadCurrentPlaylist();
        }
        _isLoading = false;
      });
      
      print('✅ ${playlists.length} playlists chargées');
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Erreur chargement playlists: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de chargement: $e'),
            backgroundColor: AppTheme.redStandard,
            action: SnackBarAction(
              label: 'Réessayer',
              textColor: AppTheme.white100,
              onPressed: _loadPlaylists,
            ),
          ),
        );
      }
    }
  }

  void _loadCurrentPlaylist() {
    if (_currentPlaylist != null && _webViewController != null) {
      _webViewController!.loadRequest(Uri.parse(_currentPlaylist!.embedUrl));
    }
  }

  void _selectPlaylist(YouTubePlaylist playlist) {
    setState(() {
      _currentPlaylist = playlist;
    });
    _loadCurrentPlaylist();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor.withOpacity(0.03),
            AppTheme.backgroundColor,
          ],
        ),
      ),
      child: Column(
        children: [
          // En-tête
          _buildHeader(),
          
          // Contenu principal
          Expanded(
            child: _isLoading 
                ? _buildLoadingState()
                : _playlists.isEmpty 
                    ? _buildEmptyState()
                    : _buildPlaylistView(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_circle_filled,
                  color: AppTheme.white100,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spaceMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'La Voix du 7ème Ange',
                      style: GoogleFonts.poppins(
                        fontSize: AppTheme.fontSize22,
                        fontWeight: AppTheme.fontBold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXSmall),
                    Text(
                      'Playlists vidéo des prédications de William Marrion Branham',
                      style: GoogleFonts.inter(
                        fontSize: AppTheme.fontSize14,
                        color: AppTheme.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_playlists.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadPlaylists,
                  color: AppTheme.primaryColor,
                  tooltip: 'Actualiser',
                ),
            ],
          ),
          if (_currentPlaylist != null) ...[
            const SizedBox(height: AppTheme.spaceMedium),
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              decoration: BoxDecoration(
                color: AppTheme.white100,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.playlist_play,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spaceSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentPlaylist!.title,
                          style: GoogleFonts.poppins(
                            fontSize: AppTheme.fontSize16,
                            fontWeight: AppTheme.fontSemiBold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        if (_currentPlaylist!.description.isNotEmpty) ...[
                          const SizedBox(height: AppTheme.spaceXSmall),
                          Text(
                            _currentPlaylist!.description,
                            style: GoogleFonts.inter(
                              fontSize: AppTheme.fontSize12,
                              color: AppTheme.grey600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Chargement des playlists...',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize16,
              color: AppTheme.grey600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.video_library_outlined,
            size: 64,
            color: AppTheme.grey400,
          ),
          const SizedBox(height: AppTheme.spaceMedium),
          Text(
            'Aucune playlist disponible',
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize18,
              fontWeight: AppTheme.fontSemiBold,
              color: AppTheme.grey600,
            ),
          ),
          const SizedBox(height: AppTheme.spaceSmall),
          Text(
            'Les administrateurs doivent ajouter des playlists YouTube\ndepuis l\'interface d\'administration.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: AppTheme.fontSize14,
              color: AppTheme.grey500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistView() {
    return Column(
      children: [
        // Lecteur vidéo principal
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.black100.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: _currentPlaylist != null
                  ? WebViewWidget(controller: _webViewController!)
                  : Container(
                      color: AppTheme.black100,
                      child: Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          size: 64,
                          color: AppTheme.white100.withOpacity(0.7),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        
        // Liste des playlists
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.playlist_play,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.spaceSmall),
                      Text(
                        'Playlists disponibles',
                        style: GoogleFonts.poppins(
                          fontSize: AppTheme.fontSize16,
                          fontWeight: AppTheme.fontSemiBold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Text(
                          '${_playlists.length}',
                          style: GoogleFonts.inter(
                            fontSize: AppTheme.fontSize12,
                            fontWeight: AppTheme.fontBold,
                            color: AppTheme.white100,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _playlists.length,
                    itemBuilder: (context, index) => _buildPlaylistCard(_playlists[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spaceMedium),
      ],
    );
  }

  Widget _buildPlaylistCard(YouTubePlaylist playlist) {
    final isSelected = _currentPlaylist?.id == playlist.id;
    
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () => _selectPlaylist(playlist),
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Container(
            padding: const EdgeInsets.all(AppTheme.space12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppTheme.spaceSmall),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppTheme.primaryColor 
                            : AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                      ),
                      child: Icon(
                        isSelected ? Icons.play_arrow : Icons.playlist_play,
                        color: isSelected ? AppTheme.white100 : AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppTheme.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist.title,
                            style: GoogleFonts.poppins(
                              fontSize: AppTheme.fontSize14,
                              fontWeight: AppTheme.fontSemiBold,
                              color: isSelected ? AppTheme.primaryColor : AppTheme.black100.withOpacity(0.87),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (playlist.description.isNotEmpty) ...[
                            const SizedBox(height: AppTheme.spaceXSmall),
                            Text(
                              playlist.description,
                              style: GoogleFonts.inter(
                                fontSize: AppTheme.fontSize12,
                                color: AppTheme.grey600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
