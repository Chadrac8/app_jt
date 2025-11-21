import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sermon.dart';
import '../services/sermon_service.dart';

class SermonSampleData {
  static final List<Sermon> _sampleSermons = [
    Sermon(
      id: '',
      titre: 'L\'amour de Dieu pour l\'humanité',
      orateur: 'Pasteur Jean Dupont',
      date: DateTime(2024, 7, 14),
      lienYoutube: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      description: 'Une prédication puissante sur l\'amour inconditionnel de Dieu pour chacun d\'entre nous.',
      duree: 45,
      tags: ['amour', 'Dieu', 'humanité', 'grâce'],
      notes: '''# L'amour de Dieu pour l'humanité

## Introduction
L'amour de Dieu dépasse notre entendement et notre compréhension humaine.

## Points principaux

### 1. Un amour inconditionnel
- Dieu nous aime malgré nos fautes
- Son amour ne dépend pas de nos actions
- Il nous aime tels que nous sommes

### 2. Un amour sacrificiel
"Car Dieu a tant aimé le monde qu'il a donné son Fils unique, afin que quiconque croit en lui ne périsse point, mais qu'il ait la vie éternelle." - Jean 3:16

### 3. Un amour transformateur
- L'amour de Dieu change nos cœurs
- Il nous donne une nouvelle perspective
- Il nous pousse à aimer les autres

## Conclusion
Acceptons cet amour et laissons-le transformer nos vies.

## Questions pour la réflexion
- Comment puis-je recevoir l'amour de Dieu aujourd'hui ?
- De quelle manière puis-je partager cet amour avec les autres ?''',
    ),
    Sermon(
      id: '',
      titre: 'La foi qui déplace les montagnes',
      orateur: 'Pasteur Marie Martin',
      date: DateTime(2024, 7, 7),
      lienYoutube: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      description: 'Découvrez comment développer une foi qui peut surmonter tous les obstacles.',
      duree: 38,
      tags: ['foi', 'miracles', 'obstacles', 'confiance'],
      notes: '''# La foi qui déplace les montagnes

## Verset clé
"Si vous aviez de la foi comme un grain de sénevé, vous diriez à cette montagne: Transporte-toi d'ici là, et elle se transporterait; rien ne vous serait impossible." - Matthieu 17:20

## La nature de la foi

### 1. La foi n'est pas une émotion
- Elle va au-delà de ce que nous ressentons
- Elle est basée sur la vérité de la Parole de Dieu
- Elle persiste même dans les moments difficiles

### 2. La foi grandit par étapes
- Commencer petit (grain de sénevé)
- Exercer sa foi régulièrement
- S'appuyer sur les expériences passées

## Comment développer sa foi

- Méditer sur la Parole de Dieu
- Prier régulièrement
- S'entourer de croyants matures
- Témoigner des œuvres de Dieu

## Applications pratiques
Identifiez les "montagnes" dans votre vie et appliquez les principes de la foi.''',
    ),
    Sermon(
      id: '',
      titre: 'La paix dans la tempête',
      orateur: 'Pasteur Paul Leroy',
      date: DateTime(2024, 6, 30),
      description: 'Comment trouver la paix de Dieu au milieu des épreuves de la vie.',
      duree: 42,
      tags: ['paix', 'épreuves', 'confiance', 'tempête'],
      notes: '''# La paix dans la tempête

## Introduction
Les tempêtes de la vie sont inévitables, mais la paix de Dieu est disponible.

## Jésus calme la tempête (Marc 4:35-41)

### Les leçons de ce récit
- Jésus était avec eux dans la barque
- Il dormait paisiblement malgré la tempête
- Sa présence change tout

## Sources de nos tempêtes
- Circonstances extérieures
- Inquiétudes personnelles
- Défis relationnels
- Problèmes de santé

## La paix de Dieu
"Et la paix de Dieu, qui surpasse toute intelligence, gardera vos cœurs et vos pensées en Jésus-Christ." - Philippiens 4:7

### Caractéristiques de cette paix
- Elle surpasse notre compréhension
- Elle garde nos cœurs
- Elle est disponible en toutes circonstances

## Comment obtenir cette paix
- Reconnaître la souveraineté de Dieu
- Lui faire confiance malgré les circonstances
- Se rappeler de ses promesses fidèles''',
    ),
    Sermon(
      id: '',
      titre: 'Le service selon le cœur de Dieu',
      orateur: 'Pasteur Jean Dupont',
      date: DateTime(2024, 6, 23),
      lienYoutube: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      description: 'Comprendre ce que signifie servir Dieu et les autres avec un cœur sincère.',
      duree: 40,
      tags: ['service', 'humilité', 'amour', 'don'],
      notes: '''# Le service selon le cœur de Dieu

## L'exemple de Jésus
"Car le Fils de l'homme est venu, non pour être servi, mais pour servir et donner sa vie comme la rançon de plusieurs." - Marc 10:45

## Caractéristiques du vrai service

### 1. L'humilité
- Servir sans chercher la reconnaissance
- Accepter les tâches simples
- Mettre les autres avant soi

### 2. L'amour comme motivation
- Servir par amour pour Dieu
- Aimer ceux que nous servons
- Le service sans amour est vain

### 3. La fidélité
- Servir avec constance
- Être fiable dans les petites choses
- Persévérer même dans les difficultés

## Domaines de service
- Dans l'église locale
- Dans notre famille
- Dans notre communauté
- Dans notre travail

## Récompenses du service
- La joie de ressembler à Jésus
- L'impact dans la vie des autres
- La croissance spirituelle personnelle''',
    ),
    Sermon(
      id: '',
      titre: 'L\'espérance chrétienne',
      orateur: 'Pasteur Marie Martin',
      date: DateTime(2024, 6, 16),
      description: 'L\'espérance que nous avons en Christ nous donne force et direction.',
      duree: 35,
      tags: ['espérance', 'avenir', 'éternité', 'promesses'],
    ),
  ];

  static Future<void> addSampleSermons() async {
    try {
      print('Ajout des sermons d\'exemple...');
      
      for (final sermon in _sampleSermons) {
        final id = await SermonService.addSermon(sermon);
        if (id != null) {
          print('Sermon "${sermon.titre}" ajouté avec l\'ID: $id');
        } else {
          print('Erreur lors de l\'ajout du sermon "${sermon.titre}"');
        }
      }
      
      print('Tous les sermons d\'exemple ont été ajoutés !');
    } catch (e) {
      print('Erreur lors de l\'ajout des sermons d\'exemple: $e');
    }
  }

  static Future<void> clearAllSermons() async {
    try {
      print('Suppression de tous les sermons...');
      
      final snapshot = await FirebaseFirestore.instance.collection('sermons').get();
      
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
        print('Sermon supprimé: ${doc.id}');
      }
      
      print('Tous les sermons ont été supprimés !');
    } catch (e) {
      print('Erreur lors de la suppression des sermons: $e');
    }
  }
}
