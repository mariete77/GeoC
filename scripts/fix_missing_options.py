import json
import random

def fix_missing_options():
    with open('scripts/questions_clean.json', 'r', encoding='utf-8') as f:
        questions = json.load(f)
        
    # Obtener lista maestra de países para rellenar opciones
    all_countries = list(set([q['correctAnswer'] for q in questions if q.get('correctAnswer')]))
    
    fixed_count = 0
    for q in questions:
        if not q.get('options') or len(q['options']) < 2:
            correct = q.get('correctAnswer')
            if correct:
                # Elegir 3 distractores aleatorios
                distractors = random.sample([c for c in all_countries if c != correct], min(3, len(all_countries)-1))
                new_options = distractors + [correct]
                random.shuffle(new_options)
                q['options'] = new_options
                fixed_count += 1
                
    with open('scripts/questions_fixed_options.json', 'w', encoding='utf-8') as f:
        json.dump(questions, f, indent=2, ensure_ascii=False)
        
    print(f"✅ Se han rellenado las opciones de {fixed_count} preguntas.")

if __name__ == '__main__':
    fix_missing_options()
