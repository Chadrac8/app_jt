#!/usr/bin/env dart

import 'dart:io';

void main() async {
  print('🚀 Démarrage du nettoyage exhaustif des valeurs hardcodées...');
  
  final libDirectory = Directory('lib');
  
  if (!libDirectory.existsSync()) {
    print('❌ Répertoire lib/ non trouvé');
    return;
  }
  
  var totalReplacements = 0;
  var totalFiles = 0;
  
  await for (final entity in libDirectory.list(recursive: true, followLinks: false)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = await entity.readAsString();
      var newContent = content;
      var replacements = 0;
      
      // === COULEURS HARDCODÉES ===
      
      // Color(0x...) patterns
      final colorPatterns = {
        'Color(0xFFE57373)': 'AppTheme.passageColor1',
        'Color(0xFF64B5F6)': 'AppTheme.passageColor2', 
        'Color(0xFF81C784)': 'AppTheme.passageColor3',
        'Color(0xFFFFB74D)': 'AppTheme.passageColor4',
        'Color(0xFFBA68C8)': 'AppTheme.passageColor5',
        'Color(0xFFFFD700)': 'AppTheme.goldColor',
        'Color(0xFF1E1E1E)': 'AppTheme.darkModeBackground',
        'Color(0xFF10B981)': 'AppTheme.successColorBright',
        'const Color(0xFFE57373)': 'AppTheme.passageColor1',
        'const Color(0xFF64B5F6)': 'AppTheme.passageColor2',
        'const Color(0xFF81C784)': 'AppTheme.passageColor3',
        'const Color(0xFFFFB74D)': 'AppTheme.passageColor4',
        'const Color(0xFFBA68C8)': 'AppTheme.passageColor5',
        'const Color(0xFFFFD700)': 'AppTheme.goldColor',
        'const Color(0xFF1E1E1E)': 'AppTheme.darkModeBackground',
        'const Color(0xFF10B981)': 'AppTheme.successColorBright',
        'Colors.lightBlue': 'AppTheme.blueStandard',
        'Colors.lightGreen': 'AppTheme.greenStandard',
      };
      
      // === TAILLES DE POLICE HARDCODÉES ===
      
      final fontSizePatterns = {
        'fontSize: 10': 'fontSize: AppTheme.fontSize10',
        'fontSize: 11': 'fontSize: AppTheme.fontSize11',
        'fontSize: 12': 'fontSize: AppTheme.fontSize12',
        'fontSize: 13': 'fontSize: AppTheme.fontSize13',
        'fontSize: 14': 'fontSize: AppTheme.fontSize14',
        'fontSize: 15': 'fontSize: AppTheme.fontSize15',
        'fontSize: 16': 'fontSize: AppTheme.fontSize16',
        'fontSize: 18': 'fontSize: AppTheme.fontSize18',
        'fontSize: 20': 'fontSize: AppTheme.fontSize20',
        'fontSize: 22': 'fontSize: AppTheme.fontSize22',
        'fontSize: 24': 'fontSize: AppTheme.fontSize24',
        'fontSize: 28': 'fontSize: AppTheme.fontSize28',
        'fontSize: 32': 'fontSize: AppTheme.fontSize32',
        'fontSize: 36': 'fontSize: AppTheme.fontSize36',
        'fontSize: 45': 'fontSize: AppTheme.fontSize45',
        'fontSize: 57': 'fontSize: AppTheme.fontSize57',
      };
      
      // === BORDER RADIUS HARDCODÉS ===
      
      final borderRadiusPatterns = {
        'BorderRadius.circular(2)': 'BorderRadius.circular(AppTheme.radius2)',
        'BorderRadius.circular(4)': 'BorderRadius.circular(AppTheme.radiusSmall)',
        'BorderRadius.circular(8)': 'BorderRadius.circular(AppTheme.radiusMedium)',
        'BorderRadius.circular(12)': 'BorderRadius.circular(AppTheme.radiusLarge)',
        'BorderRadius.circular(16)': 'BorderRadius.circular(AppTheme.radiusXLarge)',
        'BorderRadius.circular(20)': 'BorderRadius.circular(AppTheme.radiusXXLarge)',
        'BorderRadius.circular(24)': 'BorderRadius.circular(AppTheme.radiusCircular)',
        'BorderRadius.circular(32)': 'BorderRadius.circular(AppTheme.radiusRound)',
      };
      
      // === ESPACEMENT HARDCODÉS ===
      
      final spacingPatterns = {
        'EdgeInsets.all(2)': 'EdgeInsets.all(AppTheme.space2)',
        'EdgeInsets.all(4)': 'EdgeInsets.all(AppTheme.spaceXSmall)',
        'EdgeInsets.all(6)': 'EdgeInsets.all(AppTheme.space6)',
        'EdgeInsets.all(8)': 'EdgeInsets.all(AppTheme.spaceSmall)',
        'EdgeInsets.all(10)': 'EdgeInsets.all(AppTheme.space10)',
        'EdgeInsets.all(12)': 'EdgeInsets.all(AppTheme.space12)',
        'EdgeInsets.all(16)': 'EdgeInsets.all(AppTheme.spaceMedium)',
        'EdgeInsets.all(18)': 'EdgeInsets.all(AppTheme.space18)',
        'EdgeInsets.all(20)': 'EdgeInsets.all(AppTheme.space20)',
        'EdgeInsets.all(24)': 'EdgeInsets.all(AppTheme.spaceLarge)',
        'EdgeInsets.all(32)': 'EdgeInsets.all(AppTheme.spaceXLarge)',
        'EdgeInsets.all(40)': 'EdgeInsets.all(AppTheme.space40)',
        'const EdgeInsets.all(2)': 'const EdgeInsets.all(AppTheme.space2)',
        'const EdgeInsets.all(4)': 'const EdgeInsets.all(AppTheme.spaceXSmall)',
        'const EdgeInsets.all(6)': 'const EdgeInsets.all(AppTheme.space6)',
        'const EdgeInsets.all(8)': 'const EdgeInsets.all(AppTheme.spaceSmall)',
        'const EdgeInsets.all(10)': 'const EdgeInsets.all(AppTheme.space10)',
        'const EdgeInsets.all(12)': 'const EdgeInsets.all(AppTheme.space12)',
        'const EdgeInsets.all(16)': 'const EdgeInsets.all(AppTheme.spaceMedium)',
        'const EdgeInsets.all(18)': 'const EdgeInsets.all(AppTheme.space18)',
        'const EdgeInsets.all(20)': 'const EdgeInsets.all(AppTheme.space20)',
        'const EdgeInsets.all(24)': 'const EdgeInsets.all(AppTheme.spaceLarge)',
        'const EdgeInsets.all(32)': 'const EdgeInsets.all(AppTheme.spaceXLarge)',
        'const EdgeInsets.all(40)': 'const EdgeInsets.all(AppTheme.space40)',
      };
      
      // === SIZEDBOX HARDCODÉS ===
      
      final sizedBoxPatterns = {
        'SizedBox(height: 4)': 'SizedBox(height: AppTheme.spaceXSmall)',
        'SizedBox(height: 6)': 'SizedBox(height: AppTheme.space6)',
        'SizedBox(height: 8)': 'SizedBox(height: AppTheme.spaceSmall)',
        'SizedBox(height: 10)': 'SizedBox(height: AppTheme.space10)',
        'SizedBox(height: 12)': 'SizedBox(height: AppTheme.space12)',
        'SizedBox(height: 16)': 'SizedBox(height: AppTheme.spaceMedium)',
        'SizedBox(height: 18)': 'SizedBox(height: AppTheme.space18)',
        'SizedBox(height: 20)': 'SizedBox(height: AppTheme.space20)',
        'SizedBox(height: 24)': 'SizedBox(height: AppTheme.spaceLarge)',
        'SizedBox(height: 32)': 'SizedBox(height: AppTheme.spaceXLarge)',
        'SizedBox(height: 40)': 'SizedBox(height: AppTheme.space40)',
        'SizedBox(width: 4)': 'SizedBox(width: AppTheme.spaceXSmall)',
        'SizedBox(width: 6)': 'SizedBox(width: AppTheme.space6)',
        'SizedBox(width: 8)': 'SizedBox(width: AppTheme.spaceSmall)',
        'SizedBox(width: 10)': 'SizedBox(width: AppTheme.space10)',
        'SizedBox(width: 12)': 'SizedBox(width: AppTheme.space12)',
        'SizedBox(width: 16)': 'SizedBox(width: AppTheme.spaceMedium)',
        'SizedBox(width: 18)': 'SizedBox(width: AppTheme.space18)',
        'SizedBox(width: 20)': 'SizedBox(width: AppTheme.space20)',
        'SizedBox(width: 24)': 'SizedBox(width: AppTheme.spaceLarge)',
        'SizedBox(width: 32)': 'SizedBox(width: AppTheme.spaceXLarge)',
        'const SizedBox(height: 4)': 'const SizedBox(height: AppTheme.spaceXSmall)',
        'const SizedBox(height: 6)': 'const SizedBox(height: AppTheme.space6)',
        'const SizedBox(height: 8)': 'const SizedBox(height: AppTheme.spaceSmall)',
        'const SizedBox(height: 10)': 'const SizedBox(height: AppTheme.space10)',
        'const SizedBox(height: 12)': 'const SizedBox(height: AppTheme.space12)',
        'const SizedBox(height: 16)': 'const SizedBox(height: AppTheme.spaceMedium)',
        'const SizedBox(height: 18)': 'const SizedBox(height: AppTheme.space18)',
        'const SizedBox(height: 20)': 'const SizedBox(height: AppTheme.space20)',
        'const SizedBox(height: 24)': 'const SizedBox(height: AppTheme.spaceLarge)',
        'const SizedBox(height: 32)': 'const SizedBox(height: AppTheme.spaceXLarge)',
        'const SizedBox(height: 40)': 'const SizedBox(height: AppTheme.space40)',
        'const SizedBox(width: 4)': 'const SizedBox(width: AppTheme.spaceXSmall)',
        'const SizedBox(width: 6)': 'const SizedBox(width: AppTheme.space6)',
        'const SizedBox(width: 8)': 'const SizedBox(width: AppTheme.spaceSmall)',
        'const SizedBox(width: 10)': 'const SizedBox(width: AppTheme.space10)',
        'const SizedBox(width: 12)': 'const SizedBox(width: AppTheme.space12)',
        'const SizedBox(width: 16)': 'const SizedBox(width: AppTheme.spaceMedium)',
        'const SizedBox(width: 18)': 'const SizedBox(width: AppTheme.space18)',
        'const SizedBox(width: 20)': 'const SizedBox(width: AppTheme.space20)',
        'const SizedBox(width: 24)': 'const SizedBox(width: AppTheme.spaceLarge)',
        'const SizedBox(width: 32)': 'const SizedBox(width: AppTheme.spaceXLarge)',
      };
      
      // === FONT WEIGHTS HARDCODÉS ===
      
      final fontWeightPatterns = {
        'fontWeight: FontWeight.w300': 'fontWeight: AppTheme.fontLight',
        'fontWeight: FontWeight.w400': 'fontWeight: AppTheme.fontRegular',
        'fontWeight: FontWeight.w500': 'fontWeight: AppTheme.fontMedium',
        'fontWeight: FontWeight.w600': 'fontWeight: AppTheme.fontSemiBold',
        'fontWeight: FontWeight.w700': 'fontWeight: AppTheme.fontBold',
        'FontWeight.bold': 'AppTheme.fontBold',
      };
      
      // Appliquer tous les patterns
      final allPatterns = {
        ...colorPatterns,
        ...fontSizePatterns,
        ...borderRadiusPatterns,
        ...spacingPatterns,
        ...sizedBoxPatterns,
        ...fontWeightPatterns,
      };
      
      for (final pattern in allPatterns.entries) {
        if (newContent.contains(pattern.key)) {
          newContent = newContent.replaceAll(pattern.key, pattern.value);
          replacements++;
        }
      }
      
      if (replacements > 0) {
        await entity.writeAsString(newContent);
        totalFiles++;
        totalReplacements += replacements;
        print('✅ ${entity.path}: $replacements remplacements');
      }
    }
  }
  
  print('\n🎉 Nettoyage terminé !');
  print('📊 $totalReplacements remplacements dans $totalFiles fichiers');
}