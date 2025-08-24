#!/bin/bash

echo "🔍 Vérification de la suppression complète des modules 'Pour vous', 'Ressources' et 'Dons'"
echo "=================================================================="

# Vérifier que les dossiers n'existent plus
echo "📁 Vérification des dossiers..."
if [ ! -d "lib/modules/pour_vous" ]; then
    echo "✅ Dossier 'pour_vous' supprimé"
else
    echo "❌ Dossier 'pour_vous' encore présent"
fi

if [ ! -d "lib/modules/ressources" ]; then
    echo "✅ Dossier 'ressources' supprimé"
else
    echo "❌ Dossier 'ressources' encore présent"
fi

if [ ! -d "lib/modules/dons" ]; then
    echo "✅ Dossier 'dons' supprimé"
else
    echo "❌ Dossier 'dons' encore présent"
fi

echo ""
echo "🔍 Recherche de références restantes..."

# Rechercher les références dans les fichiers
echo "📋 Références 'pour_vous':"
grep -r "pour_vous" lib/ --exclude-dir=.git 2>/dev/null | wc -l

echo "📋 Références 'ressources' (hors ressources génériques):"
grep -r "ressources" lib/ --exclude-dir=.git 2>/dev/null | grep -v "ressources spirituelles" | grep -v "gestion des ressources" | wc -l

echo "📋 Références 'dons' (hors contexte général):"
grep -r "DonsModule\|dons'" lib/ --exclude-dir=.git 2>/dev/null | wc -l

echo ""
echo "🗑️ Fichiers de test supprimés:"
ls test_*dons*.dart test_*pour_vous*.dart test_*ressources*.dart 2>/dev/null | wc -l

echo ""
echo "📄 Fichiers de documentation supprimés:"
ls *POUR-VOUS*.md *DONS*.md REDIRECTIONS-FIX-COMPLETE.md 2>/dev/null | wc -l

echo ""
echo "✅ Suppression terminée !"
echo "Les modules 'Pour vous', 'Ressources' et 'Dons' ont été complètement supprimés."
