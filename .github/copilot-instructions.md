# Copilot Instructions for DreamFlow - Church Management System

## 🎯 Project Overview

**DreamFlow** is a comprehensive Flutter/Firebase church management system designed for "Jubilé Tabernacle". This is a sophisticated, modular application featuring advanced notification infrastructure, custom page builder, and extensive admin interfaces.

### Core Technologies
- **Frontend**: Flutter 3.8.0+ (Dart)
- **Backend**: Firebase (Firestore, Auth, Cloud Functions v2, Cloud Messaging)
- **Runtime**: Node.js 20 for Cloud Functions
- **Architecture**: Service-oriented with modular design

## 🏗️ Architecture Patterns

### 1. Modular Architecture
The app follows a **module-based architecture** with clear separation of concerns:

```
lib/
├── core/                    # Core system (routing, module management)
├── modules/                 # Feature modules (services, bible, songs, etc.)
├── services/               # Shared services (Firebase, notifications)
├── models/                 # Data models
├── pages/                  # UI pages (admin and member views)
├── widgets/               # Reusable UI components
├── auth/                  # Authentication logic
└── shared/                # Shared utilities and widgets
```

### 2. Service-Oriented Design
All business logic is encapsulated in services:
- `*FirebaseService` classes handle Firestore operations
- `PushNotificationService` manages FCM integration
- `AppConfigFirebaseService` handles dynamic configuration
- Services follow consistent patterns: CRUD operations, streams, error handling

### 3. Navigation Architecture
**Key Files**: `lib/core/app_router.dart`, `lib/shared/utils/navigation_service.dart`
- **AppRouter**: Central route generation with module integration
- **NavigationService**: Global navigation utilities with persistent context
- **ModuleManager**: Dynamic route registration for modules
- **Dual Navigation**: Admin and Member interfaces with different navigation patterns

## 🔧 Critical Workflows

### 1. Notification System (Advanced)
**Core Files**: 
- `lib/services/push_notification_service.dart`
- `functions/` (10+ Cloud Functions)
- `lib/pages/admin/advanced_notification_admin_page.dart`

**Flow**:
1. **Admin Interface**: 4-tab system (Send, Templates, Segments, Analytics)
2. **Rich Notifications**: Support for images, action buttons, custom data
3. **User Segmentation**: Dynamic targeting by roles, groups, custom criteria
4. **Templates**: Reusable notification templates with variables
5. **Analytics**: Track delivery, opens, interactions
6. **Cloud Functions**: Server-side processing with Node.js 20

### 2. Custom Page Builder
**Core Files**:
- `lib/pages/page_builder_page.dart`
- `lib/widgets/page_components/component_*.dart`
- `lib/models/page_model.dart`

**Components**:
- Drag-and-drop interface for custom pages
- 15+ component types (text, image, video, audio, forms, grids)
- Action system for component interactions
- Dynamic routing for custom pages
- Template system for reusable layouts

### 3. Dynamic Configuration System
**Core Files**:
- `lib/services/app_config_firebase_service.dart`
- `lib/models/app_config_model.dart`
- `lib/widgets/bottom_navigation_wrapper.dart`

**Features**:
- Dynamic module enabling/disabling
- Custom page integration in navigation
- Role-based feature access
- Real-time configuration updates

## 📱 UI Patterns

### 1. Navigation Wrappers
- **AdminNavigationWrapper**: Fixed primary/secondary page structure
- **BottomNavigationWrapper**: Dynamic tabs based on app configuration
- **Member vs Admin**: Completely different navigation patterns

### 2. Component Architecture
- **ComponentRenderer**: Universal component rendering system
- **ComponentEditor**: In-place component editing
- **ActionSystem**: Standardized component interactions

### 3. Animation Patterns
Most pages use consistent animation patterns:
```dart
late AnimationController _animationController;
late Animation<double> _fadeAnimation;
late Animation<Offset> _slideAnimation;
```

## 🔥 Firebase Integration Patterns

### 1. Service Pattern
All Firebase services follow this pattern:
```dart
class ExampleFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'collection_name';
  
  // Stream-based real-time data
  static Stream<List<Model>> getDataStream() => ...
  
  // CRUD operations
  static Future<String> create(Model data) => ...
  static Future<void> update(String id, Model data) => ...
  static Future<void> delete(String id) => ...
}
```

### 2. Cloud Functions Integration
**Functions Location**: `functions/`
**Key Functions**:
- `sendNotification`: Rich notification sending
- `sendBulkNotifications`: Batch notification processing
- `scheduleNotification`: Scheduled notifications
- `notificationAnalytics`: Track notification metrics

### 3. Real-time Data Patterns
Most data uses Firebase streams:
```dart
StreamBuilder<List<Model>>(
  stream: Service.getDataStream(),
  builder: (context, snapshot) => ...
)
```

## 🎛️ Configuration System

### 1. Module Configuration
**File**: `lib/config/app_modules.dart`
```dart
ModuleConfig(
  id: 'module_id',
  name: 'Display Name',
  description: 'Module description',
  iconName: 'icon_name',
  route: 'route_path',
  category: 'category',
  isPrimaryInBottomNav: bool,
  order: int,
)
```

### 2. Dynamic Pages
Custom pages are automatically integrated into navigation through:
- `AppConfigFirebaseService.syncCustomPages()`
- Real-time configuration updates
- Role-based visibility

## 🧩 Key Integration Points

### 1. Module Registration
**File**: `lib/core/module_manager.dart`
```dart
// Module must implement AppModule interface
class CustomModule extends AppModule {
  @override
  ModuleConfig get config => ...;
  
  @override
  Map<String, WidgetBuilder> get routes => ...;
  
  @override
  Future<void> initialize() async => ...;
}
```

### 2. Component Actions
**File**: `lib/services/component_action_service.dart`
Universal action system for:
- Page navigation
- External URLs
- Form submissions
- Module-specific actions
- Deep links

### 3. Permission System
- Role-based access control
- Group-based permissions
- Module-level restrictions
- Page-level visibility rules

## 📋 Development Conventions

### 1. Naming Patterns
- **Pages**: `*Page` (e.g., `MemberDashboardPage`)
- **Services**: `*FirebaseService` or `*Service`
- **Models**: `*Model` (e.g., `GroupModel`)
- **Widgets**: Descriptive names with `Widget` suffix for reusable components

### 2. File Organization
- **Admin pages**: `lib/pages/admin/`
- **Member pages**: `lib/pages/member_*_page.dart`
- **Shared widgets**: `lib/widgets/`
- **Module-specific**: `lib/modules/module_name/`

### 3. State Management
- **StatefulWidget** for most UI components
- **StreamBuilder** for real-time Firebase data
- **AnimationController** for UI animations
- Global state through services and static methods

### 4. Error Handling
Consistent error handling pattern:
```dart
try {
  // Operation
} catch (e) {
  print('Error context: $e');
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

## 🚀 Deployment & Build

### 1. Environment Configuration
- **Development**: Local Firebase emulators
- **Production**: Live Firebase project
- **Scripts**: `deploy-jubile.sh`, `verify-jubile.sh`

### 2. Build Process
- Flutter build for multiple platforms
- Firebase Functions deployment
- Firestore security rules deployment
- Static hosting for web components

## 🔍 Common Patterns to Follow

### 1. Page Structure
```dart
class ExamplePage extends StatefulWidget {
  @override
  State<ExamplePage> createState() => _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  // State variables
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
```

### 2. Service Integration
```dart
// Always use streams for real-time data
StreamBuilder<List<Model>>(
  stream: Service.getStream(),
  builder: (context, snapshot) {
    if (snapshot.hasError) return ErrorWidget(snapshot.error);
    if (!snapshot.hasData) return LoadingWidget();
    return DataWidget(snapshot.data!);
  },
)
```

### 3. Navigation
```dart
// Use NavigationService for global navigation
NavigationService.navigateTo('/route', arguments: data);

// Use component actions for interactive elements
ComponentActionService.executeAction(context, action);
```

## 🎯 Key Things to Remember

1. **Always consider both Admin and Member interfaces** when adding features
2. **Use the existing service patterns** for Firebase integration
3. **Follow the modular architecture** - don't put everything in one place
4. **Leverage the component system** for reusable UI elements
5. **Use the configuration system** for dynamic feature enabling
6. **Test notification flows end-to-end** (they're complex)
7. **Consider mobile and web responsive design**
8. **Follow the established animation patterns**
9. **Use streams for real-time data everywhere**
10. **Integrate with the permission system** for new features

---

*This is a sophisticated, production-ready application with extensive business logic. Take time to understand the existing patterns before making changes.*
