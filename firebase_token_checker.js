// Script à exécuter dans la console JavaScript de Firebase Console
// Pour identifier et supprimer les tokens FCM invalides

// 1. Aller sur https://console.firebase.google.com/
// 2. Sélectionner votre projet
// 3. Aller dans Firestore Database
// 4. Ouvrir la console développeur du navigateur (F12)
// 5. Coller ce script dans la console

console.log('🔍 Diagnostic des tokens FCM...');

// Fonction pour analyser un token
function analyzeToken(token, docId) {
    if (!token) {
        console.log(`❌ ${docId}: Token manquant`);
        return false;
    }
    
    if (token.length < 100) {
        console.log(`❌ ${docId}: Token trop court (${token.length} caractères) - ${token.substring(0, 30)}...`);
        return false;
    }
    
    if (token.includes(' ') || token.includes('\n')) {
        console.log(`❌ ${docId}: Token contient des espaces - ${token.substring(0, 30)}...`);
        return false;
    }
    
    if (token.startsWith('test_token_')) {
        console.log(`❌ ${docId}: Token de test - ${token}`);
        return false;
    }
    
    console.log(`✅ ${docId}: Token valide (${token.length} caractères)`);
    return true;
}

// Instructions pour utiliser ce script
console.log(`
📋 INSTRUCTIONS:
1. Aller dans Firestore Database > Collection 'fcm_tokens'
2. Pour chaque document, copier le token et vérifier avec:
   analyzeToken("VOTRE_TOKEN_ICI", "USER_ID")
3. Supprimer les documents avec des tokens invalides

⚠️  EXEMPLE D'UTILISATION:
analyzeToken("eF5Z8...[votre_token_complet]...", "user123")
`);

// Exemple de ce à quoi ressemble un token valide
console.log(`
✅ EXEMPLE DE TOKEN VALIDE:
- Longueur: 150+ caractères
- Format: eF5Z8h9K2mN7pQ3rS6tU1vW4xY0zA2bC5dE8fG1hH4iJ7kL0mN3oP6qR9sT2uV5wX8yZ1aB4cD7eF0gH3iJ6kL9mN2oP5qR8sT1uV4wX7yZ0aB3cD6eF9gH2iJ5kL8mN1oP4qR7sT0uV3wX6yZ9aB2cD5eF8gH1iJ4kL7mN0oP3qR6sT9uV2wX5yZ8aB1cD4eF7gH0iJ3kL6mN9oP2qR5sT8uV1wX4yZ7aB0cD3eF6gH9iJ2kL5mN8oP1qR4sT7uV0wX3yZ6aB9cD2eF5gH8iJ1kL4mN7oP0qR3sT6uV9wX2yZ5aB8cD1eF4gH7iJ0kL3mN6oP9qR2sT5uV8wX1yZ4aB7cD0eF3gH6iJ9kL2mN5oP8qR1sT4uV7wX0yZ3aB6cD9eF2gH5iJ8kL1mN4oP7qR0sT3uV6wX9yZ2aB5cD8eF1gH4iJ7kL0mN3oP6qR9sT2uV5wX8yZ1a

⚠️  EXEMPLES DE TOKENS INVALIDES:
- "test_token_user123" (token de test)
- "eF5Z..." (trop court)
- "eF5Z 8h9K" (contient des espaces)
- "" (vide)
- null/undefined
`);
