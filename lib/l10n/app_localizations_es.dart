// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class SEs extends S {
  SEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'GeoQuiz Battle';

  @override
  String get loading => 'Cargando...';

  @override
  String get retry => 'Reintentar';

  @override
  String get goHome => 'Ir al Inicio';

  @override
  String get pageNotFound => 'Página no encontrada';

  @override
  String get explorer => 'EXPLORADOR';

  @override
  String streak(int count) {
    return 'Streak: $count';
  }

  @override
  String get globalRanking => 'CLASIFICACIÓN GLOBAL';

  @override
  String get eloScore => 'Puntuación ELO';

  @override
  String get quickPlay => 'Partida Rápida';

  @override
  String get quickPlayDesc => 'Salta a una partida casual instantánea.';

  @override
  String get ranked => 'Clasificatoria';

  @override
  String get rankedDesc => 'Compite por ELO y sube en el ranking global.';

  @override
  String get multiplayer => 'Multijugador';

  @override
  String get multiplayerDesc => 'Enfréntate a otros jugadores en tiempo real.';

  @override
  String get ghostRun => 'Fantasma';

  @override
  String get ghostRunDesc => 'Practica contra las mejores partidas pasadas.';

  @override
  String get leaderboard => 'Clasificación';

  @override
  String get leaderboardDesc =>
      'Mira tu posición respecto a los demás jugadores.';

  @override
  String get leaderboardLoading => 'Cargando clasificación...';

  @override
  String get leaderboardError => 'Error al cargar clasificación';

  @override
  String get noPlayers => 'No hay jugadores todavía';

  @override
  String get yourPosition => 'TU POSICIÓN';

  @override
  String get elo => 'ELO';

  @override
  String get you => 'Tú';

  @override
  String get history => 'Historial';

  @override
  String get matchHistory => 'Historial de Partidas';

  @override
  String get matchHistoryDesc => 'Revisa el resumen de tus batallas pasadas.';

  @override
  String get seeAll => 'Ver todo';

  @override
  String get noMatchesYet => 'Sin partidas aún';

  @override
  String get noMatchesHint => 'Juega tu primera partida para ver tu historial.';

  @override
  String get victories => 'Victorias';

  @override
  String get defeats => 'Derrotas';

  @override
  String get winRate => 'Win Rate';

  @override
  String get eloChange => 'ELO';

  @override
  String get victory => '¡Victoria!';

  @override
  String get defeat => 'Derrota';

  @override
  String get draw => 'Empate';

  @override
  String get matchHistoryTitle => 'Historial de Partidas';

  @override
  String get all => 'Todos';

  @override
  String get casual => 'Casual';

  @override
  String get rankedFilter => 'Clasificatoria';

  @override
  String get youVs => 'Tú vs';

  @override
  String get eloChangeLabel => 'ELO';

  @override
  String get noMatchesFilter => 'No hay partidas con este filtro';

  @override
  String get quickActions => 'Acciones rápidas';

  @override
  String get matchmakingTitle => 'Buscando partida...';

  @override
  String get matchmakingSearching => 'Buscando oponente...';

  @override
  String get matchmakingCancel => 'Cancelar';

  @override
  String get matchmakingFound => '¡Oponente encontrado!';

  @override
  String get loginWelcome => 'Bienvenido a GeoC';

  @override
  String get loginSubtitle => 'Demuestra tus conocimientos de geografía';

  @override
  String get loginGoogle => 'Iniciar sesión con Google';

  @override
  String get loginApple => 'Iniciar sesión con Apple';

  @override
  String get loginAnonymous => 'Continuar sin cuenta';

  @override
  String get gameNext => 'Siguiente';

  @override
  String get gameFinish => 'Finalizar';

  @override
  String get gameResults => 'Resultados';

  @override
  String gamePoints(int points) {
    return '$points puntos';
  }

  @override
  String get gameCorrect => '¡Correcto!';

  @override
  String get gameIncorrect => 'Incorrecto';

  @override
  String gameTimeLeft(int seconds) {
    return '${seconds}s';
  }

  @override
  String get typeYourAnswer => 'Escribe tu respuesta...';

  @override
  String get submitAnswer => 'Enviar';

  @override
  String get reportQuestion => 'Reportar pregunta';

  @override
  String get reportReason => 'Motivo del reporte';

  @override
  String get reportSubmitted => 'Reporte enviado. ¡Gracias!';

  @override
  String get friends => 'Amigos';

  @override
  String get addFriend => 'Añadir amigo';

  @override
  String get noFriends => 'No tienes amigos aún';

  @override
  String get noFriendsHint => 'Añade amigos para competir contra ellos.';

  @override
  String get online => 'En línea';

  @override
  String get offline => 'Desconectado';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String daysAgo(int days) {
    return 'hace $days días';
  }
}
