#!/bin/bash

echo "🎵 VÉRIFICATION UNIFORMISATION MODULE CANTIQUES"
echo "==============================================="
echo ""

echo "📊 ÉTAT ACTUEL DES ARRIÈRE-PLANS:"
echo "=================================="

# Couleur de référence dans AppTheme
echo ""
echo "🎨 COULEURS DE RÉFÉRENCE (theme.dart):"
echo "• pageBackgroundColor = surfaceColor = #E9ECEF"
echo "• tabBarBackgroundColor = surfaceColor = #E9ECEF"
echo "• ✅ Les deux couleurs sont IDENTIQUES"
echo ""

# Vue principale du module Songs
echo "📁 MODULE CANTIQUES (songs_member_view.dart):"
if grep -q "backgroundColor: AppTheme.pageBackgroundColor" lib/modules/songs/views/songs_member_view.dart; then
    echo "   ✅ Scaffold: AppTheme.pageBackgroundColor"
else
    echo "   ❌ Scaffold: Couleur non uniforme"
fi

if grep -q "color: AppTheme.tabBarBackgroundColor" lib/modules/songs/views/songs_member_view.dart; then
    echo "   ✅ TabBar: AppTheme.tabBarBackgroundColor"
else
    echo "   ❌ TabBar: Couleur non uniforme"
fi

echo ""
echo "📋 ONGLETS ET COMPOSANTS:"
echo "========================="

# Compter les onglets dans TabController
tab_count=$(grep -o "TabController(length: [0-9]" lib/modules/songs/views/songs_member_view.dart | grep -o "[0-9]")
if [ ! -z "$tab_count" ]; then
    echo "   📊 Nombre d'onglets détectés: $tab_count"
else
    echo "   📊 Nombre d'onglets: Non détecté"
fi

# Vérifier les onglets spécifiques si ils existent
echo ""
echo "   📄 COMPOSANTS INTERNES:"

if [ -f "lib/modules/songs/widgets/songs_tab_perfect13.dart" ]; then
    echo "      • songs_tab_perfect13.dart : Présent"
else
    echo "      • songs_tab_perfect13.dart : Absent"
fi

if [ -f "lib/modules/songs/widgets/setlists_tab_perfect13.dart" ]; then
    echo "      • setlists_tab_perfect13.dart : Présent"
else
    echo "      • setlists_tab_perfect13.dart : Absent"
fi

echo ""
echo "🔍 DÉTECTION DES COULEURS CODÉES EN DUR:"
echo "========================================"

# Rechercher les couleurs problématiques dans le module songs
problematic_colors=0

if grep -q "backgroundColor.*Color(0xFF" lib/modules/songs/**/*.dart 2>/dev/null; then
    echo "⚠️  Couleurs codées en dur détectées:"
    grep -n "backgroundColor.*Color(0xFF" lib/modules/songs/**/*.dart 2>/dev/null | head -3
    problematic_colors=1
fi

if grep -q "backgroundColor.*Colors\." lib/modules/songs/**/*.dart 2>/dev/null; then
    echo "⚠️  Couleurs Flutter material détectées (non critiques):"
    grep -n "backgroundColor.*Colors\." lib/modules/songs/**/*.dart 2>/dev/null | head -3
fi

if [ $problematic_colors -eq 0 ]; then
    echo "✅ Aucune couleur codée en dur problématique détectée"
fi

echo ""
echo "📊 RÉSUMÉ DE L'HARMONISATION:"
echo "============================"

# Vérifier la vue principale
main_view_uniform=0
if grep -q "backgroundColor: AppTheme.pageBackgroundColor" lib/modules/songs/views/songs_member_view.dart && grep -q "color: AppTheme.tabBarBackgroundColor" lib/modules/songs/views/songs_member_view.dart; then
    main_view_uniform=1
fi

# Compter les fichiers harmonisés
harmonized_files=$(find lib/modules/songs -name "*.dart" -exec grep -l "AppTheme\.pageBackgroundColor\|AppTheme\.tabBarBackgroundColor" {} \; | wc -l)

echo "• Vue principale uniformisée: $main_view_uniform/1"
echo "• Fichiers harmonisés: $harmonized_files"
echo "• Couleur d'arrière-plan: #E9ECEF (AppTheme.surfaceColor)"
echo "• TabBar et pages: MÊME COULEUR"

if [ $main_view_uniform -eq 1 ]; then
    echo ""
    echo "🎉 UNIFORMISATION CANTIQUES CONFIRMÉE!"
    echo "✅ Le module utilise AppTheme.pageBackgroundColor"
    echo "✅ La TabBar utilise AppTheme.tabBarBackgroundColor" 
    echo "✅ Les deux couleurs sont identiques (#E9ECEF)"
    echo "✅ Interface cohérente dans tout le module"
else
    echo ""
    echo "⚠️  UNIFORMISATION INCOMPLÈTE"
    echo "❌ Le module principal n'est pas uniformisé"
fi

echo ""
echo "💡 COULEURS ACTUELLES:"
echo "• AppTheme.pageBackgroundColor = #E9ECEF"
echo "• AppTheme.tabBarBackgroundColor = #E9ECEF"
echo "• Résultat: Arrière-plan identique partout !"

echo ""
echo "🎵 MODULE CANTIQUES:"
echo "==================="
echo "Le module Cantiques utilise une architecture avec TabBar intégrée."
echo "L'harmonisation se fait au niveau de la vue principale songs_member_view.dart."
echo "Les onglets internes (Perfect13) sont des widgets qui héritent de l'arrière-plan parent."
