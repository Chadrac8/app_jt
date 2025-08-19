import json
import sys
from pathlib import Path

# Entrée/sortie par défaut
INPUT = Path('../assets/bible/lsg1910.json')
OUTPUT = Path('../assets/bible/lsg1910_converted.json')

def convert_bible(input_path, output_path):
    with open(input_path, encoding='utf-8') as f:
        data = json.load(f)

    # Trouver la racine des livres
    testaments = data[0]['Testaments']
    # Liste canonique des livres Louis Segond 1910
    book_names = [
        # Ancien Testament
        "Genèse", "Exode", "Lévitique", "Nombres", "Deutéronome", "Josué", "Juges", "Ruth", "1 Samuel", "2 Samuel", "1 Rois", "2 Rois", "1 Chroniques", "2 Chroniques", "Esdras", "Néhémie", "Esther", "Job", "Psaumes", "Proverbes", "Ecclésiaste", "Cantique des Cantiques", "Ésaïe", "Jérémie", "Lamentations", "Ézéchiel", "Daniel", "Osée", "Joël", "Amos", "Abdias", "Jonas", "Michée", "Nahum", "Habacuc", "Sophonie", "Aggée", "Zacharie", "Malachie",
        # Nouveau Testament
        "Matthieu", "Marc", "Luc", "Jean", "Actes", "Romains", "1 Corinthiens", "2 Corinthiens", "Galates", "Éphésiens", "Philippiens", "Colossiens", "1 Thessaloniciens", "2 Thessaloniciens", "1 Timothée", "2 Timothée", "Tite", "Philémon", "Hébreux", "Jacques", "1 Pierre", "2 Pierre", "1 Jean", "2 Jean", "3 Jean", "Jude", "Apocalypse"
    ]
    books = []
    book_idx = 0
    for testament in testaments:
        for book in testament['Books']:
            name = book_names[book_idx] if book_idx < len(book_names) else f"Livre {book_idx+1}"
            book_idx += 1
            chapters = []
            for chapter in book['Chapters']:
                verses = chapter['Verses']
                chapter_texts = [v['Text'] for v in verses if 'Text' in v]
                chapters.append(chapter_texts)
            books.append({
                'name': name,
                'chapters': chapters
            })
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(books, f, ensure_ascii=False, indent=2)
    print(f'Conversion terminée : {output_path}')

if __name__ == '__main__':
    in_path = sys.argv[1] if len(sys.argv) > 1 else INPUT
    out_path = sys.argv[2] if len(sys.argv) > 2 else OUTPUT
    convert_bible(in_path, out_path)
