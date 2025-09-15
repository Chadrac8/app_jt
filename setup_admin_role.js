// Script pour configurer les rôles administrateur dans Firebase
// À exécuter dans la console Firebase ou via un script

// 1. Créer le rôle admin si il n'existe pas
const adminRole = {
  id: 'admin',
  name: 'Administrateur',
  description: 'Accès complet à toutes les fonctionnalités',
  color: '#FF9800',
  icon: 'supervisor_account',
  modulePermissions: {
    // Permissions pour tous les modules
    dashboard: ['dashboard_visualisation_read', 'dashboard_visualisation_write'],
    personnes: ['personnes_membres_read', 'personnes_membres_write', 'personnes_membres_create', 'personnes_membres_delete'],
    groupes: ['groupes_read', 'groupes_write', 'groupes_create', 'groupes_delete'],
    // Ajoutez d'autres modules selon vos besoins
  },
  isActive: true,
  isSystemRole: true,
  createdAt: new Date(),
  updatedAt: new Date()
};

// 2. Assigner le rôle admin à votre utilisateur
// Remplacez VOTRE_USER_ID par votre vrai ID utilisateur
const userRoleAssignment = {
  userId: 'VOTRE_USER_ID', // À remplacer
  roleId: 'admin',
  assignedBy: 'system',
  assignedAt: new Date(),
  isActive: true,
  expiresAt: null,
  metadata: {
    source: 'manual_setup',
    reason: 'Initial admin setup'
  }
};

console.log('Configuration des rôles:');
console.log('1. Créer le rôle admin:', JSON.stringify(adminRole, null, 2));
console.log('2. Assigner le rôle:', JSON.stringify(userRoleAssignment, null, 2));

// Instructions pour Firebase Console:
console.log(`
ÉTAPES À SUIVRE DANS FIREBASE CONSOLE:

1. Ouvrir Firebase Console → Firestore Database

2. Créer/Vérifier la collection 'roles':
   - Ajouter un document avec ID: 'admin'
   - Copier les données du rôle admin ci-dessus

3. Créer/Vérifier la collection 'user_roles':
   - Ajouter un nouveau document (ID auto-généré)
   - Copier les données de l'assignation ci-dessus
   - IMPORTANT: Remplacer VOTRE_USER_ID par votre vrai ID

4. Vérifier votre ID utilisateur:
   - Allez dans la collection 'users'
   - Trouvez votre document utilisateur
   - Notez l'ID du document

5. Redémarrer l'application pour recharger les permissions
`);