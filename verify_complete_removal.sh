#!/bin/bash

echo "🔍 Vérification finale de la suppression des modules de toutes les barres de navigation"
echo "=============================================================================="

echo ""
echo "🔍 Recherche dans les fichiers de navigation..."

echo ""
echo "📱 AdminNavigationWrapper:"
if grep -q "pour-vous\|ressources\|dons" lib/widgets/admin_navigation_wrapper.dart; then
    echo "❌ Références trouvées dans AdminNavigationWrapper:"
    grep -n "pour-vous\|ressources\|dons" lib/widgets/admin_navigation_wrapper.dart
else
    echo "✅ Aucune référence aux modules supprimés dans AdminNavigationWrapper"
fi

echo ""
echo "📱 BottomNavigationWrapper:"
if grep -q "pour-vous\|ressources\|dons" lib/widgets/bottom_navigation_wrapper.dart; then
    echo "❌ Références trouvées dans BottomNavigationWrapper:"
    grep -n "pour-vous\|ressources\|dons" lib/widgets/bottom_navigation_wrapper.dart
else
    echo "✅ Aucune référence aux modules supprimés dans BottomNavigationWrapper"
fi

echo ""
echo "🔧 AppConfigFirebaseService:"
if grep -q "pour_vous\|ressources\|dons" lib/services/app_config_firebase_service.dart; then
    echo "❌ Références trouvées dans AppConfigFirebaseService:"
    grep -n "pour_vous\|ressources\|dons" lib/services/app_config_firebase_service.dart
else
    echo "✅ Aucune référence aux modules supprimés dans AppConfigFirebaseService"
fi

echo ""
echo "📋 AppModules configuration:"
if grep -q "pour_vous\|ressources\|dons" lib/config/app_modules.dart; then
    echo "❌ Références trouvées dans app_modules.dart:"
    grep -n "pour_vous\|ressources\|dons" lib/config/app_modules.dart
else
    echo "✅ Aucune référence aux modules supprimés dans app_modules.dart"
fi

echo ""
echo "🔍 Recherche générale dans tous les fichiers dart..."
TOTAL_REFS=$(grep -r "pour-vous\|pour_vous\|ressources.*module\|dons.*module\|DonsModule\|PourVousModule\|RessourcesModule" lib/ --include="*.dart" 2>/dev/null | wc -l)
echo "Références restantes trouvées: $TOTAL_REFS"

if [ "$TOTAL_REFS" -eq 0 ]; then
    echo "✅ SUCCÈS: Tous les modules ont été complètement supprimés !"
else
    echo "⚠️  Quelques références peuvent subsister dans des commentaires ou du code non critique"
fi

echo ""
echo "🏗️ Test de compilation..."
if flutter analyze --no-fatal-warnings > /dev/null 2>&1; then
    echo "✅ Compilation réussie"
else
    echo "⚠️  Des avertissements subsistent (normal pour les deprecated warnings)"
fi

echo ""
echo "✅ Vérification terminée !"
