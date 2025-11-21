# Optimisations Build Flutter

## 1. Réduire la Taille de l'APK/IPA

### android/app/build.gradle
```gradle
android {
    // ... existing config
    
    buildTypes {
        release {
            // Enable ProGuard/R8 shrinking et obfuscation
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            
            // Split APKs par architecture
            ndk {
                abiFilters 'armeabi-v7a', 'arm64-v8a'
            }
        }
    }
    
    // Split APKs pour réduire taille
    splits {
        abi {
            enable true
            reset()
            include 'armeabi-v7a', 'arm64-v8a', 'x86_64'
            universalApk false
        }
    }
}
```

### android/app/proguard-rules.pro
```pro
# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Models
-keep class ** extends com.google.gson.TypeAdapter
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}
```

## 2. Optimiser les Assets

### pubspec.yaml
```yaml
flutter:
  assets:
    # Utiliser formats compressés
    - assets/images/   # Convertir en WebP
    - assets/bible/    # Compresser JSON avec gzip
    
  fonts:
    # Subset fonts (seulement caractères utilisés)
    - family: Poppins
      fonts:
        - asset: fonts/Poppins-Regular.ttf
        - asset: fonts/Poppins-Bold.ttf
          weight: 700
```

### Script de compression des assets
```bash
#!/bin/bash
# compress_assets.sh

# Compresser images PNG → WebP
for img in assets/images/*.png; do
    cwebp -q 80 "$img" -o "${img%.png}.webp"
done

# Compresser JSON
for json in assets/bible/*.json; do
    gzip -9 "$json"
done

echo "✅ Assets optimisés"
```

## 3. Compiler en Mode Release avec Optimisations

### Commandes build optimisées
```bash
# Android APK optimisé
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols

# Android App Bundle (Google Play)
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols

# iOS optimisé
flutter build ios --release --obfuscate --split-debug-info=build/ios/symbols
```

## 4. Analyser la Taille

```bash
# Analyser taille de l'app
flutter build apk --analyze-size

# Analyser dépendances
flutter pub deps --style=compact

# Trouver packages lourds
flutter pub deps --style=tree | grep -A 5 "dependencies:"
```

## 5. Tree Shaking

Déjà activé par défaut en release, mais vérifier:
```yaml
# flutter.yaml
targets:
  $default:
    builders:
      flutter_tools|localization:
        options:
          tree-shake-icons: true
```

## 6. Optimisations Dart

### dart2js options (Web)
```bash
flutter build web --release --dart2js-optimization=O4
```

## Impact Attendu

- **Taille APK**: -40% à -60%
- **Taille IPA**: -30% à -50%
- **Temps chargement**: -25%
- **Mémoire runtime**: -15%

## Notes

1. **ProGuard/R8**: Réduction code mort + obfuscation
2. **Split APKs**: Fichiers plus petits par architecture
3. **WebP**: 30% plus petit que PNG/JPEG
4. **Font subsetting**: Seulement caractères utilisés
5. **JSON gzip**: -70% taille fichiers Bible
