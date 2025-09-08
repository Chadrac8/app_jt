#!/bin/bash

echo "🔍 VÉRIFICATION DE L'HARMONISATION : CANTIQUES → LA BIBLE"
echo "========================================================="
echo ""

echo "📋 Vérification des éléments de design..."

# Vérification du module La Bible (référence)
echo ""
echo "1. MODULE LA BIBLE (référence):"
if grep -q "bottom: TabBar" lib/modules/bible/views/bible_member_view.dart; then
    echo "   ✅ TabBar intégré dans AppBar"
else
    echo "   ❌ TabBar dans AppBar non trouvé"
fi

if grep -q "indicatorColor: AppTheme.primaryColor" lib/modules/bible/views/bible_member_view.dart; then
    echo "   ✅ Couleur indicateur AppTheme.primaryColor"
else
    echo "   ❌ Couleur indicateur manquante"
fi

if grep -q "Colors.grey\[600\]" lib/modules/bible/views/bible_member_view.dart; then
    echo "   ✅ Couleur texte inactif Colors.grey[600]"
else
    echo "   ❌ Couleur texte inactif manquante"
fi

# Vérification du module Cantiques (modifié)
echo ""
echo "2. MODULE CANTIQUES (modifié):"
if grep -q "bottom: TabBar" lib/modules/songs/views/songs_member_view.dart; then
    echo "   ✅ TabBar intégré dans AppBar"
else
    echo "   ❌ TabBar dans AppBar non trouvé"
fi

if grep -q "indicatorColor: AppTheme.primaryColor" lib/modules/songs/views/songs_member_view.dart; then
    echo "   ✅ Couleur indicateur AppTheme.primaryColor"
else
    echo "   ❌ Couleur indicateur manquante"
fi

if grep -q "Colors.grey\[600\]" lib/modules/songs/views/songs_member_view.dart; then
    echo "   ✅ Couleur texte inactif Colors.grey[600]"
else
    echo "   ❌ Couleur texte inactif manquante"
fi

if grep -q "Scaffold" lib/modules/songs/views/songs_member_view.dart; then
    echo "   ✅ Structure Scaffold adoptée"
else
    echo "   ❌ Structure Scaffold manquante"
fi

# Vérification que l'ancien design a été supprimé
if grep -q "Container.*decoration.*BoxShadow" lib/modules/songs/views/songs_member_view.dart; then
    echo "   ❌ Ancien design avec Container encore présent"
else
    echo "   ✅ Ancien design avec Container supprimé"
fi

echo ""
echo "📊 RÉSUMÉ DE L'HARMONISATION:"
echo "=============================="

# Compter les éléments harmonisés
harmonized_elements=0

if grep -q "bottom: TabBar" lib/modules/songs/views/songs_member_view.dart; then
    harmonized_elements=$((harmonized_elements + 1))
fi

if grep -q "indicatorColor: AppTheme.primaryColor" lib/modules/songs/views/songs_member_view.dart; then
    harmonized_elements=$((harmonized_elements + 1))
fi

if grep -q "Colors.grey\[600\]" lib/modules/songs/views/songs_member_view.dart; then
    harmonized_elements=$((harmonized_elements + 1))
fi

if grep -q "Scaffold" lib/modules/songs/views/songs_member_view.dart; then
    harmonized_elements=$((harmonized_elements + 1))
fi

echo "• Éléments harmonisés: $harmonized_elements/4"
echo "• Design de référence: Module La Bible"
echo "• Style adopté:"
echo "  - TabBar intégré dans AppBar"
echo "  - Pas de Container avec ombres"
echo "  - Couleurs standard (primaryColor + grey[600])"
echo "  - Structure Scaffold simple"

if [ $harmonized_elements -eq 4 ] && ! grep -q "Container.*decoration.*BoxShadow" lib/modules/songs/views/songs_member_view.dart; then
    echo ""
    echo "🎉 HARMONISATION RÉUSSIE!"
    echo "Le module Cantiques a maintenant le même style que le module La Bible."
else
    echo ""
    echo "⚠️  HARMONISATION INCOMPLÈTE"
    echo "Certaines modifications ne sont pas détectées."
fi

echo ""
echo "💡 Pour voir les changements, redémarrez l'application et naviguez vers le module Cantiques."
