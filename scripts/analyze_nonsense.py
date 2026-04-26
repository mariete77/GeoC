import json

def analyze_nonsense():
    with open('scripts/questions_clean.json', 'r', encoding='utf-8') as f:
        questions = json.load(f)
    
    suspicious = []
    for q in questions:
        options = q.get('options', [])
        correct = q.get('correctAnswer', '')
        
        # Criterios de sospecha
        # 1. Menos de 2 opciones
        # 2. Respuestas extremadamente cortas o caracteres extraños
        # 3. Opciones idénticas
        # 4. Respuesta correcta no está en las opciones (aunque ya lo validamos, verifiquemos)
        
        is_suspicious = False
        reason = ""
        
        if len(options) < 2:
            is_suspicious = True
            reason = "Menos de 2 opciones"
        elif any(len(str(opt)) < 2 for opt in options):
            is_suspicious = True
            reason = "Opción sospechosamente corta"
        elif len(set(options)) != len(options):
            is_suspicious = True
            reason = "Opciones duplicadas"
        elif correct not in options:
            is_suspicious = True
            reason = "Respuesta no está en las opciones"
            
        if is_suspicious:
            suspicious.append({'q': q, 'reason': reason})
            
    print(f"Total de preguntas sospechosas: {len(suspicious)}")
    print("\n--- MUESTRA (primeras 10) ---")
    for item in suspicious[:10]:
        print(f"ID: {item['q'].get('id')} | Razón: {item['reason']}")
        print(f"  Pregunta: {item['q'].get('questionText')}")
        print(f"  Opciones: {item['q'].get('options')}")
        print(f"  Correcta: {item['q'].get('correctAnswer')}")
        print("-" * 30)

if __name__ == '__main__':
    analyze_nonsense()
