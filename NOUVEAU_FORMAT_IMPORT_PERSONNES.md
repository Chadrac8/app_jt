# 📊 Nouveau Format d'Import des Personnes

## ✅ FORMAT STANDARDISÉ IMPLÉMENTÉ

**Le système d'import prend maintenant en charge le format standardisé suivant :**

```
firstName	lastName	email	phone	country	birthDate	gender	maritalStatus	address	additionalAddress	zipCode	city
```

## 🚀 CHAMPS SUPPORTÉS

### **📋 CHAMPS OBLIGATOIRES :**
- **`firstName`** - Prénom de la personne
- **`lastName`** - Nom de famille de la personne

### **📋 CHAMPS OPTIONNELS :**
- **`email`** - Adresse email
- **`phone`** - Numéro de téléphone (formatage automatique)
- **`country`** - Pays (normalisation automatique)
- **`birthDate`** - Date de naissance (formats multiples supportés)
- **`gender`** - Genre (normalisation automatique)
- **`maritalStatus`** - Statut marital (normalisation automatique)
- **`address`** - Adresse principale
- **`additionalAddress`** - Adresse complémentaire (appartement, étage, etc.)
- **`zipCode`** - Code postal (formatage automatique)
- **`city`** - Ville (capitalisation automatique)

## 🔧 TRAITEMENTS INTELLIGENTS

### **🌍 Pays (`country`) :**
```
"france" → "France"
"usa" → "États-Unis"
"germany" → "Allemagne"
"uk" → "Royaume-Uni"
```

### **👥 Genre (`gender`) :**
```
"m" → "Masculin"
"f" → "Féminin"
"male" → "Masculin"
"female" → "Féminin"
"homme" → "Masculin"
"femme" → "Féminin"
```

### **💍 Statut Marital (`maritalStatus`) :**
```
"marie" → "Marié(e)"
"married" → "Marié(e)"
"single" → "Célibataire"
"celibataire" → "Célibataire"
"divorced" → "Divorcé(e)"
"veuf" → "Veuf(ve)"
"widow" → "Veuf(ve)"
```

### **📮 Code Postal (`zipCode`) :**
```
"1234" → "01234" (complément automatique)
"12345" → "12345" (format correct)
"12-345" → "12345" (nettoyage automatique)
```

### **🏙️ Ville (`city`) :**
```
"paris" → "Paris"
"saint-denis" → "Saint-Denis"
"aix-en-provence" → "Aix-en-Provence"
"le havre" → "Le Havre"
```

### **📱 Téléphone (`phone`) :**
```
"0123456789" → "01 23 45 67 89"
"+33123456789" → "+33 1 23 45 67 89"
"01.23.45.67.89" → "01 23 45 67 89"
```

### **📅 Date de Naissance (`birthDate`) :**
```
"15/03/1980" → 1980-03-15
"1980-03-15" → 1980-03-15
"15-03-1980" → 1980-03-15
"15-03-80" → 1980-03-15 (année intelligente)
```

## 📝 EXEMPLE DE FICHIER

### **CSV/Excel :**
```csv
firstName,lastName,email,phone,country,birthDate,gender,maritalStatus,address,additionalAddress,zipCode,city
Jean,Dupont,jean.dupont@email.com,0123456789,france,15/03/1980,M,marie,123 rue de la Paix,Apt 4B,75001,paris
Marie,Martin,marie.martin@test.fr,0678901234,France,22/07/1975,female,single,456 Avenue des Champs,,75008,Paris
Pierre,Bernard,p.bernard@mail.com,+33145678901,USA,10-12-1985,homme,celibataire,789 Boulevard Saint-Germain,Étage 2,75006,PARIS
```

### **Résultat après traitement :**
```json
[
  {
    "firstName": "Jean",
    "lastName": "Dupont",
    "email": "jean.dupont@email.com",
    "phone": "01 23 45 67 89",
    "country": "France",
    "birthDate": "1980-03-15",
    "gender": "Masculin",
    "maritalStatus": "Marié(e)",
    "address": "123 rue de la Paix",
    "additionalAddress": "Apt 4B",
    "zipCode": "75001",
    "city": "Paris"
  },
  {
    "firstName": "Marie",
    "lastName": "Martin",
    "email": "marie.martin@test.fr",
    "phone": "06 78 90 12 34",
    "country": "France",
    "birthDate": "1975-07-22",
    "gender": "Féminin",
    "maritalStatus": "Célibataire",
    "address": "456 Avenue des Champs",
    "zipCode": "75008",
    "city": "Paris"
  },
  {
    "firstName": "Pierre",
    "lastName": "Bernard",
    "email": "p.bernard@mail.com",
    "phone": "+33 1 45 67 89 01",
    "country": "États-Unis",
    "birthDate": "1985-12-10",
    "gender": "Masculin",
    "maritalStatus": "Célibataire",
    "address": "789 Boulevard Saint-Germain",
    "additionalAddress": "Étage 2",
    "zipCode": "75006",
    "city": "Paris"
  }
]
```

## 🔍 DÉTECTION AUTOMATIQUE

### **Variations reconnues :**

| Champ Standard | Variations Détectées |
|----------------|---------------------|
| **firstName** | prénom, prenom, firstname, first_name, fname, givenname |
| **lastName** | nom, lastname, last_name, surname, family_name |
| **email** | email, e-mail, mail, courriel, adresse_email |
| **phone** | telephone, téléphone, phone, tel, mobile, portable |
| **country** | country, pays, nation, nationalité, origine |
| **birthDate** | naissance, date_naissance, birthdate, dob, birthday |
| **gender** | genre, gender, sexe, masculin, feminin |
| **maritalStatus** | maritalstatus, statut_marital, etat_civil, marie |
| **address** | adresse, address, rue, street, domicile |
| **additionalAddress** | additionaladdress, adresse_complementaire, apt |
| **zipCode** | zipcode, zip_code, code_postal, postal_code, cp |
| **city** | city, ville, town, commune, locality |

## 🎯 UTILISATION

### **1. Format de votre fichier :**
Utilisez le format exact : `firstName	lastName	email	phone	country	birthDate	gender	maritalStatus	address	additionalAddress	zipCode	city`

### **2. Import :**
1. Aller dans **Personnes → Import/Export**
2. Onglet **"Import"** 
3. Sélectionner votre fichier (.csv, .xlsx, .xls, .json)
4. Le système reconnaît automatiquement le format !

### **3. Résultat :**
- ✅ **Détection automatique** des colonnes
- ✅ **Normalisation intelligente** des données
- ✅ **Validation** et nettoyage
- ✅ **Messages d'erreur** détaillés si problème

## 🎉 AVANTAGES

### **Pour les utilisateurs :**
- ✅ **Format standardisé** facile à créer
- ✅ **Traitement intelligent** des données
- ✅ **Compatibilité totale** avec Excel/Google Sheets
- ✅ **Robustesse** face aux erreurs de saisie

### **Pour les administrateurs :**
- ✅ **Import en masse** simplifié
- ✅ **Données normalisées** automatiquement
- ✅ **Qualité des données** assurée
- ✅ **Gain de temps** considérable

**Le système reconnaît maintenant parfaitement votre format standardisé !** 🚀