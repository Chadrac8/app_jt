#!/bin/bash

# Script de démonstration Import/Export Personnes
# Génère des fichiers d'exemple pour tester les fonctionnalités

echo "🚀 GÉNÉRATION DE FICHIERS D'EXEMPLE IMPORT/EXPORT"
echo "================================================"

# Créer le dossier de démonstration
mkdir -p demo_import_export
cd demo_import_export

echo "📁 Création des fichiers dans: $(pwd)"

# 1. Exemple CSV basique
echo "📄 Génération: exemple_personnes_basique.csv"
cat > exemple_personnes_basique.csv << 'EOF'
firstName,lastName,email,phone,address,birthDate,roles
Jean,Dupont,jean.dupont@email.com,0123456789,"123 Rue de la Paix, 75001 Paris",1990-01-01,"membre,leader"
Marie,Martin,marie.martin@email.com,0198765432,"456 Avenue des Champs, 69000 Lyon",1985-05-15,membre
Pierre,Bernard,pierre.bernard@email.com,0147258369,"789 Boulevard Victor Hugo, 13000 Marseille",1992-12-25,"membre,jeunesse"
Sophie,Moreau,sophie.moreau@email.com,0169874532,"321 Place de la République, 31000 Toulouse",1988-08-10,membre
Michel,Petit,michel.petit@email.com,0185296374,"654 Rue de la Liberté, 59000 Lille",1975-03-20,"membre,pasteur"
EOF

# 2. Exemple CSV MailChimp
echo "📄 Génération: exemple_mailchimp.csv"
cat > exemple_mailchimp.csv << 'EOF'
FNAME,LNAME,EMAIL,PHONE,ADDRESS
Antoine,Leroy,antoine.leroy@email.com,0123456788,"100 Rue Saint-Antoine, 75004 Paris"
Camille,Roux,camille.roux@email.com,0198765433,"200 Avenue Foch, 67000 Strasbourg"
Nicolas,Fournier,nicolas.fournier@email.com,0147258368,"300 Place Bellecour, 69002 Lyon"
EOF

# 3. Exemple CSV Google Contacts
echo "📄 Génération: exemple_google_contacts.csv"
cat > exemple_google_contacts.csv << 'EOF'
"Given Name","Family Name","E-mail Address","Phone Number","Address"
"Thomas","Girard","thomas.girard@email.com","0169874533","400 Rue de Rivoli, 75001 Paris"
"Julien","Bonnet","julien.bonnet@email.com","0185296375","500 Boulevard Haussmann, 75008 Paris"
"Laura","Simon","laura.simon@email.com","0123456787","600 Avenue Montaigne, 75008 Paris"
EOF

# 4. Exemple JSON complet
echo "📄 Génération: exemple_personnes.json"
cat > exemple_personnes.json << 'EOF'
{
  "exportDate": "2025-01-01T10:00:00.000Z",
  "totalRecords": 3,
  "config": {
    "includeInactive": false,
    "includeFields": ["firstName", "lastName", "email", "phone", "address", "birthDate", "roles"],
    "excludeFields": []
  },
  "people": [
    {
      "firstName": "Alexandre",
      "lastName": "Dubois",
      "email": "alexandre.dubois@email.com",
      "phone": "0147258367",
      "address": "700 Rue de la Paix, 33000 Bordeaux",
      "birthDate": "1987-06-12",
      "roles": ["membre", "diacre"],
      "customFields": {
        "profession": "Ingénieur",
        "nombreEnfants": 2
      },
      "isActive": true,
      "createdAt": "2024-01-01T00:00:00.000Z",
      "updatedAt": "2024-12-01T00:00:00.000Z"
    },
    {
      "firstName": "Isabelle",
      "lastName": "Vincent",
      "email": "isabelle.vincent@email.com",
      "phone": "0169874534",
      "address": "800 Avenue des Pins, 06000 Nice",
      "birthDate": "1983-09-28",
      "roles": ["membre", "louange"],
      "customFields": {
        "profession": "Professeure",
        "ministere": "Musique"
      },
      "isActive": true,
      "createdAt": "2024-01-15T00:00:00.000Z",
      "updatedAt": "2024-11-15T00:00:00.000Z"
    },
    {
      "firstName": "François",
      "lastName": "Mercier",
      "email": "francois.mercier@email.com",
      "phone": "0185296376",
      "address": "900 Place du Marché, 44000 Nantes",
      "birthDate": "1979-11-03",
      "roles": ["membre", "ancien"],
      "customFields": {
        "profession": "Comptable",
        "anciennete": "15 ans"
      },
      "isActive": true,
      "createdAt": "2024-02-01T00:00:00.000Z",
      "updatedAt": "2024-10-01T00:00:00.000Z"
    }
  ]
}
EOF

# 5. Exemple avec erreurs (pour tester la validation)
echo "📄 Génération: exemple_avec_erreurs.csv"
cat > exemple_avec_erreurs.csv << 'EOF'
firstName,lastName,email,phone,address,birthDate,roles
Paul,Durand,paul.durand@email.com,0123456786,"1000 Rue de la République, 38000 Grenoble",1981-04-17,membre
,Blanc,email-invalide,téléphone-invalide,"Adresse incomplète",date-invalide,
Marie,Lefevre,marie.lefevre@email.com,,,1989-07-22,membre
Duplicate,Email,jean.dupont@email.com,0147258366,"Adresse différente",1990-01-01,membre
EOF

# 6. Template vide pour import
echo "📄 Génération: template_import.csv"
cat > template_import.csv << 'EOF'
firstName,lastName,email,phone,address,birthDate,roles
Prénom,Nom,email@exemple.com,0123456789,"123 Rue Example, 75000 Paris",1990-01-01,"role1,role2"
EOF

# 7. Fichier de documentation
echo "📄 Génération: README.md"
cat > README.md << 'EOF'
# Fichiers d'exemple Import/Export Personnes

## Fichiers disponibles

### Fichiers d'import
- `exemple_personnes_basique.csv` - Format standard avec tous les champs principaux
- `exemple_mailchimp.csv` - Format MailChimp (FNAME, LNAME, EMAIL, etc.)
- `exemple_google_contacts.csv` - Format Google Contacts
- `exemple_personnes.json` - Format JSON complet avec métadonnées
- `exemple_avec_erreurs.csv` - Fichier avec erreurs pour tester la validation
- `template_import.csv` - Template vide à remplir

### Instructions d'utilisation

#### Import CSV
1. Utiliser un des fichiers d'exemple ou le template
2. Dans l'app, aller dans Personnes > Import/Export > Import
3. Sélectionner le template approprié si nécessaire
4. Choisir le fichier et configurer les options
5. Lancer l'import

#### Import JSON  
1. Utiliser le fichier `exemple_personnes.json`
2. Dans l'app, sélectionner le fichier JSON
3. L'import utilisera automatiquement la structure JSON

#### Formats de dates supportés
- ISO 8601: `1990-01-01`
- Format français: `01/01/1990`
- Format avec tirets: `01-01-1990`

#### Champs supportés
- `firstName` (requis) - Prénom
- `lastName` (requis) - Nom de famille  
- `email` - Adresse email (validée si option activée)
- `phone` - Numéro de téléphone (validé si option activée)
- `address` - Adresse complète
- `birthDate` - Date de naissance
- `roles` - Rôles séparés par des virgules
- `isActive` - Statut actif/inactif (Oui/Non, true/false)

#### Validation
- Les emails sont validés par défaut
- Les téléphones sont validés par défaut  
- Les doublons d'email sont rejetés par défaut
- Les champs firstName et lastName sont obligatoires

#### Templates disponibles
- `default` - Format standard de l'application
- `mailchimp` - Compatible MailChimp (FNAME, LNAME, EMAIL, PHONE, ADDRESS)
- `google_contacts` - Compatible Google Contacts

### Conseils

1. **Encodage**: Utilisez UTF-8 pour éviter les problèmes d'accents
2. **Séparateur**: Utilisez la virgule (,) comme séparateur
3. **En-têtes**: La première ligne doit contenir les noms des colonnes
4. **Guillemets**: Utilisez des guillemets pour les champs contenant des virgules
5. **Test**: Commencez par un petit fichier de test
6. **Sauvegarde**: Exportez vos données avant un gros import

### Dépannage

- **Erreur de format**: Vérifiez l'encodage UTF-8
- **Champs non reconnus**: Utilisez le bon template ou configurez le mapping
- **Validation échouée**: Vérifiez le format des emails et téléphones
- **Doublons**: Activez l'option "Autoriser emails dupliqués" si nécessaire
EOF

echo ""
echo "✅ Génération terminée!"
echo ""
echo "📁 Fichiers créés dans: $(pwd)"
echo "📋 Fichiers disponibles:"
ls -la *.csv *.json *.md

echo ""
echo "🔗 Utilisation:"
echo "1. Copiez ces fichiers sur votre appareil"
echo "2. Dans l'app Jubilé Tabernacle:"
echo "   - Allez dans Personnes > Import/Export"
echo "   - Choisissez Import et sélectionnez un fichier"
echo "   - Configurez les options selon vos besoins"
echo "3. Pour l'export, utilisez les options disponibles dans l'interface"

echo ""
echo "✨ Prêt à tester les fonctionnalités Import/Export!"