# Services-Events Integration (Planning Center Online Style)

## Overview
This document describes the integration between Services and Events modules, following the Planning Center Online model where services are considered as events in the church calendar.

## Architecture

### Integration Service
**File**: `lib/services/service_event_integration_service.dart`

The `ServiceEventIntegrationService` provides automatic synchronization between services and events:

- **createServiceWithEvent**: Creates a service and automatically creates a linked event
- **updateServiceWithEvent**: Updates both the service and its linked event
- **deleteServiceWithEvent**: Deletes both the service and its linked event (with cascade deletion)

### Data Model Changes
**File**: `lib/models/service_model.dart`

Added `linkedEventId` field to `ServiceModel`:
```dart
final String? linkedEventId; // ID de l'événement lié (intégration Planning Center style)
```

## Features

### 1. Automatic Event Creation
When a service is created, an event is automatically generated with:
- Same name, description, location, and date/time
- Duration converted to end time
- Event category set to 'service'
- Special flag `isServiceEvent: true`
- Linked back to the service via `linkedServiceId`

### 2. Recurrence Support
Services with `isRecurring: true` get recurrence patterns:
- **culte** (Worship): Weekly on Sundays at 10:00
- **repetition** (Rehearsal): Weekly on Thursdays at 19:00
- **Other types**: Weekly on the same day/time as the service

The event recurrence is automatically created and managed through `EventRecurrenceService`.

### 3. Update Synchronization
When a service is updated:
- The linked event is automatically updated with the new information
- Recurrence patterns are regenerated if needed
- All changes are kept in sync

### 4. Cascade Deletion
When a service is deleted:
- The linked event is deleted
- All event recurrence patterns are removed
- All generated event instances are cleaned up

## UI Integration

### Modified Files
1. **service_form_page.dart**
   - Create: Calls `ServiceEventIntegrationService.createServiceWithEvent`
   - Update: Calls `ServiceEventIntegrationService.updateServiceWithEvent`

2. **service_detail_page.dart**
   - Delete: Calls `ServiceEventIntegrationService.deleteServiceWithEvent`

3. **services_home_page.dart**
   - Bulk delete: Uses `ServiceEventIntegrationService.deleteServiceWithEvent` for each service

## Database Structure

### Firestore Collections
- **services**: Contains service data with `linkedEventId` field
- **events**: Contains event data with `linkedServiceId` and `isServiceEvent` fields
- **event_recurrences**: Contains recurrence patterns for recurring services
- **event_instances**: Contains generated occurrences for recurring service events

## Benefits

1. **Unified Calendar**: All services appear in the church calendar alongside other events
2. **Recurrence Management**: Leverage existing event recurrence system for services
3. **Event Features**: Services benefit from event features like:
   - Calendar visualization
   - Recurrence patterns
   - Occurrence editing/cancellation
   - Future: Event registrations
   - Future: Event notifications

4. **Consistency**: Single source of truth for church activities
5. **Planning Center Compatibility**: Familiar workflow for users coming from Planning Center Online

## Usage Example

```dart
// Create a new service with automatic event creation
final service = ServiceModel(
  id: '',
  name: 'Culte du Dimanche',
  type: 'culte',
  dateTime: DateTime.now(),
  location: 'Église Principale',
  durationMinutes: 90,
  isRecurring: true,
  // ... other fields
);

await ServiceEventIntegrationService.createServiceWithEvent(service);

// The service is created AND a linked event is automatically created
// If isRecurring: true, a weekly recurrence pattern is also created
```

## Testing Checklist

- [ ] Create a new one-time service → Verify event is created
- [ ] Create a recurring service → Verify event and recurrence are created
- [ ] Update a service → Verify linked event is updated
- [ ] Delete a service → Verify event and recurrences are deleted
- [ ] View service in church calendar
- [ ] Edit individual occurrences of recurring service events
- [ ] Cancel specific occurrences

## Future Enhancements

1. **Event Registration Integration**: Allow members to register for service events
2. **Notification System**: Send reminders for upcoming services through event notifications
3. **Calendar Export**: iCal/Google Calendar integration for service events
4. **Ministry Assignment**: Link team assignments to service events
5. **Service Analytics**: Track attendance and engagement through event data

## Notes

- Services of type `culte` default to Sunday 10:00 recurrence
- Services of type `repetition` default to Thursday 19:00 recurrence
- Other service types use the service's actual day/time for recurrence
- All recurrence patterns generate instances for the next 6 months
- Individual occurrences can be modified or cancelled without affecting the pattern
