#!/bin/bash

echo "🔍 DIAGNOSTIC DU MODULE RÔLES - TEMPLATES SYSTÈME"
echo "================================================"
echo ""

# Test 1: Vérifier les fichiers critiques
echo "📁 Vérification des fichiers..."
files_to_check=(
    "lib/modules/roles/models/role_template_model.dart"
    "lib/modules/roles/providers/role_template_provider.dart"
    "lib/modules/roles/screens/role_module_test_page.dart"
    "lib/test_roles_main.dart"
    "lib/module_navigation_page.dart"
)

all_files_exist=true
for file in "${files_to_check[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file (MANQUANT)"
        all_files_exist=false
    fi
done

if [ "$all_files_exist" = true ]; then
    echo "✅ Tous les fichiers critiques sont présents"
else
    echo "❌ Certains fichiers sont manquants"
    exit 1
fi

echo ""

# Test 2: Compter les templates dans le code source
echo "🔍 Analyse du code source..."
template_count=$(grep -c "RoleTemplate(" lib/modules/roles/models/role_template_model.dart)
echo "Templates trouvés dans le code: $template_count"

# Test 3: Lister les templates système
echo ""
echo "📋 Extraction des noms de templates..."
grep -A 2 "name: '" lib/modules/roles/models/role_template_model.dart | grep "name:" | sed "s/.*name: '//" | sed "s/',//" | nl

echo ""

# Test 4: Vérifier les catégories
echo "🏷️  Catégories définies:"
grep -A 1 "enum TemplateCategory" lib/modules/roles/models/role_template_model.dart | tail -n +2 | head -8 | sed 's/.*(//' | sed 's/,.*//' | nl

echo ""

# Test 5: Test de compilation simple
echo "🔧 Test de compilation..."
flutter analyze --no-fatal-infos lib/modules/roles/models/role_template_model.dart > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Modèle RoleTemplate compile sans erreur"
else
    echo "❌ Erreurs de compilation détectées"
fi

flutter analyze --no-fatal-infos lib/modules/roles/providers/role_template_provider.dart > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Provider RoleTemplate compile sans erreur"
else
    echo "❌ Erreurs de compilation dans le provider"
fi

echo ""

# Test 6: Vérifier la structure
echo "📊 Statistiques du module:"
echo "   - Modèles: $(find lib/modules/roles/models -name "*.dart" | wc -l)"
echo "   - Providers: $(find lib/modules/roles/providers -name "*.dart" | wc -l)"
echo "   - Services: $(find lib/modules/roles/services -name "*.dart" | wc -l)"
echo "   - Écrans: $(find lib/modules/roles/screens -name "*.dart" | wc -l)"
echo "   - Widgets: $(find lib/modules/roles/widgets -name "*.dart" | wc -l)"

echo ""

# Recommandations
echo "💡 SOLUTIONS POUR VOIR LES TEMPLATES:"
echo "1. 🌐 Lancer sur web (plus stable):"
echo "   flutter run lib/test_roles_main.dart -d chrome"
echo ""
echo "2. 📱 Lancer sur simulateur iOS:"
echo "   flutter run lib/test_roles_main.dart -d 'iPhone 16 Pro'"
echo ""
echo "3. 🖥️  Lancer sur macOS:"
echo "   flutter run lib/test_roles_main.dart -d macos"
echo ""
echo "4. 🧪 Test direct (sans interface):"
echo "   flutter run lib/test_templates.dart"

echo ""
echo "🎯 Les 9 templates système devraient être visibles dans:"
echo "   Module Rôles > Onglet Templates > Sections par catégorie"

echo ""
echo "🔧 Si les templates n'apparaissent pas:"
echo "   - Firebase n'est pas connecté (normal en développement)"
echo "   - Le provider utilise automatiquement les templates locaux"
echo "   - Vérifiez la console pour les messages 'Firebase non disponible'"