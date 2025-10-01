# 🌐 Hébergement de la Politique de Confidentialité

## GitHub Pages - Configuration

### **URL de votre Politique de Confidentialité :**
```
https://chadrac8.github.io/app_jt/
```

### **Configuration GitHub Pages :**

1. **Allez sur GitHub.com** → Votre repository `app_jt`
2. **Settings** → **Pages** (dans la barre latérale)
3. **Source** : Sélectionnez `Deploy from a branch`
4. **Branch** : Sélectionnez `main`
5. **Folder** : Sélectionnez `/docs`
6. **Save**

### **Activation automatique :**
- GitHub générera automatiquement votre site
- Délai : 5-10 minutes après activation
- URL finale : `https://chadrac8.github.io/app_jt/`

### **Vérification :**
- Une fois activé, votre politique sera accessible publiquement
- Format professionnel avec votre design actuel
- Mise à jour automatique à chaque push

---

## Alternative : Firebase Hosting

Si vous préférez utiliser Firebase :

### **Commandes d'installation :**
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
# Sélectionner le dossier 'docs' comme public directory
firebase deploy
```

### **URL Firebase :**
`https://votre-projet-firebase.web.app`

---

## Mise à jour de la Politique

Pour modifier la politique :
1. **Éditez** `privacy_policy.html`
2. **Copiez** vers `docs/index.html`
3. **Commit et push** vers GitHub
4. **Mise à jour automatique** sur le site

---

## Pour l'App Store

**Lien à utiliser dans App Store Connect :**
```
https://chadrac8.github.io/app_jt/
```

Ce lien sera :
✅ Accessible publiquement
✅ Professionnel et sécurisé (HTTPS)
✅ Mis à jour automatiquement
✅ Conforme aux exigences Apple