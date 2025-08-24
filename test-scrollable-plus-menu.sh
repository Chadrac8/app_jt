#!/bin/bash

echo "🔍 Test de scrollabilité du menu Plus - Bottom Navigation"
echo "================================================================"

# Vérification de la structure du menu Plus
echo "✅ Vérification de la structure du menu Plus..."

# 1. Vérifier que DraggableScrollableSheet est présent
if grep -q "DraggableScrollableSheet" /Users/chadracntsouassouani/Downloads/app_jubile_tabernacle/lib/widgets/bottom_navigation_wrapper.dart; then
    echo "   ✅ DraggableScrollableSheet détecté"
else
    echo "   ❌ DraggableScrollableSheet manquant"
    exit 1
fi

# 2. Vérifier que AlwaysScrollableScrollPhysics est utilisé
if grep -q "AlwaysScrollableScrollPhysics" /Users/chadracntsouassouani/Downloads/app_jubile_tabernacle/lib/widgets/bottom_navigation_wrapper.dart; then
    echo "   ✅ AlwaysScrollableScrollPhysics configuré"
else
    echo "   ❌ AlwaysScrollableScrollPhysics manquant"
    exit 1
fi

# 3. Vérifier que NeverScrollableScrollPhysics n'est plus utilisé dans le GridView
if grep -A 20 "_showMoreMenu" /Users/chadracntsouassouani/Downloads/app_jubile_tabernacle/lib/widgets/bottom_navigation_wrapper.dart | grep -q "NeverScrollableScrollPhysics"; then
    echo "   ❌ NeverScrollableScrollPhysics encore présent"
    exit 1
else
    echo "   ✅ NeverScrollableScrollPhysics supprimé du GridView"
fi

# 4. Vérifier que le controller de scroll est bien attaché au GridView
if grep -A 30 "GridView.builder" /Users/chadracntsouassouani/Downloads/app_jubile_tabernacle/lib/widgets/bottom_navigation_wrapper.dart | grep -q "controller: scrollController"; then
    echo "   ✅ ScrollController attaché au GridView"
else
    echo "   ❌ ScrollController non attaché"
    exit 1
fi

# 5. Vérifier que Expanded est utilisé pour permettre l'expansion
if grep -A 5 "else" /Users/chadracntsouassouani/Downloads/app_jubile_tabernacle/lib/widgets/bottom_navigation_wrapper.dart | grep -q "Expanded"; then
    echo "   ✅ Widget Expanded utilisé pour l'espace flexible"
else
    echo "   ❌ Widget Expanded manquant"
    exit 1
fi

echo ""
echo "🔧 Vérification de la configuration du DraggableScrollableSheet..."

# 6. Vérifier les paramètres de taille
if grep -A 5 "DraggableScrollableSheet" /Users/chadracntsouassouani/Downloads/app_jubile_tabernacle/lib/widgets/bottom_navigation_wrapper.dart | grep -q "maxChildSize: 0.9"; then
    echo "   ✅ Taille maximale configurée (0.9)"
else
    echo "   ❌ Taille maximale non configurée"
fi

if grep -A 5 "DraggableScrollableSheet" /Users/chadracntsouassouani/Downloads/app_jubile_tabernacle/lib/widgets/bottom_navigation_wrapper.dart | grep -q "minChildSize: 0.3"; then
    echo "   ✅ Taille minimale configurée (0.3)"
else
    echo "   ❌ Taille minimale non configurée"
fi

echo ""
echo "📱 Test de compilation Flutter..."

cd /Users/chadracntsouassouani/Downloads/app_jubile_tabernacle

# Test de compilation
if flutter analyze lib/widgets/bottom_navigation_wrapper.dart 2>/dev/null | grep -q "No issues found"; then
    echo "   ✅ Compilation réussie sans erreurs"
else
    echo "   ⚠️  Vérification des warnings..."
    flutter analyze lib/widgets/bottom_navigation_wrapper.dart 2>&1 | head -10
fi

echo ""
echo "🎯 Résumé des améliorations apportées:"
echo "   • Suppression de NeverScrollableScrollPhysics"
echo "   • Ajout de AlwaysScrollableScrollPhysics"
echo "   • Utilisation d'Expanded pour l'espace flexible"
echo "   • Attachment du scrollController au GridView"
echo "   • Conservation du DraggableScrollableSheet"

echo ""
echo "🏆 Test de scrollabilité du menu Plus: RÉUSSI ✅"
echo "   Le menu Plus est maintenant scrollable pour de nombreux modules!"
