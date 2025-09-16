# Guide du Scheduler du Pain Quotidien

## Vue d'ensemble

Le système de planification automatique du pain quotidien met à jour automatiquement le contenu depuis branham.org chaque jour à 6h00 du matin.

## Fonctionnalités implémentées

### 1. Mise à jour automatique quotidienne
- **Heure de déclenchement** : 6h00 AM tous les jours
- **Source** : branham.org via BranhamScrapingService
- **Stockage** : SharedPreferences et Firebase
- **Persistance** : Le scheduler continue même après redémarrage de l'app

### 2. Double mécanisme de planification
- **Timer principal** : Calcule le temps jusqu'à 6h00 AM
- **Vérificateur de sauvegarde** : Timer.periodic toutes les minutes pour s'assurer qu'aucune mise à jour n'est manquée

### 3. Interface de debug
- Widget de debug disponible pour monitorer le scheduler
- Possibilité de forcer une mise à jour manuelle
- Affichage du statut en temps réel

## Fichiers modifiés/créés

### Services
- `/lib/modules/pain_quotidien/services/daily_bread_scheduler.dart` - Service principal
- `/lib/main.dart` - Initialisation du scheduler

### Debug et tests
- `/lib/modules/pain_quotidien/widgets/daily_bread_scheduler_debug_widget.dart` - Interface debug
- `/test_daily_bread_scheduler.dart` - Script de test

## Utilisation

### Démarrage automatique
Le scheduler se lance automatiquement au démarrage de l'application via `main.dart`.

### Monitoring
Pour suivre l'activité du scheduler :

```dart
// Importer le widget de debug
import 'package:jubile_tabernacle_france/modules/pain_quotidien/widgets/daily_bread_scheduler_debug_widget.dart';

// L'ajouter dans votre interface (temporairement pour debug)
DailyBreadSchedulerDebugWidget()
```

### Forcer une mise à jour
```dart
await DailyBreadScheduler.instance.forceUpdate();
```

## Vérifications

### 1. Logs de démarrage
Au lancement de l'app, vous devriez voir :
```
DailyBreadScheduler: Scheduler initialisé avec succès
DailyBreadScheduler: Prochaine mise à jour programmée pour: [DATE_TIME]
```

### 2. Mise à jour quotidienne
À 6h00 AM, vous devriez voir :
```
DailyBreadScheduler: Mise à jour automatique déclenchée
DailyBreadScheduler: Contenu mis à jour avec succès
```

### 3. Vérification de persistance
```dart
// Vérifier si le scheduler est actif
bool isRunning = DailyBreadScheduler.instance.isSchedulerRunning;
print('Scheduler actif: $isRunning');

// Obtenir la prochaine heure de mise à jour
DateTime? nextUpdate = DailyBreadScheduler.instance.getNextScheduledUpdate();
print('Prochaine mise à jour: $nextUpdate');
```

## Dépannage

### Le scheduler ne démarre pas
1. Vérifier que l'initialisation est appelée dans `main.dart`
2. Vérifier les permissions SharedPreferences
3. Regarder les logs pour les erreurs d'initialisation

### Les mises à jour ne se déclenchent pas
1. Vérifier que l'application reste en arrière-plan
2. Utiliser le widget de debug pour forcer une mise à jour
3. Vérifier la connectivité réseau à 6h00 AM

### Erreurs de scraping
1. Le BranhamScrapingService gère automatiquement les erreurs
2. En cas d'échec, une nouvelle tentative aura lieu le lendemain
3. Utiliser `forceUpdate()` pour tester manuellement

## Configuration avancée

### Changer l'heure de mise à jour
Modifier la constante dans `daily_bread_scheduler.dart` :
```dart
static const int UPDATE_HOUR = 6; // Changer ici l'heure souhaitée
```

### Désactiver temporairement
```dart
DailyBreadScheduler.instance.stopScheduler();
```

### Réactiver
```dart
DailyBreadScheduler.instance.startScheduler();
```

## Notes techniques

### Gestion de la mémoire
- Le scheduler utilise des timers légers
- Nettoyage automatique en cas d'arrêt de l'app
- Redémarrage automatique si nécessaire

### Performance
- Impact minimal sur les performances
- Vérifications efficaces avec cache
- Mise à jour uniquement si nécessaire

### Robustesse
- Gestion des erreurs réseau
- Récupération automatique en cas d'échec
- Logs détaillés pour le debug

## Support

En cas de problème, vérifier :
1. Les logs de l'application
2. L'état du scheduler via le widget de debug
3. La connectivité réseau
4. Les permissions de l'application

Le système est conçu pour être autonome et robuste, nécessitant une intervention manuelle minimale.