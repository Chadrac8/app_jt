import 'package:firebase_auth/firebase_auth.dart';
import 'user_profile_service.dart';
import 'push_notification_service.dart';

class AuthListenerService {
  static FirebaseAuth _auth = FirebaseAuth.instance;
  static bool _isInitialized = false;

  /// Initialize auth state listener
  static void initialize() {
    if (_isInitialized) return;
    
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        // User signed in - ensure profile exists
        try {
          await UserProfileService.ensureUserProfile(user);
          print('✅ Profile ensured for user: ${user.email}');
          
          // Réinitialiser les notifications push pour le nouvel utilisateur
          if (PushNotificationService.isInitialized) {
            await PushNotificationService.initialize();
            print('🔔 Push notifications reinitialized for user');
          }
        } catch (e) {
          print('❌ Error ensuring user profile: $e');
        }
      } else {
        // User signed out - clean up notifications
        try {
          await PushNotificationService.deleteToken();
          print('🔐 User signed out - notifications cleaned up');
        } catch (e) {
          print('❌ Error cleaning up notifications: $e');
        }
      }
    });
    
    _isInitialized = true;
    print('🎯 Auth listener service initialized');
  }
}