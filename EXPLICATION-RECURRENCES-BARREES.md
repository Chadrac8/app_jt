# Explication - Récurrences Barrées dans l'Onglet Récurrence

## Pourquoi les récurrences apparaissent barrées ?

Dans l'onglet "Récurrence" des événements récurrents, vous pouvez voir des éléments barrés. Voici les raisons :

### 1. **Récurrences désactivées** (Nouvellement implémenté)
- Les **règles de récurrence** désactivées apparaissent maintenant barrées et en gris
- Elles ont un interrupteur désactivé et le statut "Récurrence désactivée"
- Ces récurrences ne génèrent plus de nouvelles occurrences mais restent visibles pour historique

### 2. **Occurrences individuelles annulées**
- Les **occurrences spécifiques** d'un événement récurrent peuvent être annulées
- Quand une occurrence est annulée, elle apparaît barrée avec le statut "Occurrence annulée"
- Cela permet d'annuler une occurrence particulière (ex: pas de culte le 25 décembre) sans supprimer toute la récurrence

## Interface de l'onglet Récurrence

L'onglet se compose de deux sections principales :

### Section 1: Règles de récurrence
- **Icône verte** = Récurrence active
- **Icône grise** = Récurrence désactivée
- **Texte barré et gris** = Récurrence désactivée
- **Interrupteur** = Permet d'activer/désactiver une récurrence
- **Menu actions** = Modifier, gérer les exceptions, supprimer

### Section 2: Occurrences du mois
- **Calendrier des occurrences** pour le mois sélectionné
- **Texte barré** = Occurrence annulée pour cette date spécifique
- **Statuts possibles** :
  - "Occurrence normale" = Événement prévu normalement
  - "Occurrence modifiée" = Événement modifié pour cette date (horaire, lieu différent)
  - "Occurrence annulée" = Événement annulé pour cette date uniquement

## Actions possibles

### Sur les règles de récurrence :
- **Activer/Désactiver** : Utiliser l'interrupteur pour arrêter/reprendre la génération d'occurrences
- **Modifier** : Changer la fréquence, les jours, les dates de fin
- **Exceptions** : Définir des dates où l'événement ne doit pas avoir lieu
- **Supprimer** : Supprimer complètement la règle de récurrence

### Sur les occurrences individuelles :
- **Modifier** : Changer les détails pour cette occurrence spécifique
- **Annuler** : Annuler cette occurrence sans affecter les autres
- **Reprogrammer** : Déplacer cette occurrence à une autre date

## Exemple concret

**Situation** : Culte du dimanche tous les dimanches à 10h

1. **Règle de récurrence** : "Toutes les semaines le dimanche"
   - Status : Active (icône verte)
   - Texte : Normal (pas barré)

2. **Occurrence du 25 décembre** : Pas de culte (Noël)
   - Status : Annulée
   - Texte : Barré avec "Occurrence annulée"

3. **Occurrence du 1er janvier** : Culte à 15h (horaire spécial)
   - Status : Modifiée
   - Texte : Normal avec "Occurrence modifiée"

## Résolution si problème

Si toutes vos récurrences apparaissent barrées de manière incorrecte :

1. **Vérifier le statut** : Regarder si l'interrupteur est activé
2. **Réactiver si nécessaire** : Cliquer sur l'interrupteur pour réactiver
3. **Vérifier les dates de fin** : S'assurer que la récurrence n'est pas expirée
4. **Actualiser** : Utiliser le bouton actualiser en haut à droite

## Amélioration apportée

J'ai amélioré l'interface pour mieux distinguer :
- **Récurrences actives** : Texte normal, icône verte
- **Récurrences désactivées** : Texte barré et gris, icône grise, message explicatif
- **Occurrences normales** : Texte normal
- **Occurrences annulées** : Texte barré avec message "Occurrence annulée"

Cette distinction visuelle aide à mieux comprendre l'état de chaque élément dans le système de récurrence.