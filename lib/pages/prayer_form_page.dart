import 'package:flutter/material.dart';
import '../models/prayer_model.dart';
import '../services/prayers_firebase_service.dart';
import '../auth/auth_service.dart';
import '../theme.dart';

class PrayerFormPage extends StatefulWidget {
  final PrayerModel? prayer;

  const PrayerFormPage({super.key, this.prayer});

  @override
  State<PrayerFormPage> createState() => _PrayerFormPageState();
}

class _PrayerFormPageState extends State<PrayerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  PrayerType _selectedType = PrayerType.request;
  bool _isAnonymous = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.prayer != null) {
      _initializeForm();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    final prayer = widget.prayer!;
    _titleController.text = prayer.title;
    _contentController.text = prayer.content;
    _selectedType = prayer.type;
    _isAnonymous = prayer.isAnonymous;
  }

  Color _getTypeColor(PrayerType type) {
    switch (type) {
      case PrayerType.request:
        return Colors.orange;
      case PrayerType.testimony:
        return Colors.green;
      case PrayerType.thanksgiving:
        return Colors.purple;
    }
  }

  IconData _getTypeIcon(PrayerType type) {
    switch (type) {
      case PrayerType.request:
        return Icons.pan_tool;
      case PrayerType.testimony:
        return Icons.star;
      case PrayerType.thanksgiving:
        return Icons.celebration;
    }
  }

  Future<void> _savePrayer() async {
    if (!_formKey.currentState!.validate()) return;

    final user = AuthService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour créer une prière'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      
      final prayer = PrayerModel(
        id: widget.prayer?.id ?? '',
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        authorId: widget.prayer?.authorId ?? user.uid,
        authorName: widget.prayer?.authorName ?? (user.displayName ?? 'Utilisateur'),
        authorPhoto: widget.prayer?.authorPhoto ?? user.photoURL,
        type: _selectedType,
        category: 'Général',
        isAnonymous: _isAnonymous,
        isApproved: widget.prayer?.isApproved ?? true, // Auto-approuvé pour l'admin
        prayerCount: widget.prayer?.prayerCount ?? 0,
        prayedByUsers: widget.prayer?.prayedByUsers ?? [],
        comments: widget.prayer?.comments ?? [],
        createdAt: widget.prayer?.createdAt ?? now,
        updatedAt: widget.prayer != null ? now : null,
        isArchived: widget.prayer?.isArchived ?? false,
        tags: [],
      );

      if (widget.prayer == null) {
        // Création
        await PrayersFirebaseService.createPrayer(prayer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prière créée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Modification
        await PrayersFirebaseService.updatePrayer(prayer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prière modifiée avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.prayer == null ? 'Nouvelle prière' : 'Modifier la prière'),
        elevation: 0,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _savePrayer,
              child: Text(
                'SAUVEGARDER',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sélection du type de prière
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Type de prière',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: PrayerType.values.map((type) {
                        final isSelected = _selectedType == type;
                        return InkWell(
                          onTap: () => setState(() => _selectedType = type),
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _getTypeColor(type).withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: isSelected
                                    ? _getTypeColor(type)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getTypeIcon(type),
                                  size: 16,
                                  color: isSelected
                                      ? _getTypeColor(type)
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  type.label,
                                  style: TextStyle(
                                    color: isSelected
                                        ? _getTypeColor(type)
                                        : Colors.grey,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Titre
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Titre de la prière',
                    hintText: 'Ex: Prière pour la guérison de...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  maxLength: 100,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le titre est obligatoire';
                    }
                    if (value.trim().length < 5) {
                      return 'Le titre doit contenir au moins 5 caractères';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contenu
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextFormField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Contenu de la prière',
                    hintText: 'Partagez votre demande, témoignage ou action de grâce...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.text_fields),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 6,
                  maxLength: 1000,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le contenu est obligatoire';
                    }
                    if (value.trim().length < 10) {
                      return 'Le contenu doit contenir au moins 10 caractères';
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Options
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Options',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Publier anonymement'),
                      subtitle: const Text('Votre nom ne sera pas affiché'),
                      value: _isAnonymous,
                      onChanged: (value) => setState(() => _isAnonymous = value),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Aperçu
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aperçu',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getTypeColor(_selectedType).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getTypeColor(_selectedType),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getTypeIcon(_selectedType),
                                      size: 14,
                                      color: _getTypeColor(_selectedType),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _selectedType.label,
                                      style: TextStyle(
                                        color: _getTypeColor(_selectedType),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _titleController.text.trim().isEmpty
                                ? 'Titre de la prière'
                                : _titleController.text.trim(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _titleController.text.trim().isEmpty
                                  ? Colors.grey
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _contentController.text.trim().isEmpty
                                ? 'Contenu de la prière...'
                                : _contentController.text.trim(),
                            style: TextStyle(
                              fontSize: 12,
                              color: _contentController.text.trim().isEmpty
                                  ? Colors.grey
                                  : Colors.grey[700],
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                _isAnonymous 
                                    ? Icons.person_outline 
                                    : Icons.person,
                                size: 12,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _isAnonymous 
                                    ? 'Anonyme' 
                                    : (AuthService.currentUser?.displayName ?? 'Utilisateur'),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  fontStyle: _isAnonymous 
                                      ? FontStyle.italic 
                                      : FontStyle.normal,
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
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}