import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/home_config_service.dart';
import '../models/home_config_model.dart';
import '../../theme.dart';

class LatestSermonWidget extends StatefulWidget {
  const LatestSermonWidget({super.key});

  @override
  State<LatestSermonWidget> createState() => _LatestSermonWidgetState();
}

class _LatestSermonWidgetState extends State<LatestSermonWidget> {
  HomeConfigModel? _homeConfig;
  bool _isLoading = true;
  YoutubePlayerController? _youtubeController;

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
        setState(() {
          _homeConfig = config;
          _isLoading = false;
        });
        _initializeYoutubePlayer();
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

  void _initializeYoutubePlayer() {
    if (_homeConfig?.sermonYouTubeUrl != null) {
      final videoId = YoutubePlayer.convertUrlToId(_homeConfig!.sermonYouTubeUrl!);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            showLiveFullscreenButton: true,
            hideControls: false));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 64,
              color: AppTheme.textSecondaryColor),
            const SizedBox(height: 16),
            Text(
              'Aucune prédication disponible',
              style: TextStyle(
                fontSize: 16,
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
                child: YoutubePlayer(
                  controller: _youtubeController!,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: AppTheme.primaryColor,
                  onReady: () {
                    // Lecteur prêt
                  }))
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
                      const SizedBox(height: 8),
                      Text(
                        'Vidéo non disponible',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor)),
                    ]))),
            
            // Informations sur le sermon
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _homeConfig!.sermonTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: AppTheme.fontBold,
                      color: AppTheme.textPrimaryColor)),
                  const SizedBox(height: 12),
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
                              const SizedBox(width: 4),
                              Text(
                                'Regarder',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontWeight: AppTheme.fontSemiBold)),
                            ])),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(_homeConfig!.lastUpdated),
                        style: TextStyle(
                          fontSize: 12,
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
