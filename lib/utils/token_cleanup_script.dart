import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme.dart';

/// Script pour nettoyer les tokens FCM invalides
class TokenCleanupScript {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Nettoie tous les tokens invalides de la base de données
  static Future<void> cleanAllInvalidTokens() async {
    try {
      print('🧹 Début du nettoyage des tokens invalides...');
      
      final tokensSnapshot = await _firestore
          .collection('fcm_tokens')
          .get();
          
      print('📊 Trouvé ${tokensSnapshot.docs.length} tokens en base');
      
      int deletedCount = 0;
      
      for (final doc in tokensSnapshot.docs) {
        final data = doc.data();
        final token = data['token'] as String?;
        
        if (token == null || token.isEmpty || _isInvalidToken(token)) {
          await doc.reference.delete();
          deletedCount++;
          print('❌ Token invalide supprimé pour ${doc.id}');
        } else {
          print('✅ Token valide gardé pour ${doc.id}: ${token.substring(0, 20)}...');
        }
      }
      
      print('🎯 Nettoyage terminé: $deletedCount tokens supprimés');
      
    } catch (e) {
      print('❌ Erreur lors du nettoyage: $e');
    }
  }

  /// Vérifie si un token semble invalide
  static bool _isInvalidToken(String token) {
    // Un token FCM valide fait généralement plus de 100 caractères
    if (token.length < 100) return true;
    
    // Un token FCM ne doit pas contenir certains caractères
    if (token.contains(' ') || token.contains('\n')) return true;
    
    // Les tokens de test sont invalides
    if (token.startsWith('test_token_')) return true;
    
    return false;
  }

  /// Supprime le token de l'utilisateur actuel
  static Future<void> deleteCurrentUserToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ Aucun utilisateur connecté');
        return;
      }
      
      print('🗑️ Suppression du token pour ${user.email}...');
      
      await _firestore
          .collection('fcm_tokens')
          .doc(user.uid)
          .delete();
          
      print('✅ Token supprimé avec succès');
      
    } catch (e) {
      print('❌ Erreur lors de la suppression: $e');
    }
  }

  /// Affiche tous les tokens en base
  static Future<void> listAllTokens() async {
    try {
      print('📋 Liste de tous les tokens FCM:');
      
      final tokensSnapshot = await _firestore
          .collection('fcm_tokens')
          .get();
          
      if (tokensSnapshot.docs.isEmpty) {
        print('📝 Aucun token trouvé en base');
        return;
      }
      
      for (final doc in tokensSnapshot.docs) {
        final data = doc.data();
        final token = data['token'] as String?;
        final platform = data['platform'] as String?;
        final isActive = data['isActive'] as bool?;
        final lastUpdated = data['lastUpdated'] as Timestamp?;
        
        print('👤 User: ${doc.id}');
        print('   📱 Platform: $platform');
        print('   🔄 Active: $isActive');
        print('   🕐 Updated: ${lastUpdated?.toDate()}');
        print('   🔑 Token: ${token?.substring(0, 30) ?? 'null'}...');
        print('   ✅ Valid: ${token != null && !_isInvalidToken(token)}');
        print('');
      }
      
    } catch (e) {
      print('❌ Erreur lors de la lecture: $e');
    }
  }
}

/// Widget pour exécuter le nettoyage depuis l'interface
class TokenCleanupWidget extends StatefulWidget {
  const TokenCleanupWidget({super.key});

  @override
  State<TokenCleanupWidget> createState() => _TokenCleanupWidgetState();
}

class _TokenCleanupWidgetState extends State<TokenCleanupWidget> {
  bool _isLoading = false;
  List<String> _logs = [];

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toIso8601String().substring(11, 19)}: $message');
    });
    print(message);
  }

  Future<void> _cleanAllTokens() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    _addLog('🧹 Début du nettoyage des tokens...');
    
    try {
      await TokenCleanupScript.cleanAllInvalidTokens();
      _addLog('✅ Nettoyage terminé avec succès');
    } catch (e) {
      _addLog('❌ Erreur: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _deleteCurrentToken() async {
    setState(() {
      _isLoading = true;
    });

    _addLog('🗑️ Suppression du token actuel...');
    
    try {
      await TokenCleanupScript.deleteCurrentUserToken();
      _addLog('✅ Token supprimé');
    } catch (e) {
      _addLog('❌ Erreur: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _listTokens() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    _addLog('📋 Récupération de la liste des tokens...');
    
    try {
      await TokenCleanupScript.listAllTokens();
      _addLog('✅ Liste affichée dans les logs');
    } catch (e) {
      _addLog('❌ Erreur: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nettoyage Tokens FCM'),
        backgroundColor: AppTheme.redStandard,
        foregroundColor: AppTheme.white100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actions de nettoyage:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spaceMedium),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _listTokens,
                          icon: const Icon(Icons.list),
                          label: const Text('Lister tokens'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _deleteCurrentToken,
                          icon: const Icon(Icons.delete),
                          label: const Text('Supprimer mon token'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.orangeStandard,
                            foregroundColor: AppTheme.white100,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _cleanAllTokens,
                          icon: const Icon(Icons.cleaning_services),
                          label: const Text('Nettoyer tous'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.redStandard,
                            foregroundColor: AppTheme.white100,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceMedium),
            Text(
              'Logs:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spaceSmall),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.space12),
                decoration: BoxDecoration(
                  color: AppTheme.grey100,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: AppTheme.grey300!),
                ),
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              _logs[index],
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: AppTheme.fontSize12,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
