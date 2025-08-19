import 'package:flutter/material.dart';
import '../modules/message/message_module.dart';
import '../pages/admin/pepites_or_admin_view.dart';
import '../auth/auth_service.dart';
import '../models/person_model.dart';

/// Page d'accès au module "Le Message"
class MessagePage extends StatefulWidget {
  const MessagePage({Key? key}) : super(key: key);

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  bool _isAdmin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final currentUser = await AuthService.getCurrentUserProfile();
      if (currentUser != null) {
        final hasAdminAccess = _checkAdminAccess(currentUser);
        setState(() {
          _isAdmin = hasAdminAccess;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _checkAdminAccess(PersonModel profile) {
    return profile.roles.any((role) => 
      role.toLowerCase().contains('admin') || 
      role.toLowerCase().contains('leader') ||
      role.toLowerCase().contains('pasteur') ||
      role.toLowerCase().contains('responsable') ||
      role.toLowerCase().contains('dirigeant')
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Si l'utilisateur est admin, montrer la vue admin avec gestion des pépites
    if (_isAdmin) {
      return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Le Message - Administration'),
            backgroundColor: const Color(0xFF8B4513),
            foregroundColor: Colors.white,
            bottom: const TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(icon: Icon(Icons.auto_awesome), text: 'Gérer les Pépites'),
                Tab(icon: Icon(Icons.visibility), text: 'Vue Membre'),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              PepitesOrAdminView(),
              MessageModule(),
            ],
          ),
        ),
      );
    }

    // Vue normale pour les membres
    return MessageModule();
  }
}
