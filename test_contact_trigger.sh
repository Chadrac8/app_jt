#!/bin/bash

# Script pour tester rapidement la fonction de contact en créant un document test

echo "🧪 Test de la fonction onContactMessageCreated..."
echo ""

# Utiliser Firebase CLI pour créer un document de test
firebase firestore:set contact_messages/test-$(date +%s) '{
  "name": "Test User",
  "email": "test@example.com", 
  "subject": "Message de test automatique",
  "message": "Ceci est un message de test pour vérifier que la fonction Firebase se déclenche correctement.",
  "createdAt": {"_nanoseconds": 0, "_seconds": '$(date +%s)'},
  "isRead": false
}' --project hjye25u8iwm0i0zls78urffsc0jcgj

echo ""
echo "✅ Document de test créé dans Firestore"
echo "🔍 Vérification des logs dans 5 secondes..."
sleep 5

echo ""
echo "📋 Logs de la fonction:"
firebase functions:log --only onContactMessageCreated | tail -10
