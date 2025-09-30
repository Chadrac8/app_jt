// Script simple pour lister et identifier les cantiques
// À exécuter dans l'application Flutter directement

void printCantiqueAnalysis() {
  print('🎵 ANALYSE DES CANTIQUES');
  print('========================');
  
  // Instructions pour l'utilisateur
  print('Pour identifier les cantiques qui commencent au numéro 243:');
  print('');
  print('1. 📱 DANS L\'APPLICATION:');
  print('   - Ouvrez la section Chants');
  print('   - Regardez les premiers chants affichés');
  print('   - Notez ceux qui sont des cantiques traditionnels');
  print('');
  print('2. 🔍 IDENTIFIEZ LES CANTIQUES PAR:');
  print('   - Titres: "Ô Dieu notre aide", "Mon Jésus", "Gloire à Dieu", etc.');
  print('   - Style traditionnel/hymnes religieux');
  print('   - Souvent plus anciens que les chants modernes');
  print('');
  print('3. 📝 SOLUTION MANUELLE:');
  print('   - Console Firebase: https://console.firebase.google.com');
  print('   - Sélectionnez votre projet');
  print('   - Firestore Database > Collection "songs"');
  print('   - Modifiez le champ "number" des cantiques:');
  print('     * Premier cantique: number = 1');
  print('     * Deuxième cantique: number = 2');
  print('     * etc.');
  print('');
  print('4. 🎯 RÉSULTAT ATTENDU:');
  print('   - Cantiques: numéros 1 à X');
  print('   - Autres chants: gardent leurs numéros actuels');
  print('');
  print('💡 Alternative rapide: Dans l\'app, vérifiez si il y a une fonction');
  print('   d\'administration pour modifier les numéros des chants.');
}

// Fonction pour identifier les cantiques potentiels
bool isLikelyCantique(String title) {
  final titleLower = title.toLowerCase();
  
  // Patterns typiques des cantiques
  final patterns = [
    'ô ',
    'o ',
    'mon ',
    'ma ',
    'gloire',
    'seigneur',
    'jésus',
    'dieu',
    'éternel',
    'christ',
    'louange',
    'cantique',
    'hymne',
    'alléluia',
    'alleluia',
    'hosanna',
    'saint',
    'sainte',
    'père',
    'esprit',
    'grâce',
    'amour divin',
    'roi des rois',
    'agneau',
    'croix',
    'résurrection',
    'salut',
    'rédemption',
  ];
  
  return patterns.any((pattern) => titleLower.contains(pattern)) ||
         titleLower.startsWith(RegExp(r'^(il|elle|nous|vous|ils|elles|que|quand|comme|dans|sur|avec)\s'));
}

void main() {
  printCantiqueAnalysis();
  
  // Test de quelques titres
  print('\n🧪 TEST D\'IDENTIFICATION:');
  final testTitles = [
    'Ô Dieu notre aide',
    'Mon Jésus je t\'aime',  
    'Gloire à Dieu au plus haut des cieux',
    'Chant moderne de louange',
    'Il est vivant',
    'Que ton règne vienne',
  ];
  
  for (final title in testTitles) {
    final isCantique = isLikelyCantique(title);
    final icon = isCantique ? '✅' : '❌';
    print('   $icon "$title" = ${isCantique ? 'CANTIQUE' : 'Chant moderne'}');
  }
}