import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'theme.dart';

// Navigation
import 'module_navigation_page.dart';

// Providers
import 'modules/roles/providers/role_provider.dart';
import 'modules/roles/providers/permission_provider.dart';
import 'modules/roles/providers/role_template_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation Firebase
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialisé avec succès');
  } catch (e) {
    print('⚠️ Erreur d\'initialisation Firebase: $e');
    print('📝 L\'application fonctionne en mode développement sans Firebase');
  }
  
  runApp(const JubileTabernacleApp());
}

class JubileTabernacleApp extends StatelessWidget {
  const JubileTabernacleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Providers globaux pour les rôles
        ChangeNotifierProvider(
          create: (_) => RoleProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => PermissionProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => RoleTemplateProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'Jubilé Tabernacle',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const ModuleNavigationPage(),
        routes: {
          '/navigation': (context) => const ModuleNavigationPage(),
        },
      ),
    );
  }
}

class AppTheme {
  // Couleurs principales
  static const Color primaryColor = Color(0xFF6A1B9A); // Violet principal
  static const Color secondaryColor = Color(0xFF8E24AA);
  static const Color accentColor = Color(0xFFAB47BC);
  
  // Couleurs d'état
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  
  // Couleurs spéciales
  static const Color pinkStandard = Color(0xFFE91E63);
  static const Color goldStandard = AppTheme.goldColor;
  
  // Thème principal
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        elevation: 2,
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: AppTheme.fontSize20,
          fontWeight: AppTheme.fontSemiBold,
          color: Colors.white,
        ),
      ),
      
      // Cards
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      
      // Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
      
      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: AppTheme.grey200,
        labelStyle: const TextStyle(fontSize: AppTheme.fontSize12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      
      // Tab Bar
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: AppTheme.grey500,
        indicatorColor: primaryColor,
        indicatorSize: TabBarIndicatorSize.tab,
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}