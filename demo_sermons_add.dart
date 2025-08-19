import 'lib/modules/message/models/admin_branham_sermon_model.dart';
import 'lib/modules/message/services/admin_branham_sermon_service.dart';

/// Script pour ajouter des prédications de démonstration de William Marrion Branham
/// Exécutez ce script pour peupler la base de données avec des prédications d'exemple
void main() async {
  print('🎤 Ajout de prédications de démonstration de William Marrion Branham');
  print('====================================================================');

  final demoSermons = [
    AdminBranhamSermon(
      id: '',
      title: 'La Foi qui Fut Donnée Aux Saints',
      date: '55-0501',
      location: 'Chicago, Illinois',
      audioUrl: 'https://files.messageofhope.fr/audio/la-foi-qui-fut-donnee-aux-saints.mp3',
      description: 'Une prédication fondamentale sur la foi authentique donnée aux saints.',
      duration: const Duration(hours: 1, minutes: 30),
      language: 'fr',
      keywords: ['foi', 'saints', 'doctrine', 'fondamental'],
      series: 'Doctrine Fondamentale',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      displayOrder: 1,
    ),
    
    AdminBranhamSermon(
      id: '',
      title: 'Le Signe du Temps de la Fin',
      date: '62-1230',
      location: 'Jeffersonville, Indiana',
      audioUrl: 'https://files.messageofhope.fr/audio/le-signe-du-temps-de-la-fin.mp3',
      description: 'Les signes prophétiques qui marquent la fin des temps.',
      duration: const Duration(hours: 2, minutes: 15),
      language: 'fr',
      keywords: ['signes', 'prophétie', 'fin des temps', 'apocalypse'],
      series: 'Prophétie',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      displayOrder: 2,
    ),
    
    AdminBranhamSermon(
      id: '',
      title: 'La Révélation de Jésus-Christ',
      date: '60-1204',
      location: 'Jeffersonville, Indiana',
      audioUrl: 'https://files.messageofhope.fr/audio/la-revelation-de-jesus-christ.mp3',
      description: 'Une série sur l\'Apocalypse et la révélation progressive de Christ.',
      duration: const Duration(hours: 1, minutes: 45),
      language: 'fr',
      keywords: ['révélation', 'apocalypse', 'jésus', 'christ'],
      series: 'Apocalypse',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      displayOrder: 3,
    ),
    
    AdminBranhamSermon(
      id: '',
      title: 'Les Sept Ages de l\'Église',
      date: '60-1205',
      location: 'Jeffersonville, Indiana',
      audioUrl: 'https://files.messageofhope.fr/audio/les-sept-ages-de-leglise.mp3',
      description: 'Enseignement sur les sept périodes de l\'histoire de l\'Église.',
      duration: const Duration(hours: 2, minutes: 30),
      language: 'fr',
      keywords: ['église', 'histoire', 'sept ages', 'dispensation'],
      series: 'Sept Ages de l\'Église',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      displayOrder: 4,
    ),
    
    AdminBranhamSermon(
      id: '',
      title: 'La Semence du Serpent',
      date: '58-0928',
      location: 'Jeffersonville, Indiana',
      audioUrl: 'https://files.messageofhope.fr/audio/la-semence-du-serpent.mp3',
      description: 'Enseignement sur l\'origine du mal et la chute de l\'humanité.',
      duration: const Duration(hours: 1, minutes: 55),
      language: 'fr',
      keywords: ['serpent', 'genèse', 'chute', 'origine'],
      series: 'Genèse',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      displayOrder: 5,
    ),
    
    AdminBranhamSermon(
      id: '',
      title: 'Dieu Se Cache dans la Simplicité',
      date: '63-0317',
      location: 'Jeffersonville, Indiana',
      audioUrl: 'https://files.messageofhope.fr/audio/dieu-se-cache-dans-la-simplicite.mp3',
      description: 'Comment Dieu révèle Ses mystères aux cœurs simples.',
      duration: const Duration(hours: 1, minutes: 20),
      language: 'fr',
      keywords: ['simplicité', 'révélation', 'humilité', 'mystères'],
      series: 'Révélation Divine',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      displayOrder: 6,
    ),
    
    AdminBranhamSermon(
      id: '',
      title: 'La Parole Parlée est la Semence Originale',
      date: '62-0318',
      location: 'Jeffersonville, Indiana',
      audioUrl: 'https://files.messageofhope.fr/audio/la-parole-parlee-est-la-semence-originale.mp3',
      description: 'L\'importance de la Parole de Dieu comme semence de vie.',
      duration: const Duration(hours: 2, minutes: 0),
      language: 'fr',
      keywords: ['parole', 'semence', 'bible', 'vérité'],
      series: 'La Parole',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      displayOrder: 7,
    ),
    
    AdminBranhamSermon(
      id: '',
      title: 'Qu\'est-ce que la Vérité?',
      date: '64-0426',
      location: 'Phoenix, Arizona',
      audioUrl: 'https://files.messageofhope.fr/audio/quest-ce-que-la-verite.mp3',
      description: 'Une recherche profonde de la vérité divine et spirituelle.',
      duration: const Duration(hours: 1, minutes: 40),
      language: 'fr',
      keywords: ['vérité', 'pilate', 'jésus', 'témoignage'],
      series: 'Questions Spirituelles',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      displayOrder: 8,
    ),
  ];

  print('\\n📝 Ajout de ${demoSermons.length} prédications de démonstration...');
  
  int successCount = 0;
  int errorCount = 0;

  for (final sermon in demoSermons) {
    try {
      final id = await AdminBranhamSermonService.addSermon(sermon);
      if (id != null) {
        print('✅ Ajouté: "${sermon.title}" (${sermon.date})');
        successCount++;
      } else {
        print('❌ Échec: "${sermon.title}" (${sermon.date})');
        errorCount++;
      }
    } catch (e) {
      print('❌ Erreur pour "${sermon.title}": $e');
      errorCount++;
    }
  }

  print('\\n📊 Résumé:');
  print('   ✅ Succès: $successCount prédications');
  print('   ❌ Erreurs: $errorCount prédications');
  
  if (successCount > 0) {
    print('\\n🎉 Les prédications de démonstration ont été ajoutées avec succès !');
    print('   Vous pouvez maintenant tester le lecteur audio dans l\'onglet "Écouter".');
    print('   Les administrateurs peuvent gérer ces prédications via l\'interface admin.');
  } else {
    print('\\n⚠️ Aucune prédication n\'a pu être ajoutée.');
    print('   Vérifiez la connexion Firebase et les permissions.');
  }
}
