import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'services/sermon_service.dart';
import 'models/sermon.dart';

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Sample sermons to add
  final sampleSermons = [
    Sermon(
      id: '',
      titre: 'La communion par la rédemption',
      orateur: 'Pasteur Jean-Marie Kadjo',
      date: DateTime(2024, 3, 15),
      lienYoutube: 'https://youtube.com/watch?v=example1',
      notes: '''# La communion par la rédemption

## Introduction
La rédemption est le fondement de notre communion avec Dieu et entre frères et sœurs.

## Points principaux

### 1. Le prix de la rédemption
- Jésus a payé le prix de nos péchés
- Son sang nous purifie de toute iniquité
- **1 Jean 1:7** : "Mais si nous marchons dans la lumière..."

### 2. La nouvelle nature
- Nous sommes devenus enfants de Dieu
- Une transformation intérieure
- L'Esprit témoigne à notre esprit

### 3. La communion restaurée
- Avec le Père
- Avec le Fils
- Avec les frères et sœurs

## Conclusion
La rédemption nous unit dans une même famille spirituelle.

## Questions pour la méditation
1. Comment expérimentez-vous cette communion au quotidien ?
2. Que signifie marcher dans la lumière pour vous ?''',
      tags: ['rédemption', 'communion', 'salut'],
      duree: 45,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    
    Sermon(
      id: '',
      titre: 'La foi qui agit par l\'amour',
      orateur: 'Pasteur Marie Kouadio',
      date: DateTime(2024, 3, 22),
      lienYoutube: 'https://youtube.com/watch?v=example2',
      notes: '''# La foi qui agit par l'amour

## Texte de base
**Galates 5:6** : "Car, en Jésus-Christ, ni la circoncision ni l'incirconcision n'a de valeur, mais la foi qui est agissante par l'amour."

## Plan du message

### 1. La nature de la vraie foi
- Elle n'est pas statique
- Elle se manifeste par des actes
- Elle est motivée par l'amour

### 2. L'amour comme moteur
- L'amour de Dieu nous contraint
- Aimer Dieu en retour
- Aimer notre prochain

### 3. Les fruits visibles
- Service désintéressé
- Générosité
- Compassion active

## Application pratique
Comment ma foi se manifeste-t-elle par l'amour cette semaine ?

## Prière
Seigneur, que notre foi soit vivante et agissante par ton amour.''',
      tags: ['foi', 'amour', 'action'],
      duree: 38,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    
    Sermon(
      id: '',
      titre: 'L\'espérance qui ne trompe point',
      orateur: 'Pasteur Daniel Kouassi',
      date: DateTime(2024, 3, 29),
      lienYoutube: 'https://youtube.com/watch?v=example3',
      notes: '''# L'espérance qui ne trompe point

## Référence biblique
**Romains 5:5** : "Or, l'espérance ne trompe point, parce que l'amour de Dieu est répandu dans nos cœurs par le Saint-Esprit qui nous a été donné."

## Introduction
Dans un monde d'incertitudes, l'espérance chrétienne est notre ancre.

## Développement

### I. Une espérance fondée
- Sur les promesses de Dieu
- Sur l'œuvre de Christ
- Sur la fidélité divine

### II. Une espérance vivante
- Elle grandit dans l'épreuve
- Elle se nourrit de la Parole
- Elle s'affermit par la prière

### III. Une espérance partagée
- Encourager les autres
- Témoigner de notre espoir
- Vivre comme des gens d'espérance

## Conclusion
Notre espérance en Christ ne sera jamais déçue.

## Cantique de clôture
"Quel ami fidèle et tendre"''',
      tags: ['espérance', 'promesses', 'fidélité'],
      duree: 42,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    
    Sermon(
      id: '',
      titre: 'Marcher dans la lumière',
      orateur: 'Pasteur Esther Boni',
      date: DateTime(2024, 4, 5),
      lienYoutube: 'https://youtube.com/watch?v=example4',
      notes: '''# Marcher dans la lumière

## Texte principal
**1 Jean 1:5-7** : "La nouvelle que nous avons apprise de lui, et que nous vous annonçons, c'est que Dieu est lumière..."

## Points à retenir

### 1. Dieu est lumière
- Pureté absolue
- Vérité parfaite
- Sainteté complète

### 2. Marcher dans la lumière
- Vivre selon la vérité
- Rejeter les ténèbres du péché
- Transparence devant Dieu

### 3. Les bénédictions
- Communion avec Dieu
- Communion fraternelle
- Purification continue

## Défis personnels
- Examiner notre marche
- Confesser nos péchés
- Rechercher la sainteté

## Invitation
Venez à la lumière, elle vous affranchira.''',
      tags: ['lumière', 'sainteté', 'vérité'],
      duree: 35,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    
    Sermon(
      id: '',
      titre: 'Le fruit de l\'Esprit',
      orateur: 'Pasteur André N\'Guessan',
      date: DateTime(2024, 4, 12),
      lienYoutube: 'https://youtube.com/watch?v=example5',
      notes: '''# Le fruit de l'Esprit

## Texte de référence
**Galates 5:22-23** : "Mais le fruit de l'Esprit, c'est l'amour, la joie, la paix..."

## Les neuf aspects du fruit

### 1. L'amour (Agapé)
- Amour inconditionnel
- Source : Dieu lui-même
- Expression pratique

### 2. La joie
- Indépendante des circonstances
- Joie du salut
- Joie de la communion

### 3. La paix
- Paix avec Dieu
- Paix intérieure
- Paix avec autrui

### 4. La patience
- Endurance dans l'épreuve
- Longanimité envers les autres
- Persévérance dans la foi

### 5. La bonté
- Bienveillance active
- Générosité du cœur
- Actes de grâce

### 6. La bénignité
- Douceur de caractère
- Gentillesse manifestée
- Compassion en action

### 7. La fidélité
- Fiabilité constante
- Loyauté envers Dieu
- Engagement durable

### 8. La douceur
- Humilité véritable
- Force maîtrisée
- Sagesse pratique

### 9. La tempérance
- Maîtrise de soi
- Discipline personnelle
- Équilibre de vie

## Application
Lequel de ces fruits avez-vous besoin de cultiver davantage ?''',
      tags: ['esprit', 'fruit', 'caractère'],
      duree: 50,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  print('📡 Ajout des sermons d\'exemple...');
  
  for (int i = 0; i < sampleSermons.length; i++) {
    try {
      await SermonService.addSermon(sampleSermons[i]);
      print('✅ Sermon ${i + 1}/5 ajouté : "${sampleSermons[i].titre}"');
    } catch (e) {
      print('❌ Erreur lors de l\'ajout du sermon "${sampleSermons[i].titre}" : $e');
    }
  }
  
  print('\n🎉 Ajout terminé ! Vous pouvez maintenant tester l\'onglet Sermons.');
  exit(0);
}
