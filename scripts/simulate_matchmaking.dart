import 'dart:async';

void simulateMatchmaking() {
  int timeElapsed = 0;
  int searchRange = 100;

  print("🚀 Iniciando simulación de Matchmaking...");

  Timer.periodic(Duration(seconds: 3), (timer) {
    timeElapsed += 3;
    
    // Lógica copiada de nuestro nuevo matchmaking
    if (timeElapsed >= 15) {
      searchRange = 2000;
    } else if (timeElapsed >= 8) {
      searchRange = 300;
    } else {
      searchRange = 150;
    }

    print("⏳ Tiempo: ${timeElapsed}s | Buscando oponentes en rango: ±$searchRange ELO");

    if (timeElapsed >= 30) {
      print("🛑 Tiempo límite alcanzado. Fallback a GhostRun.");
      timer.cancel();
    }
  });
}

void main() => simulateMatchmaking();
