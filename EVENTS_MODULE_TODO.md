# Fonctionnalités Non Implémentées - Module Événements

## 📋 Vue d'ensemble

Ce document recense toutes les fonctionnalités du module Événements qui sont marquées comme "TODO" ou "à implémenter" dans le code.

---

## 🔴 Priorité Haute

### 1. **Authentification Utilisateur dans les Formulaires**
**Fichier**: `lib/pages/event_form_page.dart:296`

**État**: TODO marqué
```dart
lastModifiedBy: 'current_user_id', // TODO: Get from auth
```

**Impact**: Les modifications d'événements ne sont pas correctement attribuées à l'utilisateur actuel.

**Solution suggérée**:
```dart
import '../services/auth_service.dart';

// Dans la méthode _submitForm()
lastModifiedBy: AuthService.currentUser?.uid ?? 'unknown',
```

---

### 2. **Export de Fichiers pour les Inscriptions**
**Fichier**: `lib/widgets/event_registrations_list.dart:152`

**État**: TODO - Export fictif uniquement
```dart
// TODO: Implement actual file export
```

**Contexte**: Actuellement, l'export affiche juste un message de succès mais ne génère pas de fichier CSV/Excel.

**Impact**: Les administrateurs ne peuvent pas exporter les listes d'inscriptions.

**Solution suggérée**:
```dart
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> _exportRegistrations() async {
  try {
    final data = await EventsFirebaseService.exportEventRegistrations(widget.event.id);
    
    // Convertir en CSV
    List<List<dynamic>> rows = [
      ['Nom complet', 'Email', 'Téléphone', 'Statut', 'Date d\'inscription', 'Présent']
    ];
    
    for (final registration in data) {
      rows.add([
        registration['fullName'],
        registration['email'],
        registration['phone'] ?? '',
        registration['status'],
        registration['registrationDate'],
        registration['isPresent'] ? 'Oui' : 'Non',
      ]);
    }
    
    String csv = const ListToCsvConverter().convert(rows);
    
    // Sauvegarder et partager
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/inscriptions_${widget.event.id}_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csv);
    
    await Share.shareXFiles([XFile(path)], text: 'Inscriptions - ${widget.event.title}');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${data.length} inscription(s) exportée(s)'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  } catch (e) {
    // Gestion erreur
  }
}
```

**Dépendances requises**:
- `csv: ^6.0.0`
- `path_provider: ^2.1.0`
- `share_plus: ^7.0.0` (déjà présent)

---

### 3. **Inscription Manuelle à un Événement**
**Fichier**: `lib/widgets/event_registrations_list.dart:52`

**État**: TODO - Fonction non implémentée
```dart
Future<void> _addManualRegistration() async {
  // TODO: Implement manual registration dialog
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Fonctionnalité en cours de développement'),
      backgroundColor: AppTheme.warningColor,
    ),
  );
}
```

**Impact**: Les administrateurs ne peuvent pas inscrire manuellement quelqu'un à un événement.

**Solution suggérée**: Créer un dialogue avec formulaire :
```dart
Future<void> _addManualRegistration() async {
  final result = await showDialog<EventRegistrationModel>(
    context: context,
    builder: (context) => ManualRegistrationDialog(event: widget.event),
  );
  
  if (result != null) {
    try {
      await EventsFirebaseService.createRegistration(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inscription de ${result.fullName} ajoutée'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      // Gestion erreur
    }
  }
}
```

---

## 🟠 Priorité Moyenne

### 4. **Analyse des Réponses de Formulaires**
**Fichier**: `lib/services/events_firebase_service.dart:459`

**État**: TODO - Données vides
```dart
formResponsesSummary: {}, // TODO: Implement form responses analysis
```

**Impact**: Les statistiques d'événements ne montrent pas d'analyse des réponses aux formulaires.

**Solution suggérée**:
```dart
// Dans getEventStatistics()
Map<String, dynamic> formResponsesSummary = {};

if (registrationModels.isNotEmpty) {
  // Analyser chaque champ du formulaire
  final allResponses = registrationModels.map((r) => r.formResponses).toList();
  
  if (allResponses.isNotEmpty) {
    // Extraire tous les champs uniques
    Set<String> allFields = {};
    for (final responses in allResponses) {
      allFields.addAll(responses.keys);
    }
    
    // Pour chaque champ, compter les réponses
    for (final field in allFields) {
      Map<String, int> fieldSummary = {};
      for (final responses in allResponses) {
        final value = responses[field]?.toString() ?? 'Non renseigné';
        fieldSummary[value] = (fieldSummary[value] ?? 0) + 1;
      }
      formResponsesSummary[field] = fieldSummary;
    }
  }
}

// Utiliser dans le modèle
formResponsesSummary: formResponsesSummary,
```

---

### 5. **Édition d'Événement depuis EventCard**
**Fichier**: `lib/widgets/event_card.dart:449`

**État**: TODO - Navigation non implémentée
```dart
case 'edit':
  // TODO: Navigate to edit page
  break;
```

**Impact**: Impossible de modifier un événement depuis la carte.

**Solution suggérée**:
```dart
case 'edit':
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EventFormPage(event: widget.event),
    ),
  );
  if (result == true && widget.onUpdate != null) {
    widget.onUpdate!();
  }
  break;
```

---

### 6. **Suppression d'Événement depuis EventCard**
**Fichier**: `lib/widgets/event_card.dart:576`

**État**: TODO - Confirmation non implémentée
```dart
onTap: () {
  Navigator.pop(context);
  // TODO: Implement delete confirmation
},
```

**Solution suggérée**:
```dart
onTap: () async {
  Navigator.pop(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Supprimer l\'événement'),
      content: Text('Êtes-vous sûr de vouloir supprimer "${widget.event.title}" ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
          child: const Text('Supprimer'),
        ),
      ],
    ),
  );
  
  if (confirmed == true) {
    try {
      await EventsFirebaseService.deleteEvent(widget.event.id);
      if (widget.onDelete != null) widget.onDelete!();
    } catch (e) {
      // Gestion erreur
    }
  }
},
```

---

### 7. **Export d'Événements**
**Fichier**: `lib/pages/events_home_page.dart:239`

**État**: TODO - Fonction non implémentée
```dart
Future<void> _exportEvents() async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Export des événements en cours...'),
      backgroundColor: AppTheme.warningColor,
    ),
  );
  // TODO: Implement export functionality
}
```

**Solution suggérée**: Similaire à l'export des inscriptions (CSV/Excel).

---

## 🟡 Priorité Basse

### 8. **Restauration d'Occurrence Annulée**
**Fichier**: `lib/widgets/recurring_event_manager_widget.dart:707`

**État**: TODO - Non implémenté
```dart
void _restoreInstance(EventInstanceModel instance) {
  // TODO: Implémenter la restauration d'instance
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Fonctionnalité en cours de développement')),
  );
}
```

**Impact**: Les occurrences annulées ne peuvent pas être restaurées.

**Solution suggérée**:
```dart
void _restoreInstance(EventInstanceModel instance) async {
  try {
    await EventRecurrenceService.removeException(
      instance.recurrenceId!,
      instance.originalDate,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Occurrence restaurée')),
    );
    _loadData();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $e')),
    );
  }
}
```

**Note**: Il faut ajouter la méthode `removeException` dans `EventRecurrenceService`.

---

### 9. **Détails d'Occurrence depuis Menu**
**Fichier**: `lib/widgets/recurring_event_manager_widget.dart:381`

**État**: TODO commenté
```dart
// TODO: Details logic
```

**Impact**: Mineur - Les détails sont déjà affichés via `_showInstanceDetails()`.

---

### 10. **Voir Détails depuis MemberEventsPage**
**Fichier**: `lib/pages/member_events_page.dart:614`

**État**: TODO - Navigation non implémentée
```dart
onPressed: () {
  // TODO: Voir détails de l'événement
},
```

**Solution suggérée**:
```dart
onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MemberEventDetailPage(event: event),
    ),
  );
},
```

---

## 📧 Notifications et Emails

### État Actuel
Les fonctionnalités de notifications existent dans **Firebase Functions** (`functions/index.js`) mais ne sont pas encore intégrées dans le module Événements :

- ✅ Fonction `sendRichNotification` implémentée
- ✅ Infrastructure email (nodemailer) configurée
- ❌ **Non intégré** : Envoi de confirmation d'inscription par email
- ❌ **Non intégré** : Envoi de rappels avant événement
- ❌ **Non intégré** : Notifications lors de changement de statut d'inscription

### Solution suggérée
Créer un service d'intégration :

```dart
// lib/services/event_notification_service.dart

class EventNotificationService {
  static Future<void> sendRegistrationConfirmation(EventRegistrationModel registration, EventModel event) async {
    // Appeler la Cloud Function
    final callable = FirebaseFunctions.instance.httpsCallable('sendEventNotification');
    await callable.call({
      'type': 'registration_confirmation',
      'eventId': event.id,
      'registrationId': registration.id,
      'email': registration.email,
      'eventTitle': event.title,
      'eventDate': event.startDate.toIso8601String(),
    });
  }
  
  static Future<void> sendEventReminder(EventModel event) async {
    // Envoyer rappel 24h avant
    final callable = FirebaseFunctions.instance.httpsCallable('sendEventReminder');
    await callable.call({
      'eventId': event.id,
    });
  }
}
```

---

## 🎯 Résumé par Priorité

### 🔴 Haute (À implémenter rapidement)
1. Authentification utilisateur dans formulaires
2. Export fichiers CSV/Excel inscriptions
3. Inscription manuelle administrative

### 🟠 Moyenne (Améliore l'UX)
4. Analyse réponses formulaires
5. Édition événement depuis carte
6. Suppression événement depuis carte
7. Export événements

### 🟡 Basse (Nice-to-have)
8. Restauration occurrences annulées
9. Navigation détails événements
10. Intégration complète notifications/emails

---

## 📦 Dépendances Manquantes

Pour implémenter toutes ces fonctionnalités, ajouter à `pubspec.yaml` :

```yaml
dependencies:
  csv: ^6.0.0           # Pour export CSV
  path_provider: ^2.1.0  # Pour chemins fichiers
  # share_plus déjà présent
```

---

## 🔧 Plan d'Implémentation Suggéré

### Phase 1 (Priorité Haute)
1. Fixer l'authentification utilisateur (15 min)
2. Implémenter export CSV inscriptions (1-2h)
3. Créer dialogue inscription manuelle (2-3h)

### Phase 2 (Priorité Moyenne)
4. Ajouter analyse formulaires (1-2h)
5. Compléter actions EventCard (1h)
6. Implémenter export événements (1h)

### Phase 3 (Priorité Basse)
7. Améliorer gestion récurrence (2h)
8. Intégrer système notifications complet (4-6h)

---

## ✅ Recommandations

1. **Priorité immédiate**: Fixer l'authentification utilisateur
2. **Quick wins**: Actions EventCard (édition/suppression)
3. **Valeur business**: Export CSV inscriptions
4. **Long terme**: Système notifications complet avec emails

