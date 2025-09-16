# 📘 Guide d'utilisation - Événements Récurrents

## 🚀 Démarrage rapide

### 1. Accéder à l'interface de test

1. Lancez l'application
2. Allez sur la page **Événements**
3. Cliquez sur l'icône 🔄 (**Répéter**) dans la barre de navigation
4. Vous accédez à la page de test des événements récurrents

### 2. Créer un événement récurrent

```dart
// Dans votre code
final recurrence = EventRecurrence.weekly(
  daysOfWeek: [WeekDay.sunday],
  endType: RecurrenceEndType.afterOccurrences,
  occurrences: 52, // 1 an de cultes
);

final event = EventModel(
  id: 'culte_dominical',
  title: 'Culte dominical',
  description: 'Service de culte hebdomadaire',
  startDate: DateTime(2025, 9, 21, 10, 0), // Prochain dimanche
  endDate: DateTime(2025, 9, 21, 12, 0),
  location: 'Sanctuaire principal',
  type: 'culte',
  status: 'publie',
  createdBy: 'admin',
  isRecurring: true, // ⚠️ Important !
  isRegistrationEnabled: true,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  recurrence: recurrence, // ⚠️ Important !
);
```

## 📋 Types de récurrence disponibles

### 📅 Quotidienne
```dart
// Tous les jours
EventRecurrence.daily()

// Tous les 3 jours, pendant 30 occurrences
EventRecurrence.daily(
  interval: 3,
  endType: RecurrenceEndType.afterOccurrences,
  occurrences: 30,
)

// Tous les jours de semaine, jusqu'au 31 décembre
EventRecurrence.daily(
  interval: 1,
  endType: RecurrenceEndType.onDate,
  endDate: DateTime(2025, 12, 31),
)
```

### 📅 Hebdomadaire
```dart
// Tous les lundis
EventRecurrence.weekly(
  daysOfWeek: [WeekDay.monday],
)

// Mardi et jeudi, toutes les 2 semaines
EventRecurrence.weekly(
  daysOfWeek: [WeekDay.tuesday, WeekDay.thursday],
  interval: 2,
  endType: RecurrenceEndType.afterOccurrences,
  occurrences: 20,
)

// Tous les jours de semaine
EventRecurrence.weekly(
  daysOfWeek: [
    WeekDay.monday,
    WeekDay.tuesday,
    WeekDay.wednesday,
    WeekDay.thursday,
    WeekDay.friday,
  ],
)
```

### 📅 Mensuelle
```dart
// Le 15 de chaque mois
EventRecurrence.monthly(
  dayOfMonth: 15,
)

// Le premier lundi de chaque mois
EventRecurrence.monthly(
  weekOfMonth: 1, // Première semaine
  daysOfWeek: [WeekDay.monday],
)

// Tous les 3 mois, le 1er du mois
EventRecurrence.monthly(
  dayOfMonth: 1,
  interval: 3,
  endType: RecurrenceEndType.afterOccurrences,
  occurrences: 4, // 1 an
)
```

### 📅 Annuelle
```dart
// Chaque 15 juin
EventRecurrence.yearly(
  monthOfYear: 6,
  dayOfMonth: 15,
)

// Chaque 25 décembre, pendant 10 ans
EventRecurrence.yearly(
  monthOfYear: 12,
  dayOfMonth: 25,
  endType: RecurrenceEndType.afterOccurrences,
  occurrences: 10,
)
```

## 🎯 Utilisation des services

### Obtenir les événements d'une période
```dart
// Service principal pour obtenir les événements
final eventsData = await EventRecurrenceManagerService.getEventsForPeriod(
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 30)),
  searchQuery: 'culte', // Optionnel
  typeFilters: ['culte', 'priere'], // Optionnel
);

// Convertir en EventModel
final events = eventsData.map((data) => 
  EventModel.fromMap(data['event'])
).toList();
```

### Utiliser le service de calendrier
```dart
final calendarService = RecurringCalendarService();

// Événements d'une journée
final dayEvents = await calendarService.getEventsForDay(DateTime.now());

// Événements d'un mois
final monthEvents = await calendarService.getEventsForMonth(DateTime.now());

// Statistiques
final stats = await calendarService.getRecurrenceStatistics(
  DateTime.now(),
  DateTime.now().add(Duration(days: 90)),
);

print('Total: ${stats['totalEvents']}');
print('Récurrents: ${stats['recurringInstances']}');
print('Simples: ${stats['simpleEvents']}');
```

## 🎨 Widgets d'interface

### Formulaire de création
```dart
RecurringEventFormWidget(
  onEventCreated: (event) {
    print('Événement créé: ${event.title}');
    // Sauvegarder en base ou traiter l'événement
  },
)
```

### Affichage des événements
```dart
RecurringEventsList(
  events: myEvents,
  onEventTap: (event, data) {
    // Naviguer vers les détails
  },
  onEventLongPress: (event, data) {
    // Menu contextuel
  },
  isSelectionMode: false,
  selectedEvents: [],
  onSelectionChanged: (event, selected) {
    // Gérer la sélection
  },
)
```

### Carte d'événement
```dart
RecurringEventCard(
  event: myEvent,
  instanceData: {
    'isRecurringInstance': true,
    'recurrenceDescription': 'Tous les dimanches',
    'instanceDate': DateTime.now(),
  },
  onTap: () => print('Événement touché'),
)
```

## 📊 Page de test complète

La page `RecurringEventsTestPage` offre une interface complète pour :

### Onglet "Créer"
- Formulaire de création d'événements récurrents
- Bouton pour générer des événements de test
- Validation en temps réel

### Onglet "Liste"
- Affichage de tous les événements expandus
- Compteur d'événements
- Actualisation manuelle

### Onglet "Calendrier"
- Sélection de date
- Événements du jour sélectionné
- Navigation par date

### Onglet "Stats"
- Statistiques détaillées
- Résultats des tests automatiques
- Indicateurs de réussite

## 🛠️ Bonnes pratiques

### ✅ À faire
- Toujours définir `isRecurring = true` pour les événements récurrents
- Fournir un objet `EventRecurrence` valide
- Utiliser les factory methods (`daily()`, `weekly()`, etc.)
- Définir une fin de récurrence appropriée
- Tester avec la page de test avant production

### ❌ À éviter
- Ne pas oublier `isRecurring = true`
- Ne pas créer de récurrence sans fin sur des événements fréquents
- Ne pas ignorer les validations du formulaire
- Ne pas charger trop d'occurrences d'un coup (limite à 3-6 mois)

## 🔧 Configuration avancée

### Exceptions de dates
```dart
final recurrence = EventRecurrence.weekly(
  daysOfWeek: [WeekDay.sunday],
  exceptions: [
    DateTime(2025, 12, 25), // Pas de culte le 25 décembre
    DateTime(2026, 1, 1),   // Pas de culte le 1er janvier
  ],
);
```

### Fin de récurrence flexible
```dart
// Jamais (infini)
endType: RecurrenceEndType.never

// Après 52 occurrences
endType: RecurrenceEndType.afterOccurrences,
occurrences: 52

// Jusqu'au 31 décembre 2025
endType: RecurrenceEndType.onDate,
endDate: DateTime(2025, 12, 31)
```

## 🚨 Dépannage

### Aucun événement généré
- Vérifiez que `isRecurring = true`
- Vérifiez la période de recherche
- Vérifiez la configuration de récurrence

### Trop d'événements générés
- Limitez la période de recherche
- Vérifiez l'intervalle de récurrence
- Définissez une fin de récurrence

### Dates incorrectes
- Vérifiez la date de début
- Vérifiez la configuration des jours/mois
- Utilisez la page de test pour valider

## 📞 Support

Pour tester et valider votre implémentation :
1. Utilisez la page de test intégrée
2. Vérifiez les logs de génération
3. Consultez les statistiques
4. Testez avec différentes configurations

---

**Bonne utilisation des événements récurrents ! 🎉**