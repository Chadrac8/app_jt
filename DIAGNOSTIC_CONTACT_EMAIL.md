# Diagnostic de la fonction email de contact

## 🔍 État actuel

✅ **Fonction déployée** : `onContactMessageCreated` est active  
✅ **Code de logs** : La fonction log les détails quand elle se déclenche  
⏳ **En attente** : Test depuis l'application  

## 🧪 Pour tester la fonction

### 1. Envoyer un message depuis l'app
1. Ouvrez l'application Jubilé Tabernacle
2. Allez dans "Nous contacter" 
3. Remplissez le formulaire de contact
4. Cliquez sur "Envoyer un message"

### 2. Vérifier les logs
```bash
firebase functions:log --only onContactMessageCreated
```

### 3. Ce que vous devriez voir
Si la fonction fonctionne, vous verrez dans les logs :
```
✅ Nouveau message de contact reçu: [ID]
📧 Email qui serait envoyé:
To: contact@jubiletabernacle.org
Subject: [Sujet du message]
From: [Nom] ([Email])
Message: [Contenu]
✅ Message de contact traité avec succès
```

## 🛠️ Prochaines étapes

### Si les logs s'affichent :
✅ La fonction fonctionne → Configurer l'envoi d'email réel

### Si aucun log :
❌ Problème de déclenchement → Vérifier la collection Firebase

## 📧 Activation de l'email réel

Une fois confirmé que la fonction se déclenche :

1. **Activer Secret Manager API** :
   ```bash
   gcloud services enable secretmanager.googleapis.com --project=hjye25u8iwm0i0zls78urffsc0jcgj
   ```

2. **Configurer le secret email** :
   ```bash
   ./configure_email.sh
   ```

3. **Déployer la version complète** :
   ```bash
   firebase deploy --only functions:onContactMessageCreated
   ```

## 📋 Diagnostic rapide

Exécutez ces commandes pour vérifier l'état :

```bash
# Vérifier que la fonction existe
firebase functions:list | grep onContactMessageCreated

# Voir les logs récents  
firebase functions:log --only onContactMessageCreated

# Tester depuis l'app puis vérifier immédiatement
firebase functions:log --only onContactMessageCreated | tail -20
```

---

**📞 Test maintenant** : Envoyez un message depuis l'application et vérifiez les logs !
