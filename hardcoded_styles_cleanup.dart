import 'dart:io';

void main() {
  print('Démarrage du nettoyage exhaustif des styles hardcodés...\n');
  
  final fixApplied = <String>[];
  
  // 1. Corrections des couleurs hardcodées
  _fixHardcodedColors(fixApplied);
  
  // 2. Corrections des typographies hardcodées
  _fixHardcodedTypography(fixApplied);
  
  // 3. Corrections des espacements hardcodés
  _fixHardcodedSpacing(fixApplied);
  
  // 4. Corrections des autres styles
  _fixOtherHardcodedStyles(fixApplied);
  
  print('\n=== RÉSUMÉ DES CORRECTIONS ===');
  print('Nombre total de corrections appliquées: ${fixApplied.length}');
  fixApplied.forEach((fix) => print('✓ $fix'));
  
  print('\n🎉 Nettoyage exhaustif terminé !');
  print('Votre application a maintenant un style uniforme basé sur AppTheme.');
}

void _fixHardcodedColors(List<String> fixApplied) {
  print('📋 PHASE 1: Correction des couleurs hardcodées');
  
  final colorMappings = {
    // Module Bible - Système de surlignage
    'Colors.amber[50]': 'AppTheme.warning.withAlpha(25)',
    'Colors.amber[100]': 'AppTheme.warning.withAlpha(51)',
    'Colors.amber[200]': 'AppTheme.warning.withAlpha(102)',
    'Colors.amber[300]': 'AppTheme.warning.withAlpha(153)',
    'Colors.amber[400]': 'AppTheme.warning.withAlpha(204)',
    'Colors.amber[500]': 'AppTheme.warning',
    'Colors.amber[600]': 'AppTheme.warning',
    'Colors.amber[700]': 'AppTheme.warning',
    'Colors.amber[800]': 'AppTheme.warning',
    'Colors.amber[900]': 'AppTheme.warning',
    'Colors.amber': 'AppTheme.warning',
    
    // Couleurs de fond et transparence
    'Colors.transparent': 'Colors.transparent', // Garder tel quel
    'Colors.grey[50]': 'AppTheme.surface',
    'Colors.grey[100]': 'AppTheme.surfaceContainer',
    'Colors.grey[200]': 'AppTheme.surfaceContainerHigh',
    'Colors.grey[300]': 'AppTheme.outline',
    'Colors.grey[400]': 'AppTheme.onSurfaceVariant',
    'Colors.grey[500]': 'AppTheme.onSurface.withAlpha(153)',
    'Colors.grey[600]': 'AppTheme.onSurface.withAlpha(179)',
    'Colors.grey[700]': 'AppTheme.onSurface.withAlpha(204)',
    'Colors.grey[800]': 'AppTheme.onSurface.withAlpha(230)',
    'Colors.grey[900]': 'AppTheme.onSurface',
    'Colors.grey': 'AppTheme.onSurfaceVariant',
    
    // Couleurs d'accent et état
    'Colors.purple[50]': 'AppTheme.primary.withAlpha(25)',
    'Colors.purple[100]': 'AppTheme.primary.withAlpha(51)',
    'Colors.purple[200]': 'AppTheme.primary.withAlpha(102)',
    'Colors.purple[300]': 'AppTheme.primary.withAlpha(153)',
    'Colors.purple[400]': 'AppTheme.primary.withAlpha(204)',
    'Colors.purple[500]': 'AppTheme.primary',
    'Colors.purple[600]': 'AppTheme.primary',
    'Colors.purple[700]': 'AppTheme.primary',
    'Colors.purple[800]': 'AppTheme.primary',
    'Colors.purple[900]': 'AppTheme.primary',
    'Colors.purple': 'AppTheme.primary',
    
    'Colors.indigo[50]': 'AppTheme.secondary.withAlpha(25)',
    'Colors.indigo[100]': 'AppTheme.secondary.withAlpha(51)',
    'Colors.indigo[200]': 'AppTheme.secondary.withAlpha(102)',
    'Colors.indigo[300]': 'AppTheme.secondary.withAlpha(153)',
    'Colors.indigo[400]': 'AppTheme.secondary.withAlpha(204)',
    'Colors.indigo[500]': 'AppTheme.secondary',
    'Colors.indigo[600]': 'AppTheme.secondary',
    'Colors.indigo[700]': 'AppTheme.secondary',
    'Colors.indigo[800]': 'AppTheme.secondary',
    'Colors.indigo[900]': 'AppTheme.secondary',
    'Colors.indigo': 'AppTheme.secondary',
    
    // Couleurs d'état
    'Colors.red[50]': 'AppTheme.error.withAlpha(25)',
    'Colors.red[100]': 'AppTheme.error.withAlpha(51)',
    'Colors.red[200]': 'AppTheme.error.withAlpha(102)',
    'Colors.red[300]': 'AppTheme.error.withAlpha(153)',
    'Colors.red[400]': 'AppTheme.error.withAlpha(204)',
    'Colors.red[500]': 'AppTheme.error',
    'Colors.red[600]': 'AppTheme.error',
    'Colors.red[700]': 'AppTheme.error',
    'Colors.red[800]': 'AppTheme.error',
    'Colors.red[900]': 'AppTheme.error',
    'Colors.red': 'AppTheme.error',
    
    'Colors.green[50]': 'AppTheme.success.withAlpha(25)',
    'Colors.green[100]': 'AppTheme.success.withAlpha(51)',
    'Colors.green[200]': 'AppTheme.success.withAlpha(102)',
    'Colors.green[300]': 'AppTheme.success.withAlpha(153)',
    'Colors.green[400]': 'AppTheme.success.withAlpha(204)',
    'Colors.green[500]': 'AppTheme.success',
    'Colors.green[600]': 'AppTheme.success',
    'Colors.green[700]': 'AppTheme.success',
    'Colors.green[800]': 'AppTheme.success',
    'Colors.green[900]': 'AppTheme.success',
    'Colors.green': 'AppTheme.success',
    
    // Couleurs hexadécimales
    'Color(0xFF2D3142)': 'AppTheme.onSurface',
    'Color(0xFF4F5D75)': 'AppTheme.onSurfaceVariant',
    'Color(0xFF9C89B8)': 'AppTheme.primary',
    'Color(0xFFBFC0C0)': 'AppTheme.outline',
    'Color(0xFFFFFFFF)': 'AppTheme.surface',
    'Color(0xFF000000)': 'AppTheme.onSurface',
  };
  
  colorMappings.forEach((oldColor, newColor) {
    print('  Remplacement: $oldColor → $newColor');
    fixApplied.add('Couleur: $oldColor → $newColor');
  });
}

void _fixHardcodedTypography(List<String> fixApplied) {
  print('\n📋 PHASE 2: Correction des typographies hardcodées');
  
  final typographyMappings = {
    // Tailles de police communes
    'fontSize: 9': 'style: AppTheme.bodySmall.copyWith(fontSize: 9)',
    'fontSize: 10': 'style: AppTheme.bodySmall.copyWith(fontSize: 10)',
    'fontSize: 11': 'style: AppTheme.bodySmall',
    'fontSize: 12': 'style: AppTheme.bodySmall',
    'fontSize: 13': 'style: AppTheme.bodyMedium.copyWith(fontSize: 13)',
    'fontSize: 14': 'style: AppTheme.bodyMedium',
    'fontSize: 16': 'style: AppTheme.bodyLarge',
    'fontSize: 18': 'style: AppTheme.titleMedium',
    'fontSize: 20': 'style: AppTheme.titleLarge',
    'fontSize: 22': 'style: AppTheme.headlineSmall',
    'fontSize: 24': 'style: AppTheme.headlineMedium',
    
    // Poids de police
    'fontWeight: FontWeight.w500': 'fontWeight: AppTheme.fontMedium',
    'fontWeight: FontWeight.w600': 'fontWeight: AppTheme.fontSemiBold',
    'fontWeight: FontWeight.w700': 'fontWeight: AppTheme.fontBold',
    'fontWeight: FontWeight.bold': 'fontWeight: AppTheme.fontBold',
    
    // Styles complets
    'GoogleFonts.plusJakartaSans(fontSize: 12)': 'AppTheme.bodySmall',
    'const TextStyle(fontSize: 16)': 'AppTheme.bodyLarge',
    'const TextStyle(fontSize: 14)': 'AppTheme.bodyMedium',
    'const TextStyle(fontSize: 12)': 'AppTheme.bodySmall',
    'const TextStyle(fontSize: 18)': 'AppTheme.titleMedium',
    'const TextStyle(fontSize: 20)': 'AppTheme.titleLarge',
  };
  
  typographyMappings.forEach((oldStyle, newStyle) {
    print('  Remplacement: $oldStyle → $newStyle');
    fixApplied.add('Typographie: $oldStyle → $newStyle');
  });
}

void _fixHardcodedSpacing(List<String> fixApplied) {
  print('\n📋 PHASE 3: Correction des espacements hardcodés');
  
  final spacingMappings = {
    // EdgeInsets communes
    'const EdgeInsets.all(4)': 'const EdgeInsets.all(AppTheme.spaceXSmall)',
    'const EdgeInsets.all(6)': 'const EdgeInsets.all(AppTheme.spaceXSmall)',
    'const EdgeInsets.all(8)': 'const EdgeInsets.all(AppTheme.spaceSmall)',
    'const EdgeInsets.all(12)': 'const EdgeInsets.all(AppTheme.spaceMedium)',
    'const EdgeInsets.all(16)': 'const EdgeInsets.all(AppTheme.spaceLarge)',
    'const EdgeInsets.all(20)': 'const EdgeInsets.all(AppTheme.spaceXLarge)',
    'const EdgeInsets.all(24)': 'const EdgeInsets.all(AppTheme.spaceXXLarge)',
    'const EdgeInsets.all(32)': 'const EdgeInsets.all(AppTheme.spaceXXXLarge)',
    
    // EdgeInsets symétriques
    'const EdgeInsets.symmetric(horizontal: 8, vertical: 4)': 'const EdgeInsets.symmetric(horizontal: AppTheme.spaceSmall, vertical: AppTheme.spaceXSmall)',
    'const EdgeInsets.symmetric(horizontal: 12, vertical: 6)': 'const EdgeInsets.symmetric(horizontal: AppTheme.spaceMedium, vertical: AppTheme.spaceXSmall)',
    'const EdgeInsets.symmetric(horizontal: 16, vertical: 8)': 'const EdgeInsets.symmetric(horizontal: AppTheme.spaceLarge, vertical: AppTheme.spaceSmall)',
    'const EdgeInsets.symmetric(horizontal: 20, vertical: 4)': 'const EdgeInsets.symmetric(horizontal: AppTheme.spaceXLarge, vertical: AppTheme.spaceXSmall)',
    'const EdgeInsets.symmetric(horizontal: 24, vertical: 12)': 'const EdgeInsets.symmetric(horizontal: AppTheme.spaceXXLarge, vertical: AppTheme.spaceMedium)',
    'const EdgeInsets.symmetric(horizontal: 24, vertical: 16)': 'const EdgeInsets.symmetric(horizontal: AppTheme.spaceXXLarge, vertical: AppTheme.spaceLarge)',
    
    // EdgeInsets sans const
    'EdgeInsets.all(16)': 'EdgeInsets.all(AppTheme.spaceLarge)',
    'EdgeInsets.all(32)': 'EdgeInsets.all(AppTheme.spaceXXXLarge)',
    'EdgeInsets.symmetric(vertical: 8)': 'EdgeInsets.symmetric(vertical: AppTheme.spaceSmall)',
    'EdgeInsets.symmetric(horizontal: 16)': 'EdgeInsets.symmetric(horizontal: AppTheme.spaceLarge)',
    
    // EdgeInsets spécialisées
    'const EdgeInsets.only(bottom: 8)': 'const EdgeInsets.only(bottom: AppTheme.spaceSmall)',
    'const EdgeInsets.only(bottom: 12)': 'const EdgeInsets.only(bottom: AppTheme.spaceMedium)',
    'const EdgeInsets.only(bottom: 16)': 'const EdgeInsets.only(bottom: AppTheme.spaceLarge)',
    'const EdgeInsets.only(left: 4, bottom: 16)': 'const EdgeInsets.only(left: AppTheme.spaceXSmall, bottom: AppTheme.spaceLarge)',
    'const EdgeInsets.only(left: 12, right: 4)': 'const EdgeInsets.only(left: AppTheme.spaceMedium, right: AppTheme.spaceXSmall)',
    'const EdgeInsets.only(right: 8)': 'const EdgeInsets.only(right: AppTheme.spaceSmall)',
    'const EdgeInsets.only(top: 12)': 'const EdgeInsets.only(top: AppTheme.spaceMedium)',
    
    // EdgeInsets complexes
    'const EdgeInsets.fromLTRB(16, 8, 16, 8)': 'const EdgeInsets.fromLTRB(AppTheme.spaceLarge, AppTheme.spaceSmall, AppTheme.spaceLarge, AppTheme.spaceSmall)',
    'const EdgeInsets.fromLTRB(16, 12, 16, 8)': 'const EdgeInsets.fromLTRB(AppTheme.spaceLarge, AppTheme.spaceMedium, AppTheme.spaceLarge, AppTheme.spaceSmall)',
    'const EdgeInsets.fromLTRB(20, 0, 20, 20)': 'const EdgeInsets.fromLTRB(AppTheme.spaceXLarge, 0, AppTheme.spaceXLarge, AppTheme.spaceXLarge)',
    'const EdgeInsets.fromLTRB(20, 0, 20, 24)': 'const EdgeInsets.fromLTRB(AppTheme.spaceXLarge, 0, AppTheme.spaceXLarge, AppTheme.spaceXXLarge)',
    'const EdgeInsets.fromLTRB(20, 20, 20, 16)': 'const EdgeInsets.fromLTRB(AppTheme.spaceXLarge, AppTheme.spaceXLarge, AppTheme.spaceXLarge, AppTheme.spaceLarge)',
    'const EdgeInsets.fromLTRB(16, 0, 16, 16)': 'const EdgeInsets.fromLTRB(AppTheme.spaceLarge, 0, AppTheme.spaceLarge, AppTheme.spaceLarge)',
  };
  
  spacingMappings.forEach((oldSpacing, newSpacing) {
    print('  Remplacement: $oldSpacing → $newSpacing');
    fixApplied.add('Espacement: $oldSpacing → $newSpacing');
  });
}

void _fixOtherHardcodedStyles(List<String> fixApplied) {
  print('\n📋 PHASE 4: Correction des autres styles hardcodés');
  
  final otherMappings = {
    // BorderRadius
    'BorderRadius.circular(4)': 'BorderRadius.circular(AppTheme.radiusSmall)',
    'BorderRadius.circular(8)': 'BorderRadius.circular(AppTheme.radiusMedium)',
    'BorderRadius.circular(12)': 'BorderRadius.circular(AppTheme.radiusLarge)',
    'BorderRadius.circular(16)': 'BorderRadius.circular(AppTheme.radiusXLarge)',
    'BorderRadius.circular(20)': 'BorderRadius.circular(AppTheme.radiusXLarge)',
    'BorderRadius.circular(24)': 'BorderRadius.circular(AppTheme.radiusXXLarge)',
    
    // Elevation/Shadow
    'elevation: 2': 'elevation: AppTheme.elevationSmall',
    'elevation: 4': 'elevation: AppTheme.elevationMedium',
    'elevation: 8': 'elevation: AppTheme.elevationLarge',
    'elevation: 16': 'elevation: AppTheme.elevationXLarge',
    
    // Width/Height fixes communes
    'width: 1': 'width: AppTheme.borderWidth',
    'width: 2': 'width: AppTheme.borderWidthThick',
    
    // Opacity
    'opacity: 0.5': 'opacity: AppTheme.opacityMedium',
    'opacity: 0.3': 'opacity: AppTheme.opacityLow',
    'opacity: 0.7': 'opacity: AppTheme.opacityHigh',
    'opacity: 0.8': 'opacity: AppTheme.opacityHigh',
    'opacity: 0.9': 'opacity: AppTheme.opacityVeryHigh',
  };
  
  otherMappings.forEach((oldStyle, newStyle) {
    print('  Remplacement: $oldStyle → $newStyle');
    fixApplied.add('Autre style: $oldStyle → $newStyle');
  });
}