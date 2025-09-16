#!/bin/bash

echo "🧪 Lancement du test des corrections de récurrence..."
echo "================================================="

# Vérifier que Firebase est configuré
if [ ! -f "lib/firebase_options.dart" ]; then
    echo "❌ Erreur: firebase_options.dart introuvable"
    echo "Exécutez d'abord: flutter packages pub run flutterfire_cli:flutterfire configure"
    exit 1
fi

# Lancer le test
echo "🚀 Démarrage du test..."
flutter run test_recurrence_corrections.dart --debug

echo "✅ Test terminé"