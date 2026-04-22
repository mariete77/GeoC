import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Inicializar Firebase Admin
admin.initializeApp();

const db = admin.firestore();

/**
 * Cloud Function: onUpdateMatchResult
 *
 * Se activa cuando el campo 'result' de un match es creado o actualizado.
 *
 * Esta función actualiza el ELO de ambos jugadores en sus documentos de usuario
 * en la colección /users/{userId}/elo, usando los valores calculados en el cliente.
 *
 * También actualiza las estadísticas (wins/losses/draws) basado en el resultado.
 *
 * Firestore structure:
 *   /matches/{matchId}/result = {
 *     winnerId: string | null,
 *     scores: { [userId]: number },
 *     eloChanges: { [userId]: number },
 *     newElo: { [userId]: number }
 *   }
 *
 *   /users/{userId} = {
 *     elo: number,
 *     stats: { wins, losses, draws, totalGames, ... }
 *   }
 */
export const onUpdateMatchResult = functions.firestore
  .document('matches/{matchId}')
  .onWrite(async (change, context) => {
    const { matchId } = context.params;

    // Solo procesar si existe el campo 'result' en el nuevo documento
    const newData = change.after.data();
    if (!newData || !newData.result) {
      return null;
    }

    const result = newData.result;
    const players = newData.players as string[];

    // Verificar que tenemos los datos necesarios
    if (!result.newElo || !result.eloChanges || !result.scores) {
      console.log(`Match ${matchId}: Estructura de 'result' incompleta`);
      return null;
    }

    const winnerId = result.winnerId as string | null;
    const newElo = result.newElo as { [userId: string]: number };
    const eloChanges = result.eloChanges as { [userId: string]: number };

    // Batch write para actualizar ambos jugadores atómicamente
    const batch = db.batch();

    for (const userId of players) {
      const userRef = db.collection('users').doc(userId);

      // Actualizar ELO con el valor calculado en el cliente
      batch.update(userRef, { elo: newElo[userId] });

      // Actualizar estadísticas basado en el resultado
      const statsUpdate: { [key: string]: admin.firestore.FieldValue } = {
        'stats.totalGames': admin.firestore.FieldValue.increment(1),
      };

      if (winnerId) {
        if (userId === winnerId) {
          statsUpdate['stats.wins'] = admin.firestore.FieldValue.increment(1);
          statsUpdate['stats.currentWinStreak'] =
            admin.firestore.FieldValue.increment(1);
        } else {
          statsUpdate['stats.losses'] = admin.firestore.FieldValue.increment(1);
          statsUpdate['stats.currentWinStreak'] = 0;
        }
      } else {
        // Empate
        statsUpdate['stats.draws'] = admin.firestore.FieldValue.increment(1);
      }

      batch.update(userRef, statsUpdate);

      console.log(
        `Match ${matchId}: Actualizando usuario ${userId}: ` +
          `ELO ${newElo[userId]} (${eloChanges[userId]} puntos)`
      );
    }

    // Ejecutar el batch
    await batch.commit();

    console.log(`Match ${matchId}: ELOs y estadísticas actualizados correctamente`);

    return null;
  });

/**
 * Cloud Function opcional: onCreateUser
 *
 * Se activa cuando un nuevo documento de usuario es creado.
 * Inicializa los valores por defecto si no están presentes.
 */
export const onCreateUser = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const { userId } = context.params;
    const data = snap.data();

    // Verificar si necesita inicialización
    const needsInit = data.elo === undefined || data.stats === undefined;

    if (needsInit) {
      const updates: { [key: string]: any } = {
        elo: 1000,
      };

      if (!data.stats) {
        updates.stats = {
          totalGames: 0,
          wins: 0,
          losses: 0,
          draws: 0,
          totalCorrectAnswers: 0,
          currentWinStreak: 0,
          bestWinStreak: 0,
        };
      }

      await snap.ref.update(updates);
      console.log(`Usuario ${userId} inicializado con valores por defecto`);
    }

    return null;
  });
