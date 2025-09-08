#!/bin/bash

echo "🔍 DIAGNOSTIC ASSIGNATION RÔLES - Jubilé Tabernacle"
echo "=================================================="
echo

# Vérifier si Flutter est en cours d'exécution
if pgrep -f "flutter" > /dev/null; then
    echo "✅ Flutter app en cours d'exécution"
else
    echo "❌ Flutter app non lancée"
    echo "   Solution: flutter run -d [device]"
fi

# Vérifier les fichiers clés
echo
echo "📁 Vérification des fichiers du nouveau système de rôles:"

files=(
    "lib/modules/roles/providers/role_provider.dart"
    "lib/modules/roles/models/role.dart"
    "lib/modules/roles/models/user_role.dart"
    "lib/modules/roles/services/role_service.dart"
    "lib/modules/roles/views/new_roles_management_screen.dart"
    "lib/pages/test/role_assignment_test_page.dart"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file - MANQUANT"
    fi
done

# Vérifier la configuration Firebase
echo
echo "🔥 Vérification Firebase:"
if [ -f "lib/firebase_options.dart" ]; then
    echo "✅ Firebase configuré"
else
    echo "❌ Firebase non configuré"
fi

if [ -f "ios/Runner/GoogleService-Info.plist" ]; then
    echo "✅ iOS Firebase configuré"
else
    echo "❌ iOS Firebase non configuré"
fi

# Vérifier les imports dans main.dart
echo
echo "📋 Vérification main.dart:"
if grep -q "RoleProvider" lib/main.dart; then
    echo "✅ RoleProvider importé dans main.dart"
else
    echo "❌ RoleProvider manquant dans main.dart"
fi

if grep -q "PermissionProvider" lib/main.dart; then
    echo "✅ PermissionProvider présent dans main.dart"
else
    echo "❌ PermissionProvider manquant dans main.dart"
fi

# Vérifier la navigation admin
echo
echo "🔧 Vérification navigation admin:"
if grep -q "NewRolesManagementScreen" lib/widgets/admin_navigation_wrapper.dart; then
    echo "✅ Nouveau système intégré dans navigation"
else
    echo "❌ Ancien système encore utilisé"
fi

echo
echo "💡 SOLUTIONS RAPIDES:"
echo "=================="
echo "1. 🚀 Lancer l'app: flutter run -d [device]"
echo "2. 📱 Aller dans Admin > Rôles (nouveau système)"
echo "3. 🧪 Tester avec: lib/pages/test/role_assignment_test_page.dart"
echo "4. 🔥 Vérifier Firebase Console pour les collections:"
echo "   - roles"
echo "   - user_roles" 
echo "   - permissions"
echo

echo "📊 ÉTAPES DE TEST:"
echo "=================="
echo "1. Se connecter à l'app"
echo "2. Aller dans Admin Panel"
echo "3. Cliquer sur 'Rôles'"
echo "4. Onglet 'Assignations'"
echo "5. Bouton 'Assigner des rôles'"
echo "6. Remplir: ID utilisateur, Email, Nom"
echo "7. Sélectionner un rôle"
echo "8. Cliquer 'Assigner'"
echo

echo "🎯 SI ÇA NE FONCTIONNE TOUJOURS PAS:"
echo "===================================="
echo "- Vérifier les règles Firestore"
echo "- Vérifier les logs: flutter logs"
echo "- Utiliser la page de test pour isoler le problème"
echo "- Réinitialiser: flutter clean && flutter pub get"
echo
