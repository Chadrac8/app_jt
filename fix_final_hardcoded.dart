import 'dart:io';

void main() async {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('❌ Dossier lib/ non trouvé');
    return;
  }

  int totalReplacements = 0;
  int totalFiles = 0;

  await processDirectory(libDir, (replacements, fileCount) {
    totalReplacements += replacements;
    totalFiles += fileCount;
  });

  print('\n🎉 Nettoyage final terminé !');
  print('📊 $totalReplacements remplacements dans $totalFiles fichiers');
}

Future<void> processDirectory(Directory dir, Function(int, int) callback) async {
  int totalReplacements = 0;
  int totalFiles = 0;

  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = await entity.readAsString();
      String newContent = content;
      int fileReplacements = 0;

      // Remplacements EdgeInsets hardcodés spécifiques
      final edgeInsetsPatterns = {
        'EdgeInsets.symmetric(vertical: 8)': 'EdgeInsets.symmetric(vertical: AppTheme.space8)',
        'EdgeInsets.symmetric(horizontal: 16)': 'EdgeInsets.symmetric(horizontal: AppTheme.space16)',
        'EdgeInsets.only(left: 12, right: 4)': 'EdgeInsets.only(left: AppTheme.space12, right: AppTheme.space4)',
        'EdgeInsets.only(top: 12)': 'EdgeInsets.only(top: AppTheme.space12)',
        'EdgeInsets.symmetric(horizontal: 20, vertical: 4)': 'EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space4)',
        'EdgeInsets.all(16.0)': 'EdgeInsets.all(AppTheme.space16)',
        'EdgeInsets.only(bottom: widget.padding!.bottom)': 'EdgeInsets.only(bottom: widget.padding!.bottom)', // Garder
        'EdgeInsets.only(right: 8)': 'EdgeInsets.only(right: AppTheme.space8)',
        'EdgeInsets.symmetric(vertical: 2)': 'EdgeInsets.symmetric(vertical: AppTheme.space2)',
        'EdgeInsets.only(bottom: 8)': 'EdgeInsets.only(bottom: AppTheme.space8)',
        'EdgeInsets.only(bottom: 16)': 'EdgeInsets.only(bottom: AppTheme.space16)',
        'EdgeInsets.only(bottom: 12)': 'EdgeInsets.only(bottom: AppTheme.space12)',
        'EdgeInsets.symmetric(horizontal: 12, vertical: 6)': 'EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space6)',
        'EdgeInsets.only(left: 4, bottom: 16)': 'EdgeInsets.only(left: AppTheme.space4, bottom: AppTheme.space16)',
        'EdgeInsets.symmetric(vertical: 4)': 'EdgeInsets.symmetric(vertical: AppTheme.space4)',
        'EdgeInsets.symmetric(horizontal: 12, vertical: 8)': 'EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space8)',
        'EdgeInsets.symmetric(horizontal: 6, vertical: 2)': 'EdgeInsets.symmetric(horizontal: AppTheme.space6, vertical: AppTheme.space2)',
        'EdgeInsets.symmetric(horizontal: 24, vertical: 16)': 'EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space16)',
        'EdgeInsets.all(14)': 'EdgeInsets.all(AppTheme.space14)',
        'EdgeInsets.symmetric(horizontal: 6, vertical: 4)': 'EdgeInsets.symmetric(horizontal: AppTheme.space6, vertical: AppTheme.space4)',
        'EdgeInsets.symmetric(horizontal: 1)': 'EdgeInsets.symmetric(horizontal: AppTheme.space1)',
        'EdgeInsets.symmetric(horizontal: 24, vertical: 12)': 'EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space12)',
        'EdgeInsets.symmetric(horizontal: 8, vertical: 2)': 'EdgeInsets.symmetric(horizontal: AppTheme.space8, vertical: AppTheme.space2)',
        'EdgeInsets.symmetric(horizontal: 16, vertical: 12)': 'EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12)',
        'EdgeInsets.symmetric(horizontal: 8, vertical: 4)': 'EdgeInsets.symmetric(horizontal: AppTheme.space8, vertical: AppTheme.space4)',
        'EdgeInsets.symmetric(horizontal: 32, vertical: 12)': 'EdgeInsets.symmetric(horizontal: AppTheme.space32, vertical: AppTheme.space12)',
      };

      // BorderRadius hardcodés spécifiques
      final borderRadiusPatterns = {
        'BorderRadius.circular(10)': 'BorderRadius.circular(AppTheme.radius10)',
        'BorderRadius.circular(6)': 'BorderRadius.circular(AppTheme.radius6)',
        'BorderRadius.circular(15)': 'BorderRadius.circular(AppTheme.radius15)',
        'BorderRadius.circular(25)': 'BorderRadius.circular(AppTheme.radius25)',
      };

      // SizedBox hardcodés spécifiques
      final sizedBoxPatterns = {
        'const SizedBox(height: 2)': 'SizedBox(height: AppTheme.space2)',
        'const SizedBox(height: 3)': 'SizedBox(height: AppTheme.space3)',
      };

      // Colors hardcodés dans les fichiers de test
      final colorPatterns = {
        'Color(0xFF6A1B9A)': 'AppTheme.primaryColor',
        'Color(0xFF8E24AA)': 'AppTheme.primaryColorVariant',
        'Color(0xFFAB47BC)': 'AppTheme.primaryColorLight',
        'Color(0xFF4CAF50)': 'AppTheme.successColor',
        'Color(0xFFFF9800)': 'AppTheme.warningColor',
        'Color(0xFFF44336)': 'AppTheme.errorColor',
        'Color(0xFF2196F3)': 'AppTheme.infoColor',
        'Color(0xFFE91E63)': 'AppTheme.accentColor',
        'Color(0xFFFF6B6B)': 'AppTheme.errorColor',
        'Color(0xFFFF8E53)': 'AppTheme.warningColor',
      };

      // Appliquer tous les remplacements
      for (final pattern in edgeInsetsPatterns.entries) {
        final oldContent = newContent;
        newContent = newContent.replaceAll(pattern.key, pattern.value);
        if (newContent != oldContent) {
          fileReplacements += RegExp.escape(pattern.key).allMatches(oldContent).length;
        }
      }

      for (final pattern in borderRadiusPatterns.entries) {
        final oldContent = newContent;
        newContent = newContent.replaceAll(pattern.key, pattern.value);
        if (newContent != oldContent) {
          fileReplacements += RegExp.escape(pattern.key).allMatches(oldContent).length;
        }
      }

      for (final pattern in sizedBoxPatterns.entries) {
        final oldContent = newContent;
        newContent = newContent.replaceAll(pattern.key, pattern.value);
        if (newContent != oldContent) {
          fileReplacements += RegExp.escape(pattern.key).allMatches(oldContent).length;
        }
      }

      for (final pattern in colorPatterns.entries) {
        final oldContent = newContent;
        newContent = newContent.replaceAll(pattern.key, pattern.value);
        if (newContent != oldContent) {
          fileReplacements += RegExp.escape(pattern.key).allMatches(oldContent).length;
        }
      }

      if (fileReplacements > 0) {
        await entity.writeAsString(newContent);
        totalFiles++;
        totalReplacements += fileReplacements;
        print('✅ ${entity.path}: $fileReplacements remplacements');
      }
    }
  }

  callback(totalReplacements, totalFiles);
}