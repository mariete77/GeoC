import os
import subprocess

# Ruta de la carpeta con los batches
batches_dir = 'scripts/batches'
files = sorted([f for f in os.listdir(batches_dir) if f.endswith('.json')])

for filename in files:
    filepath = os.path.join(batches_dir, filename)
    print(f"🚀 Importando {filename}...")
    # Comando de Firebase CLI para importar
    cmd = f"firebase firestore:import {filepath} --collection questions --project geoquiz-7790d"
    
    try:
        subprocess.run(cmd, shell=True, check=True)
        print(f"✅ {filename} importado correctamente.")
    except subprocess.CalledProcessError:
        print(f"❌ Error al importar {filename}. Continuando con el siguiente...")
