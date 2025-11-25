# Guide des Statistiques et Analytics
## Module Search - William Branham Sermons

**Date**: 23 novembre 2024  
**Statut**: ✅ Implémentation complète

---

## 📊 Vue d'Ensemble

Le système de statistiques et analytics permet de tracker automatiquement l'utilisation des sermons, offrant des insights précieux sur les habitudes de lecture.

### Fonctionnalités Principales

1. **Temps de lecture par sermon** - Tracking automatique avec sessions
2. **Sermons les plus consultés** - Top N par nombre de vues
3. **Progression de lecture** - Pourcentage et dernière page
4. **Statistiques globales** - Vue d'ensemble toutes périodes
5. **Historique des sessions** - Détail de chaque session de lecture

---

## 🏗️ Architecture

### Composants Créés

```
lib/modules/search/
├── models/
│   └── sermon_analytics.dart          (160 lignes)
├── services/
│   └── sermon_analytics_service.dart  (420 lignes)
├── providers/
│   └── sermon_analytics_provider.dart (220 lignes)
└── widgets/
    └── sermon_analytics_widgets.dart  (480 lignes)
```

**Total**: 1,280 lignes de code

---

## 📋 Modèles de Données

### SermonAnalytics

```dart
class SermonAnalytics {
  final String sermonId;
  final int viewCount;                    // Nombre d'ouvertures
  final int totalReadingTimeSeconds;      // Temps total en secondes
  final int lastViewTimestamp;            // Timestamp dernière vue
  final double progressPercent;           // 0-100%
  final int lastPageRead;                 // Dernière page
  final int totalPages;                   // Nombre total de pages
  final List<ReadingSession> sessions;    // Historique
}
```

**Propriétés Computed**:
- `formattedReadingTime` - "2h 30m" ou "45m 20s"
- `averageSessionTime` - Temps moyen par session
- `lastViewDate` - DateTime de dernière vue
- `isRecentlyRead` - Lu dans les 7 derniers jours
- `isCompleted` - Progression >= 100%
- `recentSessions` - Sessions des 30 derniers jours

### ReadingSession

```dart
class ReadingSession {
  final int startTimestamp;
  final int endTimestamp;
  final int durationSeconds;
  final int pagesRead;
  final int startPage;
  final int endPage;
}
```

**Propriétés Computed**:
- `startDate` / `endDate` - DateTime
- `formattedDuration` - "15m 30s"

---

## 🔧 Service (sermon_analytics_service.dart)

### Persistance

**Stockage**: SharedPreferences (`wb_sermon_analytics`)  
**Format**: JSON Map<String, SermonAnalytics>  
**Cache**: Map en mémoire pour performances

### Méthodes Principales

#### Gestion des Sessions

```dart
// Démarrer une session
await SermonAnalyticsService.startReadingSession(
  sermonId,
  totalPages: 150,
  startPage: 1,
);

// Mettre à jour la progression
await SermonAnalyticsService.updateProgress(
  sermonId,
  currentPage: 25,
  totalPages: 150,
);

// Terminer une session
await SermonAnalyticsService.endReadingSession(
  sermonId,
  durationSeconds: 900, // 15 minutes
  startPage: 1,
  endPage: 25,
);
```

#### Requêtes Analytiques

```dart
// Top sermons par vues
List<SermonAnalytics> mostViewed = 
    await SermonAnalyticsService.getMostViewedSermons(limit: 10);

// Top sermons par temps de lecture
List<SermonAnalytics> mostRead = 
    await SermonAnalyticsService.getMostReadSermons(limit: 10);

// Sermons récemment consultés
List<SermonAnalytics> recent = 
    await SermonAnalyticsService.getRecentlyViewedSermons(limit: 10);

// Sermons en cours (0% < progress < 100%)
List<SermonAnalytics> inProgress = 
    await SermonAnalyticsService.getInProgressSermons();

// Sermons complétés (progress >= 100%)
List<SermonAnalytics> completed = 
    await SermonAnalyticsService.getCompletedSermons();
```

#### Statistiques Globales

```dart
// Temps total tous sermons
int totalSeconds = await SermonAnalyticsService.getTotalReadingTimeSeconds();

// Nombre de sermons consultés
int count = await SermonAnalyticsService.getTotalSermonsViewed();

// Temps moyen par sermon
String avgTime = await SermonAnalyticsService.getAverageReadingTime();

// Stats par période
Map<String, dynamic> stats7Days = 
    await SermonAnalyticsService.getStatsByPeriod(7);

Map<String, dynamic> stats30Days = 
    await SermonAnalyticsService.getStatsByPeriod(30);
```

**Format getStatsByPeriod()**:
```dart
{
  'days': 7,
  'sermonsRead': 5,
  'totalReadingTimeSeconds': 3600,
  'totalSessions': 8,
  'averageSessionTimeSeconds': 450,
}
```

#### Export/Import

```dart
// Export JSON
String jsonData = await SermonAnalyticsService.exportData();

// Import JSON
await SermonAnalyticsService.importData(jsonData);

// Supprimer tout
await SermonAnalyticsService.clearAll();

// Supprimer un sermon
await SermonAnalyticsService.deleteSermonAnalytics(sermonId);
```

---

## 🎮 Provider (sermon_analytics_provider.dart)

### État Géré

```dart
class SermonAnalyticsProvider with ChangeNotifier {
  Map<String, SermonAnalytics> _analytics;
  bool _isLoading;
  String? _error;
  
  // Session en cours
  String? _currentSermonId;
  DateTime? _sessionStartTime;
  int? _sessionStartPage;
  Timer? _sessionTimer;
}
```

### Fonctionnalités Clés

#### Auto-tracking de Session

```dart
// Le provider démarre automatiquement un timer qui sauvegarde
// la progression toutes les 30 secondes pendant une session active
```

#### Méthodes Publiques

```dart
// Démarrer tracking
await provider.startReadingSession(
  sermonId,
  totalPages: 150,
  startPage: 1,
);

// Mettre à jour (appelé sur changement de page)
await provider.updateProgress(
  sermonId: sermonId,
  currentPage: currentPage,
  totalPages: totalPages,
);

// Terminer
await provider.endReadingSession(endPage: currentPage);

// Récupérer stats d'un sermon
SermonAnalytics? analytics = provider.getSermonAnalytics(sermonId);

// Stats globales
Map<String, dynamic> globalStats = await provider.getGlobalStats();
```

### Lifecycle Management

Le provider :
- ✅ Termine automatiquement la session lors du dispose
- ✅ Sauvegarde périodiquement (toutes les 30s)
- ✅ Gère proprement le changement de sermon
- ✅ Cache les données en mémoire

---

## 🎨 Widgets UI

### SermonStatsCard

Widget compact affichant stats dans une card de sermon.

```dart
SermonStatsCard(
  sermonId: sermon.id,
  onTap: () => _showDetailsDialog(),
)
```

**Affiche**:
- Progression circulaire avec %
- Temps de lecture total
- Nombre de vues
- Position (page X/Y)
- Badge "Terminé" si complété

### SermonStatsDialog

Dialogue modal avec statistiques détaillées.

```dart
showDialog(
  context: context,
  builder: (_) => SermonStatsDialog(analytics: analytics),
);
```

**Affiche**:
- Progression détaillée
- Temps de lecture
- Nombre de vues
- Nombre de sessions
- Temps moyen par session
- Position actuelle
- Date dernière lecture
- Liste des 5 sessions récentes

### GlobalStatsWidget

Widget complet pour page de statistiques globales.

```dart
GlobalStatsWidget()
```

**Sections**:

1. **Statistiques générales**
   - Temps total
   - Sermons consultés
   - Temps moyen

2. **7 derniers jours**
   - Sermons lus
   - Temps total
   - Nombre de sessions

3. **30 derniers jours**
   - Sermons lus
   - Temps total
   - Nombre de sessions

4. **Top 5 sermons les plus consultés**
   - Liste avec nombre de vues
   - Temps de lecture
   - Progression
   - Indicateur complété

---

## 🔌 Intégration

### Étape 1: Ajouter le Provider

**Fichier**: `lib/main.dart`

```dart
MultiProvider(
  providers: [
    // ... providers existants ...
    ChangeNotifierProvider(
      create: (_) => SermonAnalyticsProvider(),
    ),
  ],
  child: MyApp(),
)
```

### Étape 2: Intégrer dans sermon_viewer_page.dart

```dart
class SermonViewerPage extends StatefulWidget {
  final WBSermon sermon;
  
  @override
  State<SermonViewerPage> createState() => _SermonViewerPageState();
}

class _SermonViewerPageState extends State<SermonViewerPage> {
  int _currentPage = 1;
  int _totalPages = 1;
  
  @override
  void initState() {
    super.initState();
    _startTracking();
  }
  
  @override
  void dispose() {
    _endTracking();
    super.dispose();
  }
  
  Future<void> _startTracking() async {
    final provider = Provider.of<SermonAnalyticsProvider>(
      context,
      listen: false,
    );
    
    await provider.startReadingSession(
      widget.sermon.id,
      totalPages: _totalPages,
      startPage: _currentPage,
    );
  }
  
  Future<void> _endTracking() async {
    final provider = Provider.of<SermonAnalyticsProvider>(
      context,
      listen: false,
    );
    
    await provider.endReadingSession(endPage: _currentPage);
  }
  
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    
    // Mettre à jour la progression
    final provider = Provider.of<SermonAnalyticsProvider>(
      context,
      listen: false,
    );
    
    provider.updateProgress(
      sermonId: widget.sermon.id,
      currentPage: page,
      totalPages: _totalPages,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sermon.title),
        actions: [
          IconButton(
            icon: Icon(Icons.bar_chart),
            onPressed: _showStats,
          ),
        ],
      ),
      body: PdfViewer(
        onPageChanged: _onPageChanged,
        onDocumentLoaded: (totalPages) {
          setState(() {
            _totalPages = totalPages;
          });
        },
      ),
    );
  }
  
  void _showStats() {
    final provider = Provider.of<SermonAnalyticsProvider>(
      context,
      listen: false,
    );
    
    final analytics = provider.getSermonAnalytics(widget.sermon.id);
    
    if (analytics != null) {
      showDialog(
        context: context,
        builder: (_) => SermonStatsDialog(analytics: analytics),
      );
    }
  }
}
```

### Étape 3: Afficher dans SermonCard

**Fichier**: `lib/modules/search/widgets/sermon_card.dart`

```dart
class SermonCard extends StatelessWidget {
  final WBSermon sermon;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // ... contenu existant ...
          
          // Stats
          SermonStatsCard(
            sermonId: sermon.id,
            onTap: () => _showFullStats(context),
          ),
        ],
      ),
    );
  }
}
```

### Étape 4: Ajouter Onglet Statistiques

**Fichier**: `lib/modules/search/search_home_page.dart`

```dart
TabBar(
  tabs: const [
    Tab(text: 'Sermons'),
    Tab(text: 'Recherche'),
    Tab(text: 'Notes'),
    Tab(text: 'Signets'),
    Tab(text: 'Stats'), // NOUVEAU
  ],
)

TabBarView(
  children: [
    const SermonsTabView(),
    const SearchTabView(),
    const NotesHighlightsTabView(),
    _buildBookmarksTab(),
    const GlobalStatsWidget(), // NOUVEAU
  ],
)
```

---

## 📊 Cas d'Usage

### 1. Tableau de Bord Personnel

```dart
class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SermonAnalyticsProvider>(
      builder: (context, provider, child) {
        return FutureBuilder<Map<String, dynamic>>(
          future: provider.getGlobalStats(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return CircularProgressIndicator();
            }
            
            final stats = snapshot.data!;
            
            return Column(
              children: [
                StatCard(
                  title: 'Temps de lecture',
                  value: _formatTime(stats['totalReadingTimeSeconds']),
                  icon: Icons.access_time,
                ),
                StatCard(
                  title: 'Sermons consultés',
                  value: '${stats['totalSermonsViewed']}',
                  icon: Icons.library_books,
                ),
                // ... autres cards
              ],
            );
          },
        );
      },
    );
  }
}
```

### 2. Badge de Progression

```dart
// Afficher badge sur sermon card
Consumer<SermonAnalyticsProvider>(
  builder: (context, provider, child) {
    final analytics = provider.getSermonAnalytics(sermon.id);
    
    if (analytics == null) return SizedBox.shrink();
    
    return Stack(
      children: [
        SermonImage(),
        Positioned(
          bottom: 8,
          right: 8,
          child: CircleAvatar(
            backgroundColor: Colors.blue,
            child: Text('${analytics.progressPercent.toInt()}%'),
          ),
        ),
      ],
    );
  },
)
```

### 3. Liste "Continuer la Lecture"

```dart
FutureBuilder<List<SermonAnalytics>>(
  future: provider.getInProgressSermons(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    
    return ListView.builder(
      itemCount: snapshot.data!.length,
      itemBuilder: (context, index) {
        final analytics = snapshot.data![index];
        
        return ListTile(
          title: Text(analytics.sermonId),
          subtitle: LinearProgressIndicator(
            value: analytics.progressPercent / 100,
          ),
          trailing: Text('Page ${analytics.lastPageRead}'),
          onTap: () => _resumeSermon(analytics.sermonId),
        );
      },
    );
  },
)
```

### 4. Rapport Hebdomadaire

```dart
FutureBuilder<Map<String, dynamic>>(
  future: SermonAnalyticsService.getStatsByPeriod(7),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    
    final stats = snapshot.data!;
    
    return Card(
      child: Column(
        children: [
          Text('Cette semaine'),
          Text('${stats['sermonsRead']} sermons lus'),
          Text('${stats['totalSessions']} sessions'),
          Text(_formatTime(stats['totalReadingTimeSeconds'])),
        ],
      ),
    );
  },
)
```

---

## 🧪 Tests

### Test Unitaire Service

```dart
void main() {
  test('Start reading session increases view count', () async {
    await SermonAnalyticsService.clearAll();
    
    await SermonAnalyticsService.startReadingSession(
      'test-sermon',
      totalPages: 100,
    );
    
    final analytics = await SermonAnalyticsService.getAnalytics('test-sermon');
    
    expect(analytics, isNotNull);
    expect(analytics!.viewCount, equals(1));
    expect(analytics.totalPages, equals(100));
  });
  
  test('Update progress calculates percentage correctly', () async {
    await SermonAnalyticsService.startReadingSession(
      'test-sermon',
      totalPages: 100,
    );
    
    await SermonAnalyticsService.updateProgress(
      'test-sermon',
      currentPage: 50,
      totalPages: 100,
    );
    
    final analytics = await SermonAnalyticsService.getAnalytics('test-sermon');
    
    expect(analytics!.progressPercent, equals(50.0));
    expect(analytics.lastPageRead, equals(50));
  });
}
```

### Test Widget

```dart
testWidgets('SermonStatsCard displays correctly', (tester) async {
  final analytics = SermonAnalytics(
    sermonId: 'test',
    viewCount: 5,
    totalReadingTimeSeconds: 3600,
    progressPercent: 75.0,
    lastViewTimestamp: DateTime.now().millisecondsSinceEpoch,
  );
  
  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider(
        create: (_) => SermonAnalyticsProvider(),
        child: SermonStatsCard(sermonId: 'test'),
      ),
    ),
  );
  
  expect(find.text('75%'), findsOneWidget);
  expect(find.text('1h 0m'), findsOneWidget);
  expect(find.text('5 vues'), findsOneWidget);
});
```

---

## 📈 Métriques Trackées

| Métrique | Description | Utilisation |
|----------|-------------|-------------|
| **viewCount** | Nombre d'ouvertures | Popularité sermon |
| **totalReadingTime** | Temps cumulé | Engagement |
| **progressPercent** | % lu | Complétion |
| **lastPageRead** | Dernière page | Reprise lecture |
| **sessions** | Liste sessions | Historique détaillé |
| **averageSessionTime** | Temps moyen | Qualité engagement |
| **isCompleted** | Terminé ou non | Accomplissement |
| **isRecentlyRead** | Lu récemment | Suggestion "Continuer" |

---

## 🎯 Fonctionnalités Avancées

### 1. Suggestions Intelligentes

Utiliser les analytics pour recommander :
- Sermons similaires aux plus lus
- Continuer les sermons en cours
- Relire les favoris complétés

### 2. Gamification

- Badges pour temps de lecture
- Objectifs hebdomadaires
- Streak de lecture quotidienne

### 3. Export Rapports

Générer rapports PDF avec :
- Statistiques mensuelles
- Graphiques progression
- Liste sermons lus

### 4. Sync Cloud (TODO)

Synchroniser analytics avec Firestore pour :
- Backup automatique
- Multi-device sync
- Partage stats (optionnel)

---

## 📋 Checklist d'Intégration

- [ ] Provider ajouté dans main.dart
- [ ] Tracking démarré dans sermon_viewer_page initState
- [ ] Tracking terminé dans sermon_viewer_page dispose
- [ ] updateProgress appelé sur changement de page
- [ ] SermonStatsCard ajouté dans sermon cards
- [ ] Onglet Stats ajouté dans home page
- [ ] Tests manuels effectués
- [ ] Export/import testé
- [ ] Persistance vérifiée après redémarrage

---

## 🚀 Résultat

### Fonctionnalités Complètes ✅

- ✅ Tracking automatique des sessions
- ✅ Calcul progression en temps réel
- ✅ Statistiques par sermon
- ✅ Statistiques globales
- ✅ Top sermons (vues, temps)
- ✅ Sermons en cours/complétés
- ✅ Historique des sessions
- ✅ Stats par période (7j, 30j)
- ✅ Export/Import JSON
- ✅ Widgets UI complets

### Statistiques Code

- **Fichiers créés**: 4
- **Lignes de code**: ~1,280
- **Modèles**: 2 (SermonAnalytics, ReadingSession)
- **Service**: 420 lignes
- **Provider**: 220 lignes  
- **Widgets**: 480 lignes

**Qualité**: 0 erreurs compilation ✅

---

**🎉 Système de Statistiques et Analytics Complet ! 🎉**
