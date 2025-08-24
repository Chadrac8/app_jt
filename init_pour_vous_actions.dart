import 'package:flutter/material.dart';
import 'lib/modules/vie_eglise/services/pour_vous_action_service.dart';
import 'lib/modules/vie_eglise/services/action_group_service.dart';
import 'lib/modules/vie_eglise/models/pour_vous_action.dart';
import 'lib/modules/vie_eglise/models/action_group.dart';

/// Script d'initialisation pour créer des actions "Pour vous" de démonstration
void main() async {
  print('🚀 Initialisation des actions "Pour vous"...');
  
  final actionService = PourVousActionService();
  final groupService = ActionGroupService();
  
  try {
    // Créer les groupes par défaut
    print('📁 Création des groupes par défaut...');
    await groupService.createDefaultGroups();
    
    // Attendre un peu pour que les groupes soient créés
    await Future.delayed(const Duration(seconds: 2));
    
    // Récupérer les groupes créés
    final groups = await groupService.getAllGroups().first;
    print('✅ ${groups.length} groupes créés');
    
    // Créer des actions de démonstration
    final demoActions = [
      PourVousAction(
        id: '',
        title: 'Prise de Rendez-vous',
        description: 'Prenez rendez-vous avec un pasteur ou un responsable',
        icon: Icons.calendar_today,
        iconCodePoint: Icons.calendar_today.codePoint.toString(),
        actionType: 'navigation',
        targetModule: 'rendez_vous',
        targetRoute: '/rendez_vous',
        isActive: true,
        order: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        color: '#4CAF50',
        category: 'Services',
      ),
      PourVousAction(
        id: '',
        title: 'Mur de Prière',
        description: 'Partagez vos demandes de prière avec la communauté',
        icon: Icons.favorite,
        iconCodePoint: Icons.favorite.codePoint.toString(),
        actionType: 'navigation',
        targetModule: 'mur_priere',
        targetRoute: '/mur_priere',
        isActive: true,
        order: 2,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        color: '#E91E63',
        category: 'Spirituel',
      ),
      PourVousAction(
        id: '',
        title: 'Groupes de Maison',
        description: 'Rejoignez un groupe de maison près de chez vous',
        icon: Icons.home,
        iconCodePoint: Icons.home.codePoint.toString(),
        actionType: 'navigation',
        targetModule: 'groupes',
        targetRoute: '/groupes',
        isActive: true,
        order: 3,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        color: '#FF9800',
        category: 'Communauté',
      ),
      PourVousAction(
        id: '',
        title: 'Bible en Ligne',
        description: 'Accédez à la Bible et aux outils d\'étude',
        icon: Icons.book,
        iconCodePoint: Icons.book.codePoint.toString(),
        actionType: 'navigation',
        targetModule: 'bible',
        targetRoute: '/bible',
        isActive: true,
        order: 4,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        color: '#3F51B5',
        category: 'Spirituel',
      ),
      PourVousAction(
        id: '',
        title: 'Bénévolat',
        description: 'Participez aux activités de service de l\'église',
        icon: Icons.volunteer_activism,
        iconCodePoint: Icons.volunteer_activism.codePoint.toString(),
        actionType: 'navigation',
        targetModule: 'benevolat',
        targetRoute: '/benevolat',
        isActive: true,
        order: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        color: '#9C27B0',
        category: 'Services',
      ),
      PourVousAction(
        id: '',
        title: 'Contactez-nous',
        description: 'Envoyez un message à l\'équipe pastorale',
        icon: Icons.message,
        iconCodePoint: Icons.message.codePoint.toString(),
        actionType: 'form',
        targetModule: 'message',
        actionData: {
          'formType': 'contact',
          'recipient': 'pasteur@jubile.fr'
        },
        isActive: true,
        order: 6,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        color: '#607D8B',
        category: 'Contact',
      ),
    ];
    
    print('📝 Création de ${demoActions.length} actions de démonstration...');
    
    for (final action in demoActions) {
      try {
        await actionService.createAction(action);
        print('✅ Action créée: ${action.title}');
      } catch (e) {
        print('❌ Erreur lors de la création de "${action.title}": $e');
      }
    }
    
    print('🎉 Initialisation terminée avec succès !');
    print('📱 Vous pouvez maintenant tester l\'onglet "Pour vous" dans l\'application');
    
  } catch (e) {
    print('❌ Erreur lors de l\'initialisation: $e');
  }
}
