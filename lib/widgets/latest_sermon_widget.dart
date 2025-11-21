import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/home_config_service.dart';
import '../models/home_config_model.dart';
import '../../theme.dart';

class LatestSermonWidget extends StatefulWidget {
  const LatestSermonWidget({Key? key}) : super(key: key);

  @override
  State<LatestSermonWidget> createState() => _LatestSermonWidgetState();
}

class _LatestSermonWidgetState extends State<LatestSermonWidget> with AutomaticKeepAliveClientMixin {
  HomeConfigModel? _homeConfig;
  bool _isLoading = true;
  YoutubePlayerController? _youtubeController;
  String? _lastLoadedUrl;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadHomeConfig();
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  Future<void> _loadHomeConfig() async {
    try {
      final config = await HomeConfigService.getHomeConfig();
      
      if (config.sermonYouTubeUrl != null && config.sermonYouTubeUrl!.isNotEmpty) {
        // Vérifier si l'URL a changé pour recréer le controller
        final urlChanged = _lastLoadedUrl != config.sermonYouTubeUrl;
        _lastLoadedUrl = config.sermonYouTubeUrl;
        
        setState(() {
          _homeConfig = config;
          _isLoading = false;
        });
        
        if (urlChanged) {
          // Dispose old controller if exists
          _youtubeController?.dispose();
          _youtubeController = null;
          _initializeYoutubePlayer();
        } else if (_youtubeController == null) {
          _initializeYoutubePlayer();
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _extractYoutubeVideoId(String url) {
    // Essayer d'abord avec la méthode standard
    var videoId = YoutubePlayer.convertUrlToId(url);
    
    if (videoId != null) {
      return videoId;
    }
    
    // Si ça ne marche pas, essayer d'extraire manuellement pour les lives et autres formats
    try {
      final uri = Uri.parse(url);
      
      // Format: youtube.com/live/VIDEO_ID
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'live') {
        return uri.pathSegments[1];
      }
      
      // Format: youtu.be/VIDEO_ID
      if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
        return uri.pathSegments[0];
      }
      
      // Format: youtube.com/watch?v=VIDEO_ID
      if (uri.queryParameters.containsKey('v')) {
        return uri.queryParameters['v'];
      }
      
      // Format: youtube.com/embed/VIDEO_ID
      if (uri.pathSegments.length >= 2 && uri.pathSegments[0] == 'embed') {
        return uri.pathSegments[1];
      }
    } catch (e) {
      // Ignore parsing errors
    }
    
    return null;
  }

  void _initializeYoutubePlayer() {
    if (_homeConfig?.sermonYouTubeUrl != null) {
      final videoId = _extractYoutubeVideoId(_homeConfig!.sermonYouTubeUrl!);
      
      if (videoId != null) {
        setState(() {
          _youtubeController = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(
              autoPlay: false,
              mute: false,
              showLiveFullscreenButton: true,
              hideControls: false));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dernière prédication',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: AppTheme.fontBold)),
            TextButton(
              onPressed: () async {
                // Navigation vers la chaîne YouTube
                const channelUrl = 'https://youtube.com/@jubiletabernaclefrance?si=NUyaAW5dLP7xpD5Y';
                final uri = Uri.parse(channelUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Text(
                'Voir tout',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: AppTheme.fontSemiBold))),
          ]),
        const SizedBox(height: AppTheme.spaceMedium),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spaceXLarge),
              child: CircularProgressIndicator()))
        else if (_homeConfig?.sermonYouTubeUrl == null)
          _buildNoSermonWidget()
        else
          _buildSermonWidget(),
      ]);
  }

  Widget _buildNoSermonWidget() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spaceLarge),
        child: Column(
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 64,
              color: AppTheme.textSecondaryColor),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Aucune prédication disponible',
              style: TextStyle(
                fontSize: AppTheme.fontSize16,
                color: AppTheme.textSecondaryColor)),
          ])));
  }

  Widget _buildSermonWidget() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Lecteur YouTube
            if (_youtubeController != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
                child: YoutubePlayerBuilder(
                  player: YoutubePlayer(
                    controller: _youtubeController!,
                    showVideoProgressIndicator: true,
                    progressIndicatorColor: AppTheme.primaryColor,
                    progressColors: ProgressBarColors(
                      playedColor: AppTheme.primaryColor,
                      handleColor: AppTheme.primaryColor,
                    ),
                    onReady: () {
                      // Lecteur prêt
                    },
                  ),
                  builder: (context, player) {
                    return Container(
                      color: Colors.black,
                      child: player,
                    );
                  },
                ),
              )
            else
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.textTertiaryColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16))),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.video_library,
                        size: 48,
                        color: AppTheme.textSecondaryColor),
                      const SizedBox(height: AppTheme.spaceSmall),
                      Text(
                        'Vidéo non disponible',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor)),
                      if (_homeConfig?.sermonYouTubeUrl != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'URL: ${_homeConfig!.sermonYouTubeUrl}',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ]))),
            
            // Informations sur le sermon
            Padding(
              padding: const EdgeInsets.all(AppTheme.spaceMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _homeConfig!.sermonTitle,
                    style: TextStyle(
                      fontSize: AppTheme.fontSize18,
                      fontWeight: AppTheme.fontBold,
                      color: AppTheme.textPrimaryColor)),
                  const SizedBox(height: AppTheme.space12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          // Navigation vers la vidéo YouTube
                          if (_homeConfig?.sermonYouTubeUrl != null) {
                            final uri = Uri.parse(_homeConfig!.sermonYouTubeUrl!);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.play_arrow,
                                size: 16,
                                color: AppTheme.primaryColor),
                              const SizedBox(width: AppTheme.spaceXSmall),
                              Text(
                                'Regarder',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSize12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: AppTheme.fontSemiBold)),
                            ])),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: AppTheme.textSecondaryColor),
                      const SizedBox(width: AppTheme.spaceXSmall),
                      Text(
                        _formatDate(_homeConfig!.lastUpdated),
                        style: TextStyle(
                          fontSize: AppTheme.fontSize12,
                          color: AppTheme.textSecondaryColor)),
                    ]),
                ])),
          ]));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Hier';
    } else if (difference < 7) {
      return 'Il y a $difference jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
