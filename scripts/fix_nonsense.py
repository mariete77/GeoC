import json
import random

# Diccionarios de referencia para autocorrección
CURRENCY_MAP = {
    'Colombia': 'Peso colombiano',
    'Kuwait': 'Dinar kuwaití',
    'India': 'Rupia india',
    'Chile': 'Peso chileno',
    'Brasil': 'Real brasileño',
    'Georgia': 'Lari georgiano'
}

CAPITAL_MAP = {
    'México': 'Ciudad de México',
    'Brasil': 'Brasilia',
    'Singapur': 'Singapur'
}

def fix_nonsense():
    with open('scripts/questions_clean.json', 'r', encoding='utf-8') as f:
        questions = json.load(f)
    
    fixed_count = 0
    for q in questions:
        options = q.get('options', [])
        correct = q.get('correctAnswer', '')
        
        # Si la correcta no está, vamos a inyectarla
        if correct not in options:
            # Reemplazar una opción aleatoria (o la primera si es necesario)
            if len(options) > 0:
                idx = random.randint(0, len(options) - 1)
                options[idx] = correct
                q['options'] = options
                fixed_count += 1
            else:
                # Si no había opciones, crear un set básico
                q['options'] = [correct, "Opción Incorrecta A", "Opción Incorrecta B", "Opción Incorrecta C"]
                fixed_count += 1
        
        # Traducción rápida de Spanglish/Inglés en opciones
        q['options'] = [opt.replace('Bosnia and Herzegovina convertible mark', 'Marco convertible bosnio') for opt in q.get('options', [])]

    with open('scripts/questions_final.json', 'w', encoding='utf-8') as f:
        json.dump(questions, f, indent=2, ensure_ascii=False)
        
    print(f"✅ Corrección finalizada. {fixed_count} preguntas corregidas.")
    print("Archivo guardado como scripts/questions_final.json")

if __name__ == '__main__':
    fix_nonsense()
