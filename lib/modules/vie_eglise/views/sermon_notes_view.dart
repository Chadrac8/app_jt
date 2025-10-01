import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../theme.dart';
import '../models/sermon.dart';
import '../../../theme.dart';

class SermonNotesView extends StatelessWidget {
  final Sermon sermon;

  const SermonNotesView({
    Key? key,
    required this.sermon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Notes du sermon',
          style: GoogleFonts.poppins(
            fontWeight: AppTheme.fontSemiBold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        backgroundColor: AppTheme.white100,
        elevation: 1,
        iconTheme: IconThemeData(color: AppTheme.textPrimaryColor),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSermonHeader(),
            _buildNotesContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildSermonHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.white100,
        boxShadow: [
          BoxShadow(
            color: AppTheme.grey500.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
            ),
            child: Text(
              DateFormat('dd MMMM yyyy', 'fr_FR').format(sermon.date),
              style: GoogleFonts.poppins(
                fontSize: AppTheme.fontSize12,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spaceMedium),

          // Titre
          Text(
            sermon.titre,
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize24,
              fontWeight: AppTheme.fontBold,
              color: AppTheme.textPrimaryColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppTheme.space12),

          // Orateur
          Row(
            children: [
              Icon(
                Icons.person,
                size: 18,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(
                sermon.orateur,
                style: GoogleFonts.poppins(
                  fontSize: AppTheme.fontSize16,
                  fontWeight: AppTheme.fontMedium,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),

          // Description si disponible
          if (sermon.description != null && sermon.description!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              sermon.description!,
              style: GoogleFonts.poppins(
                fontSize: AppTheme.fontSize14,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
            ),
          ],

          // Tags si disponibles
          if (sermon.tags.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceMedium),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: sermon.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize12,
                    color: AppTheme.primaryColor,
                    fontWeight: AppTheme.fontMedium,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesContent() {
    if (sermon.notes == null || sermon.notes!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.space40),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.notes_outlined,
                size: 64,
                color: AppTheme.grey500,
              ),
              const SizedBox(height: AppTheme.spaceMedium),
              Text(
                'Aucune note disponible',
                style: GoogleFonts.poppins(
                  fontSize: AppTheme.fontSize18,
                  fontWeight: AppTheme.fontSemiBold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: AppTheme.spaceSmall),
              Text(
                'Les notes de ce sermon ne sont pas encore disponibles',
                style: GoogleFonts.poppins(
                  color: AppTheme.textSecondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(AppTheme.spaceMedium),
      padding: const EdgeInsets.all(AppTheme.space20),
      decoration: BoxDecoration(
        color: AppTheme.white100,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.grey500.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête des notes
          Row(
            children: [
              Icon(
                Icons.notes,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: AppTheme.spaceSmall),
              Text(
                'Notes du sermon',
                style: GoogleFonts.poppins(
                  fontSize: AppTheme.fontSize18,
                  fontWeight: AppTheme.fontBold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space20),

          // Contenu des notes
          _buildFormattedNotes(sermon.notes!),
        ],
      ),
    );
  }

  Widget _buildFormattedNotes(String notes) {
    // Traitement simple du formatage du texte
    final lines = notes.split('\n');
    final List<Widget> widgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      if (line.isEmpty) {
        widgets.add(const SizedBox(height: AppTheme.spaceSmall));
        continue;
      }

      // Titres (lignes commençant par #)
      if (line.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              line.substring(2),
              style: GoogleFonts.poppins(
                fontSize: AppTheme.fontSize20,
                fontWeight: AppTheme.fontBold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        );
        continue;
      }

      // Sous-titres (lignes commençant par ##)
      if (line.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 6),
            child: Text(
              line.substring(3),
              style: GoogleFonts.poppins(
                fontSize: AppTheme.fontSize18,
                fontWeight: AppTheme.fontSemiBold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        );
        continue;
      }

      // Points de liste (lignes commençant par -)
      if (line.startsWith('- ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• ',
                  style: GoogleFonts.poppins(
                    fontSize: AppTheme.fontSize16,
                    color: AppTheme.primaryColor,
                    fontWeight: AppTheme.fontBold,
                  ),
                ),
                Expanded(
                  child: Text(
                    line.substring(2),
                    style: GoogleFonts.poppins(
                      fontSize: AppTheme.fontSize15,
                      color: AppTheme.textPrimaryColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Versets bibliques (lignes entre guillemets)
      if (line.startsWith('"') && line.endsWith('"')) {
        widgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.all(AppTheme.spaceMedium),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border(
                left: BorderSide(
                  color: AppTheme.primaryColor,
                  width: 4,
                ),
              ),
            ),
            child: Text(
              line,
              style: GoogleFonts.poppins(
                fontSize: AppTheme.fontSize15,
                color: AppTheme.textPrimaryColor,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
          ),
        );
        continue;
      }

      // Texte normal
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line,
            style: GoogleFonts.poppins(
              fontSize: AppTheme.fontSize15,
              color: AppTheme.textPrimaryColor,
              height: 1.6,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
