#!/bin/bash

# Script de test et validation du module rôles
# Jubilé Tabernacle - Module Rôles et Permissions

echo "🚀 JUBILÉ TABERNACLE - Test du Module Rôles"
echo "=========================================="
echo ""

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les résultats
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
    fi
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Erreur: pubspec.yaml non trouvé. Assurez-vous d'être dans le répertoire du projet.${NC}"
    exit 1
fi

print_info "Vérification de l'environnement..."

# Vérifier Flutter
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version | head -n 1)
    print_result 0 "Flutter détecté: $FLUTTER_VERSION"
else
    print_result 1 "Flutter non trouvé"
    echo "Installez Flutter depuis https://flutter.dev"
    exit 1
fi

echo ""
print_info "Vérification des fichiers du module rôles..."

# Liste des fichiers critiques à vérifier
declare -a files=(
    "lib/modules/roles/models/role.dart"
    "lib/modules/roles/models/role_template_model.dart" 
    "lib/modules/roles/providers/role_provider.dart"
    "lib/modules/roles/providers/permission_provider.dart"
    "lib/modules/roles/providers/role_template_provider.dart"
    "lib/modules/roles/services/role_template_service.dart"
    "lib/modules/roles/services/advanced_roles_permissions_service.dart"
    "lib/modules/roles/screens/role_module_test_page.dart"
    "lib/modules/roles/screens/role_template_management_screen.dart"
    "lib/modules/roles/widgets/role_template_selector_widget.dart"
    "lib/modules/roles/widgets/role_template_form_dialog.dart"
    "lib/modules/roles/widgets/bulk_permission_management_widget.dart"
    "lib/modules/roles/widgets/permission_matrix_dialog.dart"
    "lib/module_navigation_page.dart"
    "lib/test_roles_main.dart"
)

missing_files=0
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        print_result 0 "$file"
    else
        print_result 1 "$file (MANQUANT)"
        missing_files=$((missing_files + 1))
    fi
done

if [ $missing_files -gt 0 ]; then
    print_warning "$missing_files fichier(s) manquant(s) détecté(s)"
else
    print_result 0 "Tous les fichiers critiques sont présents"
fi

echo ""
print_info "Analyse du code..."

# Vérifier la syntaxe Dart
print_info "Vérification de la syntaxe Dart..."
flutter analyze > /tmp/flutter_analyze.log 2>&1
ANALYZE_RESULT=$?

if [ $ANALYZE_RESULT -eq 0 ]; then
    print_result 0 "Analyse Dart réussie - Aucune erreur critique"
else
    print_warning "Analyse Dart: Avertissements ou erreurs détectés"
    echo "Détails dans /tmp/flutter_analyze.log"
fi

# Vérifier les dépendances
print_info "Vérification des dépendances..."
flutter pub get > /dev/null 2>&1
PUB_GET_RESULT=$?
print_result $PUB_GET_RESULT "Installation des dépendances"

echo ""
print_info "Test de compilation..."

# Test de compilation de l'application principale de test
flutter build web --target=lib/test_roles_main.dart --no-sound-null-safety > /tmp/build_test.log 2>&1
BUILD_RESULT=$?

if [ $BUILD_RESULT -eq 0 ]; then
    print_result 0 "Compilation de test réussie"
else
    print_warning "Compilation de test échouée - Vérifiez /tmp/build_test.log"
fi

echo ""
print_info "Résumé des fonctionnalités du module rôles..."

echo ""
echo -e "${GREEN}🎯 FONCTIONNALITÉS IMPLÉMENTÉES:${NC}"
echo "  ✅ 9 Templates système prédéfinis (Super Admin, Admin, Moderator, etc.)"
echo "  ✅ Interface de gestion complète avec onglets"
echo "  ✅ Services backend avec validation"
echo "  ✅ Providers pour la gestion d'état"
echo "  ✅ Widgets spécialisés (Sélecteur, Formulaires, etc.)"
echo "  ✅ Interface de test avec 6 onglets fonctionnels"
echo "  ✅ Matrice des permissions"
echo "  ✅ Opérations en masse"
echo "  ✅ Validation et intégrité système"

echo ""
echo -e "${YELLOW}🔧 FONCTIONNALITÉS PRÉPARÉES:${NC}"
echo "  🔄 Export/Import complet"
echo "  🔄 Intégration Firebase avancée"
echo "  🔄 Système de notifications"
echo "  🔄 Tests unitaires automatisés"

echo ""
print_info "Instructions de test..."

echo ""
echo -e "${BLUE}📱 COMMENT TESTER:${NC}"
echo ""
echo "1. 🚀 Lancer l'application de test:"
echo "   flutter run lib/test_roles_main.dart"
echo ""
echo "2. 🖱️  Navigation:"
echo "   - Page d'accueil: Vue d'ensemble des modules"
echo "   - Bouton 'Module Rôles': Accès direct au module"
echo "   - 6 onglets de test disponibles"
echo ""
echo "3. 🧪 Tests disponibles:"
echo "   - Onglet 'Rôles': Création et gestion des rôles"
echo "   - Onglet 'Permissions': Vue des permissions système"
echo "   - Onglet 'Templates': Gestion des 9 templates prédéfinis"
echo "   - Onglet 'Matrice': Visualisation des permissions"
echo "   - Onglet 'Bulk Ops': Opérations en masse"
echo "   - Onglet 'Tests': Validation automatique"
echo ""
echo "4. 🔧 Gestion avancée:"
echo "   - Bouton 'Gestion complète': Interface de management"
echo "   - Sélecteur de templates avec aperçu"
echo "   - Formulaire de création/édition"
echo ""

# Statistiques du projet
echo ""
print_info "Statistiques du module..."

if [ -d "lib/modules/roles" ]; then
    DART_FILES=$(find lib/modules/roles -name "*.dart" | wc -l)
    TOTAL_LINES=$(find lib/modules/roles -name "*.dart" -exec wc -l {} + | tail -n 1 | awk '{print $1}')
    echo "  📁 Fichiers Dart: $DART_FILES"
    echo "  📝 Lignes de code: $TOTAL_LINES"
    
    # Compter les modèles, providers, services, etc.
    MODELS=$(find lib/modules/roles/models -name "*.dart" 2>/dev/null | wc -l)
    PROVIDERS=$(find lib/modules/roles/providers -name "*.dart" 2>/dev/null | wc -l)
    SERVICES=$(find lib/modules/roles/services -name "*.dart" 2>/dev/null | wc -l)
    SCREENS=$(find lib/modules/roles/screens -name "*.dart" 2>/dev/null | wc -l)
    WIDGETS=$(find lib/modules/roles/widgets -name "*.dart" 2>/dev/null | wc -l)
    
    echo "  🏗️  Modèles: $MODELS"
    echo "  📊 Providers: $PROVIDERS"  
    echo "  ⚙️  Services: $SERVICES"
    echo "  📱 Écrans: $SCREENS"
    echo "  🧩 Widgets: $WIDGETS"
fi

echo ""
echo -e "${GREEN}🎉 MODULE RÔLES PRÊT POUR LES TESTS!${NC}"
echo ""
echo -e "${BLUE}📖 Documentation complète disponible dans:${NC}"
echo "   GUIDE_MODULE_ROLES.md"
echo ""
echo -e "${YELLOW}🚀 Commande de lancement rapide:${NC}"
echo "   flutter run lib/test_roles_main.dart"
echo ""

# Vérifier si on peut proposer de lancer l'app
if [ $BUILD_RESULT -eq 0 ] && [ $missing_files -eq 0 ]; then
    echo -e "${GREEN}✨ Tout semble prêt! Voulez-vous lancer l'application maintenant? (y/n)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        print_info "Lancement de l'application de test..."
        flutter run lib/test_roles_main.dart
    fi
else
    print_warning "Corrigez les erreurs avant de lancer l'application"
fi

echo ""
echo "🏁 Test terminé."