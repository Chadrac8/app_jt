import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../theme.dart';
import '../../../models/pepite_or_model.dart';

/// Page de détail d'une pépite d'or avec ses citations de William Branham
class PepiteDetailPage extends StatelessWidget {
  final PepiteOrModel pepite;

  const PepiteDetailPage({
    Key? key,
    required this.pepite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.white100),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pépite d\'Or',
          style: GoogleFonts.poppins(
            color: AppTheme.white100,
            fontSize: 20,
            fontWeight: AppTheme.fontSemiBold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.white100),
            onPressed: () => _sharePepite(context),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // En-tête avec le titre de la pépite
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome,
                          size: 48,
                          color: AppTheme.white100.withOpacity(0.9),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          pepite.theme,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: AppTheme.fontBold,
                            color: AppTheme.white100,
                            height: 1.2,
                          ),
                        ),
                        if (pepite.description.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            pepite.description,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: AppTheme.white100.withOpacity(0.9),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Forme courbe en bas
                  Container(
                    height: 30,
                    decoration: const BoxDecoration(
                      color: AppTheme.white100,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Section des citations
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.format_quote,
                        color: AppTheme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Citations de William Branham',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: AppTheme.fontSemiBold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pepite.citations.length} citation${pepite.citations.length > 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.grey600,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Liste des citations
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final citation = pepite.citations[index];
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.white100,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.black100.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(
                      color: AppTheme.grey200!,
                      width: 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre de la brochure
                        if (citation.auteur.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                            ),
                            child: Text(
                              citation.auteur,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: AppTheme.fontSemiBold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Contenu de la citation
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4, right: 12),
                              child: Icon(
                                Icons.format_quote,
                                color: AppTheme.primaryColor.withOpacity(0.6),
                                size: 24,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                citation.texte,
                                style: GoogleFonts.crimsonText(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.grey800,
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Actions pour cette citation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () => _copyCitation(context, citation),
                              icon: Icon(
                                Icons.copy,
                                color: AppTheme.grey600,
                                size: 20,
                              ),
                              tooltip: 'Copier cette citation',
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: pepite.citations.length,
            ),
          ),
          
          // Espacement en bas
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }
  
  void _sharePepite(BuildContext context) {
    final text = '🌟 ${pepite.theme}\n\n'
        '${pepite.description.isNotEmpty ? '${pepite.description}\n\n' : ''}'
        '📖 Citations de William Branham :\n\n'
        '${pepite.citations.map((c) => '"${c.texte}"\n— ${c.auteur}').join('\n\n')}\n\n'
        '#PépitesOr #WilliamBranham #Spiritualité';
    
    // Copier dans le presse-papier
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Pépite partagée dans le presse-papier'),
        backgroundColor: AppTheme.greenStandard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
  
  void _copyCitation(BuildContext context, dynamic citation) {
    final text = '"${citation.texte}"\n— ${citation.auteur}';
    
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Citation copiée dans le presse-papier'),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
