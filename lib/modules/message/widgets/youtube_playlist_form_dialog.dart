import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../models/youtube_playlist_model.dart';

class YouTubePlaylistFormDialog extends StatefulWidget {
  final YouTubePlaylist? playlist;
  final Function(YouTubePlaylist) onSave;

  const YouTubePlaylistFormDialog({
    Key? key,
    this.playlist,
    required this.onSave,
  }) : super(key: key);

  @override
  _YouTubePlaylistFormDialogState createState() => _YouTubePlaylistFormDialogState();
}

class _YouTubePlaylistFormDialogState extends State<YouTubePlaylistFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _urlController;
  late TextEditingController _descriptionController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.playlist?.title ?? '');
    _urlController = TextEditingController(text: widget.playlist?.playlistUrl ?? '');
    _descriptionController = TextEditingController(text: widget.playlist?.description ?? '');
    _isActive = widget.playlist?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _isValidYouTubePlaylistUrl(String url) {
    if (url.isEmpty) return false;
    
    // Vérifier les formats de playlist YouTube valides
    final RegExp playlistRegex = RegExp(
      r'^https?://(www\.)?(youtube\.com/playlist\?list=|youtube\.com/watch\?.*list=|youtu\.be/.*\?.*list=)[a-zA-Z0-9_-]+',
      caseSensitive: false,
    );
    
    return playlistRegex.hasMatch(url);
  }

  String _extractPlaylistId(String url) {
    final RegExp listRegex = RegExp(r'list=([a-zA-Z0-9_-]+)');
    final match = listRegex.firstMatch(url);
    return match?.group(1) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(AppTheme.spaceLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.video_library,
                    color: AppTheme.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Text(
                    widget.playlist == null 
                      ? 'Ajouter une playlist'
                      : 'Modifier la playlist',
                    style: GoogleFonts.openSans(
                      fontSize: AppTheme.fontSize24,
                      fontWeight: AppTheme.fontBold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceLarge),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre
                        Text(
                          'Titre de la playlist',
                          style: GoogleFonts.openSans(
                            fontSize: AppTheme.fontSize16,
                            fontWeight: AppTheme.fontSemiBold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceSmall),
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: 'Ex: Prédications de William Marrion Branham',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              borderSide: BorderSide(color: AppTheme.surfaceColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              borderSide: BorderSide(color: AppTheme.primaryColor),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Le titre est obligatoire';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.space20),
                        
                        // URL de la playlist
                        Text(
                          'URL de la playlist YouTube',
                          style: GoogleFonts.openSans(
                            fontSize: AppTheme.fontSize16,
                            fontWeight: AppTheme.fontSemiBold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceSmall),
                        TextFormField(
                          controller: _urlController,
                          decoration: InputDecoration(
                            hintText: 'https://www.youtube.com/playlist?list=...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              borderSide: BorderSide(color: AppTheme.surfaceColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              borderSide: BorderSide(color: AppTheme.primaryColor),
                            ),
                            suffixIcon: Icon(
                              Icons.link,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'L\'URL de la playlist est obligatoire';
                            }
                            if (!_isValidYouTubePlaylistUrl(value.trim())) {
                              return 'URL de playlist YouTube invalide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppTheme.space20),
                        
                        // Description
                        Text(
                          'Description (optionnelle)',
                          style: GoogleFonts.openSans(
                            fontSize: AppTheme.fontSize16,
                            fontWeight: AppTheme.fontSemiBold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceSmall),
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Description de la playlist...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              borderSide: BorderSide(color: AppTheme.surfaceColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                              borderSide: BorderSide(color: AppTheme.primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.space20),
                        
                        // Statut actif
                        Row(
                          children: [
                            Checkbox(
                              value: _isActive,
                              onChanged: (value) {
                                setState(() {
                                  _isActive = value ?? true;
                                });
                              },
                              activeColor: AppTheme.primaryColor,
                            ),
                            Text(
                              'Playlist active',
                              style: GoogleFonts.openSans(
                                fontSize: AppTheme.fontSize16,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppTheme.spaceXLarge),
                        
                        // Boutons d'action
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Annuler',
                                style: GoogleFonts.openSans(
                                  fontSize: AppTheme.fontSize16,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppTheme.spaceMedium),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  final playlistId = _extractPlaylistId(_urlController.text.trim());
                                  
                                  final playlist = YouTubePlaylist(
                                    id: widget.playlist?.id ?? '',
                                    playlistId: playlistId,
                                    title: _titleController.text.trim(),
                                    playlistUrl: _urlController.text.trim(),
                                    description: _descriptionController.text.trim().isEmpty 
                                      ? '' 
                                      : _descriptionController.text.trim(),
                                    isActive: _isActive,
                                    createdAt: widget.playlist?.createdAt ?? DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );
                                  
                                  widget.onSave(playlist);
                                  Navigator.of(context).pop();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: AppTheme.white100,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                ),
                              ),
                              child: Text(
                                'Enregistrer',
                                style: GoogleFonts.openSans(
                                  fontSize: AppTheme.fontSize16,
                                  fontWeight: AppTheme.fontSemiBold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
