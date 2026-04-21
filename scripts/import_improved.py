"""
🔥 Script de Importación Mejorado para Firestore

Características:
- Validación de datos antes de importar
- Reintentos automáticos con backoff exponencial
- Manejo de token expirado
- Progreso visual detallado
- Modo dry-run para pruebas
- Filtrado por tipo/dificultad
- Resumen estadístico final
- Continuar donde se quedó
- Validación de estructura

Uso:
  python3 scripts/import_improved.py [opciones]

Opciones:
  --file=archivo.json          Archivo de preguntas (default: questions_all_merged.json)
  --dry-run                     Simular importación sin enviar a Firestore
  --filter-type=tipo            Filtrar por tipo (ej: flag,capital,currency)
  --filter-difficulty=dificultad Filtrar por dificultad (ej: easy,medium,hard)
  --resume                      Continuar donde se quedó
  --batch-size=100              Tamaño del batch (default: 100)
"""

import json
import urllib.request
import sys
import time
import os
import pathlib
import argparse
from typing import List, Dict, Optional, Set
from datetime import datetime
import math

# ========================================
# 🔧 CONFIGURACIÓN
# ========================================

PROJECT_ID = "geoquiz-7790d"
BASE = f"projects/{PROJECT_ID}/databases/(default)/documents/questions"
DEFAULT_BATCH_SIZE = 100
MAX_RETRIES = 3
BASE_DELAY = 2  # segundos
STATUS_FILE = "scripts/import_status.json"

# Campos obligatorios
REQUIRED_FIELDS = ['id', 'type', 'questionText', 'correctAnswer', 'options']

# ========================================
# 🔧 FUNCIONES DE UTILIDAD
# ========================================

def log(message: str, level: str = 'INFO'):
    """Log con timestamp"""
    timestamp = datetime.now().strftime('%H:%M:%S')
    print(f"[{timestamp}] [{level}] {message}")

def get_access_token() -> Optional[str]:
    """Lee el token de acceso desde Firebase CLI"""
    cred_path = pathlib.Path.home() / ".config" / "configstore" / "firebase-tools.json"
    if cred_path.exists():
        with open(cred_path, "r", encoding="utf-8") as f:
            data = json.load(f)
            return data.get("tokens", {}).get("access_token")
    return None

def field(v):
    """Convierte valores a formato Firestore"""
    if isinstance(v, str):
        return {"stringValue": v}
    elif isinstance(v, bool):
        return {"booleanValue": v}
    elif isinstance(v, int):
        return {"integerValue": str(v)}
    elif isinstance(v, float):
        return {"doubleValue": v}
    elif isinstance(v, dict):
        return {"mapValue": {"fields": {k: field(val) for k, val in v.items()}}}
    elif isinstance(v, list):
        return {"arrayValue": {"values": [field(item) for item in v]}}
    elif v is None:
        return {"nullValue": "NULL_VALUE"}
    return {"stringValue": str(v)}

def validate_question(q: Dict) -> tuple[bool, List[str]]:
    """Valida que una pregunta tenga todos los campos correctos"""
    errors = []
    
    # Verificar campos obligatorios
    for field in REQUIRED_FIELDS:
        if field not in q:
            errors.append(f"Falta campo obligatorio: {field}")
    
    # Validar que la respuesta correcta esté en las opciones
    if 'correctAnswer' in q and 'options' in q:
        correct = q['correctAnswer']
        options = q['options']
        
        if not isinstance(options, list):
            errors.append("options debe ser un array")
        elif len(options) < 2:
            errors.append("options debe tener al menos 2 elementos")
        elif correct not in options:
            errors.append(f"La respuesta correcta '{correct}' no está en las opciones: {options}")
    
    # Validar tipos específicos
    qtype = q.get('type', '')
    
    if qtype == 'flag':
        if not q.get('imageUrl'):
            errors.append(f"Tipo 'flag' requiere imageUrl")
    
    if qtype in ['population', 'area']:
        if not q.get('extraData', {}).get('infoToShow'):
            errors.append(f"Tipo '{qtype}' requiere infoToShow en extraData")
    
    return len(errors) == 0, errors

def filter_questions(questions: List[Dict], filter_type: Optional[str], filter_difficulty: Optional[str]) -> List[Dict]:
    """Filtra preguntas por tipo y/o dificultad"""
    if not filter_type and not filter_difficulty:
        return questions
    
    filtered = []
    
    for q in questions:
        if filter_type and q.get('type') != filter_type:
            continue
        if filter_difficulty and q.get('difficulty') != filter_difficulty:
            continue
        filtered.append(q)
    
    return filtered

def load_status() -> Dict:
    """Carga el estado de la importación anterior"""
    if os.path.exists(STATUS_FILE):
        with open(STATUS_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {
        'total_questions': 0,
        'imported_questions': 0,
        'failed_batches': [],
        'last_batch': 0
    }

def save_status(status: Dict):
    """Guarda el estado de la importación"""
    with open(STATUS_FILE, 'w', encoding='utf-8') as f:
        json.dump(status, f, indent=2)

def show_progress(current: int, total: int, width: int = 50):
    """Muestra barra de progreso"""
    if total == 0:
        return
    
    percent = (current / total) * 100
    filled = int(width * percent / 100)
    bar = '█' * filled + '░' * (width - filled)
    print(f"\rProgreso: [{bar}] {percent:.1f}% ({current}/{total})", end='', flush=True)

def batch_write_with_retry(
    writes: List[Dict],
    access_token: str,
    batch_num: int,
    retry_count: int = 0
) -> bool:
    """Escribe un batch a Firestore con reintentos automáticos"""
    
    body = json.dumps({"writes": writes}).encode("utf-8")
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents:batchWrite"
    
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {access_token}",
    }
    
    req = urllib.request.Request(url, data=body, headers=headers, method="POST")
    
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            result = json.loads(resp.read().decode())
            return True, None
    except urllib.error.HTTPError as e:
        error_msg = str(e)
        
        # Token expirado (401)
        if e.code == 401:
            log("Token expirado. Refrescando...", 'WARN')
            new_token = get_access_token()
            if new_token:
                return batch_write_with_retry(writes, new_token, batch_num, retry_count + 1)
        
        # Rate limit (429)
        if e.code == 429:
            delay = BASE_DELAY * (2 ** retry_count)
            log(f"Rate limit. Esperando {delay}s antes de reintentar...", 'WARN')
            time.sleep(delay)
            return batch_write_with_retry(writes, access_token, batch_num, retry_count + 1)
        
        # Error de servidor (5xx)
        if e.code >= 500:
            delay = BASE_DELAY * (2 ** retry_count)
            log(f"Error de servidor ({e.code}). Reintentando en {delay}s...", 'WARN')
            time.sleep(delay)
            if retry_count < MAX_RETRIES:
                return batch_write_with_retry(writes, access_token, batch_num, retry_count + 1)
        
        return False, error_msg
    except urllib.error.URLError as e:
        error_msg = str(e)
        delay = BASE_DELAY * (2 ** retry_count)
        log(f"Error de red: {error_msg}. Reintentando en {delay}s...", 'WARN')
        time.sleep(delay)
        if retry_count < MAX_RETRIES:
            return batch_write_with_retry(writes, access_token, batch_num, retry_count + 1)
        
        return False, error_msg
    except Exception as e:
        error_msg = str(e)
        log(f"Error inesperado: {error_msg}", 'ERROR')
        return False, error_msg

# ========================================
# 🔥 FUNCIÓN PRINCIPAL
# ========================================

def main():
    parser = argparse.ArgumentParser(description='Importador mejorado de preguntas a Firestore')
    parser.add_argument('--file', default='scripts/questions_all_merged.json',
                       help='Archivo de preguntas')
    parser.add_argument('--dry-run', action='store_true',
                       help='Simular importación sin enviar a Firestore')
    parser.add_argument('--filter-type', help='Filtrar por tipo')
    parser.add_argument('--filter-difficulty', help='Filtrar por dificultad')
    parser.add_argument('--resume', action='store_true',
                       help='Continuar donde se quedó')
    parser.add_argument('--batch-size', type=int, default=DEFAULT_BATCH_SIZE,
                       help='Tamaño del batch')
    
    args = parser.parse_args()
    
    # ========================================
    # 📊 ANÁLISIS PREVIO
    # ========================================
    
    log('🔥 Importador Mejorado de Preguntas a Firestore\n')
    log(f"📂 Archivo: {args.file}")
    
    # Obtener token (solo si no es dry-run)
    access_token = None
    if not args.dry_run:
        access_token = get_access_token()
        if not access_token:
            log("❌ No se encontró token de Firebase. Ejecuta 'firebase login' primero.", 'ERROR')
            sys.exit(1)
        log("✅ Token OAuth obtenido de Firebase CLI\n")
    
    # Cargar preguntas
    try:
        with open(args.file, 'r', encoding='utf-8') as f:
            questions = json.load(f)
        log(f"✅ {len(questions)} preguntas cargadas de {args.file}\n")
    except Exception as e:
        log(f"❌ Error cargando archivo: {e}", 'ERROR')
        sys.exit(1)
    
    # ========================================
    # 🔍 VALIDACIÓN
    # ========================================
    
    log('🔍 Validando preguntas...')
    
    invalid_questions = []
    valid_questions = []
    
    for i, q in enumerate(questions, 1):
        is_valid, errors = validate_question(q)
        
        if not is_valid:
            invalid_questions.append({
                'index': i,
                'id': q.get('id', 'unknown'),
                'errors': errors
            })
        else:
            valid_questions.append(q)
    
    if invalid_questions:
        log(f"⚠️  {len(invalid_questions)} preguntas inválidas encontradas\n", 'WARN')
        for q in invalid_questions[:10]:
            log(f"   • ID: {q['id']}", 'WARN')
            for error in q['errors']:
                log(f"     - {error}", 'WARN')
        
        if len(invalid_questions) > 10:
            log(f"\n   ... y {len(invalid_questions) - 10} más", 'WARN')
        
        # Preguntar si continuar
        if not args.dry_run:
            confirm = input("\n❓ ¿Continuar importando solo las válidas? (s/n): ")
            if confirm.lower() != 's':
                log("❌ Importación cancelada", 'INFO')
                sys.exit(0)
    else:
        log(f"✅ Todas las preguntas son válidas\n")
    
    log(f"📊 {len(valid_questions)} preguntas válidas para importar\n")
    
    # ========================================
    # 🔍 FILTRADO
    # ========================================
    
    filtered_questions = filter_questions(valid_questions, args.filter_type, args.filter_difficulty)
    
    if args.filter_type or args.filter_difficulty:
        log(f"🔍 Filtrado:")
        if args.filter_type:
            log(f"   • Tipo: {args.filter_type}")
        if args.filter_difficulty:
            log(f"   • Dificultad: {args.filter_difficulty}")
        log(f"   Resultado: {len(filtered_questions)} preguntas\n")
    else:
        filtered_questions = valid_questions
    
    # ========================================
    # 🎯 DISTRIBUCIÓN
    # ========================================
    
    type_counts = {}
    difficulty_counts = {}
    
    for q in filtered_questions:
        qtype = q.get('type', '')
        difficulty = q.get('difficulty', 'unknown')
        
        type_counts[qtype] = type_counts.get(qtype, 0) + 1
        difficulty_counts[difficulty] = difficulty_counts.get(difficulty, 0) + 1
    
    log("📊 Distribución por tipo:")
    for qtype, count in sorted(type_counts.items(), key=lambda x: -x[1]):
        pct = (count / len(filtered_questions) * 100) if filtered_questions else 0
        log(f"   • {qtype}: {count} ({pct:.1f}%)")
    
    log("\n📊 Distribución por dificultad:")
    for diff, count in sorted(difficulty_counts.items(), key=lambda x: -x[1]):
        pct = (count / len(filtered_questions) * 100) if filtered_questions else 0
        log(f"   • {diff}: {count} ({pct:.1f}%)")
    
    # ========================================
    # 📈 IMPORTACIÓN
    # ========================================
    
    if args.dry_run:
        log("\n🔍 MODO DRY-RUN: Simulación sin enviar a Firestore")
        log(f"✅ {len(filtered_questions)} preguntas listas para importar")
        log("🚀 Ejecuta sin --dry-run para importar realmente\n")
        return
    
    log("📈 Iniciando importación...\n")
    
    # Cargar estado anterior si se solicita continuar
    if args.resume:
        status = load_status()
    else:
        status = {
            'total_questions': len(filtered_questions),
            'imported_questions': 0,
            'failed_batches': [],
            'last_batch': 0
        }
    
    # Determinar desde dónde empezar
    start_batch = status['last_batch']
    if start_batch > 0:
        log(f"📂 Continuando desde el batch {start_batch}")
        log(f"   Importados anteriormente: {status['imported_questions']}\n")
    
    # Dividir en batches
    batch_size = args.batch_size
    total_batches = math.ceil(len(filtered_questions) / batch_size)
    
    # Dividir preguntas en batches
    all_batches = []
    for i in range(0, len(filtered_questions), batch_size):
        batch_num = i // batch_size
        if batch_num < start_batch:
            continue  # Saltar batches ya procesados
        all_batches.append((batch_num + 1, filtered_questions[i:i+batch_size]))
    
    log(f"📦 Procesando {len(all_batches)} batches (tamaño: {batch_size})\n")
    
    # Procesar cada batch
    total_imported = status['imported_questions']
    failed_batches = status['failed_batches']
    
    for batch_num, batch in all_batches:
        # Crear writes
        writes = []
        for q in batch:
            doc_id = q["id"]
            fields = {k: field(v) for k, v in q.items()}
            writes.append({"update": {"name": f"{BASE}/{doc_id}", "fields": fields}})
        
        # Escribir con reintentos
        success, error = batch_write_with_retry(writes, access_token, batch_num)
        
        if success:
            total_imported += len(batch)
            status['last_batch'] = batch_num
            status['imported_questions'] = total_imported
            save_status(status)
            
            show_progress(total_imported, len(filtered_questions))
            log(f"✅ Batch {batch_num}/{len(all_batches)}: {len(batch)} preguntas importadas")
        else:
            log(f"❌ Batch {batch_num}/{len(all_batches)}: {error}", 'ERROR')
            failed_batches.append({
                'batch': batch_num,
                'error': error
            })
            status['failed_batches'] = failed_batches
            save_status(status)
            
            # No detener la importación por un batch fallido
            log("   ⚠️  Continuando con el siguiente batch...", 'WARN')
        
        # Rate limit entre batches
        if batch_num < len(all_batches):
            time.sleep(0.5)
    
    print()  # Nueva línea después de la barra de progreso
    
    # ========================================
    # 📊 RESUMEN
    # ========================================
    
    log("\n" + "="*60)
    log("📊 RESUMEN DE IMPORTACIÓN")
    log("="*60)
    
    log(f"✅ Preguntas importadas: {total_imported}")
    log(f"📦 Batches procesados: {len(all_batches)}")
    log(f"❌ Batches fallidos: {len(failed_batches)}")
    
    if failed_batches:
        log(f"\n⚠️  Batches fallidos:\n")
        for fb in failed_batches:
            log(f"   • Batch {fb['batch']}: {fb['error']}")
    
    # Guardar estado final
    save_status(status)
    
    log(f"\n📄 Estado guardado en: {STATUS_FILE}")
    log("\n🎉 ¡Importación completada!")
    
    # Estadísticas por tipo
    log("\n📊 Estadísticas finales por tipo:")
    for qtype, count in sorted(type_counts.items(), key=lambda x: -x[1]):
        pct = (count / total_imported * 100) if total_imported > 0 else 0
        log(f"   • {qtype}: {count} ({pct:.1f}%)")

if __name__ == '__main__':
    main()
