import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/pepite_or_model.dart';
import '../../services/pepite_or_firebase_service.dart';
import '../../shared/widgets/custom_card.dart';
import 'pepite_or_form_page.dart';
import '../../../theme.dart';

class PepiteOrDetailPage extends StatefulWidget {
  final PepiteOrModel pepite;

  const PepiteOrDetailPage({super.key, required this.pepite});

  @override
  State<PepiteOrDetailPage> createState() => _PepiteOrDetailPageState();
}

class _PepiteOrDetailPageState extends State<PepiteOrDetailPage> {
  late PepiteOrModel _pepite;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pepite = widget.pepite;
    _incrementerVues();
  }

  Future<void> _incrementerVues() async {
    try {
      await PepiteOrFirebaseService.incrementerVues(_pepite.id);
      // Mettre à jour localement
      setState(() {
        _pepite = _pepite.copyWith(nbVues: _pepite.nbVues + 1);
      });
    } catch (e) {
      // Ignorer les erreurs pour ne pas affecter l'expérience utilisateur
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pépite d\'Or',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.white100,
          ),
        ),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: AppTheme.white100,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _partager,
            icon: const Icon(Icons.share),
            tooltip: 'Partager',
          ),
          PopupMenuButton<String>(
            onSelected: _gererAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'modifier',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _pepite.estPubliee ? 'depublier' : 'publier',
                child: Row(
                  children: [
                    Icon(
                      _pepite.estPubliee ? Icons.unpublished : Icons.publish,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(_pepite.estPubliee ? 'Dépublier' : 'Publier'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'supprimer',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: AppTheme.redStandard),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: AppTheme.redStandard)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEntete(),
                  const SizedBox(height: 24),
                  _buildCitations(),
                  const SizedBox(height: 24),
                  _buildInfosComplementaires(),
                ],
              ),
            ),
    );
  }

  Widget _buildEntete() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _pepite.estPubliee ? AppTheme.greenStandard : AppTheme.orangeStandard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  ),
                  child: Text(
                    _pepite.estPubliee ? 'Publiée' : 'Brouillon',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: AppTheme.fontSemiBold,
                      color: AppTheme.white100,
                    ),
                  ),
                ),
                const Spacer(),
                if (_pepite.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    children: _pepite.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B4513).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF8B4513),
                            fontWeight: AppTheme.fontMedium,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _pepite.theme,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: AppTheme.fontBold,
                color: const Color(0xFF8B4513),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _pepite.description,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppTheme.grey700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: AppTheme.grey600),
                const SizedBox(width: 6),
                Text(
                  _pepite.nomAuteur,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.grey600,
                  ),
                ),
                const SizedBox(width: 20),
                Icon(Icons.schedule, size: 16, color: AppTheme.grey600),
                const SizedBox(width: 6),
                Text(
                  '${_pepite.dureeDeeLectureMinutes} min de lecture',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.grey600,
                  ),
                ),
              ],
            ),
            if (_pepite.estPubliee) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.visibility, size: 16, color: AppTheme.grey600),
                  const SizedBox(width: 6),
                  Text(
                    '${_pepite.nbVues} vue${_pepite.nbVues > 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.grey600,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Icon(Icons.share, size: 16, color: AppTheme.grey600),
                  const SizedBox(width: 6),
                  Text(
                    '${_pepite.nbPartages} partage${_pepite.nbPartages > 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCitations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Citations (${_pepite.citations.length})',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: AppTheme.fontBold,
            color: const Color(0xFF8B4513),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _pepite.citations.length,
          itemBuilder: (context, index) {
            return _buildCitationCard(_pepite.citations[index], index + 1);
          },
        ),
      ],
    );
  }

  Widget _buildCitationCard(CitationModel citation, int numero) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: Center(
                    child: Text(
                      '$numero',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: AppTheme.fontBold,
                        color: AppTheme.white100,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _copierCitation(citation),
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Copier la citation',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.grey50,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: const Border(
                  left: BorderSide(
                    width: 4,
                    color: Color(0xFF8B4513),
                  ),
                ),
              ),
              child: Text(
                citation.texte,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  height: 1.6,
                  color: AppTheme.grey800,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '— ${citation.auteur}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: AppTheme.fontSemiBold,
                    color: const Color(0xFF8B4513),
                  ),
                ),
                if (citation.reference != null && citation.reference!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${citation.reference})',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppTheme.grey600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfosComplementaires() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: AppTheme.fontSemiBold,
                color: const Color(0xFF8B4513),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              'Créée le',
              _formatDate(_pepite.dateCreation),
              Icons.calendar_today,
            ),
            if (_pepite.datePublication != null)
              _buildInfoRow(
                'Publiée le',
                _formatDate(_pepite.datePublication!),
                Icons.publish,
              ),
            if (_pepite.tags.isNotEmpty)
              _buildInfoRow(
                'Tags',
                _pepite.tags.join(', '),
                Icons.tag,
              ),
            _buildInfoRow(
              'Nombre de citations',
              '${_pepite.citations.length}',
              Icons.format_quote,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String valeur, IconData icone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 18, color: AppTheme.grey600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.grey600,
                    fontWeight: AppTheme.fontMedium,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valeur,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.grey800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const mois = [
      'jan', 'fév', 'mar', 'avr', 'mai', 'jun',
      'jul', 'aoû', 'sep', 'oct', 'nov', 'déc'
    ];
    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }

  void _copierCitation(CitationModel citation) {
    final texte = '${citation.texte}\n\n— ${citation.auteur}' +
        (citation.reference?.isNotEmpty == true ? ' (${citation.reference})' : '');
    
    Clipboard.setData(ClipboardData(text: texte));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Citation copiée dans le presse-papiers'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _partager() async {
    try {
      await PepiteOrFirebaseService.incrementerPartages(_pepite.id);
      
      // Mettre à jour localement
      setState(() {
        _pepite = _pepite.copyWith(nbPartages: _pepite.nbPartages + 1);
      });

      final texte = _genererTextePartage();
      await Share.share(texte, subject: 'Pépite d\'Or: ${_pepite.theme}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du partage: $e'),
          backgroundColor: AppTheme.redStandard,
        ),
      );
    }
  }

  String _genererTextePartage() {
    var texte = '🌟 Pépite d\'Or: ${_pepite.theme}\n\n';
    texte += '${_pepite.description}\n\n';
    
    if (_pepite.citations.isNotEmpty) {
      texte += '📖 Citations:\n\n';
      for (int i = 0; i < _pepite.citations.length && i < 2; i++) {
        final citation = _pepite.citations[i];
        texte += '"${citation.texte}"\n— ${citation.auteur}';
        if (citation.reference?.isNotEmpty == true) {
          texte += ' (${citation.reference})';
        }
        texte += '\n\n';
      }
      
      if (_pepite.citations.length > 2) {
        texte += '... et ${_pepite.citations.length - 2} autre${_pepite.citations.length > 3 ? 's' : ''} citation${_pepite.citations.length > 3 ? 's' : ''}\n\n';
      }
    }
    
    texte += 'Partagé depuis l\'application ChurchFlow 🙏';
    return texte;
  }

  void _gererAction(String action) async {
    switch (action) {
      case 'modifier':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PepiteOrFormPage(pepite: _pepite),
          ),
        );
        if (result != null) {
          // Recharger la pépite mise à jour
          _rechargerPepite();
        }
        break;
      case 'publier':
      case 'depublier':
        await _publierPepite(action == 'publier');
        break;
      case 'supprimer':
        await _confirmerSuppression();
        break;
    }
  }

  Future<void> _rechargerPepite() async {
    try {
      final pepiteMiseAJour = await PepiteOrFirebaseService.obtenirPepiteOr(_pepite.id);
      if (pepiteMiseAJour != null) {
        setState(() {
          _pepite = pepiteMiseAJour;
        });
      }
    } catch (e) {
      // Ignorer les erreurs de rechargement
    }
  }

  Future<void> _publierPepite(bool publier) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await PepiteOrFirebaseService.publierPepiteOr(_pepite.id, publier);
      
      setState(() {
        _pepite = _pepite.copyWith(
          estPubliee: publier,
          datePublication: publier ? DateTime.now() : null,
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              publier ? 'Pépite publiée avec succès' : 'Pépite dépubliée',
            ),
            backgroundColor: AppTheme.greenStandard,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.redStandard,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmerSuppression() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer la pépite "${_pepite.theme}" ? '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.redStandard),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirme == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await PepiteOrFirebaseService.supprimerPepiteOr(_pepite.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pépite supprimée avec succès'),
              backgroundColor: AppTheme.greenStandard,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la suppression: $e'),
              backgroundColor: AppTheme.redStandard,
            ),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
