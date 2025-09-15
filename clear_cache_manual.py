#!/usr/bin/env python3
"""
Script pour nettoyer manuellement le cache du pain quotidien
Utilisé lorsque Flutter ne fonctionne pas correctement
"""

import os
import glob

def find_shared_preferences_files():
    """Trouve tous les fichiers SharedPreferences sur macOS"""
    
    # Chemins typiques pour SharedPreferences sur macOS
    possible_paths = [
        os.path.expanduser("~/Library/Preferences/app_jubile_tabernacle/shared_preferences/"),
        os.path.expanduser("~/Library/Application Support/app_jubile_tabernacle/shared_preferences/"),
        os.path.expanduser("~/Library/Containers/*/Data/Library/Preferences/shared_preferences/"),
        # Chrome storage pour Flutter web
        os.path.expanduser("~/Library/Application Support/Google/Chrome/Default/Local Storage/"),
        os.path.expanduser("~/Library/Application Support/Google/Chrome/Profile*/Local Storage/"),
        # Firefox storage
        os.path.expanduser("~/Library/Application Support/Firefox/Profiles/*/storage/default/"),
    ]
    
    found_files = []
    
    for path_pattern in possible_paths:
        try:
            # Expand wildcards
            paths = glob.glob(path_pattern)
            for path in paths:
                if os.path.isdir(path):
                    # Chercher les fichiers de cache Branham
                    for root, dirs, files in os.walk(path):
                        for file in files:
                            if any(keyword in file.lower() for keyword in ['branham', 'quote', 'pain', 'quotidien']):
                                found_files.append(os.path.join(root, file))
                elif os.path.isfile(path):
                    if any(keyword in path.lower() for keyword in ['branham', 'quote', 'pain', 'quotidien']):
                        found_files.append(path)
        except Exception as e:
            print(f"Erreur lors de la recherche dans {path_pattern}: {e}")
    
    return found_files

def clear_browser_storage():
    """Instructions pour nettoyer le stockage du navigateur manuellement"""
    print("\n=== NETTOYAGE MANUEL DU CACHE ===")
    print("\nPour Chrome:")
    print("1. Ouvrez Chrome")
    print("2. Allez sur localhost:8080")
    print("3. F12 > Application > Storage > Local Storage")
    print("4. Supprimez les clés contenant 'branham_quote_cache_v2' et 'branham_last_update_v2'")
    
    print("\nPour Safari:")
    print("1. Safari > Develop > Show Web Inspector")
    print("2. Onglet Storage > Local Storage")
    print("3. Supprimez les clés Branham")
    
    print("\nPour Firefox:")
    print("1. F12 > Storage > Local Storage")
    print("2. Supprimez les clés Branham")

def main():
    print("🔍 Recherche des fichiers de cache...")
    
    cache_files = find_shared_preferences_files()
    
    if cache_files:
        print(f"\n✅ Trouvé {len(cache_files)} fichier(s) de cache:")
        for file in cache_files:
            print(f"  - {file}")
        
        print("\n⚠️  Pour supprimer ces fichiers:")
        for file in cache_files:
            print(f"rm -f '{file}'")
    else:
        print("\n❌ Aucun fichier de cache trouvé dans les emplacements standards")
    
    # Instructions pour le navigateur
    clear_browser_storage()
    
    print("\n=== INSTRUCTIONS SUPPLÉMENTAIRES ===")
    print("1. Redémarrez l'application Flutter")
    print("2. Ou rafraîchissez la page web (Cmd+R)")
    print("3. Le nouveau contenu avec encodage corrigé devrait s'afficher")

if __name__ == "__main__":
    main()
